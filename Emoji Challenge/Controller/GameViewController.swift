//
//  ViewController.swift
//  Emoji Challenge
//
//  Created by shirley on 12/8/24.
//
import CoreML
import UIKit
import Vision
import AVFoundation

// 定义 CoreML 模型
var mlModel: VNCoreMLModel = {
    do {
        // 使用 init(configuration:) 初始化 CoreML 模型
        let configuration = MLModelConfiguration() // 可调整模型性能的配置
        let coreMLModel = try VNCoreMLModel(for: EmojiChallengeClassfier(configuration: configuration).model)
        return coreMLModel
    } catch {
        fatalError("Failed to load CoreML model: \(error)")
    }
}()



class GameViewController: UIViewController {
    @IBOutlet weak var cameraView: CameraView!

    @IBOutlet var gameView: GameView!
    var model = GameModel()
    
    
    private var sequenceHandler = VNSequenceRequestHandler() // 用于处理 Vision 请求

        override func viewDidLoad() {
            super.viewDidLoad()

            // 初始化表情障碍和分数
            gameView.updateEmoji("happy")  // 设置初始表情
            gameView.updateScore(0)        // 设置初始分数

            // 请求相机权限并启动摄像头
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

        // 人脸检测请求
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let results = request.results as? [VNFaceObservation], let self = self else { return }
            
            // 处理检测到的第一个面部
            if let face = results.first {
                self.processFaceObservation(face, in: pixelBuffer)
            }
        }

        // 运行人脸检测请求
        try? sequenceHandler.perform([faceDetectionRequest], on: pixelBuffer)
    }

    private func processFaceObservation(_ face: VNFaceObservation, in pixelBuffer: CVPixelBuffer) {
        // 将人脸区域转换为适合模型输入的图像
        let faceCropRect = VNImageRectForNormalizedRect(
            face.boundingBox,
            Int(CVPixelBufferGetWidth(pixelBuffer)),
            Int(CVPixelBufferGetHeight(pixelBuffer))
        )

        // 裁剪图像
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).cropped(to: faceCropRect)
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        // 创建 CoreML 分类请求
        let classificationRequest = VNCoreMLRequest(model: mlModel) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let bestResult = results.first else {
                print("Failed to classify face")
                return
            }

            // 获取分类结果
            let detectedEmoji = bestResult.identifier
            print("Detected Emoji: \(detectedEmoji)")

            // 调用游戏逻辑处理分类结果
            self?.handleDetectedEmoji(playerEmoji: detectedEmoji)
        }

        // 执行分类请求
        try? handler.perform([classificationRequest])
    }


    

        // 处理检测到的表情
    func handleDetectedEmoji(playerEmoji: String) {
        // 检查匹配结果
        let isMatch = model.checkMatch(playerEmoji: playerEmoji) // 调用 GameModel 检查匹配
        model.updateScore(isMatch: isMatch)                     // 更新分数
        gameView.playFeedbackAnimation(isMatch: isMatch)        // 播放动画

        // 打印调试信息
        print("Detected Emoji: \(playerEmoji)")
        print("Current Emoji: \(model.currentEmoji)")
        print("Score: \(model.score)")

        // 更新 UI 在主线程
        DispatchQueue.main.async {
            // 生成下一个表情障碍
            self.model.currentEmoji = self.model.generateRandomEmoji()
            self.gameView.updateEmoji(self.model.currentEmoji)  // 更新表情障碍
            self.gameView.updateScore(self.model.score)         // 更新分数显示
        }
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



