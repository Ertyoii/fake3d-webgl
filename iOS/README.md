# Fake 3D Effect - iOS Native App

A native iOS implementation of the fake 3D effect using Metal shaders and CoreMotion for device orientation.

## 🚀 Features

- **Metal Rendering**: High-performance GPU-accelerated rendering
- **CoreMotion Integration**: Natural device tilt controls
- **SwiftUI Interface**: Modern, responsive UI design
- **Multiple Demos**: Lady portrait, abstract ball, mountain, and canyon scenes
- **Optimized Performance**: 60 FPS smooth animations

## 📱 Requirements

- iOS 17.0+
- Xcode 15.0+
- Device with Metal support (iPhone 6s+ or iPad Air 2+)
- Physical device recommended for motion controls

## 🛠️ Setup Instructions

1. **Open in Xcode**:
   ```bash
   cd iOS/Fake3DEffect
   open Fake3DEffect.xcodeproj
   ```

2. **Configure Team & Bundle ID**:
   - Select the project in Xcode
   - Go to "Signing & Capabilities"
   - Set your development team
   - Update bundle identifier if needed

3. **Build & Run**:
   - Select your target device
   - Press `Cmd+R` to build and run

## 📂 Project Structure

```
iOS/Fake3DEffect/
├── Fake3DEffect.xcodeproj/     # Xcode project file
├── Fake3DEffect/
│   ├── Fake3DEffectApp.swift   # App entry point
│   ├── ContentView.swift       # Main SwiftUI interface
│   ├── MetalRenderer.swift     # Metal rendering engine
│   ├── DeviceMotionManager.swift # CoreMotion handling
│   ├── Shaders.metal           # Metal shading language shaders
│   └── Assets.xcassets/        # Image assets and app icon
├── Fake3DEffectTests/          # Unit tests
├── Fake3DEffectUITests/        # UI tests
└── README.md                   # This file
```

## 🎮 How to Use

1. **Launch the app** on your iOS device
2. **Tilt your device** to see the 3D parallax effect
3. **Tap demo buttons** to switch between different images
4. **Enjoy** the smooth, native performance!

## 🔧 Technical Details

### Metal Shaders
- **Vertex Shader**: Renders full-screen quad
- **Fragment Shader**: Applies depth-based parallax effect
- **Uniforms**: Resolution, mouse position, thresholds, time

### CoreMotion Integration
- **Device Attitude**: Uses pitch and roll for natural controls
- **Normalized Input**: Converts motion to -1 to 1 range
- **Smooth Updates**: 60 FPS motion sampling

### SwiftUI Architecture
- **Reactive UI**: Automatically updates based on state changes
- **Metal Integration**: Seamless UIViewRepresentable wrapper
- **Modern Design**: Native iOS look and feel

## 🚀 Performance Optimizations

- **Metal Pipeline**: GPU-accelerated rendering
- **Efficient Textures**: Optimized texture loading and caching
- **Smooth Motion**: High-frequency motion updates
- **Memory Management**: Proper Metal resource lifecycle

## 🎨 Customization

### Adding New Demos
1. Add images to `Assets.xcassets`
2. Update `DemoType` enum in `MetalRenderer.swift`
3. Configure thresholds for the new demo

### Shader Modifications
- Edit `Shaders.metal` for visual effects
- Modify uniforms structure for new parameters
- Update `MetalRenderer.swift` accordingly

## 📄 License

Same as the web version - based on the original WebGL implementation.
