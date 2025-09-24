//
//  CameraScene.swift
//  tutorial
//
//  Simple demo scene that shows using an SKCameraNode to follow a player and support zooming.
//

import SpriteKit

class CameraScene: SKScene {

    let player = SKSpriteNode(color: .systemRed, size: CGSize(width: 40, height: 40))
    private let cam = SKCameraNode()
    // Public world rect so SwiftUI mini-map can read it
    var worldRect: CGRect = .zero

    // Public camera scale (clamped)
    private(set) var cameraScale: CGFloat = 1.0
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 2.0

    // Camera focus mode (when true camera follows player)
    var isCameraFocused: Bool = true

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.11, blue: 0.16, alpha: 1)

        // World bounds (larger than visible size so camera has room to move)
        worldRect = CGRect(x: 0, y: 0, width: max(2000, size.width * 2), height: max(1500, size.height * 2))

        // Add some simple background nodes for visual reference
        addBackgroundGrid()

        // Add player
        player.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
        addChild(player)

        // Add and configure camera
        addChild(cam)
        camera = cam

        // Set initial camera position to player
        cam.position = player.position

        // Constraints: follow player but stay inside worldRect
        updateCameraConstraints()

        // Make scene reactive to size changes
        relayoutForCurrentSize()
    }

    private func addBackgroundGrid() {
        // Draw a simple grid of tiles for reference
        let tileSize: CGFloat = 200
        let cols = Int(ceil(worldRect.width / tileSize))
        let rows = Int(ceil(worldRect.height / tileSize))

        // Create three parallax layers (far, mid, near)
        let farLayer = SKNode()
        let midLayer = SKNode()
        let nearLayer = SKNode()

        farLayer.zPosition = -30
        midLayer.zPosition = -20
        nearLayer.zPosition = -10

        for i in 0..<cols {
            for j in 0..<rows {
                let base = SKShapeNode(rectOf: CGSize(width: tileSize - 2, height: tileSize - 2), cornerRadius: 4)
                base.strokeColor = .white.withAlphaComponent(0.06)
                base.lineWidth = 1
                base.fillColor = ( (i + j) % 2 == 0 ) ? SKColor(red: 0.10, green: 0.13, blue: 0.18, alpha: 1) : SKColor(red: 0.07, green: 0.10, blue: 0.15, alpha: 1)
                base.position = CGPoint(x: CGFloat(i) * tileSize + tileSize * 0.5, y: CGFloat(j) * tileSize + tileSize * 0.5)
                midLayer.addChild(base)

                // add some decorative circles to near layer
                if (i + j) % 7 == 0 {
                    let dot = SKShapeNode(circleOfRadius: 8)
                    dot.fillColor = .white.withAlphaComponent(0.06)
                    dot.position = base.position
                    nearLayer.addChild(dot)
                }

                // add some larger faint stars to far layer
                if (i * j) % 13 == 0 {
                    let star = SKShapeNode(circleOfRadius: 14)
                    star.fillColor = .white.withAlphaComponent(0.02)
                    star.position = base.position
                    farLayer.addChild(star)
                }
            }
        }

        addChild(farLayer)
        addChild(midLayer)
        addChild(nearLayer)

        // keep references for parallax updates
        self.farLayer = farLayer
        self.midLayer = midLayer
        self.nearLayer = nearLayer
    }

    // Parallax layer references
    private var farLayer: SKNode?
    private var midLayer: SKNode?
    private var nearLayer: SKNode?

    private func updateCameraConstraints() {
        guard let cam = camera else { return }

        // ✅ scale thực tại thời điểm này (đang animate hay không đều đúng)
        let currentScale = max(cam.xScale, 0.0001)

        // visible half size = scene size / currentScale / 2
        let viewHalfWidth  = (size.width  / currentScale) * 0.5
        let viewHalfHeight = (size.height / currentScale) * 0.5

        let xRange = SKRange(lowerLimit: worldRect.minX + viewHalfWidth,
                             upperLimit: worldRect.maxX - viewHalfWidth)
        let yRange = SKRange(lowerLimit: worldRect.minY + viewHalfHeight,
                             upperLimit: worldRect.maxY - viewHalfHeight)
        let rangeConstraint = SKConstraint.positionX(xRange, y: yRange)

        let zeroRange = SKRange(constantValue: 0)
        let followConstraint = SKConstraint.distance(zeroRange, to: player)

        cam.constraints = isCameraFocused ? [rangeConstraint, followConstraint]
                                          : [rangeConstraint]
    }




    // Allow toggling focus mode at runtime
    func setCameraFocus(_ focus: Bool) {
        isCameraFocused = focus
        updateCameraConstraints()
    }

    private func relayoutForCurrentSize() {
        // Keep camera centered on player when the size changes
        camera?.position = player.position
        updateCameraConstraints()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        relayoutForCurrentSize()
    }

    // MARK: - Player control
    // Move player to a point with a short action
    func movePlayerToward(_ point: CGPoint) {
        let clamped = clampPointToWorld(point)
        let action = SKAction.move(to: clamped, duration: 0.35)
        action.timingMode = .easeOut
        player.run(action)
    }

    // Move player by a delta (useful for button controls)
    func movePlayerBy(dx: CGFloat, dy: CGFloat) {
        let target = CGPoint(x: player.position.x + dx, y: player.position.y + dy)
        movePlayerToward(target)
    }

    private func clampPointToWorld(_ point: CGPoint) -> CGPoint {
        var x = point.x
        var y = point.y
        x = max(worldRect.minX, min(worldRect.maxX, x))
        y = max(worldRect.minY, min(worldRect.maxY, y))
        return CGPoint(x: x, y: y)
    }

    // MARK: - Camera zoom
    func setCameraScale(_ scale: CGFloat, animated: Bool = true) {
        let clamped = max(minScale, min(maxScale, scale))
        cameraScale = clamped
        if animated {
            let action = SKAction.scale(to: clamped, duration: 0.25)
            action.timingMode = .easeInEaseOut
            camera?.run(action)
        } else {
            camera?.setScale(clamped)
        }
        // update constraints since viewHalf depends on scale
        updateCameraConstraints()
    }

    func zoomIn() {
        setCameraScale(cameraScale * 0.85)
    }

    func zoomOut() {
        setCameraScale(cameraScale * 1.15)
    }

    // Set camera position directly (clamped into world)
    func setCameraPosition(_ point: CGPoint, animated: Bool = false) {
        let clamped = clampPointToWorld(point)
        if animated {
            let action = SKAction.move(to: clamped, duration: 0.25)
            action.timingMode = .easeInEaseOut
            camera?.run(action)
        } else {
            camera?.position = clamped
        }
    }

    // MARK: - Touch handling (move player)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let loc = t.location(in: self)
        movePlayerToward(loc)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let loc = t.location(in: self)
        movePlayerToward(loc)
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        updateCameraConstraints()
        // update parallax layers based on camera position (if camera exists)
        guard let camPos = camera?.position else { return }

        // far moves slowest (factor small), near moves almost 1:1
        if let far = farLayer {
            far.position = CGPoint(x: -camPos.x * 0.05, y: -camPos.y * 0.05)
        }
        if let mid = midLayer {
            mid.position = CGPoint(x: -camPos.x * 0.15, y: -camPos.y * 0.15)
        }
        if let near = nearLayer {
            near.position = CGPoint(x: -camPos.x * 0.35, y: -camPos.y * 0.35)
        }
    }

}
