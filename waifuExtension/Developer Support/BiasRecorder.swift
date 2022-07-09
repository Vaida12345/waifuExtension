//
//  BiasRecorder.swift
//  waifuExtension
//
//  Created by Vaida on 7/7/22.
//

import Foundation

struct BiasRecorder: Equatable {
    
    let stage: Stage
    let time: Double
    
    static let biasQueue = DispatchQueue.global(qos: .background)
    
    static var contents: [BiasRecorder] = []
    
    static func add(bias: BiasRecorder) {
        biasQueue.async {
            contents.append(bias)
        }
    }
    
    enum Stage: String, CaseIterable {
        case initial0
        case initial1
        case initial2
        case initial3
        case prepare
        case expend
        case inPipe
        case ml
        case outPipe
        case generateOutput
    }
    
    static var totalTime: Double {
        contents.reduce(0) { $0 + $1.time }
    }
    
    static func bias(of stage: Stage) -> Double {
        totalTime / contents.filter{ $0.stage == stage }.map(\.time).reduce(0, +)
    }
    
}
