//
//  GameModel.swift
//  Emoji Challenge
//
//  Created by shirley on 12/8/24.
//

import Foundation
class GameModel {
    var score: Int = 0
    var currentEmoji: String = "happy" // 初始表情障碍

    // 表情标签列表，与模型的输出一致
    let emojiOptions = ["anger", "contempt", "fear", "happy", "surprise"]

    /// 随机生成一个表情障碍
    func generateRandomEmoji() -> String {
        return emojiOptions.randomElement() ?? "happy"
    }

    /// 检查用户表情是否匹配当前障碍
    func checkMatch(playerEmoji: String) -> Bool {
        return playerEmoji == currentEmoji
    }

    /// 根据匹配结果更新分数
    func updateScore(isMatch: Bool) {
        score += isMatch ? 10 : -5
    }
}

