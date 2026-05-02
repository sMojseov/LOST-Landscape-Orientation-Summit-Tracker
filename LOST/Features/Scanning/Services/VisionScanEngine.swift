import Foundation
import Vision
import CoreImage
import CoreVideo
import Combine

class VisionScanEngine: ObservableObject {
    @Published var horizonAngle: Double = 0.0
    @Published var saliencyFound: Bool = false
    @Published var contourPaths: [[CGPoint]] = []

    private let requestQueue = DispatchQueue(label: "vision.scan.queue", qos: .userInitiated)
    private var isProcessing = false

    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard !isProcessing else { return }
        isProcessing = true

        requestQueue.async { [weak self] in
            guard let self = self else { return }
            defer { self.isProcessing = false }

            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

            let horizonRequest = VNDetectHorizonRequest { [weak self] request, _ in
                guard let self = self,
                      let observation = (request.results as? [VNHorizonObservation])?.first else { return }
                DispatchQueue.main.async {
                    self.horizonAngle = Double(observation.angle) * 180 / .pi
                }
            }

            let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest { [weak self] request, _ in
                guard let self = self,
                      let observation = (request.results as? [VNSaliencyImageObservation])?.first else { return }
                DispatchQueue.main.async {
                    self.saliencyFound = observation.salientObjects?.isEmpty == false
                }
            }

            let contourRequest = VNDetectContoursRequest { [weak self] request, _ in
                guard let self = self,
                      let observation = (request.results as? [VNContoursObservation])?.first else {
                    DispatchQueue.main.async { self?.contourPaths = [] }
                    return
                }

                var paths: [[CGPoint]] = []
                for contour in observation.topLevelContours {
                    let raw = Array(contour.normalizedPoints)
                    guard raw.count > 20 else { continue }

                    // Skip tiny contours (less than 5% of frame in either dimension)
                    let xs = raw.map { CGFloat($0.x) }
                    let ys = raw.map { CGFloat($0.y) }
                    let spanX = (xs.max() ?? 0) - (xs.min() ?? 0)
                    let spanY = (ys.max() ?? 0) - (ys.min() ?? 0)
                    guard spanX > 0.05 || spanY > 0.05 else { continue }

                    // Downsample long paths for render performance
                    let step = max(1, raw.count / 120)
                    let sampled = stride(from: 0, to: raw.count, by: step).map { raw[$0] }

                    // Vision origin is bottom-left; flip Y for screen space
                    let cgPoints = sampled.map { CGPoint(x: CGFloat($0.x), y: 1.0 - CGFloat($0.y)) }
                    paths.append(cgPoints)

                    if paths.count >= 25 { break }
                }

                DispatchQueue.main.async {
                    self.contourPaths = paths
                }
            }
            contourRequest.contrastAdjustment = 2.0
            contourRequest.detectsDarkOnLight = true

            do {
                try requestHandler.perform([horizonRequest, saliencyRequest, contourRequest])
            } catch {
                print("Vision engine failed: \(error)")
            }
        }
    }
}
