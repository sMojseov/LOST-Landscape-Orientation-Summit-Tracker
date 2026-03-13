//
//  CameraView.swift
//  LOST
//
//  Created by Stefan Mojseov on 04.03.26.
//

import SwiftUI
import AVFoundation
import Combine // Add this import

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            if cameraManager.isAuthorized {
                CameraPreview(session: cameraManager.session)
            } else if cameraManager.isDenied {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Text("Camera Access Denied")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear {
            cameraManager.checkPermission()
        }
    }
}

class CameraManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var isDenied = false
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.isAuthorized = true
                        self.startSession()
                    } else {
                        self.isDenied = true
                    }
                }
            }
        case .denied, .restricted:
            isDenied = true
        @unknown default:
            isDenied = true
        }
    }
    
    private func startSession() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            
            self.session.beginConfiguration()
            
            // Set session preset to .photo for 4:3 aspect ratio
            if self.session.canSetSessionPreset(.photo) {
                self.session.sessionPreset = .photo
            }
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoDeviceInput) else {
                self.session.commitConfiguration()
                return
            }
            
            self.session.addInput(videoDeviceInput)
            
            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspect
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}

#Preview {
    CameraView()
}
