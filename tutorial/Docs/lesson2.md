# Bài 2 — Camera & View trong SpriteKit

Mục tiêu: học cách sử dụng camera trong SpriteKit (`SKCameraNode`) để điều khiển vùng nhìn (panning, following, zooming) và cách tích hợp với SwiftUI (`SpriteView`).

## Khái niệm cơ bản

- `SKCameraNode` là node đặc biệt dùng làm camera cho `SKScene`.
- Khi gán `scene.camera = cameraNode`, vị trí, scale và rotation của camera xác định phần của scene được vẽ lên `SKView`.
- Camera là một node bình thường: bạn có thể thêm child, gắn action, constraints, v.v.

## Các thao tác phổ biến

1. Tạo camera và gán cho scene

```swift
let camera = SKCameraNode()
scene.addChild(camera)
scene.camera = camera
```

2. Di chuyển camera (pan)

- Bạn có thể thay đổi `camera.position` trực tiếp, hoặc dùng `SKAction.move(to:duration:)` để tạo chuyển động mượt.

```swift
let move = SKAction.move(to: CGPoint(x: 200, y: 400), duration: 1.0)
camera.run(move)
```

3. Follow một node (ví dụ player)

- Cách đơn giản: cập nhật vị trí camera mỗi khung trong `update(_:)`:

```swift
override func update(_ currentTime: TimeInterval) {
    if let target = player {
        camera?.position = target.position
    }
}
```

- Cách tốt hơn: sử dụng `SKConstraint` với `constraint = SKConstraint.distance(...)` hoặc `SKConstraint.positionX/Y` để ràng buộc camera theo node nhưng giới hạn tốc độ/biên.

```swift
let zeroRange = SKRange(constantValue: 0)
let constraint = SKConstraint.distance(zeroRange, to: player)
camera.constraints = [constraint]
```

4. Zoom (phóng to/thu nhỏ)

- Thay đổi `camera.xScale` và `camera.yScale`.

```swift
// Zoom in (phóng to)
camera.setScale(0.5) // nhỏ scale -> phóng to cảnh

// Smooth zoom
let scaleAction = SKAction.scale(to: 1.5, duration: 0.5)
camera.run(scaleAction)
```

5. Giới hạn vùng camera

- Dùng `SKConstraint` để khóa camera trong một vùng (ví dụ worldBounds) để tránh nhìn ra ngoài world.

```swift
let worldRect = CGRect(x: 0, y: 0, width: worldWidth, height: worldHeight)
let xRange = SKRange(lowerLimit: worldRect.minX + viewHalfWidth, upperLimit: worldRect.maxX - viewHalfWidth)
let yRange = SKRange(lowerLimit: worldRect.minY + viewHalfHeight, upperLimit: worldRect.maxY - viewHalfHeight)
let rangeConstraint = SKConstraint.positionX(xRange, y: yRange)
camera.constraints = [rangeConstraint]
```

## Tích hợp với SwiftUI (`SpriteView`)

- `SpriteView` hiển thị chính xác vùng mà camera quan sát. Khi bạn gán `scene.camera` và thay đổi position/scale của camera, `SpriteView` sẽ render phần đó.
- Vì `SpriteView` không trực tiếp expose `SKView`, nếu cần bật debug overlay (`showsFPS`, `showsPhysics`) hoặc cấu hình `SKView` sâu hơn, hãy tạo một `UIViewRepresentable` (iOS) hoặc `NSViewRepresentable` (macOS) thay thế để quản lý `SKView` thủ công.

## Ví dụ: camera follow player với giới hạn

```swift
class GameScene: SKScene {
    let player = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 40))
    let cam = SKCameraNode()
    var worldRect: CGRect = .zero

    override func didMove(to view: SKView) {
        worldRect = CGRect(x: 0, y: 0, width: 2000, height: 1500)
        addChild(player)
        player.position = CGPoint(x: 100, y: 100)

        addChild(cam)
        camera = cam

        // Constraints: camera should follow player but stay inside worldRect
        let viewHalfWidth = size.width * 0.5
        let viewHalfHeight = size.height * 0.5

        let xRange = SKRange(lowerLimit: worldRect.minX + viewHalfWidth, upperLimit: worldRect.maxX - viewHalfWidth)
        let yRange = SKRange(lowerLimit: worldRect.minY + viewHalfHeight, upperLimit: worldRect.maxY - viewHalfHeight)
        let rangeConstraint = SKConstraint.positionX(xRange, y: yRange)

        let distance = SKRange(constantValue: 0)
        let followConstraint = SKConstraint.distance(distance, to: player)

        cam.constraints = [rangeConstraint, followConstraint]
    }
}
```

## Gợi ý mở rộng

- Thêm damping/momentum: thay vì snap camera thẳng tới vị trí player, dùng Lerp hoặc apply physics-like smoothing.
- Pinch to zoom: nếu bạn muốn zoom bằng gesture, handle `UIPinchGestureRecognizer` ở wrapper UIViewRepresentable và điều chỉnh `camera.xScale`/`yScale` tương ứng.
- Parallax: tạo nhiều layer với tốc độ di chuyển khác nhau so với camera để tạo chiều sâu.

---

Muốn mình tiếp theo implement ví dụ demo trong project (ví dụ: thay `GameScene.swift` để thêm camera theo player + pinch to zoom + một `UIViewRepresentable` wrapper cho debug)? Nếu có, mình sẽ tạo một todo và thực hiện các thay đổi, chạy đọc lại file và hướng dẫn cách chạy trong Xcode.

## Demo: Camera System Hoàn Chỉnh (Implementation thực tế)

Chúng ta đã xây dựng một hệ thống camera hoàn chỉnh gồm 4 components chính:

### 1. `CameraScene.swift` — Core Scene Logic

**Khởi tạo và Cấu trúc:**

```swift
class CameraScene: SKScene {
    let player = SKSpriteNode(color: .systemRed, size: CGSize(width: 40, height: 40))
    private let cam = SKCameraNode()
    var worldRect: CGRect = .zero

    // Camera properties
    private(set) var cameraScale: CGFloat = 1.0
    private let minScale: CGFloat = 0.5  // zoom in max
    private let maxScale: CGFloat = 2.0  // zoom out max
    var isCameraFocused: Bool = true     // focus mode
}
```

**Flow khởi tạo (`didMove`):**

1. Thiết lập `worldRect` lớn hơn screen (2000x1500 hoặc 2x screen size)
2. Tạo parallax background (3 layers: far, mid, near)
3. Đặt player ở giữa world
4. Khởi tạo camera và gán constraints
5. Gọi `relayoutForCurrentSize()` để setup vị trí

**Hệ thống Parallax (3 lớp chiều sâu):**

```swift
override func update(_ currentTime: TimeInterval) {
    guard let camPos = camera?.position else { return }

    // Các layer di chuyển với tốc độ khác nhau theo camera
    farLayer.position = CGPoint(x: -camPos.x * 0.05, y: -camPos.y * 0.05)   // chậm nhất
    midLayer.position = CGPoint(x: -camPos.x * 0.15, y: -camPos.y * 0.15)   // trung bình
    nearLayer.position = CGPoint(x: -camPos.x * 0.35, y: -camPos.y * 0.35)  // nhanh nhất
}
```

**Logic:** Tạo cảm giác 3D bằng cách di chuyển background layers với tốc độ khác nhau.

**Camera Constraints System:**

```swift
private func updateCameraConstraints() {
    let viewHalfWidth = size.width * 0.5 * cameraScale
    let viewHalfHeight = size.height * 0.5 * cameraScale

    // Giới hạn camera trong world bounds
    let xRange = SKRange(lowerLimit: worldRect.minX + viewHalfWidth,
                        upperLimit: worldRect.maxX - viewHalfWidth)
    let yRange = SKRange(lowerLimit: worldRect.minY + viewHalfHeight,
                        upperLimit: worldRect.maxY - viewHalfHeight)
    let rangeConstraint = SKConstraint.positionX(xRange, y: yRange)

    // Follow player constraint (chỉ khi focused)
    let followConstraint = SKConstraint.distance(SKRange(constantValue: 0), to: player)

    if isCameraFocused {
        cam.constraints = [rangeConstraint, followConstraint]  // Follow + bounds
    } else {
        cam.constraints = [rangeConstraint]                    // Chỉ bounds
    }
}
```

**Logic:**

- Constraint 1: Camera không thể ra khỏi world
- Constraint 2: Camera follow player (khi focus mode bật)
- Constraints tự động cập nhật khi zoom (vì viewHalf thay đổi theo scale)

**Player Movement System:**

```swift
func movePlayerBy(dx: CGFloat, dy: CGFloat) {
    let target = CGPoint(x: player.position.x + dx, y: player.position.y + dy)
    movePlayerToward(target)
}

func movePlayerToward(_ point: CGPoint) {
    let clamped = clampPointToWorld(point)
    let action = SKAction.move(to: clamped, duration: 0.35)
    action.timingMode = .easeOut
    player.run(action)
}
```

**Logic:** Player di chuyển mượt với animation, bị giới hạn trong world bounds.

**Camera Zoom System:**

```swift
func setCameraScale(_ scale: CGFloat, animated: Bool = true) {
    let clamped = max(minScale, min(maxScale, scale))
    cameraScale = clamped

    if animated {
        let action = SKAction.scale(to: clamped, duration: 0.25)
        camera?.run(action)
    } else {
        camera?.setScale(clamped)
    }

    updateCameraConstraints()  // Cập nhật constraints vì viewHalf thay đổi
}
```

**Logic:** Zoom có giới hạn, animation mượt, constraints tự động cập nhật.

### 2. `CameraView.swift` — UIViewRepresentable Wrapper

**Mục đích:** Bridge giữa SwiftUI và SKView để có thể:

- Bật debug overlays (`showsFPS`, `showsPhysics`)
- Thêm gesture recognizers (pinch-to-zoom)
- Truy cập trực tiếp SKView properties

```swift
struct CameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.showsFPS = true
        skView.showsPhysics = false
        skView.presentScene(scene)

        // Thêm pinch gesture
        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                           action: #selector(Coordinator.handlePinch(_:)))
        skView.addGestureRecognizer(pinch)
        return skView
    }
}
```

**Pinch-to-Zoom Logic:**

```swift
@objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
    let scale = recognizer.scale
    let newScale = scene.cameraScale * (1.0 / scale)  // Invert scale
    scene.setCameraScale(newScale, animated: false)
    recognizer.scale = 1.0
}
```

### 3. `MiniMapView.swift` — Interactive Mini-Map

**Cấu trúc:**

- `MiniMapView` (SwiftUI) + `MiniMapProxy` (ObservableObject)
- Timer cập nhật player position và viewport mỗi 0.08s

**MiniMapProxy Logic:**

```swift
init(scene: CameraScene) {
    // Tạo mini scene với world size
    let s = SKScene(size: scene.worldRect.size)
    s.scaleMode = .aspectFit
    s.backgroundColor = SKColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 1)

    // Thêm grid, player node, viewport rectangle
    // Timer để sync với main scene
    timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
        self?.updateMiniMap()
    }
}
```

**Update Logic (Real-time sync):**

```swift
private func updateMiniMap() {
    // Sync player position
    playerNode?.position = source.player.position

    // Update viewport rectangle
    let camPos = source.camera?.position ?? CGPoint.zero
    let visibleW = source.size.width * source.cameraScale
    let visibleH = source.size.height * source.cameraScale

    let rect = CGRect(x: -visibleW/2, y: -visibleH/2, width: visibleW, height: visibleH)
    viewportNode?.path = CGPath(rect: rect, transform: nil)
    viewportNode?.position = camPos

    // Visual feedback cho focus mode
    if source.isCameraFocused {
        viewportNode?.strokeColor = .white
        viewportNode?.lineWidth = 2
    } else {
        viewportNode?.strokeColor = .gray
        viewportNode?.lineWidth = 1
    }
}
```

**Drag-to-Navigate Logic:**

```swift
func handleDrag(at point: CGPoint, in size: CGSize) {
    // Convert mini-map coordinates to world coordinates
    let rx = point.x / size.width
    let ry = (size.height - point.y) / size.height  // Flip Y (SpriteKit origin)

    let worldX = source.worldRect.minX + rx * source.worldRect.width
    let worldY = source.worldRect.minY + ry * source.worldRect.height

    source.setCameraPosition(CGPoint(x: worldX, y: worldY), animated: true)
}
```

### 4. `Lesson2.swift` — SwiftUI UI Integration

**Layout Structure:**

```swift
ZStack {
    CameraView(scene: scene)                    // Main game view

    VStack { /* HUD (top-left) */ }             // Scale & position info
    VStack { /* Mini-map (top-right) */ }       // Interactive mini-map
    VStack { /* Controls (bottom) */ }          // D-pad + zoom buttons
}
```

**Controls Integration:**

```swift
// D-pad (player movement)
Button(action: { scene.movePlayerBy(dx: 0, dy: 40) }) {
    Image(systemName: "arrow.up")
}

// Zoom controls
Button(action: { scene.zoomIn() }) {
    Image(systemName: "plus.magnifyingglass")
}

// Focus toggle
Button(action: { scene.setCameraFocus(!scene.isCameraFocused) }) {
    Image(systemName: scene.isCameraFocused ? "target" : "target.circle")
        .foregroundColor(scene.isCameraFocused ? .yellow : .white)
}
```

**Logic Flow hoàn chỉnh:**

1. User nhấn D-pad → `movePlayerBy()` → Player animation → Camera follow (nếu focused)
2. User pinch/zoom → `setCameraScale()` → Camera zoom + constraints update
3. User toggle focus → `setCameraFocus()` → Constraints update + visual feedback
4. User drag mini-map → `handleDrag()` → Camera jump to new position
5. Timer cập nhật mini-map → Player position + viewport sync → Visual feedback

**Performance optimizations:**

- Timer 0.08s (12.5 FPS) cho mini-map (đủ smooth, không lag)
- Grid giới hạn 20x15 tiles
- Parallax chỉ 3 layers
- Constraints auto-update chỉ khi cần thiết

## Cách chạy và test Demo

### Bước 1: Build & Run

1. Mở `tutorial.xcodeproj` trong Xcode
2. Chọn target `tutorial` và Simulator (iPhone 15 Pro khuyên dùng)
3. Build & Run (⌘R)
4. Trong app: tap "lesson 2 sence"

### Bước 2: Test các tính năng

**A. Player Movement & Camera Follow:**

- Dùng D-pad (4 mũi tên) để di chuyển player đỏ
- Camera sẽ follow player mượt mà (focus mode mặc định = ON)
- Quan sát parallax background di chuyển với tốc độ khác nhau

**B. Zoom System:**

- Tap nút `+` (plus.magnifyingglass): zoom in
- Tap nút `-` (minus.magnifyingglass): zoom out
- Hoặc dùng pinch gesture trên main view
- HUD top-left sẽ hiển thị scale realtime

**C. Focus Mode Toggle:**

- Tap nút target: toggle giữa focus/free camera
- Focus ON: icon vàng, camera follow player
- Focus OFF: icon trắng, camera tự do

**D. Mini-map Navigation:**

- Mini-map ở góc trên phải hiển thị toàn bộ world
- Player đỏ nhỏ di chuyển theo realtime
- Viewport rectangle trắng hiển thị vùng camera
- Khi focus OFF: drag trên mini-map để jump camera

**E. Debug Info:**

- HUD hiển thị camera scale và position
- FPS counter (từ SKView.showsFPS)
- Mini-map viewport thay đổi màu theo focus mode

### Bước 3: Advanced Testing

**Workflow Integration:**

1. Di chuyển player bằng D-pad
2. Zoom out để thấy toàn cảnh
3. Tắt focus mode (nút target → trắng)
4. Drag mini-map để explore world
5. Zoom in tại vùng mới
6. Bật lại focus mode để follow player

**Performance check:**

- FPS ổn định ~60fps trên Simulator
- Parallax mượt mà không giật lag
- Mini-map update realtime không ảnh hưởng performance chính

Nếu có lỗi build hoặc runtime issues, check:

- Import statements đầy đủ (SwiftUI, SpriteKit, Combine)
- All files trong Xcode project target
- Simulator iOS version compatibility
