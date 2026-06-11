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
    @Published var peakScreenPositions: [String: CGPoint] = [:]

    // Capture + road state
    @Published var capturedImage: UIImage?
    @Published var roadResult: NearestRoadService.RoadResult?
    @Published var isSearchingRoad = false
    @Published var showRoadSheet = false
    @Published var photoSaved: Bool = false
    @Published var photoSaveError: String?

    let locationService = LocationManager()
    let visionEngine = VisionScanEngine()
    let motionManager = CMMotionManager()

    @Published var devicePitch: Double = 0.0
    @Published var deviceRoll: Double = 0.0
    @Published var headingIsLocked: Bool = false
    @Published var justLocked: Bool = false

    @Published var correctedHeading: Double? = nil
    @Published var skylineMatchQuality: Double = 0.0
    @Published var demIsAvailable: Bool = false
    @Published var showDEMDownloadPrompt: Bool = false
    @Published var isDownloadingDEM: Bool = false
    @Published var demDownloadProgress: Double = 0.0
    @Published var isSessionActive: Bool = true

    private let stabilizationFactor = 0.06
    private var demPromptShown = false
    private var stableFrameCount: Int = 0
    private let lockThresholdFrames: Int = 60
    private var cancellables = Set<AnyCancellable>()
    private var demCache = DEMReaderCache()
    private var demSkyline: [SkylinePoint] = []
    private var isSkylineRendering = false
    private var skylineRenderTask: Task<Void, Never>? = nil
    private let motionTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    init() {
        startMotion()
        bindData()
        checkDEMAvailability()
    }

    func pauseSession() {
        isSessionActive = false
        motionManager.stopDeviceMotionUpdates()
    }

    func resumeSession() {
        isSessionActive = true
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
            motionManager.startDeviceMotionUpdates()
        }
    }

    // MARK: - Capture

    func capturePhoto(arView: ARSCNView, contourPaths: [[CGPoint]]) {
        // snapshot() and UIKit drawing must happen on the main thread
        assert(Thread.isMainThread, "capturePhoto must be called from the main thread")

        let snapshot = arView.snapshot()
        let composite = drawContours(on: snapshot, paths: contourPaths)
        capturedImage = composite

        // Capture values needed inside the async closure before entering it
        let imageToSave = composite
        let confidenceAtCapture = self.confidenceScore
        let peakAtCapture = self.visiblePeaks.first
        let locationAtCapture = self.locationService.userLocation

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard let self = self else { return }

            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.photoSaveError = "Photo library access denied. Tap 'Open Settings' to allow access."
                    self.photoSaved = false
                    self.showRoadSheet = true
                    self.findNearestRoad()
                }
                return
            }

            // Show sheet immediately so the user isn't blocked waiting for save.
            DispatchQueue.main.async {
                self.showRoadSheet = true
                self.findNearestRoad()
            }

            // performChanges runs on PHPhotoLibrary's internal queue — no main-thread risk.
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: imageToSave)
            }) { [weak self] success, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.photoSaved = success
                    if success {
                        if let peak = peakAtCapture, let location = locationAtCapture {
                            let record = ScanRecord(
                                mountainName: peak.mountain.name,
                                mountainElevation: peak.mountain.elevation,
                                date: Date(),
                                confidenceScore: confidenceAtCapture,
                                userLatitude: location.coordinate.latitude,
                                userLongitude: location.coordinate.longitude
                            )
                            ScanRecord.save(record)
                        }
                    } else {
                        self.photoSaveError = error?.localizedDescription ?? "Failed to save photo."
                    }
                }
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

    // MARK: - DEM Download

    func promptDEMDownloadIfNeeded() {
        guard !demIsAvailable, !demPromptShown else { return }
        demPromptShown = true
        showDEMDownloadPrompt = true
    }

    func downloadDEMTiles() {
        guard let location = locationService.userLocation else { return }
        isDownloadingDEM = true
        demDownloadProgress = 0.0

        Task {
            let success = await DEMTileManager.shared.downloadTiles(for: location.coordinate) { progress in
                Task { @MainActor in
                    self.demDownloadProgress = progress
                }
            }
            await MainActor.run {
                self.isDownloadingDEM = false
                if success {
                    self.demIsAvailable = true
                    self.loadDEMAndRenderSkyline()
                }
            }
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

        locationService.$userLocation
            .compactMap { $0 }
            .first()
            .sink { [weak self] _ in
                self?.checkDEMAvailability()
            }
            .store(in: &cancellables)

        motionTimer
            .sink { [weak self] _ in
                guard let self = self, self.isSessionActive, let motion = self.motionManager.deviceMotion else { return }
                let newPitch = motion.attitude.pitch * 180 / .pi
                let newRoll = motion.attitude.roll * 180 / .pi
                self.devicePitch = (newPitch * self.stabilizationFactor) + (self.devicePitch * (1 - self.stabilizationFactor))
                self.deviceRoll = (newRoll * self.stabilizationFactor) + (self.deviceRoll * (1 - self.stabilizationFactor))

                // Heading lock detection
                let r = motion.rotationRate
                let magnitude = sqrt(r.x * r.x + r.y * r.y + r.z * r.z)
                if magnitude < 0.05 {
                    self.stableFrameCount += 1
                    if self.stableFrameCount >= self.lockThresholdFrames && !self.headingIsLocked {
                        self.headingIsLocked = true
                        self.justLocked = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                            self?.justLocked = false
                        }
                    }
                } else {
                    self.stableFrameCount = 0
                    if self.headingIsLocked {
                        self.headingIsLocked = false
                    }
                }

                self.updatePeaksAndConfidence()
            }
            .store(in: &cancellables)

        visionEngine.$saliencyFound
            .sink { [weak self] _ in self?.updatePeaksAndConfidence() }
            .store(in: &cancellables)
    }

    private func checkDEMAvailability() {
        Task {
            guard let location = locationService.userLocation else { return }
            let available = await DEMTileManager.shared.areAllTilesDownloaded(for: location.coordinate)
            await MainActor.run {
                self.demIsAvailable = available
                if available {
                    self.loadDEMAndRenderSkyline()
                }
            }
        }
    }

    private func loadDEMAndRenderSkyline() {
        guard !isSkylineRendering else { return }
        guard let location = locationService.userLocation else { return }
        isSkylineRendering = true

        skylineRenderTask?.cancel()
        skylineRenderTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            var cache = DEMReaderCache()
            cache.load(tilesFor: location.coordinate)

            // CPU-intensive (~50ms), runs off main thread
            let skyline = DEMSkylineRenderer.render(from: location, using: cache)

            await MainActor.run {
                self.demCache = cache
                self.demSkyline = skyline
                self.isSkylineRendering = false
            }
        }
    }

    private func runSkylineMatch(heading: Double) {
        guard !demSkyline.isEmpty,
              !visionEngine.contourPaths.isEmpty else { return }

        let contours = visionEngine.contourPaths
        let skyline = demSkyline

        let visionProfile = VisionSkylineExtractor.extract(from: contours, heading: heading)
        guard visionProfile.isUsable else { return }

        guard let result = SkylineProfileMatcher.match(
            visionProfile: visionProfile,
            demSkyline: skyline,
            currentHeading: heading
        ) else { return }

        if result.isReliable {
            var corrected = heading + result.correctionDegrees
            corrected = (corrected + 360).truncatingRemainder(dividingBy: 360)
            self.correctedHeading = corrected
        } else {
            self.correctedHeading = nil
        }
        self.skylineMatchQuality = result.quality
    }

    private func updatePeaksAndConfidence() {
        guard let location = locationService.userLocation,
              let heading = locationService.heading else { return }

        let rawHeading = heading.trueHeading

        // Use DEM-corrected heading when available, fall back to magnetometer
        let effectiveHeading = correctedHeading ?? rawHeading

        // Run skyline matching on every update (fast — the heavy render is already done)
        runSkylineMatch(heading: rawHeading)

        // Find all peaks within range
        let allPeaks = PeakFinderService.findVisiblePeaks(
            userLocation: location,
            mountains: Mountain.data,
            maxDistance: 100_000
        )

        // Filter to peaks within ±45° of effective heading
        // Normalised delta handles 0°/360° wrap correctly
        self.visiblePeaks = allPeaks.filter { peak in
            let delta = (peak.azimuth - effectiveHeading + 540)
                .truncatingRemainder(dividingBy: 360) - 180
            return abs(delta) < 45
        }

        // Confidence scoring — 5-signal weighted model (100 pts total)
        let horizAccuracy = location.horizontalAccuracy
        let gpsScore: Double = horizAccuracy <= 20 ? 40 : horizAccuracy <= 50 ? 25 : 10

        let stability = abs(self.deviceRoll) + abs(self.devicePitch)
        let gyroScore: Double = stability <= 10 ? 35 : stability <= 20 ? 20 : 5

        let compassScore: Double = heading.headingAccuracy <= 20 ? 15 : 8

        let visionScore: Double = visionEngine.saliencyFound ? 5 : 0

        var skylineScore: Double = 0
        if demIsAvailable {
            if skylineMatchQuality >= 0.6 {
                skylineScore = 5
            } else if skylineMatchQuality < 0.2 {
                skylineScore = -5
            }
        }

        self.confidenceScore = max(0, min(100, gpsScore + gyroScore + compassScore + visionScore + skylineScore))
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}
