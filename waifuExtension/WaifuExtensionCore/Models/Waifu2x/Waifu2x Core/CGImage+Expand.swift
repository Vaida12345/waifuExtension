//
//  NSImage+MultiArray.swift
//  Waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import CoreML
import Cocoa

extension CGImage {
    
    /// Expand the original image by shrink_size and store rgb in float array.
    /// The model will shrink the input image by 7 px.
    ///
    /// - Returns: Float array of rgb values
    public func expand(withAlpha: Bool, in waifu2x: Waifu2x) -> [Float] {
        let rect = NSRect.init(origin: .zero, size: CGSize(width: width, height: height))
        
        // Redraw image in 32-bit RGBA
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4)
        data.initialize(repeating: 0, count: width * height * 4)
        defer {
            data.deallocate()
        }
        let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4 * width, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipLast.rawValue)
        context?.draw(self, in: rect)
        
        let exwidth = width + 2 * waifu2x.shrink_size
        let exheight = height + 2 * waifu2x.shrink_size
        
        var arr = [Float](repeating: 0, count: 3 * exwidth * exheight)
        
        var xx, yy, pixel: Int
        var r, g, b, a: UInt8
        var fr, fg, fb: Float
        // http://www.jianshu.com/p/516f01fed6e4
        
        var y1 = 0
        while y1 < height {
            var x = 0
            while x < width {
                xx = x + waifu2x.shrink_size
                yy = y1 + waifu2x.shrink_size
                pixel = (width * y1 + x) * 4
                r = data[pixel]
                g = data[pixel + 1]
                b = data[pixel + 2]
                // !!! rgb values are from 0 to 1
                // https://github.com/chungexcy/waifu2x-new/blob/master/image_test.py
                fr = Float(r) / 255 + waifu2x.clip_eta8
                fg = Float(g) / 255 + waifu2x.clip_eta8
                fb = Float(b) / 255 + waifu2x.clip_eta8
                if withAlpha {
                    a = data[pixel + 3]
                    if a > 0 {
//                        fr *= 255 / Float(a)
//                        fg *= 255 / Float(a)
//                        fb *= 255 / Float(a)
                    }
                }
                arr[yy * exwidth + xx] = fr
                arr[yy * exwidth + xx + exwidth * exheight] = fg
                arr[yy * exwidth + xx + exwidth * exheight * 2] = fb
                
                x += 1
            }
            
            y1 += 1
        }
        
        // Top-left corner
        pixel = 0
        r = data[pixel]
        g = data[pixel + 1]
        b = data[pixel + 2]
        fr = Float(r) / 255
        fg = Float(g) / 255
        fb = Float(b) / 255
        
        var y2 = 0
        while y2 < waifu2x.shrink_size {
            
            var x = 0
            while x < waifu2x.shrink_size {
                arr[y2 * exwidth + x] = fr
                arr[y2 * exwidth + x + exwidth * exheight] = fg
                arr[y2 * exwidth + x + exwidth * exheight * 2] = fb
                
                x += 1
            }
            
            y2 += 1
        }
        
        // Top-right corner
        pixel = (width - 1) * 4
        r = data[pixel]
        g = data[pixel + 1]
        b = data[pixel + 2]
        fr = Float(r) / 255
        fg = Float(g) / 255
        fb = Float(b) / 255
        
        var y3 = 0
        while y3 < waifu2x.shrink_size {
            var x = width+waifu2x.shrink_size
            
            while x < width+2*waifu2x.shrink_size {
                arr[y3 * exwidth + x] = fr
                arr[y3 * exwidth + x + exwidth * exheight] = fg
                arr[y3 * exwidth + x + exwidth * exheight * 2] = fb
                
                x += 1
            }
            
            y3 += 1
        }
        
        // Bottom-left corner
        pixel = (width * (height - 1)) * 4
        r = data[pixel]
        g = data[pixel + 1]
        b = data[pixel + 2]
        fr = Float(r) / 255
        fg = Float(g) / 255
        fb = Float(b) / 255
        
        var y4 = height+waifu2x.shrink_size
        while y4 < height+2*waifu2x.shrink_size {
            
            var x = 0
            while x < waifu2x.shrink_size {
                arr[y4 * exwidth + x] = fr
                arr[y4 * exwidth + x + exwidth * exheight] = fg
                arr[y4 * exwidth + x + exwidth * exheight * 2] = fb
                
                x += 1
            }
            
            y4 += 1
        }
        
        // Bottom-right corner
        pixel = (width * (height - 1) + (width - 1)) * 4
        r = data[pixel]
        g = data[pixel + 1]
        b = data[pixel + 2]
        fr = Float(r) / 255
        fg = Float(g) / 255
        fb = Float(b) / 255
        
        var y5 = height+waifu2x.shrink_size
        while y5 < height+2*waifu2x.shrink_size {
            var x = width+waifu2x.shrink_size
            while x < width+2*waifu2x.shrink_size {
                arr[y5 * exwidth + x] = fr
                arr[y5 * exwidth + x + exwidth * exheight] = fg
                arr[y5 * exwidth + x + exwidth * exheight * 2] = fb
                
                x += 1
            }
            
            y5 += 1
        }
        
        // Top & bottom bar
        var x = 0
        while x < width {
            pixel = x * 4
            r = data[pixel]
            g = data[pixel + 1]
            b = data[pixel + 2]
            fr = Float(r) / 255
            fg = Float(g) / 255
            fb = Float(b) / 255
            xx = x + waifu2x.shrink_size
            var y6 = 0
            while y6 < waifu2x.shrink_size {
                arr[y6 * exwidth + xx] = fr
                arr[y6 * exwidth + xx + exwidth * exheight] = fg
                arr[y6 * exwidth + xx + exwidth * exheight * 2] = fb
                
                y6 += 1
            }
            pixel = (width * (height - 1) + x) * 4
            r = data[pixel]
            g = data[pixel + 1]
            b = data[pixel + 2]
            fr = Float(r) / 255
            fg = Float(g) / 255
            fb = Float(b) / 255
            xx = x + waifu2x.shrink_size
            
            var y7 = height+waifu2x.shrink_size
            while y7 < height+2*waifu2x.shrink_size {
                arr[y7 * exwidth + xx] = fr
                arr[y7 * exwidth + xx + exwidth * exheight] = fg
                arr[y7 * exwidth + xx + exwidth * exheight * 2] = fb
                
                y7 += 1
            }
            
            x += 1
        }
        
        // Left & right bar
        var y8 = 0
        while y8 < height {
            pixel = (width * y8) * 4
            r = data[pixel]
            g = data[pixel + 1]
            b = data[pixel + 2]
            fr = Float(r) / 255
            fg = Float(g) / 255
            fb = Float(b) / 255
            yy = y8 + waifu2x.shrink_size
            
            var x1 = 0
            while x1 < waifu2x.shrink_size {
                arr[yy * exwidth + x1] = fr
                arr[yy * exwidth + x1 + exwidth * exheight] = fg
                arr[yy * exwidth + x1 + exwidth * exheight * 2] = fb
                
                x1 += 1
            }
            
            pixel = (width * y8 + (width - 1)) * 4
            r = data[pixel]
            g = data[pixel + 1]
            b = data[pixel + 2]
            fr = Float(r) / 255
            fg = Float(g) / 255
            fb = Float(b) / 255
            yy = y8 + waifu2x.shrink_size
            
            var x = width+waifu2x.shrink_size
            while x < width+2*waifu2x.shrink_size {
                arr[yy * exwidth + x] = fr
                arr[yy * exwidth + x + exwidth * exheight] = fg
                arr[yy * exwidth + x + exwidth * exheight * 2] = fb
                
                x += 1
            }
            
            y8 += 1
        }
        
        return arr
    }
    
}
