//
//  GameView.swift
//  Emoji Challenge
//
//  Created by shirley on 12/8/24.
//

import UIKit
import SceneKit
import ARKit

class GameView: UIView {

    @IBOutlet weak var sceneView: ARSCNView!

   
    @IBOutlet weak var emojiLabel: UILabel!
    
         
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    
    var currentTargetEmoji: String?
    
    
// 配置 ARSCNView
    func configureSceneView() {
        sceneView.scene = SCNScene()
        if ARFaceTrackingConfiguration.isSupported {
            let configuration = ARFaceTrackingConfiguration()
            sceneView.session.run(configuration)
        } else {
            print("ARFaceTrackingConfiguration is not supported.")
        }
    }
    
    func updateEmoji(_ emoji: String) {
        guard currentTargetEmoji != emoji else { return }
        currentTargetEmoji = emoji

        DispatchQueue.main.async {
            let emojiMap: [String: String] = [
                "anger": "😡",
                "contempt": "😒",
                "fear": "😱",
                "happy": "😊",
                "surprise": "😮"
            ]
            self.emojiLabel.text = emojiMap[emoji] ?? "❓"
        }
    }

    func updateScore(_ score: Int) {
        DispatchQueue.main.async {
            self.scoreLabel.text = "Score: \(score)"
        }
    }

//    func playFeedbackAnimation(isMatch: Bool) {
//        let feedbackColor = isMatch ? UIColor.green : UIColor.red
//        UIView.animate(withDuration: 0.2, animations: {
//            self.backgroundColor = feedbackColor
//        }) { _ in
//            UIView.animate(withDuration: 0.2) {
//                self.backgroundColor = .white
//            }
//        }
//    }
}
