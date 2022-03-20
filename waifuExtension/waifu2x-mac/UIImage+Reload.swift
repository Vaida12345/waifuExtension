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
    public func reload() -> NSImage {
        
        let tempfile = "\(NSHomeDirectory())/tmp/\(UUID()).png"
        try! FinderItem(at: tempfile).generateDirectory()
        self.write(to: tempfile)
        let image = NSImage(contentsOf: URL(fileURLWithPath: tempfile))!
        try! FinderItem(at: tempfile).removeFile()
        return image
    }
    
}
