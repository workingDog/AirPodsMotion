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
        RealityView(motionManager: motionManager)
            .ignoresSafeArea()
    }
}

@Observable
class MotionManager {
    private let manager = CMHeadphoneMotionManager()
    var attitude: CMAttitude?

    init() {
        
        let status = CMHeadphoneMotionManager.authorizationStatus()
        print("\n----> status: \(status)")
        
        if manager.isDeviceMotionAvailable {
            print("\n----> Device motion available")
            manager.startDeviceMotionUpdates(to: .main) { motion, error in
    //            print("\n----> Device motion started \(motion)")
                guard let motion = motion, error == nil else { return }
                self.attitude = motion.attitude
            }
        } else {
            print("Device motion not available on this device")
        }
    }
    
    deinit {
        manager.stopDeviceMotionUpdates()
    }
}


struct RealityView: UIViewRepresentable {
    var motionManager: MotionManager
    
  //  let arView = ARView(frame: .zero)
    
    let arView = ARView(frame: .zero,
                        cameraMode: .nonAR,
                        automaticallyConfigureSession: true)
                        

    let cube = ModelEntity(mesh: .generateBox(size: 3, cornerRadius: 0.5),
                           materials: [SimpleMaterial(color: .blue, isMetallic: false)])

    func makeUIView(context: Context) -> ARView {
        arView.environment.background = .color(.lightGray)
        
        // Camera
        let cameraEntity = Entity()
        cameraEntity.components[PerspectiveCameraComponent.self] = PerspectiveCameraComponent()
        cameraEntity.position = [0, 0, 15]
        
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(cameraEntity)
        arView.scene.addAnchor(anchor)
        
        // Lights
        let lightAnchor = AnchorEntity(world: .zero)
        
        let omniLight = PointLight()
        omniLight.light.intensity = 2000
        let omniEntity = Entity()
        omniEntity.components[PointLightComponent.self] = PointLightComponent(color: .white, intensity: 2000, attenuationRadius: 20)
        omniEntity.position = [0, 10, 10]
        
        let ambientLight = DirectionalLight()
        ambientLight.light.intensity = 1000
        ambientLight.light.color = .gray
        let ambientEntity = Entity()
        ambientEntity.components[DirectionalLightComponent.self] = DirectionalLightComponent(color: .gray, intensity: 1000, isRealWorldProxy: false)
        ambientEntity.orientation = simd_quatf(angle: -.pi/4, axis: [1, 0, 0])
        
        lightAnchor.addChild(omniEntity)
        lightAnchor.addChild(ambientEntity)
        arView.scene.addAnchor(lightAnchor)
        
        // Cube with face
        let faceAnchor = AnchorEntity(world: .zero)
        
        // Eyes
        let eye = ModelEntity(mesh: .generateSphere(radius: 0.3),
                              materials: [SimpleMaterial(color: .white, isMetallic: false)])
        let leftEye = eye.clone(recursive: true)
        leftEye.position = [0.6, 0.6, 1.5]
        let rightEye = eye.clone(recursive: true)
        rightEye.position = [-0.6, 0.6, 1.5]
        
        // Nose
        let nose = ModelEntity(mesh: .generateSphere(radius: 0.3),
                               materials: [SimpleMaterial(color: .red, isMetallic: false)])
        nose.position = [0, 0, 1.5]
        
        // Mouth
        let mouth = ModelEntity(mesh: .generateBox(size: [1.5, 0.2, 0.2], cornerRadius: 0.1),
                                materials: [SimpleMaterial(color: .black, isMetallic: false)])
        mouth.position = [0, -0.6, 1.5]
        
        cube.addChild(leftEye)
        cube.addChild(rightEye)
        cube.addChild(nose)
        cube.addChild(mouth)
        
        faceAnchor.addChild(cube)
        arView.scene.addAnchor(faceAnchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let attitude = motionManager.attitude {
            cube.transform.rotation = quaternionFromEuler(
                pitch: -Float(attitude.pitch),
                yaw:   -Float(attitude.yaw),
                roll:  -Float(attitude.roll)
            )
        }
    }
    
    func quaternionFromEuler(pitch: Float, yaw: Float, roll: Float) -> simd_quatf {
        let qx = simd_quatf(angle: pitch, axis: [1, 0, 0])
        let qy = simd_quatf(angle: yaw,   axis: [0, 1, 0])
        let qz = simd_quatf(angle: roll,  axis: [0, 0, 1])
        return qy * qx * qz // Note: order matters
    }
}
