import SpriteKit

class MyGameScene: SKScene {
    private var keyData: [KeyData] = []
    private let keyboardNode = SKNode()
    
    // Scroll state
    private var contentWidth: CGFloat = 0
    private var lastTouchX: CGFloat = 0
    private var totalDrag: CGFloat = 0
    private var isDragging: Bool = false
    private var pressedCandidate: SKNode?
    
    // Layout option: số phím trắng hiển thị trên mỗi màn
    private let keysPerScreen: CGFloat = 14
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.11, blue: 0.16, alpha: 1)
        addChild(keyboardNode)
        loadKeyData()
        layoutKeyboard()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutKeyboard() // re-layout khi xoay/đổi size
    }
    
    private func loadKeyData() {
        guard let path = Bundle.main.path(forResource: "KeyNote", ofType: "json"),
              let data = NSData(contentsOfFile: path) else {
            print("Không thể tìm thấy file KeyNote.json")
            return
        }
        do {
            keyData = try JSONDecoder().decode([KeyData].self, from: data as Data)
            print("Đã load \(keyData.count) phím")
        } catch {
            print("Lỗi khi decode JSON: \(error)")
        }
    }
    
    private func layoutKeyboard() {
        keyboardNode.removeAllChildren()
        
        let pianoHeight = size.height / 1.7
        let pianoCenterY = pianoHeight / 2
        
        let displayKeys = keyData
        
        let whiteCount = displayKeys.filter { $0.color == "white" }.count
        
        // Kích thước key
        let whiteKeyWidth  = size.width / keysPerScreen
        let whiteKeyHeight = pianoHeight * 0.8
        let blackKeyWidth  = whiteKeyWidth * 0.6
        let blackKeyHeight = whiteKeyHeight * 0.7
        
        let leftEdge: CGFloat = 0
        
        var whiteIndex: Int = 0
        
        for k in displayKeys {
            if k.color == "white" {
                // Tâm phím trắng ở giữa cell thứ whiteIndex
                let x = leftEdge + (CGFloat(whiteIndex) + 0.5) * whiteKeyWidth
                let node = createWhiteKey(
                    keySize: CGSize(width: whiteKeyWidth, height: whiteKeyHeight),
                    keyInfo: k
                )
                node.position = CGPoint(x: x, y: pianoCenterY)
                keyboardNode.addChild(node)
                
                whiteIndex += 1
            } else {
                // Phím đen nằm giữa phím trắng trước đó và phím trắng kế tiếp
                // => tại mốc whiteIndex hiện tại (vì whiteIndex đã tăng sau khi đi qua white trước đó)
                // Ví dụ A0 (whiteIndex=0) -> A#0 ở x = (0+1)*W - 0.5W? Không cần, chỉ cần đặt đúng "giữa": x = leftEdge + CGFloat(whiteIndex) * whiteKeyWidth
                let x = leftEdge + CGFloat(whiteIndex) * whiteKeyWidth
                let node = createBlackKey(
                    keySize: CGSize(width: blackKeyWidth, height: blackKeyHeight),
                    keyInfo: k
                )
                node.position = CGPoint(
                    x: x,
                    y: pianoCenterY + (whiteKeyHeight - blackKeyHeight) * 0.5
                )
                keyboardNode.addChild(node)
            }
        }
        
        // Tổng bề rộng theo số phím trắng
        contentWidth = CGFloat(whiteCount) * whiteKeyWidth
        
        // Reset/clamp vị trí
        if contentWidth <= size.width {
            keyboardNode.position.x = 0
        } else {
            clampKeyboardX()
        }
    }
    
    
    private func createWhiteKey(keySize: CGSize, keyInfo: KeyData) -> SKShapeNode {
        let key = SKShapeNode(rectOf: keySize, cornerRadius: keySize.width * 0.06)
        key.name = "white_key_\(keyInfo.fullName)"
        key.fillColor = .white
        key.strokeColor = SKColor(white: 0.2, alpha: 1.0)
        key.lineWidth = 1.0
        key.zPosition = 10
        
        // Viền sáng cạnh trên
        let highlightHeight = keySize.height * 0.08
        let highlight = SKShapeNode(
            rectOf: CGSize(width: keySize.width * 0.96, height: highlightHeight),
            cornerRadius: highlightHeight * 0.3
        )
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.35)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 0, y: keySize.height/2 - highlightHeight/2 - 2)
        highlight.zPosition = 1
        key.addChild(highlight)
        
        // Nhãn
        let label = SKLabelNode(text: keyInfo.fullName)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = min(14, keySize.width * 0.2)
        label.fontColor = SKColor(white: 0.2, alpha: 1.0)
        label.position = CGPoint(x: 0, y: -keySize.height/2 + label.fontSize + 6)
        label.zPosition = 2
        key.addChild(label)
        
        return key
    }
    
    private func createBlackKey(keySize: CGSize, keyInfo: KeyData) -> SKShapeNode {
        let key = SKShapeNode(rectOf: keySize, cornerRadius: keySize.width * 0.06)
        key.name = "black_key_\(keyInfo.fullName)"
        key.fillColor = SKColor(white: 0.1, alpha: 1.0)
        key.strokeColor = SKColor(white: 0.05, alpha: 1.0)
        key.lineWidth = 1.0
        key.zPosition = 20
        
        // gradient key
        let gradient = SKShapeNode(
            rectOf: CGSize(width: keySize.width * 0.9, height: keySize.height * 0.3),
            cornerRadius: keySize.width * 0.04
        )
        gradient.fillColor = SKColor(white: 0.25, alpha: 0.6)
        gradient.strokeColor = .clear
        gradient.position = CGPoint(x: 0, y: keySize.height/3)
        gradient.zPosition = 1
        key.addChild(gradient)
        
        // name
        let label = SKLabelNode(text: keyInfo.fullName)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = min(12, keySize.width * 0.18)
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: -keySize.height/2 + label.fontSize + 4)
        label.zPosition = 2
        key.addChild(label)
        
        return key
    }
    
    private func getBlackKeyPosition(for keyInfo: KeyData, whiteKeyWidth: CGFloat, leftEdge: CGFloat, baseOctave: Int) -> CGFloat {
        // Vị trí giữa các phím trắng trong 1 octave (C=0 … B=6)
        let rel: [String: CGFloat] = [
            "C#": 0.5, "D#": 1.5, "F#": 3.5, "G#": 4.5, "A#": 5.5
        ]
        guard let r = rel[keyInfo.note] else { return leftEdge }
        
        // Tính offset theo octave đầu tiên có trong data hiển thị (động)
        let octaveOffset = CGFloat(keyInfo.octave - baseOctave) * 7.0
        
        // Tâm phím đen
        return leftEdge + (octaveOffset + r + 0.5) * whiteKeyWidth
    }
    
    // Giới hạn kéo trong khoảng hiển thị
    private func clampKeyboardX() {
        let minX = min(0, size.width - contentWidth) // âm nếu content rộng hơn màn
        keyboardNode.position.x = max(minX, min(0, keyboardNode.position.x))
    }
    
    // MARK: - Touch: Scroll 1 ngón + Tap nếu không kéo
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        lastTouchX = t.location(in: self).x
        totalDrag = 0
        isDragging = false
        
        // Ghi nhận phím (để nếu không kéo thì coi như tap)
        let p = t.location(in: self)
        pressedCandidate = resolveKeyNode(from: nodes(at: p))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let x = t.location(in: self).x
        let dx = x - lastTouchX
        lastTouchX = x
        
        // Kéo nội dung
        if contentWidth > size.width {
            keyboardNode.position.x += dx
            clampKeyboardX()
        }
        
        totalDrag += abs(dx)
        if totalDrag > 8 { // ngưỡng: > 8pt coi như đang kéo, không xem là tap nữa
            isDragging = true
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            pressedCandidate = nil
            isDragging = false
            totalDrag = 0
        }
        
        guard !isDragging, let keyNode = pressedCandidate else { return }
        // Tap animation (nếu cần phát âm, gọi play ở đây)
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.08)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.08)
        keyNode.run(.sequence([scaleDown, scaleUp]))
        print("Phím tap: \(keyNode.name ?? "?")")
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        pressedCandidate = nil
        isDragging = false
        totalDrag = 0
    }
    
    // Leo lên node cha để bắt “key_” kể cả chạm vào label/gradient
    private func resolveKeyNode(from nodes: [SKNode]) -> SKNode? {
        for n in nodes {
            var cur: SKNode? = n
            while let c = cur {
                if let nm = c.name, nm.contains("key_") { return c }
                cur = c.parent
            }
        }
        return nil
    }
}
