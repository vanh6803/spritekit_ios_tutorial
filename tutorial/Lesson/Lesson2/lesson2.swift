//
//  lesson2.swift
//  tutorial
//
//  Created by Nguyễn Việt Anh on 24/9/25.
//
import SwiftUI
import SpriteKit

struct Lesson2: View {
    @State private var scene: CameraScene = {
        let s = CameraScene(size: CGSize(width: 750, height: 1334))
        s.scaleMode = .resizeFill
        return s
    }()

    var body: some View {
        ZStack {
            // Camera frame
            CameraView(scene: scene)
                .ignoresSafeArea()

            // HUD nhỏ ở góc
            VStack(alignment: .leading, spacing: 6) {
                Text("Scale: \(String(format: "%.2f", scene.cameraScale))")
                    .font(.caption)
                    .padding(6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(6)
                Text("Camera: x=\(Int(scene.camera?.position.x ?? 0)), y=\(Int(scene.camera?.position.y ?? 0))")
                    .font(.caption2)
                    .padding(6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(6)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Mini-map ở góc trên phải
            VStack {
                HStack {
                    Spacer()
                    MiniMapView(scene: scene)
                        .frame(width: 150, height: 120)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding()
                }
                Spacer()
            }

            // D-pad controls overlay
            VStack {
                Spacer()
                HStack {
                    VStack(spacing: 6) {
                        Button(action: { scene.movePlayerBy(dx: 0, dy: 40) }) {
                            Image(systemName: "arrow.up")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        HStack(spacing: 6) {
                            Button(action: { scene.movePlayerBy(dx: -40, dy: 0) }) {
                                Image(systemName: "arrow.left")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            Button(action: { scene.movePlayerBy(dx: 40, dy: 0) }) {
                                Image(systemName: "arrow.right")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                        Button(action: { scene.movePlayerBy(dx: 0, dy: -40) }) {
                            Image(systemName: "arrow.down")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // Zoom and focus controls
                    VStack(spacing: 8) {
                        Button(action: { scene.zoomIn() }) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { scene.zoomOut() }) {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { 
                            scene.setCameraFocus(!scene.isCameraFocused)
                        }) {
                            Image(systemName: scene.isCameraFocused ? "target" : "target.circle")
                                .font(.title2)
                                .foregroundColor(scene.isCameraFocused ? .yellow : .white)
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
            }
        }
    }
}


#Preview {
    Lesson2()
}
