//
//  DemoConfiguration.swift
//  Fake3DEffect
//
//  Created by hts on 8/31/25.
//

import Foundation

// Demo type enumeration - shared between ContentView and MetalRenderer
enum DemoType: String, CaseIterable {
    case lady = "lady"
    case ball = "ball"
    case mount = "mount"
    case canyon = "canyon"
    
    var displayName: String {
        switch self {
        case .lady: return "Lady Portrait"
        case .ball: return "Abstract Ball"
        case .mount: return "Mountain"
        case .canyon: return "Canyon"
        }
    }
    
    var imageName: String {
        return rawValue
    }
    
    var depthImageName: String {
        return "\(rawValue)-map"
    }
    
    var horizontalThreshold: Float {
        switch self {
        case .lady, .canyon: return 35.0
        case .ball, .mount: return 15.0
        }
    }
    
    var verticalThreshold: Float {
        switch self {
        case .lady: return 15.0
        case .ball, .mount, .canyon: return 25.0
        }
    }
}
