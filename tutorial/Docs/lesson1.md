# Bài 1: Tạo Game Scene Cơ Bản với SpriteKit và SwiftUI

## Tổng quan

Bài học này giới thiệu cách tích hợp SpriteKit với SwiftUI để tạo một game scene cơ bản. Chúng ta sẽ tạo một scene với nền tối, một nhãn tiêu đề, và các quả bóng vật lý có thể tương tác thông qua touch.

## Cấu trúc dự án

Dự án bao gồm các file chính sau:

- `Lesson/Lesson1/lesson1.swift`: View SwiftUI chính để hiển thị SpriteKit scene
- `Lesson/Lesson1/GameScene.swift`: Lớp GameScene kế thừa từ SKScene, chứa logic game
- `Docs/lesson1.md`: Tài liệu hướng dẫn này

## Chi tiết triển khai

### 1. lesson1.swift - SwiftUI View

#### Cấu trúc code

```swift
import SwiftUI
import SpriteKit

struct Lesson1 : View {
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: makeScene(size: geometry.size))
                .ignoresSafeArea()
        }
    }

    private func makeScene(size: CGSize) -> SKScene {
        let scene = GameScene(size: size)
        scene.scaleMode = .resizeFill
        return scene
    }
}
```

#### Giải thích chi tiết

**Import statements:**

- `import SwiftUI`: Cần thiết để sử dụng SwiftUI framework
- `import SpriteKit`: Cần thiết để tích hợp với SpriteKit

**Struct Lesson1:**

- Là một SwiftUI View struct, tuân theo protocol `View`
- Sử dụng `GeometryReader` để lấy kích thước của view container

**GeometryReader:**

- Cho phép truy cập kích thước và vị trí của parent view
- Trong trường hợp này, dùng để lấy `geometry.size` làm kích thước cho scene

**SpriteView:**

- Là SwiftUI view wrapper cho SpriteKit scene
- Nhận parameter `scene` là SKScene instance
- `.ignoresSafeArea()` đảm bảo scene phủ toàn màn hình, không bị safe area cắt

**makeScene() function:**

- Tạo instance của `GameScene` với kích thước được cung cấp
- `scene.scaleMode = .resizeFill`: Scene sẽ tự động scale để lấp đầy toàn bộ SpriteView, có thể bị stretch

### 2. GameScene.swift - SpriteKit Scene

#### Cấu trúc code

```swift
import SpriteKit

class GameScene: SKScene {
    // Property
    private let titleLabel = SKLabelNode(text: "Bài 1: Game Scene")

    // Lifecycle methods
    override func didMove(to view: SKView) { ... }
    override func didChangeSize(_ oldSize: CGSize) { ... }

    // Helper methods
    private func relayoutForCurrentSize() { ... }
    func spawnBall(at position: CGPoint) { ... }

    // Touch handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { ... }
}
```

#### Giải thích chi tiết từng phần

**Import và Class Declaration:**

```swift
import SpriteKit

class GameScene: SKScene {
    private let titleLabel = SKLabelNode(text: "Bài 1: Game Scene")
}
```

- Kế thừa từ `SKScene`, là container chính cho tất cả game objects
- `titleLabel` là SKLabelNode private, dùng để hiển thị tiêu đề

**didMove(to:) - Khởi tạo scene:**

```swift
override func didMove(to view: SKView) {
    backgroundColor = SKColor(red: 0.08, green: 0.11, blue: 0.16, alpha: 1)

    // Label setup
    titleLabel.fontName = "AvenirNext-Bold"
    titleLabel.fontSize = 28
    titleLabel.fontColor = .white
    addChild(titleLabel)

    // Physics setup
    physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    physicsBody?.categoryBitMask = 0x1 << 1

    // Spawn initial ball
    spawnBall(at: CGPoint(x: size.width / 2, y: size.height / 2))

    // Initial layout
    relayoutForCurrentSize()
}
```

**Thiết lập background:**

- Sử dụng `SKColor` với RGBA values để tạo màu nền tối
- Các giá trị được normalize từ 0.0 đến 1.0

**Thiết lập label:**

- `fontName`: Chỉ định font family
- `fontSize`: Kích thước font tính bằng points
- `fontColor`: Màu chữ
- `addChild()`: Thêm node vào scene hierarchy

**Thiết lập physics:**

- `SKPhysicsBody(edgeLoopFrom: frame)`: Tạo physics body dạng vòng biên bao quanh frame
- `categoryBitMask`: Đặt category cho collision detection (bit shifting để tạo unique mask)

**Spawn ball ban đầu:**

- Gọi `spawnBall()` ở vị trí trung tâm scene

**didChangeSize(\_:) - Xử lý thay đổi kích thước:**

```swift
override func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)

    // Update physics body
    physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    physicsBody?.categoryBitMask = 0x1 << 1

    // Re-layout
    relayoutForCurrentSize()
}
```

- Được gọi khi scene size thay đổi (rotation, split view, etc.)
- Cập nhật physics body theo frame mới
- Gọi relayout để reposition các elements

**relayoutForCurrentSize() - Layout logic:**

```swift
private func relayoutForCurrentSize() {
    let safeTop = view?.safeAreaInsets.top ?? 0
    titleLabel.position = CGPoint(
        x: size.width / 2,
        y: size.height - safeTop - 44
    )
}
```

- Tính toán safe area top inset
- Position label ở giữa theo trục X, chừa safe area và margin theo trục Y

**spawnBall(at:) - Tạo quả bóng:**

```swift
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
```

**Tạo visual ball:**

- `SKShapeNode(circleOfRadius:)`: Tạo node hình tròn
- Thiết lập màu fill, stroke, line width
- Đặt position

**Thiết lập physics properties:**

- `SKPhysicsBody(circleOfRadius:)`: Tạo physics body hình tròn
- `restitution`: Độ nảy (0.0 = không nảy, 1.0 = nảy hoàn toàn)
- `friction`: Ma sát (0.0 = trơn, 1.0 = dính)
- `linearDamping`: Giảm tốc độ tuyến tính theo thời gian

**touchesBegan(\_:with:) - Xử lý touch:**

```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let loc = touch.location(in: self)
    spawnBall(at: loc)
}
```

- Lấy touch đầu tiên từ set touches
- Chuyển đổi vị trí touch sang coordinate system của scene
- Spawn ball tại vị trí đó

## Các khái niệm quan trọng

### SpriteKit Scene Lifecycle

- `didMove(to:)`: Được gọi khi scene được thêm vào view
- `didChangeSize(_:)`: Được gọi khi scene size thay đổi
- `update(_:)`: Được gọi mỗi frame (không override trong bài này)

### Physics World

- Mỗi scene có physics world riêng
- Physics bodies mô phỏng vật lý thực tế
- Collision detection và response

### Node Hierarchy

- Scene là root node
- Các node con được thêm bằng `addChild()`
- Position tính từ bottom-left corner (0,0)

### Coordinate System

- Origin (0,0) ở bottom-left
- X tăng sang phải, Y tăng lên trên
- Units là points (không phụ thuộc density)

## Các phần bổ sung và mở rộng

### 1. Performance Considerations

- Số lượng physics bodies ảnh hưởng đến performance
- Cân nhắc remove nodes không cần thiết
- Sử dụng texture atlas cho nhiều sprites

### 2. Accessibility

- Thêm accessibility labels cho interactive elements
- Hỗ trợ voice over cho game elements

### 3. Error Handling

- Kiểm tra nil cho optional values
- Xử lý trường hợp scene size = 0

### 4. Testing

- Unit tests cho logic functions
- UI tests cho SwiftUI integration
- Performance tests cho physics simulation

### 5. Advanced Physics

- Joints và constraints
- Custom physics fields
- Ray casting cho collision detection

## Kết luận

Bài học này đã giới thiệu cách cơ bản để tích hợp SpriteKit với SwiftUI, tạo scene với physics simulation và touch interaction. Đây là nền tảng để xây dựng các game phức tạp hơn với SpriteKit.
