//
//  ModelCoordinator.swift
//  waifuExtension
//
//  Created by Vaida on 3/15/22.
//

import Foundation
import AppKit
import Support
import os

public final class ModelCoordinator: DataProvider {
    
    public typealias Container = _ModelCoordinator
    
    @Published public var container: Container
    
    /// The main ``DataProvider`` to work with.
    public static var main = ModelCoordinator()
    
    public static var allInstalledImageModels: [any InstalledImageModel.Type] {
        [Model_RealSR.self, Model_RealCUGAN.self, Model_RealESRGAN.self]
    }
    
    public static var allInstalledFrameModels: [any InstalledFrameModel.Type] {
        [Model_CAIN.self, Model_DAIN.self, Model_RIFE.self]
    }
    
    public static var allInstalledModels: [any InstalledModel.Type] {
        allInstalledFrameModels + allInstalledImageModels
    }
    
    /// Load contents from disk, otherwise initialize with the default parameters.
    public init() {
        if let container = ModelCoordinator.decoded() {
            self.container = container
        } else {
            self.container = Container(imageModel: .caffe, frameModel: .cain)
            save()
        }
    }
    
}


public struct _ModelCoordinator: CustomStringConvertible, Codable, Hashable, Equatable {
    
    enum FileOption {
        case path(_ item: FinderItem)
        case image(_ image: NSImage)
    }
    
    /// The model used to enlarge images
    public var imageModel: ImageModel
    
    public enum ImageModel: String, CaseIterable, Codable, Hashable {
        case caffe = "Waifu2x"
        case realcugan = "Real-CUGAN"
        case realesrgan = "Real-ESRGAN"
        case realsr = "RealSR"
    }
    
    public var caffe: Model_Caffe = .waifu2x_anime_style_art_rgb_scale2
    public var realsr = Model_RealSR()
    public var realcugan = Model_RealCUGAN()
    public var realesrgan = Model_RealESRGAN()
    
    public var chosenImageModel: (any InstalledImageModel.Type)? {
        switch imageModel {
        case .caffe:
            return nil
        case .realcugan:
            return Model_RealCUGAN.self
        case .realesrgan:
            return Model_RealESRGAN.self
        case .realsr:
            return Model_RealESRGAN.self
        }
    }
    
    /// Returns whether the model used is from Waifu2x_Caffe
    public var isCaffe: Bool {
        switch self.imageModel {
        case .caffe:
            return true
        default:
            return false
        }
    }
    
    /// Number of frames inside each separate video
    public var videoSegmentFrames: Int = 2000
    
    /// The model used to interpolate frames.
    public var frameModel: FrameModel
    
    private var caffeScaleLevel: Int = 2
    
    public var scaleLevel: Int {
        get {
            switch imageModel {
            case .caffe:
                return caffeScaleLevel
            case .realsr:
                return realsr.scaleLevel
            case .realcugan:
                return realcugan.scaleLevel
            case .realesrgan:
                return realesrgan.scaleLevel
            }
        }
        set {
            switch imageModel {
            case .caffe:
                caffeScaleLevel = newValue
            case .realsr:
                Logger().error("could not set realsr scaleLevel")
            case .realcugan:
                realcugan.scaleLevel = newValue
            case .realesrgan:
                Logger().error("could not set realesrgan scaleLevel")
            }
        }
    }
    
    public enum FrameModel: String, CaseIterable, Codable, Hashable {
        case dain = "DAIN"
        case cain = "CAIN"
        case rife = "RIFE"
    }
    
    public var cain = Model_CAIN()
    public var dain = Model_DAIN()
    public var rife = Model_RIFE()
    
    public var chosenFrameModel: (any InstalledFrameModel.Type)? {
        switch frameModel {
        case .rife:
            return Model_RIFE.self
        case .cain:
            return Model_CAIN.self
        case .dain:
            return Model_DAIN.self
        }
    }
    
    public var enableFrameInterpolation = false
    
    /// Determines whether interpolate frames, 2 for one time, 4 for two times.
    public var frameInterpolation: Int = 1
    
    /// Determines whether `concurrentPerform` is used.
    public var enableConcurrent: Bool = true
    
    /// The return value is true iff all values are true
    public var disableTTA: Bool {
        get {
            !self.realsr.enableTTA &&
            !self.realcugan.enableTTA &&
            !self.realesrgan.enableTTA &&
            !self.rife.enableTTA
        }
        set {
            self.realsr.enableTTA     = !newValue
            self.realcugan.enableTTA  = !newValue
            self.realesrgan.enableTTA = !newValue
            self.rife.enableTTA       = !newValue
        }
    }
    
    init(imageModel: ImageModel, frameModel: FrameModel) {
        self.imageModel = imageModel
        self.frameModel = frameModel
    }
    
    public var description: String {
        "ModelCoordinate<imageModel: \(imageModel), frameModel: \(frameModel), frameSegmentFrames: \(videoSegmentFrames), scaleLevel: \(scaleLevel), enableFrameInterpolation: \(enableConcurrent), frameInterpolation: \(frameInterpolation), enableConcurrent: \(enableConcurrent)>"
    }
    
    public var enableMemoryOnly: Bool = false
    
    /// Waifu2x Excluded.
    public func runImageModel(input: FinderItem, outputItem: FinderItem, task: ShellManager) {
        switch self.imageModel {
        case .realcugan:
            self.realcugan.run(inputItem: input, outputItem: outputItem, task: task)
        case .realesrgan:
            self.realesrgan.run(inputItem: input, outputItem: outputItem, task: task)
        case .realsr:
            self.realsr.run(inputItem: input, outputItem: outputItem, task: task)
        case .caffe:
            fatalError("Unexpected, use waifu2x.run instead")
        }
    }
    
    public func runFrameModel(input1: String, input2: String, outputPath: String, task: ShellManager) {
        switch self.frameModel {
        case .cain:
            self.cain.run(input1Item: FinderItem(at: input1), input2Item: FinderItem(at: input2), outputItem: FinderItem(at: outputPath), task: task)
        case .dain:
            self.dain.run(input1Item: FinderItem(at: input1), input2Item: FinderItem(at: input2), outputItem: FinderItem(at: outputPath), task: task)
        case .rife:
            self.rife.run(input1Item: FinderItem(at: input1), input2Item: FinderItem(at: input2), outputItem: FinderItem(at: outputPath), task: task)
        }
    }
}
