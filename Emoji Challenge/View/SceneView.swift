//
//  SceneView.swift
//  Emoji Challenge
//
//  Created by shirley on 12/12/24.
//

import Foundation
import SceneKit
import ARKit

class SceneView: ARSCNView {
    
    // MARK: - Properties
    var currentTargetEmoji: String? = "happy" // 默认表情
    var onScoreUpdate: ((Int) -> Void)? // 分数更新回调
    private var score = 0 // 当前分数
    private var emojiTextures: [String: UIImage] = [:] // 预加载的 emoji 资源
    private var lastPlankCreationTime: TimeInterval = 0 // 上次木板生成时间
    private var originalBackgroundColor: UIColor? // 原始背景颜色

    // MARK: - Configure Scene
    func configureScene() {
        // 初始化场景
        self.scene = SCNScene()
        self.originalBackgroundColor = self.backgroundColor ?? .white
        
        // 配置 AR 会话
        if ARFaceTrackingConfiguration.isSupported {
            let configuration = ARFaceTrackingConfiguration()
            self.session.run(configuration)
        } else {
            print("ARFaceTrackingConfiguration is not supported.")
        }
        
        // 预加载资源
        preloadEmojiTextures()
    }
    
    private func preloadEmojiTextures() {
        // 预加载 emoji 图片资源
        let emojis = ["anger", "contempt", "fear", "happy", "surprise"]
        for emoji in emojis {
            if let image = UIImage(named: emoji) {
                emojiTextures[emoji] = image
            }
        }
    }
    
    // MARK: - Add Dynamic Wood Plank
    func addDynamicWoodPlank(targetEmoji: String) {
        // 创建木板几何
        let plank = SCNBox(width: 0.5, height: 0.3, length: 0.02, chamferRadius: 0.0)
        plank.firstMaterial?.diffuse.contents = UIImage(named: "woodTexture")

        let plankNode = SCNNode(geometry: plank)

        // 找到最远的地板位置
        var farthestZ: Float = -1.0
        self.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "floor" && node.position.z < farthestZ {
                farthestZ = node.position.z
            }
        }

        // 设置木板的位置
        plankNode.position = SCNVector3(0, -0.35, farthestZ)
        plankNode.name = "plank"

        // 添加表情贴图
        if let emojiImage = emojiTextures[targetEmoji] {
            let emojiPlane = SCNPlane(width: 0.3, height: 0.2)
            emojiPlane.firstMaterial?.diffuse.contents = emojiImage

            let emojiNode = SCNNode(geometry: emojiPlane)
            emojiNode.position = SCNVector3(0, 0, 0.03) // 表情位置略微突出木板表面
            plankNode.addChildNode(emojiNode)
        }

        // 将木板添加到场景中
        self.scene.rootNode.addChildNode(plankNode)
    }

    // MARK: - Slide Planks and Match Detection
    func slidePlanksAndCheckMatch(deltaTime: TimeInterval, detectedEmoji: String) {
        let speed: Float = 0.2 // 滑动速度
        
        self.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "plank" {
                node.position.z += speed * Float(deltaTime)
                
                // 检查是否超出屏幕
                if node.position.z > 1.0 {
                    node.removeFromParentNode()
                } else if node.position.z > -0.1 && node.position.z < 0.1 {
                    // 匹配检测逻辑
                    let isMatch = (detectedEmoji == self.currentTargetEmoji)
                    if isMatch {
                        self.score += 10 // 更新分数
                        self.onScoreUpdate?(self.score)
                    }
                    self.playFeedbackAnimation(isMatch: isMatch)
                    node.removeFromParentNode()
                }
            }
        }
    }
    
    // MARK: - Feedback Animation
    private func playFeedbackAnimation(isMatch: Bool) {
        let feedbackColor = isMatch ? UIColor.green : UIColor.red
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, animations: {
                self.backgroundColor = feedbackColor
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.backgroundColor = self.originalBackgroundColor
                }
            }
        }
    }
    
    // MARK: - Update Scene
    func updateScene(deltaTime: TimeInterval, detectedEmoji: String) {
        slidePlanksAndCheckMatch(deltaTime: deltaTime, detectedEmoji: detectedEmoji)
        
        let currentTime = CACurrentMediaTime()
        if currentTime - lastPlankCreationTime > 2.0 { // 每 2 秒生成一个木板
            lastPlankCreationTime = currentTime
            
            // 安全解包 currentTargetEmoji
            if let targetEmoji = currentTargetEmoji {
                addDynamicWoodPlank(targetEmoji: targetEmoji)
            } else {
                print("Error: currentTargetEmoji is nil")
            }
        }
    }

    // MARK: - Reset Scene
    func resetScene() {
        // 清空场景中的节点
        self.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        // 重置分数和目标表情
        score = 0
        currentTargetEmoji = "happy" // 重置为默认值
        onScoreUpdate?(score)
    }
}
