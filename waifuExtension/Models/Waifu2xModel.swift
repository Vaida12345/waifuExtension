//
//  Waifu2xModel.swift
//  waifuExtension
//
//  Created by Vaida on 11/28/21.
//

import CoreML
import Foundation

struct Waifu2xModel: Equatable {
    
    let `class`: String
    let name: String
    let scale: Int
    let noise: Int?
    let style: String?
    
    let block_size: Int
    
    var model: MLModel {
        switch self.name{
        case "anime_style_art_scale2":
            return try! anime_style_art_scale2(configuration: Waifu2xModel.configuration).model
        case "anime_style_art_noise1_model":
            return try! anime_style_art_noise1_model(configuration: Waifu2xModel.configuration).model
        case "anime_style_art_noise2_model":
            return try! anime_style_art_noise2_model(configuration: Waifu2xModel.configuration).model
        case "anime_style_art_noise3_model":
            return try! anime_style_art_noise3_model(configuration: Waifu2xModel.configuration).model
            
        case "anime_style_art_rgb_scale2":
            return try! anime_style_art_rgb_scale2(configuration: Waifu2xModel.configuration).model
        case "anime_style_art_rgb_noise0_model":
            return try! anime_style_art_rgb_noise0_model(configuration: Waifu2xModel.configuration).model
        case "anime_style_art_rgb_noise1_model":
            return try! anime_style_art_rgb_noise1_model(configuration: Waifu2xModel.configuration).model
        case "anime_style_art_rgb_noise2_model":
            return try! anime_style_art_rgb_noise2_model(configuration: Waifu2xModel.configuration).model
        case "anime_style_art_rgb_noise3_model":
            return try! anime_style_art_rgb_noise3_model(configuration: Waifu2xModel.configuration).model
            
        case "upconv_7_anime_style_art_rgb_scale2":
            return try! upconv_7_anime_style_art_rgb_scale2(configuration: Waifu2xModel.configuration).model
        case "upconv_7_anime_style_art_rgb_noise0_scale2":
            return try! upconv_7_anime_style_art_rgb_noise0_scale2(configuration: Waifu2xModel.configuration).model
        case "upconv_7_anime_style_art_rgb_noise1_scale2":
            return try! upconv_7_anime_style_art_rgb_noise1_scale2(configuration: Waifu2xModel.configuration).model
        case "upconv_7_anime_style_art_rgb_noise2_scale2":
            return try! upconv_7_anime_style_art_rgb_noise2_scale2(configuration: Waifu2xModel.configuration).model
        case "upconv_7_anime_style_art_rgb_noise3_scale2":
            return try! upconv_7_anime_style_art_rgb_noise3_scale2(configuration: Waifu2xModel.configuration).model
            
        case "upconv_7_photo_scale2":
            return try! upconv_7_photo_scale2(configuration: Waifu2xModel.configuration).model
        case "upconv_7_photo_noise0_scale2":
            return try! upconv_7_photo_noise0_scale2(configuration: Waifu2xModel.configuration).model
        case "upconv_7_photo_noise1_scale2":
            return try! upconv_7_photo_noise1_scale2(configuration: Waifu2xModel.configuration).model
        case "upconv_7_photo_noise2_scale2":
            return try! upconv_7_photo_noise2_scale2(configuration: Waifu2xModel.configuration).model
        case "upconv_7_photo_noise3_scale2":
            return try! upconv_7_photo_noise3_scale2(configuration: Waifu2xModel.configuration).model
            
        case "photo_scale2":
            return try! photo_scale2(configuration: Waifu2xModel.configuration).model
        case "photo_noise0_model":
            return try! photo_noise0_model(configuration: Waifu2xModel.configuration).model
        case "photo_noise1_model":
            return try! photo_noise1_model(configuration: Waifu2xModel.configuration).model
        case "photo_noise2_model":
            return try! photo_noise2_model(configuration: Waifu2xModel.configuration).model
        case "photo_noise3_model":
            return try! photo_noise3_model(configuration: Waifu2xModel.configuration).model
            
        case "ukbench_scale2":
            return try! ukbench_scale2(configuration: Waifu2xModel.configuration).model
        
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
    
    static let configuration = { ()-> MLModelConfiguration in
        let config = MLModelConfiguration()
        config.computeUnits = .all
        return config
    }()
    
    static let allModels: [Waifu2xModel] = [
//        Waifu2xModel(class: "anime_style_art", name: "anime_style_art_scale2", stye: "anime", scale: 2, noise: nil),
//        Waifu2xModel(class: "anime_style_art", name: "anime_style_art_noise1_model", stye: "anime", scale: 1, noise: 1),
//        Waifu2xModel(class: "anime_style_art", name: "anime_style_art_noise2_model", stye: "anime", scale: 1, noise: 2),
//        Waifu2xModel(class: "anime_style_art", name: "anime_style_art_noise3_model", stye: "anime", scale: 1, noise: 3),
        
        Waifu2xModel(class: "anime_style_art_rgb", name: "anime_style_art_rgb_scale2", stye: "anime", scale: 2, noise: nil),
        Waifu2xModel(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise0_model", stye: "anime", scale: 1, noise: 0),
        Waifu2xModel(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise1_model", stye: "anime", scale: 1, noise: 1),
        Waifu2xModel(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise2_model", stye: "anime", scale: 1, noise: 2),
        Waifu2xModel(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise3_model", stye: "anime", scale: 1, noise: 3),
        
        Waifu2xModel(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_scale2", stye: "anime", scale: 2, noise: nil),
        Waifu2xModel(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise0_scale2", stye: "anime", scale: 2, noise: 0),
        Waifu2xModel(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise1_scale2", stye: "anime", scale: 2, noise: 1),
        Waifu2xModel(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise2_scale2", stye: "anime", scale: 2, noise: 2),
        Waifu2xModel(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise3_scale2", stye: "anime", scale: 2, noise: 3),
        
        Waifu2xModel(class: "upconv_7_photo", name: "upconv_7_photo_scale2", stye: "photo", scale: 2, noise: nil),
        Waifu2xModel(class: "upconv_7_photo", name: "upconv_7_photo_noise0_scale2", stye: "photo", scale: 2, noise: 0),
        Waifu2xModel(class: "upconv_7_photo", name: "upconv_7_photo_noise1_scale2", stye: "photo", scale: 2, noise: 1),
        Waifu2xModel(class: "upconv_7_photo", name: "upconv_7_photo_noise2_scale2", stye: "photo", scale: 2, noise: 2),
        Waifu2xModel(class: "upconv_7_photo", name: "upconv_7_photo_noise3_scale2", stye: "photo", scale: 2, noise: 3),
        
        Waifu2xModel(class: "photo", name: "photo_scale2", stye: "photo", scale: 2, noise: nil),
        Waifu2xModel(class: "photo", name: "photo_noise0_model", stye: "photo", scale: 1, noise: 0),
        Waifu2xModel(class: "photo", name: "photo_noise1_model", stye: "photo", scale: 1, noise: 1),
        Waifu2xModel(class: "photo", name: "photo_noise2_model", stye: "photo", scale: 1, noise: 2),
        Waifu2xModel(class: "photo", name: "photo_noise3_model", stye: "photo", scale: 1, noise: 3),
        
        Waifu2xModel(class: "ukbench", name: "ukbench_scale2", stye: nil, scale: 1, noise: nil)
    ]
    
    static let waifu2x_anime_style_art_rgb_scale2 = Waifu2xModel(class: "anime_style_art_rgb", name: "anime_style_art_rgb_scale2", stye: "anime", scale: 2, noise: nil)
    static let waifu2x_anime_style_art_rgb_noise0 = Waifu2xModel(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise0_model", stye: "anime", scale: 1, noise: 0)
    static let waifu2x_anime_style_art_rgb_noise1 = Waifu2xModel(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise1_model", stye: "anime", scale: 1, noise: 1)
    static let waifu2x_anime_style_art_rgb_noise2 = Waifu2xModel(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise2_model", stye: "anime", scale: 1, noise: 2)
    static let waifu2x_anime_style_art_rgb_noise3 = Waifu2xModel(class: "anime_style_art_rgb", name: "anime_style_art_rgb_noise3_model", stye: "anime", scale: 1, noise: 3)
    
    static let waifu2x_upconv_7_anime_style_art_rgb_scale2 = Waifu2xModel(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_scale2", stye: "anime", scale: 2, noise: nil)
    static let waifu2x_upconv_7_anime_style_art_rgb_noise0_scale2 = Waifu2xModel(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise0_scale2", stye: "anime", scale: 2, noise: 0)
    static let waifu2x_upconv_7_anime_style_art_rgb_noise1_scale2 = Waifu2xModel(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise1_scale2", stye: "anime", scale: 2, noise: 1)
    static let waifu2x_upconv_7_anime_style_art_rgb_noise2_scale2 = Waifu2xModel(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise2_scale2", stye: "anime", scale: 2, noise: 2)
    static let waifu2x_upconv_7_anime_style_art_rgb_noise3_scale2 = Waifu2xModel(class: "upconv_7_anime_style_art_rgb", name: "upconv_7_anime_style_art_rgb_noise3_scale2", stye: "anime", scale: 2, noise: 3)
    
    static let waifu2x_upconv_7_photo_scale2 = Waifu2xModel(class: "upconv_7_photo", name: "upconv_7_photo_scale2", stye: "photo", scale: 2, noise: nil)
    static let waifu2x_upconv_7_photo_noise0_scale2 = Waifu2xModel(class: "upconv_7_photo", name: "upconv_7_photo_noise0_scale2", stye: "photo", scale: 2, noise: 0)
    static let waifu2x_upconv_7_photo_noise1_scale2 = Waifu2xModel(class: "upconv_7_photo", name: "upconv_7_photo_noise1_scale2", stye: "photo", scale: 2, noise: 1)
    static let waifu2x_upconv_7_photo_noise2_scale2 = Waifu2xModel(class: "upconv_7_photo", name: "upconv_7_photo_noise2_scale2", stye: "photo", scale: 2, noise: 2)
    static let waifu2x_upconv_7_photo_noise3_scale2 = Waifu2xModel(class: "upconv_7_photo", name: "upconv_7_photo_noise3_scale2", stye: "photo", scale: 2, noise: 3)
    
    static let waifu2x_photo_scale2 = Waifu2xModel(class: "photo", name: "photo_scale2", stye: "photo", scale: 2, noise: nil)
    static let waifu2x_photo_noise0 = Waifu2xModel(class: "photo", name: "photo_noise0_model", stye: "photo", scale: 1, noise: 0)
    static let waifu2x_photo_noise1 = Waifu2xModel(class: "photo", name: "photo_noise1_model", stye: "photo", scale: 1, noise: 1)
    static let waifu2x_photo_noise2 = Waifu2xModel(class: "photo", name: "photo_noise2_model", stye: "photo", scale: 1, noise: 2)
    static let waifu2x_photo_noise3 = Waifu2xModel(class: "photo", name: "photo_noise3_model", stye: "photo", scale: 1, noise: 3)
}

