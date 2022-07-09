//
//  NSImage+Alpha.swift
//  waifu2x
//
//  Created by xieyi on 2017/12/29.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import Cocoa

extension NSImage {
    
    // For images with more than 8 bits per component, extracting alpha only produces incomplete image
    func alphaTyped<T>(bits: Int, zero: T, cgImage: CGImage) -> UnsafeMutablePointer<T> {
        let width = Int(self.representations[0].pixelsWide)
        let height = Int(self.representations[0].pixelsHigh)
        let data = UnsafeMutablePointer<T>.allocate(capacity: width * height * 4)
        data.initialize(repeating: zero, count: width * height)
        let alphaOnly = CGContext(data: data, width: width, height: height, bitsPerComponent: bits, bytesPerRow: width * 4 * bits / 8, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        alphaOnly?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return data
    }
    
    func alphaNonTyped(_ datap: UnsafeMutableRawPointer, cgImage: CGImage) {
        let width = Int(self.representations[0].pixelsWide)
        let height = Int(self.representations[0].pixelsHigh)
        let alphaOnly = CGContext(data: datap, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)
        alphaOnly?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    
    func alpha(cgImage: CGImage) -> [UInt8] {
        let width = Int(self.representations[0].pixelsWide)
        let height = Int(self.representations[0].pixelsHigh)
        var data = [UInt8].init(repeating: 0, count: width * height)
        let bitsPerComponent = cgImage.bitsPerComponent
        
        if bitsPerComponent == 8 {
            alphaNonTyped(&data, cgImage: cgImage)
        } else if bitsPerComponent == 16 {
            let typed: UnsafeMutablePointer<UInt16> = alphaTyped(bits: 16, zero: 0, cgImage: cgImage)
            var i = 0
            while i < data.count {
                data[i] = UInt8(typed[i * 4 + 3] >> 8)
                
                i += 1
            }
            typed.deallocate()
        } else if bitsPerComponent == 32 {
            let typed: UnsafeMutablePointer<UInt32> = alphaTyped(bits: 32, zero: 0, cgImage: cgImage)
            var i = 0
            while i < data.count {
                data[i] = UInt8(typed[i * 4 + 3] >> 24)
                
                i += 1
            }
            typed.deallocate()
        }
        return data
    }
    
}
