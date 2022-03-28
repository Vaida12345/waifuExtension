//
//  Waifu2x.swift
//  Waifu2x-mac
//
//  Created by xieyi on 2018/1/24.
//  Copyright © 2018年 xieyi. All rights reserved.
//

import Foundation
import CoreML
import Cocoa
import Metal
import MetalKit

public class Waifu2x {
    
    /// The output block size.
    /// It is dependent on the model.
    /// Do not modify it until you are sure your model has a different number.
    var block_size = 128
    
    /// The difference between output and input block size
    var shrink_size = 7
    
    /// Do not exactly know its function
    /// However it can on average improve PSNR by 0.09
    /// https://github.com/nagadomi/self/commit/797b45ae23665a1c5e3c481c018e48e6f0d0e383
    let clip_eta8 = Float(0.00196)
    
    var interrupt = false
    
    private var model_pipeline: BackgroundPipeline<MLMultiArray>! = nil
    private var out_pipeline: BackgroundPipeline<MLMultiArray>! = nil
    
    var didFinishedOneBlock: (( _ total: Int)->Void)? = nil
    
    func run(_ image: NSImage!, model: ModelCoordinator, _ callback: @escaping (String) -> Void = { _ in }) -> NSImage? {
        guard image != nil else {
            return nil
        }
        
        let fullDate = Date()
        var MyLogger = MyLogger(path: "\(Configuration.main.saveFolder)/logs/log.txt")
        
        self.interrupt = false
        self.block_size = model.caffe.block_size
        let out_scale = model.caffe.scale
        
        let width = Int(image.representations[0].pixelsWide)
        let height = Int(image.representations[0].pixelsHigh)
        var fullWidth = width
        var fullHeight = height
        guard let cgimg = image.representations[0].cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Failed to get CGImage")
            return nil
        }
        var fullCG = cgimg
        
        // If image is too small, expand it
        if width < block_size || height < block_size {
            if width < block_size {
                fullWidth = block_size
            }
            if height < block_size {
                fullHeight = block_size
            }
            var bitmapInfo = cgimg.bitmapInfo.rawValue
            if bitmapInfo & CGBitmapInfo.alphaInfoMask.rawValue == CGImageAlphaInfo.first.rawValue {
                bitmapInfo = bitmapInfo & ~CGBitmapInfo.alphaInfoMask.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
            } else if bitmapInfo & CGBitmapInfo.alphaInfoMask.rawValue == CGImageAlphaInfo.last.rawValue {
                bitmapInfo = bitmapInfo & ~CGBitmapInfo.alphaInfoMask.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            }
            let context = CGContext(data: nil, width: fullWidth, height: fullHeight, bitsPerComponent: cgimg.bitsPerComponent, bytesPerRow: cgimg.bytesPerRow / width * fullWidth, space: cgimg.colorSpace ?? CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo)
            var y = fullHeight - height
            if y < 0 {
                y = 0
            }
            context?.draw(cgimg, in: CGRect(x: 0, y: y, width: width, height: height))
            guard let contextCG = context?.makeImage() else {
                return nil
            }
            fullCG = contextCG
        }
        
        var hasalpha = cgimg.alphaInfo != CGImageAlphaInfo.none
        var channels = 3
        var alpha: [UInt8]! = nil
        
        if hasalpha {
            alpha = image.alpha()
            var ralpha = false
            // Check if it really has alpha
            var aIndex = 0
            
            while aIndex < alpha.count {
                let a = alpha[aIndex]
                if a < 255 {
                    ralpha = true
                    break
                }
                
                aIndex += 1
            }
            
            if ralpha {
                channels = 4
            } else {
                hasalpha = false
            }
        }
        
        let out_width = width * out_scale
        let out_height = height * out_scale
        let out_fullWidth = fullWidth * out_scale
        let out_fullHeight = fullHeight * out_scale
        let out_block_size = self.block_size * out_scale
        let rects = fullCG.getCropRects(from: self)
        // Prepare for output pipeline
        // Merge arrays into one array
        let normalize = { (input: Double) -> Double in
            let output = input * 255
            if output > 255 {
                return 255
            }
            if output < 0 {
                return 0
            }
            return output
        }
        
        let bufferSize = out_block_size * out_block_size * 3
        let imgData = UnsafeMutablePointer<UInt8>.allocate(capacity: out_width * out_height * channels)
        defer {
            imgData.deallocate()
        }
        
        // Alpha channel support
        var alpha_task: BackgroundTask? = nil
        if hasalpha {
            alpha_task = BackgroundTask("alpha") {
                if out_scale > 1 {
                    var outalpha: [UInt8]? = nil
                    if let metalBicubic = try? MetalBicubic() {
                        NSLog("Maximum texture size supported: %d", metalBicubic.maxTextureSize())
                        if out_width <= metalBicubic.maxTextureSize() && out_height <= metalBicubic.maxTextureSize() {
                            outalpha = metalBicubic.resizeSingle(alpha, width, height, Float(out_scale))
                        }
                    }
                    var emptyAlpha = true
                    for item in outalpha ?? [] {
                        if item > 0 {
                            emptyAlpha = false
                            break
                        }
                    }
                    if outalpha != nil && !emptyAlpha {
                        alpha = outalpha!
                    } else {
                        // Fallback to CPU scale
                        let bicubic = Bicubic(image: alpha, channels: 1, width: width, height: height)
                        alpha = bicubic.resize(scale: Float(out_scale))
                    }
                }
                
                var y = 0
                
                while y < out_height {
                    var x = 0
                    
                    while x < out_width {
                        imgData[(y * out_width + x) * channels + 3] = alpha[y * out_width + x]
                        
                        x += 1
                    }
                    
                    y += 1
                }
                
                
            }
        }
        
        MyLogger?.addItem(["initial date:", fullDate.distance(to: Date()).description])
        let preparePipeDate = Date()
        
        // Output, takes no time
        self.out_pipeline = BackgroundPipeline<MLMultiArray>("out_pipeline", count: rects.count, waifu2x: self) { (index, array) in
            let rect = rects[index]
            let origin_x = Int(rect.origin.x) * out_scale
            let origin_y = Int(rect.origin.y) * out_scale
            let dataPointer = UnsafeMutableBufferPointer(start: array.dataPointer.assumingMemoryBound(to: Double.self),
                                                         count: bufferSize)
            var dest_x: Int
            var dest_y: Int
            var src_index: Int
            var dest_index: Int
            
            var channel = 0
            while channel < 3 {
                var src_y = 0
                while src_y < out_block_size {
                    var src_x = 0
                    while src_x < out_block_size {
                        dest_x = origin_x + src_x
                        dest_y = origin_y + src_y
                        if dest_x >= out_fullWidth || dest_y >= out_fullHeight {
                            continue
                        }
                        src_index = src_y * out_block_size + src_x + out_block_size * out_block_size * channel
                        dest_index = (dest_y * out_width + dest_x) * channels + channel
                        imgData[dest_index] = UInt8(normalize(dataPointer[src_index]))
                        
                        src_x += 1
                    }
                    
                    src_y += 1
                }
                
                channel += 1
            }
        }
        
        MyLogger?.addItem(["prepare:", preparePipeDate.distance(to: Date()).description])
        var mlArray: [MLMultiArray] = []
        
        // Start running model
        let expendImageDate = Date()
        var expwidth = fullWidth + 2 * self.shrink_size
        var expheight = fullHeight + 2 * self.shrink_size
        let expanded = fullCG.expand(withAlpha: hasalpha, in: self)
        callback("processing")
        MyLogger?.addItem(["expendImage:", expendImageDate.distance(to: Date()).description])
        
        let in_pipeDate = Date()
        
        if MTLCreateSystemDefaultDevice() != nil {
            // calculation with GPU
            
            var arrayLengthFull = 3 * (self.block_size + 2 * self.shrink_size) * (self.block_size + 2 * self.shrink_size)
            let arrayLength = (self.block_size + 2 * self.shrink_size)
            
            let device = MTLCreateSystemDefaultDevice()!
            let library = try! device.makeDefaultLibrary(bundle: Bundle(for: type(of: self)))
            
            let constants = MTLFunctionConstantValues()
            constants.setConstantValue(&self.block_size, type: MTLDataType.int, index: 0)
            constants.setConstantValue(&self.shrink_size, type: MTLDataType.int, index: 1)
            constants.setConstantValue(&expwidth, type: MTLDataType.int, index: 2)
            constants.setConstantValue(&expheight, type: MTLDataType.int, index: 3)
            constants.setConstantValue(&arrayLengthFull, type: MTLDataType.int, index: 4)
            
            let calculationFunction = try! library.makeFunction(name: "Calculation", constantValues: constants)
            let pipelineState = try! device.makeComputePipelineState(function: calculationFunction)
            let commandQueue = device.makeCommandQueue()!
            
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
            
            let expandedBuffer = device.makeBuffer(bytes: expanded, length: expanded.count * MemoryLayout<Float>.size, options: .storageModeShared)!
            let resultBuffer = device.makeBuffer(length: arrayLengthFull * rects.count * MemoryLayout<Float>.size, options: .storageModeShared)!
            let xArrayBuffer = device.makeBuffer(bytes: rects.map({ Float($0.origin.x) }), length: rects.count * MemoryLayout<Float>.size, options: .storageModeShared)!
            let yArrayBuffer = device.makeBuffer(bytes: rects.map({ Float($0.origin.y) }), length: rects.count * MemoryLayout<Float>.size, options: .storageModeShared)!
            
            commandEncoder.setComputePipelineState(pipelineState)
            commandEncoder.setBuffer(expandedBuffer, offset: 0, index: 0)
            commandEncoder.setBuffer(xArrayBuffer, offset: 0, index: 1)
            commandEncoder.setBuffer(yArrayBuffer, offset: 0, index: 2)
            commandEncoder.setBuffer(resultBuffer, offset: 0, index: 3)
            
            let gridSize = MTLSizeMake(arrayLength, arrayLength, rects.count)
            
            var threadGroupSize = pipelineState.maxTotalThreadsPerThreadgroup
            if threadGroupSize > arrayLengthFull * rects.count {
                threadGroupSize = arrayLengthFull * rects.count
            }
            
            let threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1)
            commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
            commandEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            let rawPointer = resultBuffer.contents()
            let shape = [rects.count, 3, Int(self.block_size + 2 * self.shrink_size), Int(self.block_size + 2 * self.shrink_size)]
            let shapedArray = MLShapedArray<Float>(bytesNoCopy: rawPointer, shape: shape, deallocator: .none)
            
            mlArray = shapedArray.map({ MLMultiArray($0) })
            
            if let didFinishedOneBlock = self.didFinishedOneBlock {
                didFinishedOneBlock(2)
            }
            
        } else {
            // calculate with CPU
            var in_pipeResults: [(index: Int, value: MLMultiArray)] = []
            
            DispatchQueue.concurrentPerform(iterations: rects.count) { index in
                let rect = rects[index]
                
                let x = Int(rect.origin.x)
                let y = Int(rect.origin.y)
                let multi = try! MLMultiArray(shape: [3, NSNumber(value: self.block_size + 2 * self.shrink_size), NSNumber(value: self.block_size + 2 * self.shrink_size)], dataType: .float32)
                
                var y_exp = y
                
                while y_exp < (y + self.block_size + 2 * self.shrink_size) {
                    
                    var x_exp = x
                    while x_exp < (x + self.block_size + 2 * self.shrink_size) {
                        let x_new = x_exp - x
                        let y_new = y_exp - y
                        multi[y_new * (self.block_size + 2 * self.shrink_size) + x_new] = NSNumber(value: expanded[y_exp * expwidth + x_exp])
                        multi[y_new * (self.block_size + 2 * self.shrink_size) + x_new + (self.block_size + 2 * self.shrink_size) * (self.self.block_size + 2 * self.shrink_size)] = NSNumber(value: expanded[y_exp * expwidth + x_exp + expwidth * expheight])
                        multi[y_new * (self.block_size + 2 * self.shrink_size) + x_new + (self.block_size + 2 * self.shrink_size) * (self.block_size + 2 * self.shrink_size) * 2] = NSNumber(value: expanded[y_exp * expwidth + x_exp + expwidth * expheight * 2])
                        
                        x_exp += 1
                    }
                    
                    y_exp += 1
                }
                
                in_pipeResults.append((index, multi))
                
                if let didFinishedOneBlock = self.didFinishedOneBlock {
                    didFinishedOneBlock(rects.count * 2)
                }
            }
            
            mlArray = in_pipeResults.sorted(by: { $0.index < $1.index }).map({ $0.value })
        }
        
        MyLogger?.addItem(["In Pipe:", in_pipeDate.distance(to: Date()).description])
        
        let model_pipelineDate = Date()
        
        // Prepare for model pipeline
        // Run prediction on each block
        let mlmodel = model.caffe.model
        var index = 0
        while index < rects.count {
            let array = mlArray[index]
            
            self.out_pipeline.appendObject(try! mlmodel.prediction(input: array))
            if let didFinishedOneBlock = self.didFinishedOneBlock {
                didFinishedOneBlock(2 * rects.count)
            }
            
            index += 1
        }
        
        MyLogger?.addItem("ML:", model_pipelineDate.distance(to: Date()).description)
        
        let out_pipelineDate = Date()
        callback("wait_alpha")
        alpha_task?.wait()
        self.out_pipeline.wait()
        MyLogger?.addItem("outpipe:", out_pipelineDate.distance(to: Date()).description)
        
        self.model_pipeline = nil
        self.out_pipeline = nil
        if self.interrupt {
            return nil
        }
        
        callback("generate_output")
        let generateImageDate = Date()
        let cfbuffer = CFDataCreate(nil, imgData, out_width * out_height * channels)!
        let dataProvider = CGDataProvider(data: cfbuffer)!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
        if hasalpha {
            bitmapInfo |= CGImageAlphaInfo.last.rawValue
        }
        let cgImage = CGImage(width: out_width, height: out_height, bitsPerComponent: 8, bitsPerPixel: 8 * channels, bytesPerRow: out_width * channels, space: colorSpace, bitmapInfo: CGBitmapInfo.init(rawValue: bitmapInfo), provider: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        let outImage = NSImage(cgImage: cgImage!, size: CGSize(width: out_width, height: out_height))
        callback("finished")
        MyLogger?.addItem("generateImage:", generateImageDate.distance(to: Date()).description)
        
        MyLogger?.addItem("waifu2x finished with time:", fullDate.distance(to: Date()).description)
        if Configuration.main.isLogEnabled { MyLogger?.log() }
        
        return outImage
    }
    
}

struct MyLogger {
    
    let path: String
    
    var items: [[String]] = []
    
    init?(path: String) {
        guard Configuration.main.isLogEnabled else { return nil }
        var item = FinderItem(at: path)
        item.generateOutputPath()
        self.path = item.path
    }
    
    mutating func addItem<T>(_ item: [T]) where T: CustomStringConvertible {
        items.append(item.map({ $0.description }))
    }
    
    mutating func addItem<T>(_ item: T...) where T: CustomStringConvertible {
        items.append(item.map({ $0.description }))
    }
    
    func log() {
        let value = printMatrix(matrix: items)
        try! value.write(toFile: path, atomically: true, encoding: .utf8)
    }
}
