//
//  lesson1.swift
//  tutorial
//
//  Created by Nguyễn Việt Anh on 24/9/25.
//
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
