//
//  NSImage+Crop.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import Cocoa

extension NSImage {
    
    public func crop(rects: [CGRect]) -> [NSImage] {
        var result: [NSImage] = []
        var rectIndex = 0
        while rectIndex < rects.count {
        let rect = rects[rectIndex]
            result.append(crop(rect: rect))
            rectIndex += 1
        }
        return result
    }
    
    public func crop(rect: CGRect) -> NSImage {
        var rect = NSRect.init(origin: .zero, size: self.size)
        let cgimg = cgImage(forProposedRect: &rect, context: nil, hints: nil)?.cropping(to: rect)
        return NSImage(cgImage: cgimg!, size: rect.size)
    }
    
}
