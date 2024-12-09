//
//  GameView.swift
//  Emoji Challenge
//
//  Created by shirley on 12/8/24.
//

import UIKit

class GameView: UIView {
    // 定义摄像头预览层
        @IBOutlet weak var cameraView: CameraView!
    
        // 当前表情障碍
        @IBOutlet weak var emojiLabel: UILabel!
   
        // 当前分数显示
        @IBOutlet weak var scoreLabel: UILabel!
    
    
        // 更新表情障碍
        func updateEmoji(_ emoji: String) {
            emojiLabel.text = emoji
        }

        // 更新分数
        func updateScore(_ score: Int) {
            scoreLabel.text = "Score: \(score)"
        }

        // 播放匹配成功或失败动画
        func playFeedbackAnimation(isMatch: Bool) {
            let feedbackColor = isMatch ? UIColor.green : UIColor.red
            UIView.animate(withDuration: 0.2, animations: {
                self.backgroundColor = feedbackColor
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.backgroundColor = .white
                }
            }
        }
        func updateEmoji(int) -> <#return type#> {
            <#function body#>
        }
    
}
