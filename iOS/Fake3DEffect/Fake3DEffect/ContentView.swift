//
//  ContentView.swift
//  Fake3DEffect
//
//  Created by hts on 8/31/25.
//

import SwiftUI
import MetalKit

struct ContentView: View {
    @StateObject private var motionManager = DeviceMotionManager()
    @State private var selectedDemo: DemoType = .lady
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title Section
                    VStack(spacing: 8) {
                        Text("Fake 3D Effect with Shaders")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Tilt your device to see the effect")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Metal View
                    MetalView(
                        demo: selectedDemo,
                        motionManager: motionManager
                    )
                    .aspectRatio(getImageAspectRatio(for: selectedDemo), contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .padding(.horizontal, 20)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Spacer()
                    
                    // Demo Selection
                    VStack(spacing: 16) {
                        Text("Select Demo")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(DemoType.allCases, id: \.self) { demo in
                                DemoButton(
                                    demo: demo,
                                    isSelected: selectedDemo == demo
                                ) {
                                    selectedDemo = demo
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            motionManager.startMotionUpdates()
        }
        .onDisappear {
            motionManager.stopMotionUpdates()
        }
    }
    
    // Helper function to get aspect ratio for each demo
    private func getImageAspectRatio(for demo: DemoType) -> CGFloat {
        switch demo {
        case .lady:
            return 1.5 // Landscape image (wider than tall)
        case .ball:
            return 1.0 // Square image
        case .mount:
            return 1.5 // Landscape image (roughly 3:2)
        case .canyon:
            return 1.33 // Landscape image (roughly 4:3)
        }
    }
}

struct DemoButton: View {
    let demo: DemoType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(demo.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(demo.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                    .stroke(
                        isSelected ? Color.blue : Color.white.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}
