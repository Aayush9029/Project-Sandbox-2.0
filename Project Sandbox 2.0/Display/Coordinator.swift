//
//  Coordinator.swift
//  Project Sandbox 2.0
//
//  Created by Aayush Pokharel on 2022-04-07.
//

import MetalKit

struct Particle {
    var color: SIMD4<Float>
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var lifespan: Float16
}

class Coordinator : NSObject, MTKViewDelegate {
    var parent: MetalKitView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    
    var clearPass: MTLComputePipelineState!
    var drawDotPass: MTLComputePipelineState!
    
    var particleBuffer: MTLBuffer!
    
    var screenWidth: Float!
    var screenHeight: Float!

    var particleCount: Int = 5_000 //change this to add / remove particle
    
    init(_ parent: MetalKitView) {
        
        self.parent = parent
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
        }
        self.metalCommandQueue = metalDevice.makeCommandQueue()!
        
        screenWidth = Float(UIScreen.main.bounds.width)
        screenHeight = Float(UIScreen.main.bounds.height) 
        
        let library =  metalDevice.makeDefaultLibrary()
        let clearFunc = library?.makeFunction(name: "clear_pass_func")
        let drawDotFunc = library?.makeFunction(name: "draw_dots_func")
        
        do {
            clearPass = try self.metalDevice?.makeComputePipelineState(function: clearFunc!)
            drawDotPass = try self.metalDevice?.makeComputePipelineState(function: drawDotFunc!)
        }catch let error as NSError {
            print(error)
        }
        super.init()
        
        createParticles()
    }
    
    func createParticles(){
        var particles: [Particle] = []
        for _ in 0..<particleCount{
            let red: Float = Float(arc4random_uniform(100)) / 100
            let green: Float = Float(arc4random_uniform(100)) / 100
            let blue: Float = Float(arc4random_uniform(100)) / 100
            let particle = Particle(color: SIMD4<Float>(red, green, blue, 1),
                                    position: SIMD2<Float>(Float(arc4random_uniform(UInt32(screenWidth)) + 100),
                                                     Float(arc4random_uniform(UInt32(screenHeight))) + 10),
                                    velocity: SIMD2<Float>((Float(arc4random() %  10) - 5) + 1,
                                                     (Float(arc4random() %  10) - 5) + 1),
                                    lifespan: 100.00
            )
            particles.append(particle)
        }
        print(particles.count)
        particleBuffer = metalDevice?.makeBuffer(bytes: particles, length: MemoryLayout<Particle>.stride * particleCount, options: [])
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else { return }
        
        let commandbuffer = metalCommandQueue.makeCommandBuffer()
        let computeCommandEncoder = commandbuffer?.makeComputeCommandEncoder()
        
        computeCommandEncoder?.setComputePipelineState(clearPass)
        computeCommandEncoder?.setTexture(drawable.texture, index: 0)
        
        let w = clearPass.threadExecutionWidth
        let h = clearPass.maxTotalThreadsPerThreadgroup / w
        
        var threadsPerThreadGroup = MTLSize(width: w, height: h, depth: 1)
        var threadsPerGrid = MTLSize(width: drawable.texture.width, height: drawable.texture.height, depth: 1)
        computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        
        computeCommandEncoder?.setComputePipelineState(drawDotPass)
        computeCommandEncoder?.setBuffer(particleBuffer, offset: 0, index: 0)
        threadsPerGrid = MTLSize(width: particleCount, height: 1, depth: 1)
        threadsPerThreadGroup = MTLSize(width: w, height: 1, depth: 1)
        computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        
        computeCommandEncoder?.endEncoding()
        commandbuffer?.present(drawable)
        commandbuffer?.commit()
    }
}
