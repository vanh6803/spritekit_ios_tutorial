import SwiftUI
import SpriteKit
import Combine

// MARK: - MiniMap (SwiftUI Canvas)

struct MiniMapView: View {
    @ObservedObject private var model: MiniMapModel

    init(scene: CameraScene) {
        self.model = MiniMapModel(scene: scene)
    }

    var body: some View {
        GeometryReader { geo in
            let map = MiniMapMapping(world: model.worldRect, box: geo.size)

            ZStack {
                // Nền mini-map + viền ngoài
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )

                // Vẽ nội dung theo tỉ lệ worldRect
                Canvas { ctx, size in
                    let contentRect = map.contentRect

                    // Viền content (khác viền ngoài)
                    var contentPath = Path(roundedRect: contentRect, cornerRadius: 6)
                    ctx.stroke(contentPath, with: .color(.white.opacity(0.10)), lineWidth: 1)

                    // Lưới nhẹ (bước theo world units)
                    let step: CGFloat = 200
                    if step > 0 {
                        var grid = Path()
                        var x = ceil(model.worldRect.minX / step) * step
                        while x <= model.worldRect.maxX {
                            let p1 = map.worldToMini(CGPoint(x: x, y: model.worldRect.minY))
                            let p2 = map.worldToMini(CGPoint(x: x, y: model.worldRect.maxY))
                            grid.move(to: p1); grid.addLine(to: p2)
                            x += step
                        }
                        var y = ceil(model.worldRect.minY / step) * step
                        while y <= model.worldRect.maxY {
                            let p1 = map.worldToMini(CGPoint(x: model.worldRect.minX, y: y))
                            let p2 = map.worldToMini(CGPoint(x: model.worldRect.maxX, y: y))
                            grid.move(to: p1); grid.addLine(to: p2)
                            y += step
                        }
                        ctx.stroke(grid, with: .color(.white.opacity(0.08)), lineWidth: 0.5)
                    }

                    // Player marker
                    let pp = map.worldToMini(model.playerPos)
                    let r: CGFloat = 4
                    let playerRect = CGRect(x: pp.x - r, y: pp.y - r, width: 2*r, height: 2*r)
                    ctx.fill(Path(ellipseIn: playerRect), with: .color(.red))
                    ctx.stroke(Path(ellipseIn: playerRect), with: .color(.white), lineWidth: 1)

                    // Viewport (khung camera)
                    let vpWorld = model.viewportWorldRect()
                    let vpMini  = map.worldRectToMiniRect(vpWorld)
                    var vpPath  = Path(roundedRect: vpMini, cornerRadius: 2)
                    ctx.stroke(
                        vpPath,
                        with: .color(model.isCameraFocused ? .white : .gray),
                        lineWidth: model.isCameraFocused ? 2 : 1
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let worldPoint = map.miniToWorld(value.location)
                        model.moveCamera(to: worldPoint)
                    }
            )
        }
    }
}

// MARK: - Mapping world <-> mini

private struct MiniMapMapping {
    let world: CGRect
    let box: CGSize
    let scale: CGFloat
    let contentRect: CGRect

    init(world: CGRect, box: CGSize) {
        self.world = world
        self.box   = box
        let sx = box.width  / max(world.width,  0.0001)
        let sy = box.height / max(world.height, 0.0001)
        self.scale = min(sx, sy)

        let contentW = world.width  * scale
        let contentH = world.height * scale
        let offsetX  = (box.width  - contentW) * 0.5
        let offsetY  = (box.height - contentH) * 0.5
        self.contentRect = CGRect(x: offsetX, y: offsetY, width: contentW, height: contentH)
    }

    // SpriteKit world (y-up) -> SwiftUI (y-down)
    func worldToMini(_ p: CGPoint) -> CGPoint {
        let x = contentRect.minX + (p.x - world.minX) * scale
        let y = contentRect.maxY - (p.y - world.minY) * scale
        return CGPoint(x: x, y: y)
    }

    func worldRectToMiniRect(_ r: CGRect) -> CGRect {
        let tl = worldToMini(CGPoint(x: r.minX, y: r.maxY))
        let br = worldToMini(CGPoint(x: r.maxX, y: r.minY))
        return CGRect(x: tl.x, y: tl.y, width: br.x - tl.x, height: br.y - tl.y)
    }

    // SwiftUI point -> SpriteKit world (clamped vào content)
    func miniToWorld(_ p: CGPoint) -> CGPoint {
        // chuyển vào toạ độ content (clamp)
        let lx = max(0, min(contentRect.width,  p.x - contentRect.minX))
        let ly = max(0, min(contentRect.height, contentRect.maxY - p.y)) // y-up local

        let wx = world.minX + lx / scale
        let wy = world.minY + ly / scale
        return CGPoint(x: wx, y: wy)
    }
}

// MARK: - Bridge model đọc Scene

private final class MiniMapModel: ObservableObject {
    private let scene: CameraScene
    private var timer: Timer?

    @Published var worldRect: CGRect
    @Published var playerPos: CGPoint
    @Published var cameraPos: CGPoint
    @Published var cameraScale: CGFloat
    @Published var isCameraFocused: Bool

    init(scene: CameraScene) {
        self.scene          = scene
        self.worldRect      = scene.worldRect
        self.playerPos      = scene.player.position
        self.cameraPos      = scene.camera?.position ?? .zero
        self.cameraScale    = scene.cameraScale
        self.isCameraFocused = scene.isCameraFocused

        // Cập nhật đều đặn (nhẹ nhàng)
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.worldRect   = self.scene.worldRect
            self.playerPos   = self.scene.player.position
            self.cameraPos      = self.scene.camera?.position ?? self.cameraPos
            self.cameraScale    = self.scene.camera?.xScale ?? self.scene.cameraScale
            self.isCameraFocused = self.scene.isCameraFocused
        }
    }

    func moveCamera(to point: CGPoint) {
        scene.setCameraPosition(point, animated: true)
    }

    func viewportWorldRect() -> CGRect {
        // ✅ đọc scale thực tế của camera thay vì scene.cameraScale
        let s = max(scene.camera?.xScale ?? scene.cameraScale, 0.0001)
        let w = scene.size.width  / s
        let h = scene.size.height / s
        return CGRect(x: cameraPos.x - w/2, y: cameraPos.y - h/2, width: w, height: h)
    }


    deinit { timer?.invalidate() }
}
