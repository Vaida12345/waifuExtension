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

@dynamicMemberLookup final public class ModelCoordinator: DataProvider {
    
    @Published public var content = _ModelCoordinator(imageModel: .caffe, frameModel: .cain)
    
    public static var main: ModelCoordinator = .decode(from: .preferencesDirectory.with(subPath: "model coordinator.json"))
    
    public static var allInstalledImageModels: [any InstalledImageModel.Type] {
        [Model_RealSR.self, Model_RealCUGAN.self, Model_RealESRGAN.self]
    }
    
    public static var allInstalledFrameModels: [any InstalledFrameModel.Type] {
        [Model_CAIN.self, Model_DAIN.self, Model_RIFE.self]
    }
    
    public static var allInstalledModels: [any InstalledModel.Type] {
        allInstalledFrameModels + allInstalledImageModels
    }
    
    public init() { }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(content)
    }
    
    public static func == (lhs: ModelCoordinator, rhs: ModelCoordinator) -> Bool {
        lhs.content == rhs.content
    }
    
    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<_ModelCoordinator, Subject>) -> Subject {
        get { content[keyPath: keyPath] }
        set { content[keyPath: keyPath] = newValue }
    }
    
    public subscript<Subject>(dynamicMember keyPath: KeyPath<_ModelCoordinator, Subject>) -> Subject {
        content[keyPath: keyPath]
    }
    
    //MARK: - Codable
    
    enum CodingKeys: CodingKey {
        case content
    }
    
    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<ModelCoordinator.CodingKeys> = try decoder.container(keyedBy: ModelCoordinator.CodingKeys.self)
        
        self.content = try container.decode(_ModelCoordinator.self, forKey: ModelCoordinator.CodingKeys.content)
        
    }
    
    final public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<ModelCoordinator.CodingKeys> = encoder.container(keyedBy: ModelCoordinator.CodingKeys.self)
        
        try container.encode(self.content, forKey: ModelCoordinator.CodingKeys.content)
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
                Logger().error("could not set")
            case .realcugan:
                realcugan.scaleLevel = newValue
            case .realesrgan:
                Logger().error("could not set")
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
    
    public var enableFrameInterpolation = false
    
    /// Determines whether interpolate frames, 2 for one time, 4 for two times.
    public var frameInterpolation: Int = 1
    
    /// Determines whether `concurrentPerform` is used.
    public var enableConcurrent: Bool = true
    
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
