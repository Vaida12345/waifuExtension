//
//  estimateSize.swift
//  waifuExtension
//
//  Created by Vaida on 12/5/21.
//

import Foundation
import CoreML

class EstimateSizeMLFeature: MLFeatureProvider {
    
    var width: Double
    var height: Double
    
    var featureNames: Set<String> {
        get {
            return ["Width", "Height"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "Width" {
            return MLFeatureValue(double: width)
        } else if featureName == "Height" {
            return MLFeatureValue(double: height)
        }
        return nil
    }
    
    init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

func estimateSize(finderItems: [FinderItem], frames: Int, scale: String) -> String? {
    guard let scaleP = Int(scale) else { return nil }
    let scale = pow(2, scaleP)
    var values: [Double] = []
    let model = try! PNGImageSizeRegressor(configuration: Waifu2xModel.configuration).model
    for i in finderItems.filter({ $0.avAsset != nil }) {
        let cgImage = i.firstFrame!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let output = try! model.prediction(from: EstimateSizeMLFeature(width: Double(cgImage.width * scale), height: Double(cgImage.height * scale)))
        let size = output.featureValue(for: "Size")!.doubleValue
        let framesCount = min(Double(i.frameRate!) * i.avAsset!.duration.seconds, Double(frames))
        values.append(size * framesCount)
    }
    guard !values.isEmpty else { return nil }
    return (values.max()!).expressAsFileSize()
}
