//
//  estimateSize.swift
//  waifuExtension
//
//  Created by Vaida on 12/5/21.
//

import Foundation
import CoreML
import AVFoundation
import AppKit

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

func estimateSize(finderItems: [FinderItem], frames: Int, scale: Int) -> String? {
    let scaleP = Int(scale)
    let scale = pow(2, scaleP)
    var values: [Double] = []
    let model = try! PNGImageSizeRegressor(configuration: Model_Caffe.configuration).model
    for i in finderItems.filter({ $0.avAsset != nil }) {
        guard let cgImage = i.avAsset?.firstFrame?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
        guard let output = try? model.prediction(from: EstimateSizeMLFeature(width: Double(cgImage.width * scale), height: Double(cgImage.height * scale))) else { continue }
        let size = output.featureValue(for: "Size")!.doubleValue
        let framesCount = min(Double(i.avAsset!.frameRate!) * i.avAsset!.duration.seconds, Double(frames))
        values.append(size * framesCount)
    }
    guard !values.isEmpty else { return nil }
    return Int(values.max()!).expressAsFileSize()
}

extension AVAsset {
    
    /// Returns all the frames of the video.
    ///
    /// - Attention: The return value is `nil` if the file does not exist, or `avAsset` not found.
    var firstFrame: NSImage? {
        let asset = self
        let vidLength: CMTime = asset.duration
        let seconds: Double = CMTimeGetSeconds(vidLength)
        let frameRate = Double(asset.tracks(withMediaType: .video).first!.nominalFrameRate)
        
        var requiredFramesCount = Int(seconds * frameRate)
        
        if requiredFramesCount == 0 {
            requiredFramesCount = 1
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        let time: CMTime = CMTimeMake(value: 0, timescale: vidLength.timescale)
        var imageRef: CGImage?
        do {
            imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        } catch {
            print(error)
        }
        guard let ref = imageRef else { return nil }
        let thumbnail = NSImage(cgImage: ref, size: NSSize(width: ref.width, height: ref.height))
        return thumbnail
    }
    
}
