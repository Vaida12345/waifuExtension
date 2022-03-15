//
//  Support.swift
//
//
//  Created by Vaida on 2019/8/21.
//  Copyright © 2022 Vaida. All rights reserved.
//

import Cocoa
import Foundation
import SwiftUI

//MARK: - Structures

/// Classes that can be copied.
protocol Copyable {
    
    /// Creates an instance from itself.
    ///
    /// - Parameters:
    ///    - instance: The instance to initialize with.
    init(_ instance: Self)
    
}

/// A continuous gesture recognizer for panning gestures.
class PanGestureRecognizer: NSPanGestureRecognizer {
    
    var touchesDidStart: (() -> Void)? = nil
    var touchesDragged: (() -> Void)? = nil
    var touchesDidEnd: (() -> Void)? = nil
    
    /// Creates an instance with its actions.
    ///
    /// - Parameters:
    ///    - mouseDown: Informs the gesture recognizer that the user pressed the left mouse button.
    ///    - mouseDragged: Informs the gesture recognizer that the user moved the mouse with the left button pressed.
    ///    - mouseUp: Informs the gesture recognizer that the user released the left mouse button.
    convenience init(target: Any?, mouseDown: (() -> Void)? = nil, mouseDragged: (() -> Void)? = nil, mouseUp: (() -> Void)? = nil) {
        self.init(target: target, action: nil)
        self.touchesDidStart = mouseDown
        self.touchesDragged = mouseDragged
        self.touchesDidEnd = mouseUp
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        if touchesDidStart != nil {
            touchesDidStart!()
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        if touchesDragged != nil {
            touchesDragged!()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        if touchesDidEnd != nil {
            touchesDidEnd!()
        }
    }
    
}


//MARK: - Extensions

extension Array {
    
    /// Returns the same array but in different order.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3].inRandomOrder
    ///     // prints "[3, 1, 2]"
    var inRandomOrder: [Element] {
        var content: [Element] = []
        var originalContent = self
        while !originalContent.isEmpty { content.append(originalContent.remove(at: (0...(originalContent.count - 1)).randomElement()!)) }
        return content
    }
    
    /// The mean value of this array.
    func average() -> Element where Element: Arithmetical {
        self.reduce(Element.zero, { $0 + $1 }) / Element(self.count)
    }
    
    /// The arrangement of this array.
    ///
    /// From [StackOverflow](https://stackoverflow.com/questions/34968470/calculate-all-permutations-of-a-string-in-swift)
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3].arrangement())
    ///     // prints "[[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]"
    func arrangement() -> [[Element]] {
        
        var scratch = self  // This is a scratch space for Heap's algorithm
        var result: [[Element]] = []  // This will accumulate our result
        
        // Heap's algorithm
        func heap(_ n: Int) {
            if n == 1 {
                result.append(scratch)
                return
            }
            
            for i in 0..<n - 1 {
                heap(n - 1)
                let j = (n % 2 == 1) ? 0 : i
                scratch.swapAt(j, n - 1)
            }
            heap(n - 1)
        }
        
        // Let's get started
        heap(scratch.count)
        
        // And return the result we built up
        return result
    }
    
    /// The combination of this array.
    ///
    /// From [StackOverflow](https://stackoverflow.com/questions/25162500/swift-generate-combinations-with-repetition)
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3].combination(n: 2))
    ///     // prints "[[1, 2], [1, 3], [2, 3]]"
    ///
    /// - Parameters:
    ///    - n: The number of elements chosen.
    func combination(n: Int) -> [[Element]] {
        if n == 0 { return [[]] }
        
        guard let first = self.first else { return [] }
        
        let head = [first]
        let subCombos = self.combination(n: n - 1)
        var ret = subCombos.map { head + $0 }
        ret += Array(self.dropFirst()).combination(n: n)
        
        return ret
    }
    
    /// Determines whether the sequence contains the sub-sequence.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3, 1, 2, 3].contains([1, 2, 3]))
    ///     // prints "true"
    ///
    /// - Parameters:
    ///     - sequence: The sequence to be found.
    ///
    /// - Returns: `true` if the sequence contains the sub-sequence; `false` otherwise.
    func contains(_ sequence: [Element]) -> Bool where Element: Equatable {
        guard !sequence.isEmpty else { return true }
        guard sequence.count != 1 else { return self.contains(sequence.first!) }
        guard !self.isEmpty else { return false }
        
        var i = 0
        while i + 1 < self.count {
            i += 1
            
            guard let index = self.findIndex(of: sequence.first!, occurrence: i) else { return false }
            guard self.count >= index + sequence.count else { return false }
            if Array(self[index..<index + sequence.count]) == sequence { return true }
        }
        
        return false
    }
    
    /// Finds the repeated elements.
    ///
    /// **Example**
    ///
    ///     let content = [1, 2, 1, 2, 3, 1, 2, 1, 2, 3, 1, 2]
    ///     print(content.findRepeatedElements() ?? "")
    ///     // prints "[1, 2, 1, 2, 3]"
    ///
    /// - Note:
    /// If multiple sequences were found, it would only return the first one.
    ///
    /// - Attention: The return value is `nil` if no repeated elements were found.
    ///
    /// - Returns: The repeated elements; `nil` otherwise.
    func findRepeatedElements() -> [Element]? where Element: Equatable {
        var possibleElements: [[Element]] = []
        
        var i = -1
        while i + 1 < self.count {
            i += 1
            
            var ii = i - 1
            while ii + 1 < self.count {
                ii += 1
                
                guard self[i] == self[ii] else { continue }
                guard ii + (ii - i) <= self.count else { continue }
                guard self[i..<ii] == self[ii..<ii + (ii - i)] else { continue }
                if !Array(self[i..<ii]).isEmpty { possibleElements.append(Array(self[i..<ii])) }
            }
        }
        
        var index = -1
        while index + 1 < possibleElements.count {
            index += 1
            let i = possibleElements[index]
            
            let leadingItems = self.firstIndex(of: i)!.first!
            let endingItems = (self.count - leadingItems) % i.count
            
            var content = self
            while content.contains(i) { content.removeSubrange(content.firstIndex(of: i)!) }
            if content.count == leadingItems + endingItems && content[content.count - endingItems..<content.count] == i[0..<endingItems] { return i }
        }
        
        return nil
    }
    
    /// Forms an array of two `Array`s without repeated elements, and stores in `self`.
    ///
    /// **Example**
    ///
    ///     var lhs: [Fraction] = [1, 2, 3, 4]
    ///     let rhs: [Fraction] = [4, 5, 6, 7]
    ///     lhs.formUnion(rhs)
    ///     print(lhs)
    ///     // prints [1, 2, 3, 4, 5, 6, 7]
    ///
    /// - Parameters:
    ///     - other: Another array to perform union with.
    mutating func formUnion(_ other: Array) where Element: Hashable {
        self = self.union(other)
    }
    
    /// Forms an array of two `Array`s with only repeated elements, and stores in `self`.
    ///
    /// **Example**
    ///
    ///     var lhs: [Fraction] = [1, 2, 3, 4]
    ///     let rhs: [Fraction] = [4, 5, 6, 7]
    ///     lhs.intersection(rhs)
    ///     print(lhs)
    ///     // prints [4]
    ///
    /// - Parameters:
    ///     - other: Another array to perform intersection with.
    mutating func formIntersection(_ other: Array) where Element: Hashable {
        self = self.intersection(other)
    }
    
    /// Forms an array of two `Array`s without repeated elements.
    ///
    /// **Example**
    ///
    ///     let lhs: [Fraction] = [1, 2, 3, 4]
    ///     let rhs: [Fraction] = [4, 5, 6, 7]
    ///     print(lhs.union(rhs))
    ///     // prints [1, 2, 3, 4, 5, 6, 7]
    ///
    /// - Parameters:
    ///     - rhs: Another array to perform union with.
    ///
    /// - Returns: The union of two arrays.
    func union(_ rhs: Array) -> Array where Element: Hashable {
        self + rhs.filter { !self.contains($0) }
    }
    
    /// Forms an array of two `Array`s with only repeated elements.
    ///
    /// **Example**
    ///
    ///     let lhs: [Fraction] = [1, 2, 3, 4]
    ///     let rhs: [Fraction] = [4, 5, 6, 7]
    ///     print(lhs.intersection(rhs))
    ///     // prints [4]
    ///
    /// - Parameters:
    ///     - rhs: Another array to perform intersection with.
    ///
    /// - Returns: The intersection of two arrays.
    func intersection(_ rhs: Array) -> Array where Element: Hashable {
        self.filter({ rhs.contains($0) })
    }
    
    /// Removes the repeated elements of an array, leaving only the entries different from each other.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3, 1].removingRepeatedElements())
    ///     // prints "[1, 2, 3]"
    ///
    /// - Returns: The array without repeated elements.
    func removingRepeatedElements() -> Self where Element: Hashable {
        Array(Set(self)).sorted(by: { self.firstIndex(of: $0)! < self.firstIndex(of: $1)! })
    }
    
    /// Returns a new sequence in which all occurrences of a target sequence in the receiver are replaced by another given sequence.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3, 4].replacingOccurrences(of: [2, 3], with: [23]))
    ///     // prints "[1, 23, 4]"
    ///
    /// - Parameters:
    ///     - replacement: The sequence with which to replace target.
    ///     - target: The sequence to replace.
    ///
    /// - Returns: A new sequence in which all occurrences of target in the receiver are replaced by replacement.
    func replacingOccurrences(of target: [Element], with replacement: [Element]) -> Self where Element: Equatable {
        var content = self
        while content.contains(target) {
            content.replaceSubrange(content.firstIndex(of: target)!, with: replacement)
        }
        return content
    }
    
    /// Returns a new sequence in which all occurrences of a target sequence in the receiver are removed.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3, 4].removingOccurrences(of: [2, 3]))
    ///     // prints "[1, 4]"
    ///
    /// - Parameters:
    ///     - target: The sequence to be removed.
    ///
    /// - Returns: A new sequence in which all occurrences of target in the receiver are removed.
    func removingOccurrences(of target: [Element]) -> Self where Element: Equatable {
        var content = self
        while content.contains(target) {
            content.removeSubrange(content.firstIndex(of: target)!)
        }
        return content
    }
    
}


extension BinaryFloatingPoint where Self: LosslessStringConvertible {
    
    /// The `String` representation of the part after the decimal place ".".
    ///
    /// **Example**
    ///
    ///     print(1.0.decimalPart)
    ///     //prints ""
    ///
    ///     print(1.1.decimalPart)
    ///     //prints "1"
    var decimalPart: String {
        guard !self.isWholeNumber else { return "" }
        return String(self).components(separatedBy: ".").last!
    }
    
    /// The `String` representation of the part before the decimal place ".".
    ///
    /// **Example**
    ///
    ///     print(2.1.integerPart)
    ///     //prints "2"
    var integerPart: String {
        guard !self.isWholeNumber else { return String(self) }
        return String(self).components(separatedBy: ".").first!
    }
    
    /// Determines whether this value represents a whole number.
    ///
    /// **Example**
    ///
    ///     print(1.0.isWholeNumber)
    ///     //prints "true"
    ///
    ///     print(1.1.isWholeNumber)
    ///     //prints "false"
    ///
    var isWholeNumber: Bool {
        Self(Int(self)) == self
    }
    
    /// Returns the scientific expression.
    ///
    /// **Example**
    ///
    ///     print(314159.2.expressedScientifically())
    ///     // prints "(3.141592, 5)"
    ///
    /// - Returns:
    ///   `value `  The coefficient of c\*10^n.
    ///
    ///   `power `  The power of c\*10^n.
    func expressedScientifically() -> (value: Self, power: Int) {
        guard self != 0 else { return (0, 0) }
        var content = self
        var counter = 0
        let sign = self.sign
        
        if content > 1 {
            while content / 10 > 1 {
                content /= 10
                counter += 1
            }
            return (content * ((sign == .minus) ? 1 : -1), counter)
        } else {
            while content < 1 {
                content *= 10
                counter -= 1
            }
            return (content * ((sign == .minus) ? 1 : -1), counter)
        }
    }
    
    /// return the expression of time. Values are in seconds.
    ///
    /// **Example**
    ///
    ///     print(0.000012345.expressedAsTime())
    ///     // prints "12.3µs"
    func expressedAsTime() -> String {
        if self == 0 { return "0s" }
        if self < 1e-15 { return String(format: "%.3gas", Double(self) * 1e18) }
        if self < 1e-12 { return String(format: "%.3gfs", Double(self) * 1e15) }
        if self < 1e-9 { return String(format: "%.3gps", Double(self) * 1e12) }
        if self < 1e-6 { return String(format: "%.3gns", Double(self) * 1e9) }
        if self < 1e-3 { return String(format: "%.3gµs", Double(self) * 1e6) }
        if self < 1 { return String(format: "%.3gms", Double(self) * 1e3) }
        if self < Self(pow(60.0, 1)) { return String(format: "%.3gs", Double(self)) }
        if self < Self(pow(60.0, 2)) { return String(format: "%.3gmin", Double(self) / pow(60.0, 1)) }
        if self < Self(pow(60.0, 3)) { return String(format: "%.3ghr", Double(self) / pow(60.0, 2)) }
        if self < Self(pow(60.0, 3)) * 24 { return String(format: "%.3gdays", Double(self) / pow(60.0, 3)) }
        if self < Self(pow(60.0, 3)) * 24 * 365 { return String(format: "%.3gyrs", Double(self) / pow(60.0, 3) * 24) }
        if self < Self(pow(60.0, 3)) * 24 * 365 * 100 { return String(format: "%.3gcentries", Double(self) / pow(60.0, 3) * 24 * 365) }
        return String(format: "%.1fs", Double(self))
    }
    
    /// Returns the rounded value.
    ///
    ///  **Example**
    ///
    ///     print(3.1415926535.rounded(toDigit: 3))
    ///     // prints "3.142"
    ///
    /// - Parameters:
    ///     - digit: The digit to be rounded to.
    ///
    /// - Returns: The rounded value.
    func rounded(toDigit digit: Int) -> Self {
        return Self(String(format: "%.\(digit)f", Double(self)))!
    }
    
}


extension BinaryInteger {
    
    /// Returns the expression of file size.
    ///
    /// **Example**
    ///
    ///     print(1902662.expressAsFileSize())
    ///     // prints "1.9MB"
    func expressAsFileSize() -> String {
        if Double(self) < 1e3 { return String(format: "%.3gB", Double(self)) }
        if Double(self) < 1e6 { return String(format: "%.3gKB", Double(self) / 1e3) }
        if Double(self) < 1e9 { return String(format: "%.3gMB", Double(self) / 1e6) }
        if Double(self) < 1e12 { return String(format: "%.3gGB", Double(self) / 1e9) }
        return String(format: "%.3gTB", Double(self) / 1e12)
    }
    
}


extension CGRect {
    
    /// A point that specifies the coordinates of the rectangle’s center.
    var center: CGPoint {
        get { CGPoint(x: self.origin.x + self.size.width / 2, y: self.origin.y + self.size.height / 2) }
        set { self = CGRect(center: newValue, size: self.size) }
    }
    
    /// Creates an instance with the center point and the size of `CGRect`.
    ///
    /// - Parameters:
    ///     - center: The center point.
    ///     - size: The size of the `CGRect`.
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
    
}


extension Copyable {
    
    /// Copies the instance.
    func copied() -> Self {
        Self(self)
    }
    
}


extension Character {
    
    /// Creates an instance with an `Int`.
    ///
    /// - Parameters:
    ///     - content: The content to initialize with.
    init(_ content: Int) {
        self.init(String(content))
    }
    
}


extension Collection {
    
    /// The second element of the collection.
    ///
    ///  **Example**
    ///
    ///     let numbers = [10, 20, 30, 40, 50]
    ///     print(numbers.second)
    ///     // prints "Optional(20)"
    ///
    /// - Attention: The return value is `nil` if there is only one or no element.
    var second: Self.Element? {
        guard self.startIndex != self.endIndex else { return nil }
        let index = self.index(after: self.startIndex)
        return self[index]
    }
    
    /// Determines whether the array contains duplicated items.
    ///
    ///**Example**
    ///
    ///     print("1231".containsDuplicatedItems())
    ///     // prints "true"
    ///
    /// - Returns: `true` if duplicated items were found; `false` otherwise.
    func containsDuplicatedItems() -> Bool where Element: Hashable {
        !Dictionary(grouping: self, by: { $0 }).allSatisfy({ $1.count == 1 })
    }
    
    /// Finds the repeated elements.
    ///
    /// **Example**
    ///
    ///     let content = "fat.rat.eat.bat.cat.eat.fat.rat"
    ///     print(content.findRepeatedElements(ofLength: 3))
    ///     // prints "[".ea", ".ra", "at.", "eat", "fat", "rat", "t.e"]"
    ///
    /// - Returns: The repeated elements; empty otherwise.
    func findRepeatedElements(ofLength k: Int) -> [SubSequence] where Element: Equatable, SubSequence: Comparable {
        var slices: [SubSequence] = []
        var output: [SubSequence] = []
        for i in 0...self.count - k {
            slices.append(self[self.index(self.startIndex, offsetBy: i)..<self.endIndex])
        }
        
        slices.sort()
        
        for i in 0..<self.count - k - 1 {
            let lhs = slices[i][slices[i].startIndex..<slices[i].index(slices[i].startIndex, offsetBy: k)]
            let rhs = slices[i + 1][slices[i + 1].startIndex..<slices[i + 1].index(slices[i + 1].startIndex, offsetBy: k)]
            if lhs == rhs {
                output.append(rhs)
            }
        }
        
        return output
    }
    
    /// Finds the index where the `n`th occurrence of the `element` is.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3, 1].findIndex(of: 1, occurrence: 2) ?? "")
    ///     // prints "3"
    ///
    /// - Important: The number of occurrence, ie, `n`, starts from `1`.
    ///
    /// - Attention: The return value is `nil` if the number of presence of `element` < `n`.
    ///
    /// - Parameters:
    ///     - element: The element to search for.
    ///     - n: The number of occurrence.
    ///
    /// - Returns: The `n`th index where the `element` is; `nil` otherwise.
    func findIndex(of element: Element, occurrence n: Int) -> Index? where Element: Equatable {
        guard self.contains(element) else { return nil }
        var value = self.dropFirst(0)
        var indexes: Index = self.startIndex
        
        var index = -1
        while index + 1 < n {
            index += 1
            
            guard let index = value.firstIndex(of: element) else { return nil }
            self.formIndex(&indexes, offsetBy: value.distance(from: value.startIndex, to: index) + 1)
            guard index < self.endIndex else { return nil }
            value = value[value.index(after: index)..<value.endIndex]
        }
        
        return self.index(indexes, offsetBy: -1)
    }
    
    /// Returns the first index where the `sequence` is.
    ///
    /// **Example**
    ///
    ///     let content = [1, 2, 3, 1, 2, 4]
    ///     print(content.firstIndex(of: [1, 2, 4]) ?? "")
    ///     //prints "3..<6"
    ///
    /// - Attention: The return value is `nil` if the `sequence` is empty or `self` does not contain the `sequence`.
    ///
    /// - Parameters:
    ///     - sequence: The sequence to be found.
    ///
    /// - Returns: The first index where the `sequence` is; `nil` otherwise.
    func firstIndex(of sequence: Self) -> Range<Index>? where Element: Equatable {
        guard !sequence.isEmpty else { return nil }
        guard sequence.count != 1 else { return self.firstIndex(of: sequence.first!)!..<self.index(after: firstIndex(of: sequence.first!)!) }
        
        var i = 0
        while i + 1 < self.count {
            i += 1
            
            guard let index = self.findIndex(of: sequence.first!, occurrence: i) else { return nil }
            guard self.index(index, offsetBy: sequence.count) <= self.endIndex else { return nil }
            if self[index..<self.index(index, offsetBy: sequence.count)].map({ $0 }) == sequence.map({ $0 }) { return index..<self.index(index, offsetBy: sequence.count) }
        }
        
        return nil
    }
    
}


extension Int {
    
    /// Initialize with a `Character`.
    init?(_ value: Character) {
        self.init(String(value))
    }
    
}


extension NSImage {
    
    /// The pixel size of `NSImage`.
    ///
    /// aka, `self.cgImage.size`.
    var pixelSize: CGSize? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }
    
    /// Returns the size which the image fits in the size.
    func aspectRatioFit(in size: CGSize) -> CGSize {
        let pixelSize = self.pixelSize!
        var resultSize: CGSize = .zero
        
        // if the `size` is wider than `pixel size`
        if size.width / size.height >= pixelSize.width / pixelSize.height {
            resultSize.height = size.height
            resultSize.width = pixelSize.width * size.height / pixelSize.height
        } else {
            resultSize.width = size.width
            resultSize.height = pixelSize.height * size.width / pixelSize.width
        }
        return resultSize
    }
    
    /// Embed the image in a square.
    ///
    /// It changes the canvas size into width x width.
    func embedInSquare() -> NSImage? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        guard cgImage.width != cgImage.height else { return self }
        let width = max(cgImage.width, cgImage.height)
        let originX = (width - cgImage.width) / 2
        let originY = (width - cgImage.height) / 2
        
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: width,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
            bitmapRep.size = CGSize(width: width, height: width)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: originX, y: originY, width: cgImage.width, height: cgImage.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()
            
            let resizedImage = NSImage(size: CGSize(width: width, height: width))
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }
        
        return nil
    }
    
    /// Resizes the `ImageRep` behind the `NSImage`.
    ///
    /// - Important: The method should be rarely used. To change the size of a `NSImage`, use
    ///
    ///         NSImage().size = CGSize(x: Double, y: Double)
    ///
    /// - Remark: The method changes the resolution of the `ImageRep` behind the image.
    ///
    /// - Parameters:
    ///   - newSize: The changed size of image.
    ///
    /// - Returns: The `NSImage`, which is resized.
    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()
            
            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }
        
        return nil
    }
    
    /// Trims image into the rect provided.
    ///
    /// - Parameters:
    ///   - rect: The rect to which to trim.
    ///
    /// - Returns: The `NSImage` which is trimmed.
    func trimmed(rect: CGRect) -> NSImage {
        let result = NSImage(size: rect.size)
        result.lockFocus()
        
        let destRect = CGRect(origin: .zero, size: result.size)
        self.draw(in: destRect, from: rect, operation: .copy, fraction: 1.0)
        
        result.unlockFocus()
        return result
    }
    
    /// Write a `NSImage` as `.png` to the path.
    ///
    /// - Parameters:
    ///   - path: The path to save the image.
    func write(to path: String) {
        guard let data = tiffRepresentation,
              let rep = NSBitmapImageRep(data: data),
              let imageData = rep.representation(using: .png, properties: [:])
        else {
            print("failed to write image to \(path)")
            return
        }
        
        try! imageData.write(to: URL(fileURLWithPath: path, isDirectory: false))
    }
    
    /// Write a raw `NSImage.tiffRepresentation` to the path.
    ///
    /// - Parameters:
    ///   - path: The path to save the image.
    func writeRaw(to path: String) {
        guard let data = tiffRepresentation else {
            print("failed to write image to \(path)")
            return
        }
        try! data.write(to: URL(fileURLWithPath: path, isDirectory: false))
    }
    
}


extension NSView {
    
    /// The `NSImage` representation of the view.
    ///
    /// - Important: The `bounds` of the view cannot be `zero`.
    ///
    /// - Returns: The `NSImage` of view.
    var image: NSImage {
        let imageRepresentation = bitmapImageRepForCachingDisplay(in: bounds)!
        cacheDisplay(in: bounds, to: imageRepresentation)
        return NSImage(cgImage: imageRepresentation.cgImage!, size: bounds.size)
    }
    
}


extension Numeric {
    
    /// Assign the sign to the value.
    ///
    /// `1 -> " + 1"`
    func assignedSign(negative: Bool = false) -> String where Self: Comparable {
        if negative { return (-1 * self).assignedSign() }
        if self >= 0 {
            return " + \(self.magnitude)"
        } else {
            return " - \(self.magnitude)"
        }
    }
    
}


extension SignedInteger {
    
    /// All the factors of current Int. If `self` is less than or equal to 1, the only factor was set to 1.
    var factors: [Self] {
        guard abs(self) > 1 else { return [1] }
        var content: [Self] = []
        var counter: Self = 1
        while counter < Int(sqrt(abs(Double(self)))) {
            if self.isMultiple(of: counter) {
                content.append(counter)
                content.append(abs(self) / counter)
            }
            counter += 1
        }
        return content.sorted()
    }
    
    /// The factorial.
    ///
    /// Aka, `n!`
    var factorial: Self {
        if self == 1 { return 1 }
        var content: Self = 1
        var value = self
        while value > 1 {
            content *= value
            value -= 1
        }
        return content
    }
    
}


extension String {
    
    func localized() -> String {
        NSLocalizedString(self, comment: "nil")
    }
    
    /// Extracts digits from a `String`.
    ///
    /// **Example**
    ///
    ///     print("a0123.hi12".extractDigits())
    ///     // prints "[123, 12]"
    ///
    /// - Returns: The numbers inside the `String`
    func extractDigits() -> [Int] {
        self.split(whereSeparator: { Int($0) == nil }).map { Int($0)! }
    }
    
    /// Returns the formal version.
    ///
    /// **Example**
    ///
    ///     print("this is a pen     ").formalized()
    ///     // prints "This is a pen."
    ///
    /// - Remark: This function would capitalize the initial character, add '.' at the end, remove unwanted spaces.
    ///
    /// - Returns: A formal version of `self`.
    func formalized() -> String {
        guard !self.isEmpty else { return self }
        var content = [Character](self)
        content[0] = Character(content.first!.uppercased())
        while content.last == " " { content.removeLast() }
        while content.first == " " { content.removeFirst() }
        if content.last != "." { content.append(".") }
        return String(content).replacingOccurrences(of: "  ", with: " ")
    }
    
    /// Write the `String` to the path.
    ///
    /// If file already exits, the `String` will be added to the end.
    func writeAppend(to path: String, atomically useAuxiliaryFile: Bool, encoding enc: Encoding) throws {
        var content = ""
        if let previousString = try? String(contentsOfFile: path) {
            content = previousString
            try FinderItem(at: path).removeFile()
        }
        content += self + "\n"
        try content.write(toFile: path, atomically: useAuxiliaryFile, encoding: enc)
    }
    
}


extension View {
    
    /// Open the `View` in a new window.
    @discardableResult func openInWindow(title: String, sender: Any?) -> NSWindow {
        let controller = NSHostingController(rootView: self)
        let win = NSWindow(contentViewController: controller)
        win.contentViewController = controller
        win.title = title
        win.makeKeyAndOrderFront(sender)
        return win
    }
    
    /// The `NSImage` representation of the view.
    ///
    /// - Returns: The `NSImage` of view.
    var image: NSImage {
        let view = self.nsView
        view.setFrameSize(view.fittingSize)
        return view.image
    }
    
    /// The `NSImage` representation of the view.
    var nsView: NSView {
        return NSHostingView(rootView: self)
    }
    
    /// The `NSImage` representation of the view.
    ///
    /// - Returns: The `NSImage` of view.
    func saveImage(size: CGSize) -> NSImage {
        let view = NSHostingView(rootView: self)
        view.setFrameSize(size)
        return view.image
    }
    
}


//MARK: - Supporting Functions

/// Prints a `[[String]]` nicely.
///
/// - Important: `space` is auto-generated content, do not fill.
///
/// - Parameters:
///    - list: The list to be printed.
///    - space: Auto generated content.
@discardableResult func printMatrix<T>(matrix: [[T]], transpose: Bool = false, includeIndex: Bool = false, space: [Int] = []) -> String where T: CustomStringConvertible {
    guard matrix.count > 1 else {
        print(matrix.first ?? "")
        return matrix.first?.description ?? ""
    }
    
    if transpose {
        var newMatrix: [[String]] = [[String]](repeating: [String](repeating: "", count: matrix.count), count: matrix.first!.count)
        
        var i = -1
        while i + 1 < matrix.count {
            i += 1
            
            var ii = -1
            while ii + 1 < matrix.first!.count {
                ii += 1
                
                newMatrix[ii][i] = matrix[i][ii].description
            }
        }
        return printMatrix(matrix: newMatrix, includeIndex: includeIndex)
    }
    
    if includeIndex {
        var newMatrix: [[String]] = [[String]](repeating: [String](repeating: "", count: matrix.count), count: matrix.first!.count)
        
        var i = -1
        while i + 1 < matrix.count {
            i += 1
            
            var ii = -1
            while ii + 1 < matrix.first!.count {
                ii += 1
                
                newMatrix[ii][i] = matrix[i][ii].description
            }
        }
        newMatrix.insert([Int](0..<matrix.count).map { $0.description }, at: 0)
        
        return printMatrix(matrix: newMatrix, transpose: true)
    }
    
    var space1: [Int] = space
    while space1.count != matrix.last!.count { space1.append(0) }
    
    var index = -1
    while index + 1 < matrix.count {
        index += 1
        let i = matrix[index]
        
        var currentItem = 0
        var content = ""
        
        while currentItem != i.count {
            content += i[currentItem].description
            
            while content.count + 4 > Int(space1[currentItem]) {
                space1[currentItem] += 1
                return printMatrix(matrix: matrix, space: space1)
            }
            
            while content.count < space1[currentItem] { content += " " }
            currentItem += 1
        }
    }
    
    var value = ""
    
    index = -1
    while index + 1 < matrix.count {
        index += 1
        let item = matrix[index]
        
        var content = ""
        
        var currentItem = 0
        while currentItem != item.count {
            content += item[currentItem].description
            while content.count < space1[currentItem] { content += " " }
            currentItem += 1
        }
        print(content)
        value += content + "\n"
    }
    
    return value
}

/// Asks for user input.
///
/// **Example**
///
///     let _ = input("Please enter")
///     // prints "Please enter: "
///
/// - Note: Pass `content` with `""` to prevent displaying anything.
///
/// - Attention: The return value is `nil` if the user input cannot be interpreted as `String`.
///
/// - Parameters:
///     - content: The content to be displayed.
///
/// - Returns: The `String` version of user input; `nil` otherwise.
func input(_ content: String) -> String? {
    if !content.isEmpty { print("\(content): ", terminator: "") }
    guard let input = readLine() else { return nil }
    return input
}

/// Solves an equation with Newton's Method.
///
/// **Example**
///
///     // solve for 3x == 3
///     func f(_ x: Double) -> Double {
///         return 3*x
///     }
///
///     print(solve(f(_:), 3))
///     // prints "1.0"
///
///     // Closure can also be used:
///     let answer = solve { x in
///         3 * x
///     }
///
/// - Remark: The function was set to failure after spending more than 2 seconds.
///
/// - Remark: By default, the delta was set to:` let delta = 1e-10`
///
/// - Note: Due to the limitations of Newton's Method, functions with multiple answers or functions that are not continuous may not be solved.
///
/// - Attention: The return value is `nil` if no solutions can be found.
///
/// - Parameters:
///     - lhs: The function to be solved.
///     - rhs: The y value of the function.
///
/// - Returns: The answer to the equation; `nil` otherwise.
func solve<T>(_ lhs: (_ x: T) -> T, _ rhs: T = 0) -> T? where T: BinaryFloatingPoint {
    let delta = T(0.0000000001)
    
    func f(_ x: T) -> T {
        return lhs(x) - rhs
    }
    
    func derivative(at x: T, delta: T = delta) -> T? {
        let content = (f(x + delta) - f(x)) / delta
        guard content != 0 else {
            if delta < 1 {
                return derivative(at: x + delta, delta: delta * 2)
            } else {
                return nil
            }
        }
        return content
    }
    
    func mutateX_n1() -> T? {
        if let value = derivative(at: x_n) {
            return x_n - (f(x_n)) / (value)
        } else {
            guard !initialValues.isEmpty else { return nil }
            x_n = initialValues.removeFirst()
            return mutateX_n1()
        }
    }
    
    let date = Date()
    var initialValues: [T] = [-1, -10, -100, 1, 10, 100]
    var x_n = initialValues.removeFirst()
    var x_n1 = x_n - (f(x_n)) / (derivative(at: x_n) ?? 1)
    
    while abs(x_n1 - x_n) >= delta {
        guard abs(x_n) < T(pow(10.0, 50.0)) else {
            print("Failed to solve: answer exceeds 10^50")
            return nil
        }
        x_n = x_n1
        guard let value = mutateX_n1() else { return nil }
        x_n1 = value
        
        if date.distance(to: Date()) > 2 {
            print("Failed to solve: spent more than 2 seconds")
            return nil
        }
    }
    
    return x_n1
}

/// Determines whether the `lhs` and `rhs` is similar under the threshold.
///
/// - Parameters:
///     - lhs: The `lhs` value.
///     - rhs: The `rhs` value.
///     - threshold: The threshold of comparison.
///
/// - Returns: `true` if they are proximately equal.
func proximateEqual<T>(lhs: T, rhs: T, threshold: T) -> Bool where T: Numeric, T: Comparable {
    if lhs - threshold <= rhs && lhs + threshold >= rhs {
        return true
    } else {
        return false
    }
}

/// Runs shell commands.
///
/// - Parameters:
///   - commands: The commands to run. Put each line of command into an array.
///
/// - Returns: The result of commands.
@discardableResult func shell(_ commands: [String]) -> String? {
    let task = Process()
    let pipe = Pipe()
    let command = commands.reduce("", { $0 + "\n" + $1 })
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    
    return output
}

/// Raise the power of an int.
///
/// - Parameters:
///     - lhs: The int.
///     - rhs: The int.
func pow(_ lhs: Int, _ rhs: Int) -> Int {
    return Int(pow(Double(lhs), Double(rhs)))
}
