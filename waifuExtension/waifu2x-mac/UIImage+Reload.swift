//
//  UIImage+Reload.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import Cocoa

extension NSImage {
    
    /// Workaround: Apply two ML filters sequently will break the image
    ///
    /// - Returns: the reloaded image
    public func reload(withIndex: String? = nil) -> NSImage {
        
        let tmpfile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp/\(withIndex ?? "").png")
        self.write(to: tmpfile.path)
        return NSImage(contentsOf: tmpfile)!
    }
    
}
