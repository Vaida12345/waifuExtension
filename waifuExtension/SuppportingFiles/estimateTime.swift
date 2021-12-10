//
//  estimateTime.swift
//  waifuExtension
//
//  Created by Vaida on 12/6/21.
//

import Foundation
import CoreML

class EstimateTimeMLFeature: MLFeatureProvider {
    
    var width: Double
    var height: Double
    var concurrentCount: Double
    
    var featureNames: Set<String> {
        get {
            return ["Width", "Height", "ConcurrentCount"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "Width" {
            return MLFeatureValue(double: width)
        } else if featureName == "Height" {
            return MLFeatureValue(double: height)
        } else if featureName == "ConcurrentCount" {
            return MLFeatureValue(double: concurrentCount)
        }
        return nil
    }
    
    init(width: Double, height: Double, concurrentCount: Double) {
        self.width = width
        self.height = height
        self.concurrentCount = concurrentCount
    }
}
