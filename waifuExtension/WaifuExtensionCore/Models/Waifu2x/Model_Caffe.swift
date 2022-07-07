//
//  Model_Caffe.swift
//  waifuExtension
//
//  Created by Vaida on 11/28/21.
//

import CoreML
import Foundation

public struct Model_Caffe: Equatable, Codable, Hashable {
    
    public let `class`: String
    public let name: String
    public let scale: Int
    public let noise: Int?
    public let style: String?
    
    public let block_size: Int
    
    public var model: MLModel {
        switch self.name{
        case "anime_style_art_scale2":
            return try! anime_style_art_scale2(configuration: Model_Caffe.configuration).model
        case "anime_style_art_noise1_model":
            return try! anime_style_art_noise1_model(configuration: Model_Caffe.configuration).model
        case "anime_style_art_noise2_model":
            return try! anime_style_art_noise2_model(configuration: Model_Caffe.configuration).model
        case "anime_style_art_noise3_model":
            return try! anime_style_art_noise3_model(configuration: Model_Caffe.configuration).model
            
        case "anime_style_art_rgb_scale2":
            return try! anime_style_art_rgb_scale2(configuration: Model_Caffe.configuration).model
        case "anime_style_art_rgb_noise0_model":
            return try! anime_style_art_rgb_noise0_model(configuration: Model_Caffe.configuration).model
        case "anime_style_art_rgb_noise1_model":
            return try! anime_style_art_rgb_noise1_model(configuration: Model_Caffe.configuration).model
        case "anime_style_art_rgb_noise2_model":
            return try! anime_style_art_rgb_noise2_model(configuration: Model_Caffe.configuration).model
        case "anime_style_art_rgb_noise3_model":
            return try! anime_style_art_rgb_noise3_model(configuration: Model_Caffe.configuration).model
            
        case "upconv_7_anime_style_art_rgb_scale2":
            return try! upconv_7_anime_style_art_rgb_scale2(configuration: Model_Caffe.configuration).model
        case "upconv_7_anime_style_art_rgb_noise0_scale2":
            return try! upconv_7_anime_style_art_rgb_noise0_scale2(configuration: Model_Caffe.configuration).model
        case "upconv_7_anime_style_art_rgb_noise1_scale2":
            return try! upconv_7_anime_style_art_rgb_noise1_scale2(configuration: Model_Caffe.configuration).model
        case "upconv_7_anime_style_art_rgb_noise2_scale2":
            return try! upconv_7_anime_style_art_rgb_noise2_scale2(configuration: Model_Caffe.configuration).model
        case "upconv_7_anime_style_art_rgb_noise3_scale2":
            return try! upconv_7_anime_style_art_rgb_noise3_scale2(configuration: Model_Caffe.configuration).model
            
        case "upconv_7_photo_scale2":
            return try! upconv_7_photo_scale2(configuration: Model_Caffe.configuration).model
        case "upconv_7_photo_noise0_scale2":
            return try! upconv_7_photo_noise0_scale2(configuration: Model_Caffe.configuration).model
        case "upconv_7_photo_noise1_scale2":
            return try! upconv_7_photo_noise1_scale2(configuration: Model_Caffe.configuration).model
        case "upconv_7_photo_noise2_scale2":
            return try! upconv_7_photo_noise2_scale2(configuration: Model_Caffe.configuration).model
        case "upconv_7_photo_noise3_scale2":
            return try! upconv_7_photo_noise3_scale2(configuration: Model_Caffe.configuration).model
            
        case "photo_scale2":
            return try! photo_scale2(configuration: Model_Caffe.configuration).model
        case "photo_noise0_model":
            return try! photo_noise0_model(configuration: Model_Caffe.configuration).model
        case "photo_noise1_model":
            return try! photo_noise1_model(configuration: Model_Caffe.configuration).model
        case "photo_noise2_model":
            return try! photo_noise2_model(configuration: Model_Caffe.configuration).model
        case "photo_noise3_model":
            return try! photo_noise3_model(configuration: Model_Caffe.configuration).model
            
        case "ukbench_scale2":
            return try! ukbench_scale2(configuration: Model_Caffe.configuration).model
        
        default:
            fatalError("Unexpected")
        }
    }
    
    init(class: String, name: String, stye: String?, scale: Int, noise: Int?) {
        self.class = `class`
        self.name = name
        self.scale = scale
        self.noise = noise
        self.block_size = { ()-> Int in
            return scale == 1 ? 128: 142
        }()
        self.style = stye
    }
    
    static let configuration = MLModelConfiguration()
    
    public static let allModels: [Model_Caffe] = [
//        Model_Caffe(class: "anime_style_art", name: "anime_style_art_scale2", stye: "anime", scale: 2, noise: nil),
//        Model_Caffe(class: "anime_style_art", name: "anime_style_art_noise1_model", stye: "anime", scale: 1, noise: 1),
//        Model_Caffe(class: "anime_style_art", name: "anime_style_art_noise2_model", stye: "anime", scale: 1, noise: 2),
//        Model_Caffe(class: "anime_style_art", name: "anime_style_art_noise3_model", stye: "anime", scale: 1, noise: 3),
        
        Model_Caffe(class: "anime_style_art_rgb", name: "anime_style_art_rgb_scale2", stye: "anime", scale: 2, noise: nil),
        Model_Caffe(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise0_model", stye: "anime", scale: 1, noise: 0),
        Model_Caffe(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise1_model", stye: "anime", scale: 1, noise: 1),
        Model_Caffe(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise2_model", stye: "anime", scale: 1, noise: 2),
        Model_Caffe(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise3_model", stye: "anime", scale: 1, noise: 3),
        
        Model_Caffe(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_scale2", stye: "anime", scale: 2, noise: nil),
        Model_Caffe(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise0_scale2", stye: "anime", scale: 2, noise: 0),
        Model_Caffe(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise1_scale2", stye: "anime", scale: 2, noise: 1),
        Model_Caffe(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise2_scale2", stye: "anime", scale: 2, noise: 2),
        Model_Caffe(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise3_scale2", stye: "anime", scale: 2, noise: 3),
        
        Model_Caffe(class: "upconv_7_photo", name: "upconv_7_photo_scale2", stye: "photo", scale: 2, noise: nil),
        Model_Caffe(class: "upconv_7_photo", name: "upconv_7_photo_noise0_scale2", stye: "photo", scale: 2, noise: 0),
        Model_Caffe(class: "upconv_7_photo", name: "upconv_7_photo_noise1_scale2", stye: "photo", scale: 2, noise: 1),
        Model_Caffe(class: "upconv_7_photo", name: "upconv_7_photo_noise2_scale2", stye: "photo", scale: 2, noise: 2),
        Model_Caffe(class: "upconv_7_photo", name: "upconv_7_photo_noise3_scale2", stye: "photo", scale: 2, noise: 3),
        
        Model_Caffe(class: "photo", name: "photo_scale2", stye: "photo", scale: 2, noise: nil),
        Model_Caffe(class: "photo", name: "photo_noise0_model", stye: "photo", scale: 1, noise: 0),
        Model_Caffe(class: "photo", name: "photo_noise1_model", stye: "photo", scale: 1, noise: 1),
        Model_Caffe(class: "photo", name: "photo_noise2_model", stye: "photo", scale: 1, noise: 2),
        Model_Caffe(class: "photo", name: "photo_noise3_model", stye: "photo", scale: 1, noise: 3),
        
        Model_Caffe(class: "ukbench", name: "ukbench_scale2", stye: nil, scale: 1, noise: nil),
    ]
    
    public static let waifu2x_anime_style_art_rgb_scale2 = Model_Caffe(class: "anime_style_art_rgb", name: "anime_style_art_rgb_scale2", stye: "anime", scale: 2, noise: nil)
    public static let waifu2x_anime_style_art_rgb_noise0 = Model_Caffe(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise0_model", stye: "anime", scale: 1, noise: 0)
    public static let waifu2x_anime_style_art_rgb_noise1 = Model_Caffe(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise1_model", stye: "anime", scale: 1, noise: 1)
    public static let waifu2x_anime_style_art_rgb_noise2 = Model_Caffe(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise2_model", stye: "anime", scale: 1, noise: 2)
    public static let waifu2x_anime_style_art_rgb_noise3 = Model_Caffe(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise3_model", stye: "anime", scale: 1, noise: 3)
    
    public static let waifu2x_upconv_7_anime_style_art_rgb_scale2 = Model_Caffe(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_scale2", stye: "anime", scale: 2, noise: nil)
    public static let waifu2x_upconv_7_anime_style_art_rgb_noise0_scale2 = Model_Caffe(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise0_scale2", stye: "anime", scale: 2, noise: 0)
    public static let waifu2x_upconv_7_anime_style_art_rgb_noise1_scale2 = Model_Caffe(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise1_scale2", stye: "anime", scale: 2, noise: 1)
    public static let waifu2x_upconv_7_anime_style_art_rgb_noise2_scale2 = Model_Caffe(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise2_scale2", stye: "anime", scale: 2, noise: 2)
    public static let waifu2x_upconv_7_anime_style_art_rgb_noise3_scale2 = Model_Caffe(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise3_scale2", stye: "anime", scale: 2, noise: 3)
    
    public static let waifu2x_upconv_7_photo_scale2 = Model_Caffe(class: "upconv_7_photo", name: "upconv_7_photo_scale2", stye: "photo", scale: 2, noise: nil)
    public static let waifu2x_upconv_7_photo_noise0_scale2 = Model_Caffe(class: "upconv_7_photo", name: "upconv_7_photo_noise0_scale2", stye: "photo", scale: 2, noise: 0)
    public static let waifu2x_upconv_7_photo_noise1_scale2 = Model_Caffe(class: "upconv_7_photo", name: "upconv_7_photo_noise1_scale2", stye: "photo", scale: 2, noise: 1)
    public static let waifu2x_upconv_7_photo_noise2_scale2 = Model_Caffe(class: "upconv_7_photo", name: "upconv_7_photo_noise2_scale2", stye: "photo", scale: 2, noise: 2)
    public static let waifu2x_upconv_7_photo_noise3_scale2 = Model_Caffe(class: "upconv_7_photo", name: "upconv_7_photo_noise3_scale2", stye: "photo", scale: 2, noise: 3)
    
    public static let waifu2x_photo_scale2 = Model_Caffe(class: "photo", name: "photo_scale2", stye: "photo", scale: 2, noise: nil)
    public static let waifu2x_photo_noise0 = Model_Caffe(class: "photo", name: "photo_noise0_model", stye: "photo", scale: 1, noise: 0)
    public static let waifu2x_photo_noise1 = Model_Caffe(class: "photo", name: "photo_noise1_model", stye: "photo", scale: 1, noise: 1)
    public static let waifu2x_photo_noise2 = Model_Caffe(class: "photo", name: "photo_noise2_model", stye: "photo", scale: 1, noise: 2)
    public static let waifu2x_photo_noise3 = Model_Caffe(class: "photo", name: "photo_noise3_model", stye: "photo", scale: 1, noise: 3)
    
}

