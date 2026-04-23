import Foundation
import CoreLocation
import CoreMotion
import Combine
import ARKit
import SceneKit
import Photos
import UIKit

class ScanningViewModel: ObservableObject {
    @Published var visiblePeaks: [VisiblePeak] = []
    @Published var confidenceScore: Double = 0.0

    // Capture + road state
    @Published var capturedImage: UIImage?
    @Published var roadResult: NearestRoadService.RoadResult?
    @Published var isSearchingRoad = false
    @Published var showRoadSheet = false
    @Published var photoSaveError: String?

    let locationService = LocationManager()
    let visionEngine = VisionScanEngine()
    let motionManager = CMMotionManager()

    @Published var devicePitch: Double = 0.0
    @Published var deviceRoll: Double = 0.0

    private let stabilizationFactor = 0.15
    private var cancellables = Set<AnyCancellable>()
    private let motionTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    init() {
        startMotion()
        bindData()
    }

    // MARK: - Capture

    func capturePhoto(arView: ARSCNView, contourPaths: [[CGPoint]]) {
        let snapshot = arView.snapshot()
        let composite = drawContours(on: snapshot, paths: contourPaths)
        capturedImage = composite

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard let self = self else { return }
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.photoSaveError = "Photo library access denied."
                    self.showRoadSheet = true
                }
                return
            }
            UIImageWriteToSavedPhotosAlbum(composite, nil, nil, nil)
            DispatchQueue.main.async {
                self.showRoadSheet = true
                self.findNearestRoad()
            }
        }
    }

    func findNearestRoad() {
        guard let location = locationService.userLocation else { return }
        isSearchingRoad = true
        Task { @MainActor in
            let result = await NearestRoadService.find(from: location)
            self.roadResult = result
            self.isSearchingRoad = false
        }
    }

    // MARK: - Private

    private func drawContours(on image: UIImage, paths: [[CGPoint]]) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { ctx in
            image.draw(at: .zero)
            let cg = ctx.cgContext
            cg.setLineWidth(2.5)
            cg.setLineCap(.round)
            cg.setLineJoin(.round)

            for path in paths {
                guard path.count > 1 else { continue }
                // Glow pass
                cg.setStrokeColor(UIColor.systemGreen.withAlphaComponent(0.25).cgColor)
                cg.setLineWidth(6)
                cg.beginPath()
                cg.move(to: CGPoint(x: path[0].x * image.size.width, y: path[0].y * image.size.height))
                for pt in path.dropFirst() {
                    cg.addLine(to: CGPoint(x: pt.x * image.size.width, y: pt.y * image.size.height))
                }
                cg.closePath()
                cg.strokePath()

                // Sharp pass
                cg.setStrokeColor(UIColor.systemGreen.withAlphaComponent(0.85).cgColor)
                cg.setLineWidth(1.5)
                cg.beginPath()
                cg.move(to: CGPoint(x: path[0].x * image.size.width, y: path[0].y * image.size.height))
                for pt in path.dropFirst() {
                    cg.addLine(to: CGPoint(x: pt.x * image.size.width, y: pt.y * image.size.height))
                }
                cg.closePath()
                cg.strokePath()
            }
        }
    }

    // MARK: - Motion & Peaks

    private func startMotion() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
            motionManager.startDeviceMotionUpdates()
        }
    }

    private func bindData() {
        locationService.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        motionTimer
            .sink { [weak self] _ in
                guard let self = self, let motion = self.motionManager.deviceMotion else { return }
                let newPitch = motion.attitude.pitch * 180 / .pi
                let newRoll = motion.attitude.roll * 180 / .pi
                self.devicePitch = (newPitch * self.stabilizationFactor) + (self.devicePitch * (1 - self.stabilizationFactor))
                self.deviceRoll = (newRoll * self.stabilizationFactor) + (self.deviceRoll * (1 - self.stabilizationFactor))
                self.updatePeaksAndConfidence()
            }
            .store(in: &cancellables)

        visionEngine.$saliencyFound
            .sink { [weak self] _ in self?.updatePeaksAndConfidence() }
            .store(in: &cancellables)
    }

    private func updatePeaksAndConfidence() {
        guard let location = locationService.userLocation,
              let heading = locationService.heading else { return }

        let allPeaks = PeakFinderService.findVisiblePeaks(userLocation: location, mountains: Mountain.data)
        self.visiblePeaks = allPeaks.filter { peak in
            let angleDiff = abs(peak.azimuth - heading.trueHeading)
            return min(angleDiff, 360 - angleDiff) < 45
        }

        var score = 100.0
        let horizAccuracy = location.horizontalAccuracy
        if horizAccuracy > 20 { score -= 15 }
        if horizAccuracy > 50 { score -= 20 }
        let stability = abs(self.deviceRoll) + abs(self.devicePitch)
        if stability > 10 { score -= 10 }
        if stability > 20 { score -= 15 }
        if !visionEngine.saliencyFound { score -= 10 }
        if heading.headingAccuracy > 20 { score -= 10 }
        self.confidenceScore = max(0, min(100, score))
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}
