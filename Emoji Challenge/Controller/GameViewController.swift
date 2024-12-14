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
    
    @IBOutlet weak var gameView: GameView!
    
    var model = GameModel()
    private var sequenceHandler = VNSequenceRequestHandler()
    private var gameModel = ARModel()
    private var countdownTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 初始化表情障碍和分数
        gameView.updateEmoji("happy")  // 设置初始表情
        gameView.updateScore(0)        // 设置初始分数

        // 初始化场景
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        setupInitialFloors()
        addDynamicWoodPlank()
    }


       override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           // 配置 AR 会话
           let configuration = ARFaceTrackingConfiguration()
           sceneView.session.run(configuration)
       }

        override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause() // 使用正确的 sceneView
        }

       // 处理 ARKit 帧
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            // Vision 人脸检测
            guard let frame = sceneView.session.currentFrame else { return } // 使用 sceneView
            let pixelBuffer = frame.capturedImage
            handleFaceDetection(pixelBuffer: pixelBuffer)
            
            // 滑动地板逻辑
            slideFloors()
            loadNewFloorsIfNeeded()
        }



       private func handleFaceDetection(pixelBuffer: CVPixelBuffer) {
           let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
               guard let self = self,
                     let results = request.results as? [VNFaceObservation],
                     let face = results.first else { return }

               // 处理人脸检测结果
               self.processFaceObservation(face, in: pixelBuffer)
           }

           // 执行请求
           try? sequenceHandler.perform([faceDetectionRequest], on: pixelBuffer)
       }

       private func processFaceObservation(_ face: VNFaceObservation, in pixelBuffer: CVPixelBuffer) {
           let faceCropRect = VNImageRectForNormalizedRect(
               face.boundingBox,
               Int(CVPixelBufferGetWidth(pixelBuffer)),
               Int(CVPixelBufferGetHeight(pixelBuffer))
           )
           let ciImage = CIImage(cvPixelBuffer: pixelBuffer).cropped(to: faceCropRect)
           let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

           let classificationRequest = VNCoreMLRequest(model: mlModel) { [weak self] request, error in
               guard let results = request.results as? [VNClassificationObservation],
                     let bestResult = results.first,
                     let self = self else { return }

               let detectedEmoji = bestResult.identifier
               DispatchQueue.main.async {
                   self.handleDetectedEmoji(playerEmoji: detectedEmoji)
               }
           }

           try? handler.perform([classificationRequest])
       }

       // 处理表情检测结果
       func handleDetectedEmoji(playerEmoji: String) {
           let isMatch = model.checkMatch(playerEmoji: playerEmoji)
           model.updateScore(isMatch: isMatch)
           //gameView.playFeedbackAnimation(isMatch: isMatch)

           DispatchQueue.main.async {
               self.model.currentEmoji = self.model.generateRandomEmoji()
               self.gameView.updateEmoji(self.model.currentEmoji)
               self.gameView.updateScore(self.model.score)
           }
       }
    
    
    
    
    private func startCountdown() {
        gameModel.countdownValue = 20
        sceneView.updateCountdownLabel(with: gameModel.countdownValue)
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
    }

    @objc private func updateCountdown() {
        gameModel.countdownValue -= 1
        sceneView.updateCountdownLabel(with: gameModel.countdownValue)
        if gameModel.countdownValue <= 0 {
            endGame()
        }
    }

    private func endGame() {
        countdownTimer?.invalidate()
        sceneView.showGameOverlay(in: view, score: 1234) { [weak self] in
            self?.restartGame()
        }
    }

    @objc private func restartGame() {
        sceneView.removeGameOverlay()
        gameModel.reset()
        startCountdown()
    }

    // MARK: 创建地板
    func createFloor(at position: SCNVector3) -> SCNNode {
        let floor = SCNPlane(width: 1.0, height: 1.0)
        floor.firstMaterial?.diffuse.contents = UIImage(named: "floorTexture")

        let floorNode = SCNNode(geometry: floor)
        floorNode.eulerAngles.x = -.pi / 2
        floorNode.position = position
        floorNode.name = "floor"
        return floorNode
    }

    func setupInitialFloors() {
        for i in 0..<5 {
            let floorNode = createFloor(at: SCNVector3(0, -0.5, Float(i) * -1.0))
            sceneView.scene.rootNode.addChildNode(floorNode)
        }
    }

    // MARK: 动态添加木板
    func addDynamicWoodPlank() {
        //print("Attempting to add plank. isPlankOnScreen: \(gameModel.isPlankOnScreen)")
        guard !gameModel.isPlankOnScreen else {
            //print("Plank is already on screen. Skipping...")
            return }

        let plank = SCNBox(width: 0.5, height: 0.3, length: 0.02, chamferRadius: 0.0)
        plank.firstMaterial?.diffuse.contents = UIImage(named: "woodTexture")

        let plankNode = SCNNode(geometry: plank)
        
        var farthestZ: Float = -1.0 // 默认值，防止无地板时出错
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "floor" && node.position.z < farthestZ {
                farthestZ = node.position.z
            }
        }

        plankNode.position = SCNVector3(0, -0.35, farthestZ - 1.0)
        plankNode.name = "plank"

        // 添加表情图案
        let emojiTextures = ["anger", "contempt", "fear", "happy", "surprise"]
        if let randomEmoji = emojiTextures.randomElement() {
            //print("Selected emoji: \(randomEmoji)")
            if let emojiImage = UIImage(named: randomEmoji) {
                print("Loaded emoji image: \(randomEmoji)")
                let emojiPlane = SCNPlane(width: 0.5, height: 0.5)
                emojiPlane.firstMaterial?.diffuse.contents = emojiImage

                let emojiNode = SCNNode(geometry: emojiPlane)
                emojiNode.position = SCNVector3(0, 0.15, 0.03)
                plankNode.addChildNode(emojiNode)
            }
        }

        sceneView.scene.rootNode.addChildNode(plankNode)
        gameModel.isPlankOnScreen = true
    }


    func slideFloors() {
        print("slideFloors() called")
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            //print("Node name: \(node.name ?? "Unnamed"), Position: \(node.position)")
            if node.name == "floor" || node.name == "plank" {
                node.position.z += 0.036
                if node.position.z > 1.0 {
                    node.removeFromParentNode()
                    if node.name == "plank" {
                        gameModel.isPlankOnScreen = false
                        addDynamicWoodPlank() // 确保在同一个线程中处理
                        //print("Plank removed. Adding new plank...")
                    }
                }
            }
        }
    }

    func loadNewFloorsIfNeeded() {
        var farthestZ: Float = 0.0
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "floor" && node.position.z < farthestZ {
                farthestZ = node.position.z
            }
        }

        if farthestZ > -4.0 {
            let newFloor = createFloor(at: SCNVector3(0, -0.5, farthestZ - 1.0))
            sceneView.scene.rootNode.addChildNode(newFloor)
        }
    }

    
}
