//
//  DeviceMotionManager.swift
//  Fake3DEffect
//
//  Created by hts on 8/31/25.
//

import Foundation
import CoreMotion
import Combine

class DeviceMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()
    private let maxTilt: Double = 15.0 // degrees
    
    @Published var mousePosition: CGPoint = .zero
    @Published var isMotionAvailable: Bool = false
    
    init() {
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        isMotionAvailable = motionManager.isDeviceMotionAvailable
        
        if isMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 FPS
        }
    }
    
    func startMotionUpdates() {
        guard isMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        guard motionManager.isDeviceMotionActive == false else { return }

        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else {
                if let error = error {
                    print("Motion update error: \(error)")
                }
                return
            }
            
            // Process motion data on background queue, update UI on main
            self.processMotionData(motion)
        }
    }
    
    func stopMotionUpdates() {
        guard motionManager.isDeviceMotionActive else { return }
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        // Get attitude more efficiently (avoid intermediate variables)
        let pitch = motion.attitude.pitch * 180.0 / .pi  // Forward/backward tilt
        let roll = motion.attitude.roll * 180.0 / .pi    // Left/right tilt
        
        // Clamp and normalize in one step for better performance
        let normalizedX = max(-1.0, min(1.0, roll / maxTilt))
        let normalizedY = max(-1.0, min(1.0, pitch / maxTilt))
        
        // Create new position
        let newPosition = CGPoint(x: -normalizedX, y: normalizedY)
        
        // Add threshold to avoid micro-updates and reduce GPU load
        let threshold: Double = 0.005  // Smaller threshold for smoother motion
        if abs(newPosition.x - mousePosition.x) > threshold || 
           abs(newPosition.y - mousePosition.y) > threshold {
            
            // Update on main queue only when necessary
            DispatchQueue.main.async { [weak self] in
                self?.mousePosition = newPosition
            }
        }
    }
    
    deinit {
        stopMotionUpdates()
    }
}

// MARK: - Extensions for easier access
extension DeviceMotionManager {
    var normalizedMouseX: Float {
        Float(mousePosition.x)
    }
    
    var normalizedMouseY: Float {
        Float(mousePosition.y)
    }
}
