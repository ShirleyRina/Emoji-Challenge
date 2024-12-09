//
//  ViewController.swift
//  Emoji Challenge
//
//  Created by shirley on 12/8/24.
//

import UIKit
import Vision
import AVFoundation



class GameViewController: UIViewController {
    @IBOutlet weak var cameraView: CameraView!

    @IBOutlet var gameView: GameView!
    var model = GameModel()
    private var sequenceHandler = VNSequenceRequestHandler() // 用于处理 Vision 请求

        override func viewDidLoad() {
            super.viewDidLoad()
            requestCameraPermission { [weak self] granted in
                if granted {
                    self?.cameraView.startCamera()
                    self?.setupVideoOutput()
                } else {
                    print("Camera permission denied.")
                }
            }
        }

        // 配置摄像头输出
        private func setupVideoOutput() {
            guard let captureSession = cameraView.captureSession else { return }
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoOutputQueue"))
            captureSession.addOutput(videoOutput)
        }

        // 处理摄像头帧
        private func handleFaceDetection(buffer: CMSampleBuffer) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }

            let faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
                guard let results = request.results as? [VNFaceObservation], let self = self else { return }
                if let face = results.first {
                    self.processFaceObservation(face) // 处理检测到的面部
                }
            }

            // 运行请求
            try? sequenceHandler.perform([faceDetectionRequest], on: pixelBuffer)
        }

        // 处理面部特征点
        private func processFaceObservation(_ observation: VNFaceObservation) {
            if let landmarks = observation.landmarks {
                // 示例：判断用户是否在微笑
                let isSmiling = landmarks.mouthSmile?.confidence ?? 0 > 0.5
                let detectedEmoji = isSmiling ? "😊" : "😢"
                handleDetectedEmoji(playerEmoji: detectedEmoji)
            }
        }

        // 处理检测到的表情
        func handleDetectedEmoji(playerEmoji: String) {
            let isMatch = model.checkMatch(playerEmoji: playerEmoji)
            model.updateScore(isMatch: isMatch)
            gameView.playFeedbackAnimation(isMatch: isMatch)
            model.currentEmoji = model.generateRandomEmoji()
            gameView.updateEmoji(model.currentEmoji)
            gameView.updateScore(model.score)
        }
}
    extension GameViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            handleFaceDetection(buffer: sampleBuffer)
        }
    }
    // 扩展添加权限请求方法
    extension GameViewController {
        func requestCameraPermission(completion: @escaping (Bool) -> Void) {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                completion(true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            case .denied, .restricted:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }



