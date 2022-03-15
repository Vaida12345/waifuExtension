//
//  ModelCoordinator.swift
//  waifuExtension
//
//  Created by Vaida on 3/15/22.
//

import Foundation
import AppKit

struct ModelCoordinator {
    
    enum FileOption {
        case path(_ item: FinderItem)
        case image(_ image: NSImage)
    }
    
    /// The model used to enlarge images
    var imageModel: ImageModel
    
    enum ImageModel: String, CaseIterable {
        case caffe = "Waifu2x"
        case realcugan_ncnn_vulkan = "Real-CUGAN"
        case realesrgan_ncnn_vulkan = "Real-ESRGAN"
        case realsr_ncnn_vulkan = "RealSR"
    }
    
    var caffe: Model_Caffe = .waifu2x_anime_style_art_rgb_scale2
    var realsr_ncnn_vulkan: Model_realsr_ncnn_vulkan = Model_realsr_ncnn_vulkan()
    var realcugan_ncnn_vulkan: Model_realcugan_ncnn_vulkan = Model_realcugan_ncnn_vulkan()
    var realesrgan_ncnn_vulkan: Model_realesrgan_ncnn_vulkan = Model_realesrgan_ncnn_vulkan()
    
    /// Returns whether the model used is from Waifu2x_Caffe
    var isCaffe: Bool {
        switch self.imageModel {
        case .caffe:
            return true
        default:
            return false
        }
    }
    
    /// Number of frames inside each separate video
    var videoSegmentFrames: Int = 2000
    
    /// The model used to interpolate frames.
    var frameModel: FrameModel
    
    private var caffeScaleLevel: Int = 2
    
    var scaleLevel: Int {
        get {
            switch imageModel {
            case .caffe:
                return caffeScaleLevel
            case .realsr_ncnn_vulkan:
                return realsr_ncnn_vulkan.scaleLevel
            case .realcugan_ncnn_vulkan:
                return realcugan_ncnn_vulkan.scaleLevel
            case .realesrgan_ncnn_vulkan:
                return realesrgan_ncnn_vulkan.scaleLevel
            }
        }
        set {
            switch imageModel {
            case .caffe:
                caffeScaleLevel = newValue
            case .realsr_ncnn_vulkan:
                print("could not set")
            case .realcugan_ncnn_vulkan:
                realcugan_ncnn_vulkan.scaleLevel = newValue
            case .realesrgan_ncnn_vulkan:
                print("could not set")
            }
        }
    }
    
    enum FrameModel: String, CaseIterable {
        case dain_ncnn_vulkan = "DAIN"
        case cain_ncnn_vulkan = "CAIN"
        case rife_dain_ncnn_vulkan = "RIFE"
    }
    
    var cain_ncnn_vulkan: Model_cain_ncnn_vulkan = Model_cain_ncnn_vulkan()
    var dain_ncnn_vulkan: Model_dain_ncnn_vulkan = Model_dain_ncnn_vulkan()
    var rife_dain_ncnn_vulkan: Model_rife_dain_ncnn_vulkan = Model_rife_dain_ncnn_vulkan()
    
    var enableFrameInterpolation = false
    
    /// Determines whether interpolate frames, 2 for one time, 4 for two times.
    var frameInterpolation: Int = 2
    
    /// Determines whether `concurrentPerform` is used.
    var enableConcurrent: Bool = true
    
    init(imageModel: ImageModel, frameModel: FrameModel) {
        self.imageModel = imageModel
        self.frameModel = frameModel
    }
    
    func runImageModel(input: FileOption, outputItem: FinderItem) {
        
        func applyInstalledModel<T>(input: NSImage, model: T) where T: InstalledImageModel {
            let path = FinderItem(at: "\(NSHomeDirectory())/tmp/vulkan/input/file.png").generateOutputPath()
            input.write(to: path)
            
            model.run(inputItem: FinderItem(at: path), outputItem: outputItem)
            do {
                try FinderItem(at: path).removeFile()
            } catch { }
        }
        
        switch (input, self.imageModel) {
        case (.image(let image), .caffe):
            Waifu2x().run(image, model: self)?.write(to: outputItem.path)
        case (.path(let path), .caffe):
            Waifu2x().run(path.image!, model: self)?.write(to: outputItem.path)
            
        case (.path(let path), .realcugan_ncnn_vulkan):
            self.realcugan_ncnn_vulkan.run(inputItem: path, outputItem: outputItem)
        case (.path(let path), .realesrgan_ncnn_vulkan):
            self.realesrgan_ncnn_vulkan.run(inputItem: path, outputItem: outputItem)
        case (.path(let path), .realsr_ncnn_vulkan):
            self.realsr_ncnn_vulkan.run(inputItem: path, outputItem: outputItem)
            
        case (.image(let image), .realcugan_ncnn_vulkan):
            applyInstalledModel(input: image, model: self.realcugan_ncnn_vulkan)
        case (.image(let image), .realesrgan_ncnn_vulkan):
            applyInstalledModel(input: image, model: self.realesrgan_ncnn_vulkan)
        case (.image(let image), .realsr_ncnn_vulkan):
            applyInstalledModel(input: image, model: self.realsr_ncnn_vulkan)
        }
    }
    
    func runFrameModel(input1: FileOption, input2: FileOption, outputPath: String) {
        
    }
}
