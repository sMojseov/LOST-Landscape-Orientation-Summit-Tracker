//
//  ScanningView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI
import CoreMotion
import CoreLocation
import Combine
import AVFoundation
import ARKit
import SceneKit
import MapKit

struct ScanningView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ScanningViewModel()
    @State private var isScanning = false
    @State private var torchOn = false
    @State private var arSceneViewRef: ARSCNView?
    @State private var showGuideBox = true
    @State private var guideBoxTimer: Timer? = nil
    @Environment(\.colorScheme) var colorScheme

    private var canCapture: Bool {
        viewModel.confidenceScore >= 40
    }

    private var deviceIsLevel: Bool {
        abs(viewModel.deviceRoll) <= 3.0
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = width * 4 / 3
            let cameraCenterY = geometry.size.height / 2

            ZStack {
                Color.black.ignoresSafeArea()

                // ARKit Camera & 3D Anchors
                ARSceneView(viewModel: viewModel, sceneViewRef: $arSceneViewRef)
                    .frame(width: width, height: height)
                    .clipped()
                    .position(x: width / 2, y: cameraCenterY)

                // Contour outline overlay
                if isScanning {
                    ContourOverlayView(paths: viewModel.visionEngine.contourPaths)
                        .frame(width: width, height: height)
                        .position(x: width / 2, y: cameraCenterY)
                        .allowsHitTesting(false)
                }

                // 3×3 alignment grid
                if isScanning {
                    ZStack {
                        HStack {
                            Spacer()
                            Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1)
                            Spacer()
                            Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1)
                            Spacer()
                        }
                        VStack {
                            Spacer()
                            Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                            Spacer()
                            Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
                            Spacer()
                        }
                    }
                    .frame(width: width, height: height)
                    .position(x: width / 2, y: cameraCenterY)
                }

                // Peak label overlays — SwiftUI screen-space (replaces SCNText 3D nodes)
                if isScanning {
                    let arOffsetY = cameraCenterY - height / 2
                    ForEach(viewModel.visiblePeaks) { peak in
                        if let pos = viewModel.peakScreenPositions[peak.mountain.name] {
                            PeakLabelView(peak: peak, confidence: viewModel.confidenceScore)
                                .position(x: pos.x, y: pos.y + arOffsetY)
                        }
                    }
                }

                // Horizon alignment guide box
                if isScanning && showGuideBox {
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                Color.sageGreen.opacity(0.75),
                                style: StrokeStyle(lineWidth: 1.5, dash: [8, 5])
                            )
                            .frame(width: width * 0.80, height: height * 0.35)

                        Text("ALIGN PEAKS HERE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.sageGreen.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                            .offset(y: -12)
                    }
                    .position(x: width / 2, y: cameraCenterY)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: showGuideBox)
                }

                // Top overlay
                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            Text(viewModel.correctedHeading.map { String(format: "%.0f° ⊕", $0) }
                                 ?? formatHeading(viewModel.locationService.heading))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.ultraThinMaterial).overlay(Color.sageGreen.opacity(0.25)))
                        .overlay(Capsule().stroke(Color.sageGreen.opacity(0.4), lineWidth: 0.5))

                        if isScanning && viewModel.headingIsLocked {
                            Text("LOCKED")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.sageGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.sageGreen.opacity(0.15))
                                        .overlay(Capsule().stroke(Color.sageGreen.opacity(0.4), lineWidth: 0.5))
                                )
                                .scaleEffect(viewModel.justLocked ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.justLocked)
                                .transition(.scale.combined(with: .opacity))
                        }

                        Spacer()

                        if isScanning {
                            HStack(spacing: 6) {
                                // DEM active badge
                                if viewModel.demIsAvailable {
                                    HStack(spacing: 3) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 8))
                                        Text("DEM")
                                            .font(.system(size: 9, weight: .black, design: .monospaced))
                                    }
                                    .foregroundColor(.sageGreen)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.sageGreen.opacity(0.12)))
                                    .overlay(Capsule().stroke(Color.sageGreen.opacity(0.3), lineWidth: 0.5))
                                    .transition(.scale.combined(with: .opacity))
                                }
                                // Contour count badge
                                HStack(spacing: 4) {
                                    Circle().fill(Color.sageGreen).frame(width: 6, height: 6)
                                    Text("\(viewModel.visionEngine.contourPaths.count) outlines")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.sageGreen)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(.ultraThinMaterial).overlay(Color.sageGreen.opacity(0.12)))
                                .overlay(Capsule().stroke(Color.sageGreen.opacity(0.3), lineWidth: 0.5))
                            }
                        } else {
                            Text("4:3")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.top, 56)
                    .padding(.horizontal, 16)
                    Spacer()
                }

                // Gyro level line
                if isScanning {
                    VStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(abs(viewModel.deviceRoll) <= 2.0 ? Color.white.opacity(0.9) : Color.yellow.opacity(0.9))
                                .frame(width: 6, height: 6)
                            Rectangle()
                                .fill(abs(viewModel.deviceRoll) <= 2.0 ? Color.white.opacity(0.9) : Color.yellow.opacity(0.9))
                                .frame(width: 140, height: 1.5)
                            Circle()
                                .fill(abs(viewModel.deviceRoll) <= 2.0 ? Color.white.opacity(0.9) : Color.yellow.opacity(0.9))
                                .frame(width: 6, height: 6)
                        }
                        .overlay(alignment: .topTrailing) {
                            Text(String(format: "%.1f°", abs(viewModel.deviceRoll)))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(abs(viewModel.deviceRoll) <= 2.0 ? .white.opacity(0.9) : .yellow.opacity(0.9))
                                .offset(x: 20, y: -14)
                        }
                        .rotationEffect(Angle(degrees: viewModel.visionEngine.horizonAngle != 0
                            ? viewModel.visionEngine.horizonAngle
                            : viewModel.deviceRoll))
                        .animation(.easeOut(duration: 0.25), value: viewModel.deviceRoll)
                    }
                    .position(x: width / 2, y: cameraCenterY)
                }

                // Bottom controls
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        HUDGlassCard(label: "Altitude", value: String(format: "%.0fm", viewModel.locationService.altitude))
                        HUDGlassCard(label: "Heading", value: formatHeading(viewModel.locationService.heading))
                        HUDGlassCard(label: "Confidence", value: isScanning
                            ? (viewModel.skylineMatchQuality > 0.3
                                ? "\(Int(viewModel.confidenceScore))% ◈"
                                : "\(Int(viewModel.confidenceScore))%")
                            : "--")
                    }
                    .padding(.horizontal, 16)

                    if isScanning && !viewModel.demIsAvailable && !viewModel.isDownloadingDEM {
                        Button { viewModel.showDEMDownloadPrompt = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 10, weight: .bold))
                                Text("ENHANCE · Download terrain")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.sageGreen.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.ultraThinMaterial).overlay(Color.sageGreen.opacity(0.08)))
                            .overlay(Capsule().stroke(Color.sageGreen.opacity(0.25), lineWidth: 0.5))
                        }
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                    }

                    VStack(spacing: 8) {
                        HStack(spacing: 40) {
                        // Stop scanning / cancel
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                isScanning = false
                            }
                        } label: {
                            Image(systemName: isScanning ? "xmark" : "arrow.uturn.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 48, height: 48)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }

                        // Main shutter: start scan or capture
                        Button {
                            if isScanning {
                                guard canCapture else { return }
                                if let arView = arSceneViewRef {
                                    viewModel.capturePhoto(
                                        arView: arView,
                                        contourPaths: viewModel.visionEngine.contourPaths
                                    )
                                }
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    isScanning = true
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .strokeBorder(
                                        isScanning
                                            ? (canCapture ? Color.sageGreen.opacity(0.9) : Color.white.opacity(0.3))
                                            : Color.white.opacity(0.85),
                                        lineWidth: 2
                                    )
                                    .frame(width: 72, height: 72)
                                if isScanning {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(canCapture ? .sageGreen : Color.white.opacity(0.3))
                                } else {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 62, height: 62)
                                }
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isScanning)
                        }

                        // Torch
                        Button {
                            torchOn.toggle()
                            toggleTorch(on: torchOn)
                        } label: {
                            Image(systemName: torchOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(torchOn ? .yellow : .white.opacity(0.8))
                                .frame(width: 48, height: 48)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        }

                        if isScanning && !canCapture {
                            Text("Hold steady for a better scan")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.2), value: canCapture)
                        }
                    }
                }
                .padding(.bottom, 110)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // DEM download progress overlay
                if viewModel.isDownloadingDEM {
                    VStack(spacing: 12) {
                        Text("DOWNLOADING TERRAIN")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.sageGreen)
                        ProgressView(value: viewModel.demDownloadProgress)
                            .tint(.sageGreen)
                            .frame(width: 200)
                            .animation(.linear, value: viewModel.demDownloadProgress)
                        Text("\(Int(viewModel.demDownloadProgress * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .overlay(Color.sageGreen.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sageGreen.opacity(0.3), lineWidth: 1))
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear { lockOrientation(.portrait) }
        .onDisappear {
            lockOrientation(.all)
            if torchOn { toggleTorch(on: false) }
        }
        .sheet(isPresented: $viewModel.showRoadSheet, onDismiss: {
            viewModel.photoSaved = false
            viewModel.photoSaveError = nil
        }) {
            RoadNavigationSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: isScanning) { _, scanning in
            if scanning {
                showGuideBox = true
                guideBoxTimer?.invalidate()
                guideBoxTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                    DispatchQueue.main.async {
                        if deviceIsLevel {
                            withAnimation { showGuideBox = false }
                        }
                    }
                }
            } else {
                guideBoxTimer?.invalidate()
                showGuideBox = true
            }
        }
        .onChange(of: viewModel.deviceRoll) { _, roll in
            if isScanning && abs(roll) > 8.0 && !showGuideBox {
                withAnimation { showGuideBox = true }
                guideBoxTimer?.invalidate()
                guideBoxTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                    DispatchQueue.main.async {
                        if deviceIsLevel {
                            withAnimation { showGuideBox = false }
                        }
                    }
                }
            }
        }
        .onChange(of: isScanning) { _, scanning in
            if scanning { viewModel.promptDEMDownloadIfNeeded() }
        }
        .onChange(of: appState.selectedTab) { _, newTab in
            let onScanTab = newTab == AppState.Tab.scan.rawValue
            if onScanTab {
                viewModel.resumeSession()
                if let arView = arSceneViewRef {
                    let config = ARWorldTrackingConfiguration()
                    config.worldAlignment = .gravityAndHeading
                    arView.session.run(config)
                }
            } else {
                viewModel.pauseSession()
                arSceneViewRef?.session.pause()
                if torchOn {
                    torchOn = false
                    toggleTorch(on: false)
                }
            }
        }
        .alert("Terrain Matching", isPresented: $viewModel.showDEMDownloadPrompt) {
            Button("Download") { viewModel.downloadDEMTiles() }
            Button("Not Now", role: .cancel) { }
        } message: {
            Text("Download SRTM elevation data to enable skyline-based heading correction. Improves peak identification accuracy in mountainous terrain.")
        }
    }

    // MARK: - Helpers

    private func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = orientation
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            }
        } else {
            UIDevice.current.setValue(
                orientation == .portrait ? UIInterfaceOrientation.portrait.rawValue : UIInterfaceOrientation.unknown.rawValue,
                forKey: "orientation"
            )
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch { print("Torch error: \(error)") }
    }

    private func formatHeading(_ heading: CLHeading?) -> String {
        guard let h = heading else { return "0° N" }
        let degrees = h.magneticHeading
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
        let index = Int((degrees + 22.5) / 45.0) & 7
        return String(format: "%.0f° %@", degrees, directions[index])
    }
}

// MARK: - Contour Overlay

struct ContourOverlayView: View {
    let paths: [[CGPoint]]

    var body: some View {
        Canvas { context, size in
            for path in paths {
                guard path.count > 1 else { continue }

                var p = Path()
                p.move(to: CGPoint(x: path[0].x * size.width, y: path[0].y * size.height))
                for pt in path.dropFirst() {
                    p.addLine(to: CGPoint(x: pt.x * size.width, y: pt.y * size.height))
                }
                p.closeSubpath()

                // Glow
                context.stroke(p, with: .color(.sageGreen.opacity(0.2)),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                // Sharp line
                context.stroke(p, with: .color(.sageGreen.opacity(0.85)),
                                style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Road Navigation Sheet

struct RoadNavigationSheet: View {
    @ObservedObject var viewModel: ScanningViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let err = viewModel.photoSaveError {
                            Text("SAVE FAILED")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.red)
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Text("Open Settings")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.sageGreen)
                            }
                            .padding(.top, 2)
                        } else if viewModel.photoSaved {
                            Text("SCAN SAVED")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.sageGreen)
                            Text("Nearest Road")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        } else {
                            Text("SAVING…")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Nearest Road")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                    if let img = viewModel.capturedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.sageGreen.opacity(0.4), lineWidth: 1))
                    }
                }
                .padding()

                Divider().background(Color.white.opacity(0.08))

                if viewModel.isSearchingRoad {
                    VStack(spacing: 12) {
                        ProgressView().tint(.sageGreen)
                        Text("Locating nearest road…")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if let road = viewModel.roadResult {
                    VStack(spacing: 16) {
                        // Direction compass card
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.sageGreen.opacity(0.12))
                                    .frame(width: 64, height: 64)
                                    .overlay(Circle().stroke(Color.sageGreen.opacity(0.3), lineWidth: 1))
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.sageGreen)
                                    .rotationEffect(.degrees(road.bearingDegrees))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(road.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text(formattedDistance(road.distanceMeters))
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.sageGreen)
                                Text(bearingLabel(road.bearingDegrees))
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        .padding(.horizontal)

                        // Walking tip
                        HStack(spacing: 10) {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.earthGold)
                                .font(.system(size: 14))
                            Text("Follow the arrow. Stay on ridgelines and avoid dense vegetation.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.55))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal)

                        // Navigate button
                        Button {
                            road.mapItem.openInMaps(launchOptions: [
                                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
                            ])
                        } label: {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Open in Maps")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.sageGreen)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal)

                        Button {
                            viewModel.showRoadSheet = false
                        } label: {
                            Text("Dismiss")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.bottom, 8)
                    }
                    .padding(.top, 16)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "road.lanes")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.2))
                        Text("No road found nearby")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.4))
                        Text("You may be in a remote area. Try moving to higher ground for better GPS signal.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 40)

                    Button {
                        viewModel.showRoadSheet = false
                    } label: {
                        Text("Dismiss")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km away", meters / 1000)
        } else {
            return String(format: "%.0f m away", meters)
        }
    }

    private func bearingLabel(_ degrees: Double) -> String {
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let idx = Int((degrees + 22.5) / 45.0) % 8
        return "Head \(dirs[idx]) · \(Int(degrees))°"
    }
}

// MARK: - ARSceneView

struct ARSceneView: UIViewRepresentable {
    @ObservedObject var viewModel: ScanningViewModel
    @Binding var sceneViewRef: ARSCNView?

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator

        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        DispatchQueue.main.async { self.sceneViewRef = arView }
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        let existingNames = uiView.scene.rootNode.childNodes.compactMap { $0.name }

        for peak in viewModel.visiblePeaks where !existingNames.contains(peak.mountain.name) {
            let azRadians = peak.azimuth * .pi / 180
            let elRadians = peak.elevationAngle * .pi / 180
            let d: Float = 50.0
            let x = d * Float(sin(azRadians))
            let z = -d * Float(cos(azRadians))
            let y = d * Float(tan(elRadians))

            let node = SCNNode()
            node.name = peak.mountain.name
            node.position = SCNVector3(x, y, z)
            uiView.scene.rootNode.addChildNode(node)
        }

        let visibleNames = viewModel.visiblePeaks.map { $0.mountain.name }
        for child in uiView.scene.rootNode.childNodes {
            if let name = child.name, !visibleNames.contains(name) {
                child.removeFromParentNode()
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, ARSessionDelegate, ARSCNViewDelegate {
        var parent: ARSceneView
        private var lastProcessTime: TimeInterval = 0

        init(_ parent: ARSceneView) {
            self.parent = parent
            super.init()
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard parent.viewModel.isSessionActive else { return }
            let now = CACurrentMediaTime()
            if now - lastProcessTime > 0.1 {
                parent.viewModel.visionEngine.processFrame(frame.capturedImage)
                lastProcessTime = now
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard let sceneView = renderer as? ARSCNView else { return }
            
            // Ensure UI operations like accessing view bounds or projecting points are on the main thread
            DispatchQueue.main.async {
                let bounds = sceneView.bounds
                let margin: CGFloat = 60

                var positions: [String: CGPoint] = [:]
                for node in sceneView.scene.rootNode.childNodes {
                    guard let name = node.name else { continue }
                    let projected = sceneView.projectPoint(node.worldPosition)
                    // z < 1 means the point is in front of the camera
                    guard projected.z > 0 && projected.z < 1 else { continue }
                    let x = min(max(CGFloat(projected.x), margin), bounds.width - margin)
                    let y = min(max(CGFloat(projected.y), margin), bounds.height - margin)
                    positions[name] = CGPoint(x: x, y: y)
                }

                self.parent.viewModel.peakScreenPositions = positions
            }
        }
    }
}

// MARK: - HUD Card

struct HUDGlassCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.sageGreen.opacity(0.7))
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial)
        .overlay(Color.sageGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Peak Label (screen-space SwiftUI overlay)

struct PeakLabelView: View {
    let peak: VisiblePeak
    let confidence: Double

    private var dotColor: Color {
        if confidence >= 75 { return .sageGreen }
        if confidence >= 50 { return .earthGold }
        return Color.red.opacity(0.7)
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(peak.mountain.name)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(String(format: "%.0fm · %.1fkm",
                            Double(peak.mountain.elevation),
                            peak.distance / 1000))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .overlay(Color.sageGreen.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(Color.sageGreen.opacity(0.4), lineWidth: 0.5))
        .allowsHitTesting(false)
    }
}
