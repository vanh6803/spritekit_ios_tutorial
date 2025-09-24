//
//  ContentView.swift
//  tutorial
//
//  Created by Nguyễn Việt Anh on 23/9/25.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NavigationLink("lesson 1 sence") {
                    Lesson1()
                }
                .buttonStyle(.borderedProminent)

                NavigationLink("lesson 2 sence") {
                    Lesson2()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Tutorial")
        }
    }
}

#Preview {
    ContentView()
}
