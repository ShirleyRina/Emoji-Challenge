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
    
    private(set) var countdownLabel: UILabel!
    private(set) var gameOverlay: UIView?
    private var restartHandler: (() -> Void)?

    // 使用代码初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit() // 初始化通用配置
    }
    
    // 从 Storyboard/XIB 初始化
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit() // 初始化通用配置
    }
    
    // 通用初始化方法
    private func commonInit() {
        // 初始化倒计时标签
        countdownLabel = UILabel(frame: CGRect(x: 20, y: 50, width: 100, height: 50))
        countdownLabel.text = "20"
        countdownLabel.font = UIFont.boldSystemFont(ofSize: 24)
        countdownLabel.textColor = .white
        countdownLabel.backgroundColor = .black
        countdownLabel.textAlignment = .center
        countdownLabel.layer.cornerRadius = 5
        countdownLabel.layer.masksToBounds = true
        
        // 将倒计时标签添加到 ARSCNView 中
        self.addSubview(countdownLabel)
    }

    // 设置倒计时
    func setupCountdown(in view: UIView) {
        view.addSubview(countdownLabel)
    }

    // 更新倒计时标签
    func updateCountdownLabel(with value: Int) {
        countdownLabel.text = "\(value)"
    }

    // 显示游戏覆盖层
    func showGameOverlay(in view: UIView, score: Int, restartHandler: @escaping () -> Void) {
        gameOverlay = UIView(frame: view.bounds)
        gameOverlay?.backgroundColor = UIColor.black.withAlphaComponent(0.8)

        let scoreLabel = UILabel(frame: CGRect(x: 50, y: 300, width: view.bounds.width - 100, height: 50))
        scoreLabel.text = "Score: \(score)"
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 30)
        scoreLabel.textColor = .white
        scoreLabel.textAlignment = .center
        scoreLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        gameOverlay?.addSubview(scoreLabel)

        let playAgainImageView = UIImageView(frame: CGRect(x: (view.bounds.width - 200) / 2, y: 550, width: 200, height: 50))
        playAgainImageView.image = UIImage(named: "play_again")
        playAgainImageView.contentMode = .scaleAspectFit
        playAgainImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playAgainTapped(_:)))
        playAgainImageView.addGestureRecognizer(tapGesture)
        gameOverlay?.addSubview(playAgainImageView)

        view.addSubview(gameOverlay!)

        // 保存重启处理器
        self.restartHandler = restartHandler
    }

    // 移除游戏覆盖层
    func removeGameOverlay() {
        gameOverlay?.removeFromSuperview()
        gameOverlay = nil
    }

    @objc private func playAgainTapped(_ sender: UITapGestureRecognizer) {
        restartHandler?()
    }
    
}
