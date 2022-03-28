//
//  ModelCoordinator.swift
//  waifuExtension
//
//  Created by Vaida on 3/15/22.
//

import Foundation
import AppKit

struct ModelCoordinator: Identifiable, CustomStringConvertible {
    
    var id: UUID
    
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
    var rife_dain_ncnn_vulkan: Model_rife_ncnn_vulkan = Model_rife_ncnn_vulkan()
    
    var enableFrameInterpolation = false
    
    /// Determines whether interpolate frames, 2 for one time, 4 for two times.
    var frameInterpolation: Int = 1
    
    /// Determines whether `concurrentPerform` is used.
    var enableConcurrent: Bool = true
    
    init(imageModel: ImageModel, frameModel: FrameModel) {
        self.imageModel = imageModel
        self.frameModel = frameModel
        self.id = UUID()
    }
    
    var description: String {
        "ModelCoordinate<imageModel: \(imageModel), frameModel: \(frameModel), frameSegmentFrames: \(videoSegmentFrames), scaleLevel: \(scaleLevel), enableFrameInterpolation: \(enableConcurrent), frameInterpolation: \(frameInterpolation), enableConcurrent: \(enableConcurrent)>"
    }
    
    var enableMemoryOnly: Bool = false
    
    /// Waifu2x Excluded.
    func runImageModel(input: FinderItem, outputItem: FinderItem, task: ShellManager) {
        switch self.imageModel {
        case .realcugan_ncnn_vulkan:
            self.realcugan_ncnn_vulkan.run(inputItem: input, outputItem: outputItem, task: task)
        case .realesrgan_ncnn_vulkan:
            self.realesrgan_ncnn_vulkan.run(inputItem: input, outputItem: outputItem, task: task)
        case .realsr_ncnn_vulkan:
            self.realsr_ncnn_vulkan.run(inputItem: input, outputItem: outputItem, task: task)
        case .caffe:
            fatalError("Unexpected, use waifu2x.run instead")
        }
    }
    
    func runFrameModel(input1: String, input2: String, outputPath: String, task: ShellManager) {
        switch self.frameModel {
        case .cain_ncnn_vulkan:
            self.cain_ncnn_vulkan.run(input1Item: FinderItem(at: input1), input2Item: FinderItem(at: input2), outputItem: FinderItem(at: outputPath), task: task)
        case .dain_ncnn_vulkan:
            self.dain_ncnn_vulkan.run(input1Item: FinderItem(at: input1), input2Item: FinderItem(at: input2), outputItem: FinderItem(at: outputPath), task: task)
        case .rife_dain_ncnn_vulkan:
            self.rife_dain_ncnn_vulkan.run(input1Item: FinderItem(at: input1), input2Item: FinderItem(at: input2), outputItem: FinderItem(at: outputPath), task: task)
        }
    }
}
