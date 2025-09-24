## Bài 1 — SpriteKit + SwiftUI: Game Scene

Mục tiêu: tạo một `SKScene` đơn giản (`GameScene`) và nhúng vào SwiftUI bằng `SpriteView` để thực hành nền, label, biên vật lý, một quả bóng có physics và xử lý chạm để spawn thêm.

### Tệp liên quan

- `ContentView.swift` — SwiftUI view chứa `SpriteView(scene:)` (bridge giữa SwiftUI và SpriteKit).
- `GameScene.swift` — lớp `SKScene` chính: thiết lập background, label, physics edge loop, spawn ball, xử lý chạm.

### Tóm tắt hành vi chính

- ContentView:

  - Tạo `GameScene(size:)` với `scaleMode = .resizeFill` (xem `ContentView.swift`).
  - Hiển thị scene bằng `SpriteView(scene:)`.

- GameScene:
  - `didMove(to:)`:
    - Đặt `backgroundColor` và thêm `titleLabel` (SKLabelNode).
    - Tạo biên vật lý quanh scene: `physicsBody = SKPhysicsBody(edgeLoopFrom: frame)`.
    - Gọi `spawnBall(at:)` để tạo 1 quả bóng ban đầu.
    - Gọi `relayoutForCurrentSize()` để đặt lại vị trí các node phụ thuộc kích thước.
  - `didChangeSize(_:)`:
    - Cập nhật lại `physicsBody` theo frame mới và gọi lại `relayoutForCurrentSize()`.
  - `spawnBall(at:)`:
    - Tạo `SKShapeNode(circleOfRadius:)`, gán `SKPhysicsBody(circleOfRadius:)` và cấu hình `restitution`, `friction`, `linearDamping`.
    - `addChild(ball)`.
  - Xử lý chạm: override `touchesBegan(_:with:)` để spawn ball tại vị trí chạm.

### Lưu ý kỹ thuật ngắn gọn

- Kích thước scene: `ContentView` khởi tạo scene bằng `geometry.size` nên sẽ phù hợp với view thật (scaleMode `.resizeFill`).
- Scale modes:
  - `.resizeFill`: scene co dãn theo view (thường dùng khi bạn muốn layout dựa vào kích thước mới).
  - `.aspectFill` / `.aspectFit`: giữ tỉ lệ, có thể cắt hoặc letterbox.
- Debugging: để xem physics bodies và FPS, bật trên `SKView` (ví dụ trong AppDelegate/SceneDelegate hoặc SwiftUI wrapper):

```swift
if let skView = view as? SKView {
    skView.showsFPS = true
    skView.showsPhysics = true
}
```

### Cách chạy nhanh (Xcode)

1. Mở `tutorial.xcodeproj` bằng Xcode.
2. Chọn target `tutorial` và một Simulator (ví dụ iPhone 15 Pro).
3. Build & Run (Cmd+R).
4. Khi app chạy, chạm/click vào màn hình để spawn thêm quả bóng. Quan sát debug overlay nếu đã bật.

### Gợi ý mở rộng (tăng độ khó từ bài này)

- Dùng `SKSpriteNode` với texture thay vì `SKShapeNode` để có hình đẹp hơn (lưu ảnh vào Assets và tạo sprite từ texture).
- Thêm `SKPhysicsContactDelegate` để xử lý va chạm, tính điểm, hoặc phát hiện game-over.
- Tối ưu: dùng object pool để tái sử dụng node thay vì tạo/destroy nhiều lần.
- Kết hợp SwiftUI HUD: truyền trạng thái từ `GameScene` cho một `ObservableObject` và bind với SwiftUI overlay để hiển thị điểm/pauses.

### Try it — chỉnh sửa nhanh để bật debug overlays

Mở `ContentView.swift` và trong `makeScene(size:)` hoặc nơi bạn tạo `SKView` (nếu dùng UIViewRepresentable) bật `showsFPS`/`showsPhysics`. Với cấu trúc hiện tại (SwiftUI `SpriteView`) bạn có thể tạm debug bằng cách tạo `SKView` trong một `UIViewRepresentable` để có quyền truy cập vào các tùy chọn debug.

Muốn mình làm hộ phần đó (ví dụ thêm một `SpriteViewRepresentable` với debug toggles)? Mình có thể thêm nhanh.

---

Nếu bạn muốn, mình sẽ tiếp tục và:

- Thêm ví dụ đổi `spawnBall` sang `SKSpriteNode` dùng asset image.
- Thêm phiên bản demo bật `showsFPS`/`showsPhysics` bằng `UIViewRepresentable`.
