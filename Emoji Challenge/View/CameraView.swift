//
//  CameraView.swift
//  Emoji Challenge
//
//  Created by shirley on 12/8/24.
//

import Foundation
import UIKit
import AVFoundation

//A fundamental camera view
class CameraView: UIView {
    var captureSession: AVCaptureSession? 

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    func startCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession,
              let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("Error setting up camera")
            return
        }

        captureSession.addInput(videoInput)
        videoPreviewLayer.session = captureSession
        videoPreviewLayer.videoGravity = .resizeAspectFill
        captureSession.startRunning()
    }

    func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
    }
}
