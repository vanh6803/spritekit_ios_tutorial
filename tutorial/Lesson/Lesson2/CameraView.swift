import SwiftUI
import SpriteKit

// UIViewRepresentable wrapper that hosts SKView so we can enable debug overlays
// and add gesture recognizers (pinch-to-zoom).
struct CameraView: UIViewRepresentable {
    let scene: CameraScene

    func makeUIView(context: Context) -> SKView {
        let skView = SKView(frame: .zero)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsPhysics = false
        skView.presentScene(scene)

        // Add pinch gesture for zooming
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        skView.addGestureRecognizer(pinch)

        context.coordinator.skView = skView
        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Ensure the presented scene is our scene
        if uiView.scene !== scene {
            uiView.presentScene(scene)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scene: scene)
    }

    class Coordinator: NSObject {
        weak var skView: SKView?
        let scene: CameraScene

        init(scene: CameraScene) {
            self.scene = scene
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard recognizer.state == .changed || recognizer.state == .ended else { return }
            let scale = recognizer.scale
            // pinch scale ~1 means no change; invert to zoom in/out
            let newScale = scene.cameraScale * (1.0 / scale)
            scene.setCameraScale(newScale, animated: false)
            recognizer.scale = 1.0
        }
    }
}
