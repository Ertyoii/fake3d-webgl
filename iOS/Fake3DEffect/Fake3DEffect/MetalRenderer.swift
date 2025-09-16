//
//  MetalRenderer.swift
//  Fake3DEffect
//
//  Created by hts on 8/31/25.
//

import Foundation
import Metal
import MetalKit
import SwiftUI
import UIKit

// Uniforms structure matching the Metal shader
struct Uniforms {
    var resolution: SIMD4<Float>    // width, height, scaleX, scaleY (16 bytes)
    var mouse: SIMD2<Float>         // normalized mouse position (8 bytes)
    var threshold: SIMD2<Float>     // horizontal and vertical threshold (8 bytes)
    var time: Float                 // time for animations (4 bytes)
    var pixelRatio: Float           // device pixel ratio (4 bytes)
    var padding: SIMD2<Float>       // padding to align to 16-byte boundary (8 bytes)
    
    init(resolution: SIMD4<Float>, mouse: SIMD2<Float>, threshold: SIMD2<Float>, time: Float, pixelRatio: Float) {
        self.resolution = resolution
        self.mouse = mouse
        self.threshold = threshold
        self.time = time
        self.pixelRatio = pixelRatio
        self.padding = SIMD2<Float>(0, 0) // Initialize padding
    }
}

class MetalRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    
    // Optimized buffer management
    private var uniformsBuffer: MTLBuffer?
    private let maxBuffersInFlight = 3
    private var currentBufferIndex = 0
    private var bufferSemaphore = DispatchSemaphore(value: 3)
    
    // Texture cache for efficient loading
    private var textureCache: [String: MTLTexture] = [:]
    private lazy var textureLoader = MTKTextureLoader(device: device)
    private var originalTexture: MTLTexture?
    private var depthTexture: MTLTexture?
    
    // Uniforms
    private var uniforms = Uniforms(
        resolution: SIMD4<Float>(0, 0, 1, 1),
        mouse: SIMD2<Float>(0, 0),
        threshold: SIMD2<Float>(35, 15),
        time: 0,
        pixelRatio: 1
    )
    
    // Demo configuration
    var currentDemo: DemoType = .lady {
        didSet {
            guard oldValue != currentDemo else { return }
            loadTextures(for: currentDemo)
            uniforms.threshold = SIMD2<Float>(currentDemo.horizontalThreshold, currentDemo.verticalThreshold)
        }
    }
    
    // Motion input
    var mousePosition: CGPoint = .zero {
        didSet {
            uniforms.mouse = SIMD2<Float>(Float(mousePosition.x), Float(mousePosition.y))
        }
    }
    
    private let startTime = CACurrentMediaTime()
    
    init?(device: MTLDevice) {
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        self.commandQueue = commandQueue
        
        super.init()
        
        setupMetal()
        setupUniformsBuffer()
        loadTextures(for: currentDemo)
    }
    
    private func setupUniformsBuffer() {
        // Metal requires 256-byte alignment for buffer offsets
        let uniformsAlignedSize = (MemoryLayout<Uniforms>.size + 255) & ~255  // Round up to 256-byte boundary
        let totalBufferSize = uniformsAlignedSize * maxBuffersInFlight
        uniformsBuffer = device.makeBuffer(length: totalBufferSize, options: [.storageModeShared])
        uniformsBuffer?.label = "UniformsBuffer"
    }
    
    private func setupMetal() {
        // Create vertex buffer for full-screen quad (two triangles)
        let vertices: [Float] = [
            -1.0, -1.0,  // Bottom left
             1.0, -1.0,  // Bottom right
            -1.0,  1.0,  // Top left
            -1.0,  1.0,  // Top left
             1.0, -1.0,  // Bottom right
             1.0,  1.0   // Top right
        ]
        
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
        
        // Create render pipeline
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create Metal library")
            return
        }
        
        guard let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: "fragment_main") else {
            print("Failed to create shader functions")
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 2 * MemoryLayout<Float>.size
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }
    
    private func loadTextures(for demo: DemoType) {
        // Use cached textures for better performance
        originalTexture = loadTextureWithCache(name: demo.imageName)
        depthTexture = loadTextureWithCache(name: demo.depthImageName)
    }
    
    private func loadTextureWithCache(name: String) -> MTLTexture? {
        if let cachedTexture = textureCache[name] {
            return cachedTexture
        }

        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue),
            .SRGB: NSNumber(value: true)
        ]

        do {
            let texture = try textureLoader.newTexture(
                name: name,
                scaleFactor: UIScreen.main.scale,
                bundle: .main,
                options: options
            )
            texture.label = name
            textureCache[name] = texture
            return texture
        } catch {
            print("Failed to create texture named \(name): \(error)")
            return nil
        }
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Update resolution uniforms with proper aspect ratio scaling
        let pixelRatio = Float(UIScreen.main.scale)
        uniforms.pixelRatio = 1.0 / pixelRatio
        
        // Calculate proper aspect ratio scaling to maintain image proportions
        guard let originalTexture = originalTexture else { 
            uniforms.resolution = SIMD4<Float>(Float(size.width), Float(size.height), 1.0, 1.0)
            return 
        }
        
        let imageAspect = Float(originalTexture.width) / Float(originalTexture.height)
        let viewAspect = Float(size.width) / Float(size.height)
        
        var scaleX: Float = 1.0
        var scaleY: Float = 1.0
        
        // Scale to show entire image without distortion
        if viewAspect > imageAspect {
            // View is wider than image - scale X to fit
            scaleX = imageAspect / viewAspect
            scaleY = 1.0
        } else {
            // View is taller than image - scale Y to fit
            scaleX = 1.0
            scaleY = viewAspect / imageAspect
        }
        
        uniforms.resolution = SIMD4<Float>(Float(size.width), Float(size.height), scaleX, scaleY)
    }
    
    func draw(in view: MTKView) {
        // Wait for available buffer (triple buffering)
        bufferSemaphore.wait()
        
        guard let pipelineState = pipelineState,
              let vertexBuffer = vertexBuffer,
              let uniformsBuffer = uniformsBuffer,
              let originalTexture = originalTexture,
              let depthTexture = depthTexture,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            bufferSemaphore.signal()
            return
        }
        
        // Update uniforms with current buffer (using 256-byte aligned offset)
        let uniformsAlignedSize = (MemoryLayout<Uniforms>.size + 255) & ~255
        let uniformsOffset = uniformsAlignedSize * currentBufferIndex
        let uniformsPointer = uniformsBuffer.contents().advanced(by: uniformsOffset).bindMemory(to: Uniforms.self, capacity: 1)
        
        // Update time efficiently
        uniforms.time = Float(CACurrentMediaTime() - startTime)
        uniformsPointer.pointee = uniforms
        
        // Create command buffer with optimization
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { 
            bufferSemaphore.signal()
            return 
        }
        commandBuffer.label = "Fake3D Render Command"
        
        // Add completion handler for buffer recycling
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.bufferSemaphore.signal()
        }
        
        // Create render encoder
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { 
            bufferSemaphore.signal()
            return 
        }
        renderEncoder.label = "Fake3D Render Encoder"
        
        // Set pipeline state
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set vertex buffer
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Set uniforms buffer (more efficient than setFragmentBytes)
        renderEncoder.setFragmentBuffer(uniformsBuffer, offset: uniformsOffset, index: 0)
        
        // Set textures
        renderEncoder.setFragmentTexture(originalTexture, index: 0)
        renderEncoder.setFragmentTexture(depthTexture, index: 1)
        
        // Draw primitives
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        // End encoding
        renderEncoder.endEncoding()
        
        // Present drawable
        commandBuffer.present(drawable)
        
        // Commit command buffer
        commandBuffer.commit()
        
        // Advance to next buffer
        currentBufferIndex = (currentBufferIndex + 1) % maxBuffersInFlight
    }
}

// MARK: - Demo Types
// DemoType is now defined in DemoConfiguration.swift

// MARK: - SwiftUI Integration

struct MetalView: UIViewRepresentable {
    let demo: DemoType
    let motionManager: DeviceMotionManager
    
    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        metalView.device = device
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.autoResizeDrawable = true
        
        guard let renderer = MetalRenderer(device: device) else {
            fatalError("Failed to create Metal renderer")
        }
        metalView.delegate = renderer
        
        // Store renderer in context for updates
        context.coordinator.renderer = renderer
        
        return metalView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        guard let renderer = context.coordinator.renderer else { return }

        if renderer.currentDemo != demo {
            renderer.currentDemo = demo
        }

        renderer.mousePosition = motionManager.mousePosition
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var renderer: MetalRenderer?
    }
}
