//
//  MachineLearning.swift
//  
//
//  Created by Vaida on 10/12/21.
//  Copyright © 2021 Vaida. All rights reserved.
//
/*
import Foundation
import Cocoa
import CoreML
import NaturalLanguage
import Vision


struct NLCreator: Codable {
    
    let tokens: [String]
    
    let labels: [String]
    
    static var data: [NLCreator] = []
    
    static func createFile() {
        try! FinderItem.saveJSON(NLCreator.data, to: "/Users/vaida/Desktop/NLData.json")
    }
    
    static func createTokens(from text: String, separator: [String]? = nil, labels: [String]? = nil) {
        let tokens: [String]
        
        if let separator = separator {
            tokens = text.split(whereSeparator: { separator.contains(String($0)) }).map({ String($0) }).filter({ $0 != " " })
        } else {
            tokens = [text]
        }
        
        if let labels = labels {
            NLCreator.data.append(NLCreator(tokens: tokens, labels: labels))
        } else {
            print("""
            NLCreator.data.append(NLCreator(tokens: \(tokens),
                                             labels: [<#String#>]))
            """)
        }
    }
}


//MARK: - Supporting Functions

extension String {
    
    /// Identifies the part of speech of each word.
    ///
    /// **Example**
    ///
    ///     print("This is true".partOfSpeech)
    ///     ["This": "Determiner", "true": "Adjective", "is": "Verb"]
    var partOfSpeech: [String: String] {
        var content: [String: String] = [:]
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = self
        let options: NLTagger.Options = [.omitWhitespace, .omitWhitespace]
        tagger.enumerateTags(in: self.startIndex..<self.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag {
                content[String(self[tokenRange])] = tag.rawValue
            }
            return true
        }
        return content
    }
}

/// Returns the ML result by applying a ML model to an image.
///
/// **Example**
///
///     applyML(to: NSImage(), model: Normal_Image_Classifier_2().model)
///
/// - Important: The class would be returned only if the confidence is greater than the threshold.
///
/// - Note: By default, the threshold, ie. confidence, was set to 0.8.
///
/// - Attention: The return value is `nil` if the size of `image` is `zero`, the `MLModel` is invalid, or no item reaches the threshold.
///
/// - Parameters:
///     - confidence: The threshold.
///     - model: The ML Classifier model.
///     - image: The image on which performs the ML.
///
/// - Returns: The class of the image; `nil` otherwise.
func applyML(to image: NSImage, model: MLModel, confidence: Float = 0.8) -> String? {
    guard image.size != NSSize.zero else { print("skip \(image)"); return nil }
    guard let image = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { print("skip \(image)"); return nil }
    
    let orientation = CGImagePropertyOrientation.up
    let handler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
    
    let model = try! VNCoreMLModel(for: model)
    let request = VNCoreMLRequest(model: model)
    try! handler.perform([request])
    
    guard let results = request.results else { print("skip \(image): can not form request from current model"); return nil }
    let classifications = results as! [VNClassificationObservation]
    guard !classifications.isEmpty else { print("skip \(image): the classification array of \(classifications) is empty"); return nil }
    
    let topClassifications = classifications.prefix(2)
    let descriptions = topClassifications.map { classification -> String? in
        guard classification.confidence > confidence else { return nil }
        return "\(classification.identifier)"
    }
    return descriptions.first!
}

/// Finds the texts in an `image` with `Vision`.
///
/// - Attention: The return value is `nil` if there is no `cgImage` behind the `image` or the ML failed to generate any results.
///
/// - Parameters:
///     - languages: The languages to be recognized, use ISO language code, such as "zh-Hans", "en".
///     - languageCorrection: A boolean indicating whether `NL` would be used to improve results.
///     - image: The image to be extracted text from.
///
/// - Returns: The texts in the image; `nil` otherwise.
func findText(in image: NSImage, languages: [String]? = nil, languageCorrection: Bool = true) -> [String]? {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { print("failed findText(in: \(image): no cgImage behind the given image!");  return nil }
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    let request = VNRecognizeTextRequest()
    
    request.recognitionLevel = .accurate
    request.recognitionLanguages = languages ?? ["en"]
    request.usesLanguageCorrection = languageCorrection
    try! handler.perform([request])
    
    guard let results = request.results else { print("failed findText(in: \(image): can not form results"); return nil }
    guard let observations = results as? [VNRecognizedTextObservation] else { return nil }
    let recognizedStrings = observations.compactMap { observation in
        // Return the string of the top VNRecognizedText instance.
        return observation.topCandidates(1).first?.string
    }
    
    return recognizedStrings
}
*/
