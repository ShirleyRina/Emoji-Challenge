//
//  ViewController.swift
//  Emoji Challenge
//
//  Created by shirley on 12/8/24.
//
import UIKit
import ARKit
import Vision
import CoreML


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



class GameViewController: UIViewController, ARSCNViewDelegate {
 
    @IBOutlet weak var sceneView: SceneView!
    
    @IBOutlet var gameView: GameView!
    
    var currentTargetEmoji: String = "happy"
    var model = GameModel() // 游戏逻辑模型
    private var sequenceHandler = VNSequenceRequestHandler() // Vision 请求处理器
    private var lastUpdateTime: TimeInterval = 0
    
    // AVCapture 会话
    private var captureSession: AVCaptureSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化捕获会话
        setupCaptureSession()
        
        // 配置游戏视图和 SceneView
        gameView.configureSceneView()
        sceneView.configureScene()
        sceneView.delegate = self
        
        // 初始化表情和分数
        currentTargetEmoji = "happy"
        gameView.updateEmoji(currentTargetEmoji)
        gameView.updateScore(0)
        
        // 添加第一个动态木板
        sceneView.addDynamicWoodPlank(targetEmoji: currentTargetEmoji)
        
        // 定时滑动木板并更新逻辑
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let currentTime = CACurrentMediaTime()
            let deltaTime = currentTime - self.lastUpdateTime
            self.lastUpdateTime = currentTime
            
            self.sceneView.updateScene(deltaTime: deltaTime, detectedEmoji: self.currentTargetEmoji)
        }
    }
    
    // MARK: - 设置捕获会话
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("Unable to access front camera")
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            fatalError("Unable to create AVCaptureDeviceInput")
        }
        captureSession.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(output)
        
        captureSession.startRunning()
    }
    
    // MARK: - 处理捕获的样本缓冲区
    func handleFaceDetection(buffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        
        // 创建 Vision 人脸检测请求
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            guard let results = request.results as? [VNFaceObservation], let face = results.first else { return }
            
            self.processFaceObservation(face, in: pixelBuffer)
        }
        
        // 执行人脸检测请求
        try? sequenceHandler.perform([faceDetectionRequest], on: pixelBuffer)
    }
    
    // MARK: - 处理人脸观测结果
    func processFaceObservation(_ face: VNFaceObservation, in pixelBuffer: CVPixelBuffer) {
        // 将人脸区域裁剪为适合模型输入的图像
        let faceRect = VNImageRectForNormalizedRect(face.boundingBox, Int(CVPixelBufferGetWidth(pixelBuffer)), Int(CVPixelBufferGetHeight(pixelBuffer)))
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).cropped(to: faceRect)
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // 创建 CoreML 分类请求
        let classificationRequest = VNCoreMLRequest(model: mlModel) { [weak self] request, error in
            guard let self = self else { return }
            guard let results = request.results as? [VNClassificationObservation], let bestResult = results.first else {
                print("Failed to classify face")
                return
            }
            
            // 获取检测到的玩家表情
            let detectedEmoji = bestResult.identifier
            print("Detected Emoji: \(detectedEmoji)")
            
            // 调用游戏逻辑处理分类结果
            self.handleDetectedEmoji(playerEmoji: detectedEmoji)
        }
        
        // 执行分类请求
        try? handler.perform([classificationRequest])
    }
    
    // MARK: - 处理检测到的玩家表情
func handleDetectedEmoji(playerEmoji: String) {
    let isMatch = (playerEmoji == currentTargetEmoji)
    
    model.updateScore(isMatch: isMatch)
    gameView.updateScore(model.score)
    
    if isMatch {
        currentTargetEmoji = model.generateRandomEmoji()
        print("New Target Emoji: \(currentTargetEmoji)")
        
        DispatchQueue.main.async {
            self.gameView.updateEmoji(self.currentTargetEmoji)
            self.sceneView.addDynamicWoodPlank(targetEmoji: self.currentTargetEmoji)
        }
    }
}

}


extension GameViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        handleFaceDetection(buffer: sampleBuffer)
    }
}
