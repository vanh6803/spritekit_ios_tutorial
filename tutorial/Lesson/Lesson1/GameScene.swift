//
//  GameScene.swift
//  tutorial
//
//  Created for SpriteKit + SwiftUI tutorial (Bài 1)
//

import SpriteKit

class GameScene: SKScene {

    // Giữ tham chiếu để reposition khi đổi size
    private let titleLabel = SKLabelNode(text: "Bài 1: Game Scene")

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.11, blue: 0.16, alpha: 1)

        // Label
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        addChild(titleLabel)

        // Viền vật lý (edge loop) theo frame hiện tại
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.categoryBitMask = 0x1 << 1

        // 1 quả bóng ở giữa
        spawnBall(at: CGPoint(x: size.width / 2, y: size.height / 2))

        // Đặt layout ban đầu
        relayoutForCurrentSize()
    }

    /// Gọi mỗi khi size scene thay đổi (xoay máy, split view, iPad multitask…)
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        // Cập nhật lại edge loop theo frame mới
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.categoryBitMask = 0x1 << 1

        // Re-layout các node phụ thuộc size
        relayoutForCurrentSize()
    }

    private func relayoutForCurrentSize() {
        // Safe area top (nếu có)
        let safeTop = view?.safeAreaInsets.top ?? 0

        // Đặt label ở giữa theo trục X, chừa safe area theo trục Y
        titleLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height - safeTop - 44 // 44: margin tuỳ chỉnh
        )
    }

    func spawnBall(at position: CGPoint) {
        let radius: CGFloat = 30
        let ball = SKShapeNode(circleOfRadius: radius)
        ball.fillColor = .systemTeal
        ball.strokeColor = .white
        ball.lineWidth = 2
        ball.position = position

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.restitution = 0.7
        body.friction = 0.2
        body.linearDamping = 0.1
        ball.physicsBody = body

        addChild(ball)
    }

    // Touch handling: spawn a ball where the user touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        spawnBall(at: loc)
    }
}
