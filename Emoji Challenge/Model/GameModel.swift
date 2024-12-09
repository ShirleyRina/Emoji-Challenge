//
//  GameModel.swift
//  Emoji Challenge
//
//  Created by shirley on 12/8/24.
//

import Foundation
class GameModel {
    // 当前分数
    var score: Int = 0

    // 当前表情障碍
    var currentEmoji: String = "😊"

    // 支持的表情选项
    private let emojiOptions = ["😊", "😢", "😱", "😮", "😡"]

    /// 随机生成一个表情障碍
    func generateRandomEmoji() -> String {
        return emojiOptions.randomElement() ?? "😊"
    }

    /// 检查用户表情是否匹配当前障碍
    func checkMatch(playerEmoji: String) -> Bool {
        return playerEmoji == currentEmoji
    }

    /// 根据匹配结果更新分数
    func updateScore(isMatch: Bool) {
        if isMatch {
            score += 10 // 成功匹配加分
        } else {
            score -= 5 // 匹配失败扣分
        }
    }
}
