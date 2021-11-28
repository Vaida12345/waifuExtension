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
    let model: MLModel
    let scale: Int
    let noise: Int?
    let style: String?
    
    let block_size: Int
    
    init(class: String, model: MLModel, stye: String?, scale: Int, noise: Int?) {
        self.class = `class`
        self.model = model
        self.scale = scale
        self.noise = noise
        self.block_size = scale == 1 ? 128: 142
        self.style = stye
    }
    
    static let configuration = MLModelConfiguration()
    
    static let allModels: [Waifu2xModel] = [
//        Waifu2xModel(class: "anime_style_art", model: try! anime_style_art_scale2(configuration: configuration).model, stye: "anime", scale: 2, noise: nil),
//        Waifu2xModel(class: "anime_style_art", model: try! anime_style_art_noise1_model(configuration: configuration).model, stye: "anime", scale: 1, noise: 1),
//        Waifu2xModel(class: "anime_style_art", model: try! anime_style_art_noise2_model(configuration: configuration).model, stye: "anime", scale: 1, noise: 2),
//        Waifu2xModel(class: "anime_style_art", model: try! anime_style_art_noise3_model(configuration: configuration).model, stye: "anime", scale: 1, noise: 3),
        
        Waifu2xModel(class: "anime_style_art_rgb", model: try! anime_style_art_rgb_scale2(configuration: configuration).model, stye: "anime", scale: 2, noise: nil),
        Waifu2xModel(class: "anime_style_art_rgb", model: try! anime_style_art_rgb_noise0_model(configuration: configuration).model, stye: "anime", scale: 1, noise: 0),
        Waifu2xModel(class: "anime_style_art_rgb", model: try! anime_style_art_rgb_noise1_model(configuration: configuration).model, stye: "anime", scale: 1, noise: 1),
        Waifu2xModel(class: "anime_style_art_rgb", model: try! anime_style_art_rgb_noise2_model(configuration: configuration).model, stye: "anime", scale: 1, noise: 2),
        Waifu2xModel(class: "anime_style_art_rgb", model: try! anime_style_art_rgb_noise3_model(configuration: configuration).model, stye: "anime", scale: 1, noise: 3),
        
        Waifu2xModel(class: "upconv_7_anime_style_art_rgb", model: try! upconv_7_anime_style_art_rgb_scale2(configuration: configuration).model, stye: "anime", scale: 2, noise: nil),
        Waifu2xModel(class: "upconv_7_anime_style_art_rgb", model: try! upconv_7_anime_style_art_rgb_noise0_scale2(configuration: configuration).model, stye: "anime", scale: 2, noise: 0),
        Waifu2xModel(class: "upconv_7_anime_style_art_rgb", model: try! upconv_7_anime_style_art_rgb_noise1_scale2(configuration: configuration).model, stye: "anime", scale: 2, noise: 1),
        Waifu2xModel(class: "upconv_7_anime_style_art_rgb", model: try! upconv_7_anime_style_art_rgb_noise2_scale2(configuration: configuration).model, stye: "anime", scale: 2, noise: 2),
        Waifu2xModel(class: "upconv_7_anime_style_art_rgb", model: try! upconv_7_anime_style_art_rgb_noise3_scale2(configuration: configuration).model, stye: "anime", scale: 2, noise: 3),
        
        Waifu2xModel(class: "upconv_7_photo", model: try! upconv_7_photo_scale2(configuration: configuration).model, stye: "photo", scale: 2, noise: nil),
        Waifu2xModel(class: "upconv_7_photo", model: try! upconv_7_photo_noise0_scale2(configuration: configuration).model, stye: "photo", scale: 2, noise: 0),
        Waifu2xModel(class: "upconv_7_photo", model: try! upconv_7_photo_noise1_scale2(configuration: configuration).model, stye: "photo", scale: 2, noise: 1),
        Waifu2xModel(class: "upconv_7_photo", model: try! upconv_7_photo_noise2_scale2(configuration: configuration).model, stye: "photo", scale: 2, noise: 2),
        Waifu2xModel(class: "upconv_7_photo", model: try! upconv_7_photo_noise3_scale2(configuration: configuration).model, stye: "photo", scale: 2, noise: 3),
        
        Waifu2xModel(class: "photo", model: try! photo_scale2(configuration: configuration).model, stye: "photo", scale: 2, noise: nil),
        Waifu2xModel(class: "photo", model: try! photo_noise0_model(configuration: configuration).model, stye: "photo", scale: 1, noise: 0),
        Waifu2xModel(class: "photo", model: try! photo_noise1_model(configuration: configuration).model, stye: "photo", scale: 1, noise: 1),
        Waifu2xModel(class: "photo", model: try! photo_noise2_model(configuration: configuration).model, stye: "photo", scale: 1, noise: 2),
        Waifu2xModel(class: "photo", model: try! photo_noise3_model(configuration: configuration).model, stye: "photo", scale: 1, noise: 3),
        
        Waifu2xModel(class: "ukbench", model: try! ukbench_scale2(configuration: configuration).model, stye: nil, scale: 2, noise: nil)
    ]
}

