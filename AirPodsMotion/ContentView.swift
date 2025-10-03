//
//  ContentView.swift
//  AirPodsMotion
//
//  Created by Ringo Wathelet on 2025/10/02.
//

import SwiftUI
import RealityKit
import CoreMotion


struct ContentView: View {
    @State private var motionManager = MotionManager()
    
    var body: some View {
        RealityView { content in
            // Load the model from bundle
            if let entity = try? await Entity(named: "robot.usdz") {
                entity.scale = [0.03, 0.03, 0.03]
                entity.position = [0, -0.5, 0]
                
                // Wrap it in an anchor so it's visible in world space
                let anchor = AnchorEntity()
                anchor.addChild(entity)
                content.add(anchor)
                
                // Add a simple camera
                let camera = PerspectiveCamera()
                camera.position = [0, 0, 2]
                anchor.addChild(camera)
                
                // Add a light so it’s not black
                let light = DirectionalLight()
                light.light.intensity = 12000
                light.orientation = simd_quatf(angle: -.pi/4, axis: [1,0,0])
                anchor.addChild(light)

                // animate the model, just for fun
                for anim in entity.availableAnimations {
                    entity.playAnimation(anim.repeat(duration: .infinity), transitionDuration: 1.25, startsPaused: false)
                }
            }
        } update: { content in
            // Update rotation every frame when state changes
            if let entity = content.entities.first,
               let model = entity.findEntity(named: "robot_walk_idle") {
                model.orientation = motionManager.quaternionAttitude()
            }
        }
        .ignoresSafeArea()
        .background(Color.gray.opacity(0.5))
    }
}

@Observable
class MotionManager {
    private let manager = CMHeadphoneMotionManager()
    var attitude: CMAttitude?
    
    init() {
        print("\n----> status: \(CMHeadphoneMotionManager.authorizationStatus())")
        if manager.isDeviceMotionAvailable {
            print("----> Device motion available")
            manager.startDeviceMotionUpdates(to: .main) { motion, error in
                guard let motion = motion, error == nil else { return }
                self.attitude = motion.attitude
            }
        } else {
            print("Device motion not available on this device")
        }
    }
    
    func quaternionAttitude() -> simd_quatf {
        if let attitude {
            let s = 2.0 // <--- to adjust the sensitivity
            let qx = simd_quatf(angle: -Float(attitude.pitch * s), axis: [1, 0, 0])
            let qy = simd_quatf(angle: -Float(attitude.yaw * s),   axis: [0, 1, 0])
            let qz = simd_quatf(angle: -Float(attitude.roll * s),  axis: [0, 0, 1])
            return qy * qx * qz // Note: order matters
        } 
        return simd_quatf()
    }
    
    deinit {
        manager.stopDeviceMotionUpdates()
    }
}
