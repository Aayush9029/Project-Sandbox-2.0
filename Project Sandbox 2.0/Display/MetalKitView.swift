//
//  MetalKitView.swift
//  Project Sandbox 2.0
//
//  Created by Aayush Pokharel on 2022-04-07.
//

import MetalKit
import SwiftUI


struct MetalKitView: UIViewRepresentable {
    typealias UIViewType = MTKView
    
    func updateUIView(_ uiView: MTKView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<MetalKitView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        
        return mtkView
    }
}

