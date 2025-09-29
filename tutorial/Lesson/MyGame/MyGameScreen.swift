import SwiftUI
import SpriteKit

struct MyGameScreen: View {
    @State private var scene = MyGameScene(size: .zero)

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    // chỉ set 1 lần khi xuất hiện
                    scene.scaleMode = .resizeFill
                    scene.size = geo.size
                }
                .onChange(of: geo.size) { newSize in
                    scene.size = newSize
                }
        }
    }
}

#Preview {
    MyGameScreen()
}