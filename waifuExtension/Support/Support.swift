//
//  Support.swift
//
//
//  Created by Vaida on 2019/8/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation


//MARK: - Structures

/// The English alphabetic.
///
/// Defined as:
///
///     let alphabet = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
let alphabet = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]

/// A transcoder that converts  between different bases.
struct Coder {
    static let characters = ["0","1","2","3","4","5","6","7","8","9", "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","+","-"]
    
    /// Encodes Decimal to a `String`.
    ///
    /// **Example**
    ///
    ///     print(Coder.encode(123, with: 32) ?? "")
    ///     // prints "3R"
    ///
    /// - Attention: The return value is `nil` if the `base` is greater than 64.
    ///
    /// - Important: The base should be less or equal to 64.
    ///
    /// - Parameters:
    ///     - content: The content to be converted.
    ///     - base: The base of the converted base.
    ///
    /// - Returns: The content that is converted into the `base`.
    static func encode(_ content: Int, with base: Int) -> String? {
        guard base <= 64 else { return nil }
        var encodedContent = ""
        var content = content
        while content >= base {
            encodedContent.insert(Character(characters[content%base]), at: encodedContent.startIndex)
            content /= base
        }
        encodedContent.insert(Character(characters[content]), at: encodedContent.startIndex)
        return String(encodedContent)
    }
    
    /// Decodes a `String` to Decimal.
    ///
    /// **Example**
    ///
    ///     print(Coder.decode(String("7NG"), with: 64) ?? "")
    ///     // prints "30160.0"
    ///
    /// - Important: The base should be less or equal to 64.
    ///
    /// - Attention: The return value is `nil` if the `base` is greater than 64.
    ///
    /// - Parameters:
    ///     - with: The base of current number.
    ///     - content: The content to be converted.
    ///
    /// - Returns: The content that is converted into decimal.
    static func decode(_ content: String, with base: Int) -> Double? {
        guard base <= 64 else { return nil }
        var decodedContent = 0.0
        let contentß = content.map({ String($0) })
        
        for i in 0...contentß.count-1 {
            let index = contentß.count-1-i
            decodedContent += pow(Double(base), Double(index))*Double(characters.firstIndex(of: contentß[i])!)
        }
        
        return decodedContent
    }
}

/// A `Size` whose `width` and `height` are both `Int`.
struct Size: Equatable {
    /// The size whose width and height are both zero.
    static var zero: Size {
        return Size(width: 0, height: 0)
    }
    
    /// The width of the size.
    var width: Int
    
    /// The height of the size.
    var height: Int
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
        return self.reduce(Element.zero, {$0 + $1}) / Element(self.count)
    }
    
    /// The arrangement of this array.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3].arrangement())
    ///     // prints "[[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]"
    func arrangement() -> [[Element]] {
        var items: [[Element]] = []
        for i in 0..<self.count {
            var value = self
            let removedContent = value.remove(at: i)
            for ii in value.arrangement() {
                var content = ii
                content.insert(removedContent, at: 0)
                items.append(content)
            }
            
            if value.arrangement().isEmpty {
                items.append([removedContent])
            }
        }
        return items
    }
    
    /// The combination of this array.
    ///
    /// - Parameters:
    ///    - n: The number of elements chosen.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3].combination(n: 2))
    ///     // prints "[[1, 2], [1, 3], [2, 3]]"
    func combination(n: Int) -> [[Element]] {
        if n == 0 { return [] }
        if n == 1 { return self.map({ [$0] }) }
        
        var items: [[Element]] = []
        var value = self
        for _ in 0..<self.count {
            let removedValue = value.removeFirst()
            for ii in value.combination(n: n - 1) {
                var content = ii
                content.insert(removedValue, at: 0)
                items.append(content)
            }
        }
        return items
    }
    
    /// Determines whether the array contains duplicated items.
    ///
    ///**Example**
    ///
    ///     print(creator.template)
    ///     // prints "true"
    ///
    /// - Parameters:
    ///     - ignore: `return` `false` if the only duplicated items are the items in the ignore list.
    ///
    /// - Returns: `true` if duplicated items were found; `false` otherwise.
    func containsDuplicatedItems(ignore: [Element] = []) -> Bool where Element: Hashable {
        var dictionary: [Element: Int] = [:]
        let _ = self.map({ if dictionary.keys.contains($0) { dictionary[$0]! += 1 } else { dictionary[$0] = 1 } })
        
        guard !ignore.isEmpty else { return !dictionary.values.allSatisfy({ $0 == 1 }) }
        for i in ignore { if dictionary.keys.contains(i) { dictionary[i] = 1 } }
        
        return !dictionary.values.allSatisfy({ $0 == 1 })
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
        
        for i in 1..<self.count {
            guard let index = self.findIndex(sequence.first!, occurrence: i) else { return false }
            guard self.count >= index+sequence.count else { return false }
            if Array(self[index..<index+sequence.count]) == sequence { return true }
        }
        
        return false
    }
    
    /// Find the elements in the array that sums to the specific value.
    func findElementsToSum(to sum: Element, threshold: Element? = nil, results: [Element]? = nil) -> [Element] where Element: BinaryFloatingPoint {
        let threshold = threshold ?? self.reduce(0, +)
        
        let upperBounce = {()-> Int in
            var content = Element(0)
            var value = self.sorted(by: <)
            var counter = 0
            while content < sum && counter < self.count {
                content += value.removeFirst()
                counter += 1
            }
            return counter
        }()
        
        let lowerBounce = {()-> Int in
            var content = Element(0)
            var value = self.sorted(by: >)
            var counter = 0
            while content < sum && counter < self.count {
                content += value.removeFirst()
                counter += 1
            }
            return counter
        }()
        
        for i in lowerBounce...upperBounce {
            for ii in self.combination(n: i) {
                if abs(ii.reduce(0, +) - sum) < threshold {
                    return self.findElementsToSum(to: sum, threshold: abs(ii.reduce(0, +) - sum), results: ii)
                }
            }
        }
        
        if abs((results ?? []).reduce(0, +) - sum) != 0 { print("findElementsToSum(): finish with error: \(abs((results ?? []).reduce(0, +) - sum).rounded())") }
        print("The sum is \((results ?? []).reduce(0, +).rounded())")
        
        return results ?? []
    }
    
    /// Finds the index where the `n`th occurrence of the `element` is.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3, 1].findIndex(1, occurrence: 2) ?? "")
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
    func findIndex(_ element: Element, occurrence n: Int) -> Index? where Element: Equatable {
        guard self.contains(element) else { return nil }
        var value = self
        var indexes = 0
        for _ in 0..<n {
            guard let index = value.firstIndex(of: element) else { return nil }
            indexes += index + 1
            guard value.count >= index+1 else { return nil }
            value = Array(value[index+1..<value.count])
        }
        return indexes - 1
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
        for i in 0..<self.count {
            for ii in i..<self.count {
                guard self[i] == self[ii] else { continue }
                guard ii+(ii-i) <= self.count else { continue }
                guard self[i..<ii] == self[ii..<ii+(ii-i)] else { continue }
                if !Array(self[i..<ii]).isEmpty { possibleElements.append(Array(self[i..<ii])) }
            }
        }
        
        for i in possibleElements {
            let leadingItems = self.firstIndex(of: i)!.first!
            let endingItems = (self.count - leadingItems) % i.count
            
            var content = self
            while content.contains(i) { content.removeSubrange(content.firstIndex(of: i)!) }
            if content.count == leadingItems + endingItems && content[content.count - endingItems..<content.count] == i[0..<endingItems] { return i }
        }
        
        return nil
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
    func firstIndex(of sequence: [Element]) -> Range<Index>? where Element: Equatable {
        guard !sequence.isEmpty else { return nil }
        guard sequence.count != 1 else { return Range(self.firstIndex(of: sequence.first!)!...self.firstIndex(of: sequence.first!)!) }
        
        for i in 1..<self.count {
            guard let index = self.findIndex(sequence.first!, occurrence: i) else { return nil }
            guard index+sequence.count <= self.count else { return nil }
            if Array(self[index..<index+sequence.count]) == sequence { return index..<index+sequence.count }
        }
        
        return nil
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
        var content: Array = []
        for i in self { if !content.contains(i) { content.append(i) } }
        for i in rhs { if !content.contains(i) { content.append(i) } }
        
        return content
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
        var content: Array = []
        for i in self { if rhs.contains(i) { content.append(i) } }
        return content
    }
    
    /// Removes the repeated elements of an array, leaving only the entries different from each other.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3, 1].removingRepeatedElements())
    ///     // prints "[1, 2, 3]"
    ///
    /// - Returns: The array without repeated elements.
    func removingRepeatedElements() -> Self where Element: Equatable {
        var content: Self = []
        for i in self { if !content.contains(i) { content.append(i) } }
        return content
    }
    
    /// Removes the repeated elements of an array, leaving only the entries different from each other.
    ///
    /// **Example**
    ///
    ///     print([1, 2, 3, 1].removingRepeatedElements(==))
    ///     // prints "[1, 2, 3]"
    ///
    /// - Parameters:
    ///    - condition: Determine whether two values are equation
    ///
    /// - Returns: The array without repeated elements.
    func removingRepeatedElements(by condition: ((_ value1: Element, _ value2: Element) -> Bool)) -> Self {
        var content: Self = []
        for i in self {
            if content.allSatisfy({ !condition($0, i) }) {
                content.append(i)
            }
        }
        return content
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
    
    /// The standard derivation of this array.
    func standardDerivation() -> Element where Element == Fraction {
        if self.allSatisfy({ $0 == self.first }) { return 0 }
        let result = self.map({ ($0 - self.average()) * ($0 - self.average()) }).reduce(Element(0), +)
        return Element(sqrt((1 / Element(self.count)) * result))
    }
    
    /// The standard derivation of this array.
    func standardDerivation() -> Element where Element == Double {
        if self.allSatisfy({ $0 == self.first }) { return 0 }
        let result = self.map({ ($0 - self.average()) * ($0 - self.average()) }).reduce(Element(0), +)
        return Element(sqrt((1 / Element(self.count)) * result))
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
        return Self(Int(self)) == self
    }
    
    /// Returns the scientific expression.
    ///
    /// **Example**
    ///
    ///     print(314159.2.expressedAsScientific())
    ///     // prints "(3.141592, 5)"
    ///
    /// - Returns:
    ///   `value `  The coefficient of c\*10^n.
    ///
    ///   `power `  The power of c\*10^n.
    func expressedAsScientific() -> (value: Self, power: Int) {
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
        if self < Self(pow(60.0, 3))*24 { return String(format: "%.3gdays", Double(self) / pow(60.0, 3)) }
        if self < Self(pow(60.0, 3))*24*365 { return String(format: "%.3gyrs", Double(self) / pow(60.0, 3)*24) }
        if self < Self(pow(60.0, 3))*24*365*100 { return String(format: "%.3gcentries", Double(self) / pow(60.0, 3)*24*365) }
        return String(format: "%gs", Double(self).rounded())
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

extension CGRect {
    
    /// Creates an instance with the center point and the size of `CGRect`.
    ///
    /// - Parameters:
    ///     - center: The center point.
    ///     - size: The size of the `CGRect`.
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x-size.width/2, y: center.y-size.height/2, width: size.width, height: size.height)
    }
    
    /// Calculates the distance between the center points of two `CGRect`s.
    ///
    /// - Parameters:
    ///     - rhs: Another `CGRect`.
    ///
    /// - Returns: The distance between their center points.
    func distance(to rhs: CGRect) -> CGFloat {
        let deltaX = rhs.origin.x - self.origin.x
        let deltaY = rhs.origin.y - self.origin.y
        return sqrt(pow(deltaX, 2) + pow(deltaY, 2))
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
}

extension Int {
    
    /// Initialize with a `Character`.
    init?(_ value: Character) {
        self.init(String(value))
    }
}

extension NSImage {
    
    /// The image in the form of its colors.
    var colorMatrix: [[NSColor]]? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let representation = NSBitmapImageRep(cgImage: cgImage)
        var matrix: [[NSColor]] = []
        for i in 0..<Int(representation.size.height) {
            var vector: [NSColor] = []
            for ii in 0..<Int(representation.size.width) {
                vector.append(representation.colorAt(x: ii, y: i)!)
            }
            matrix.append(vector)
        }
        return matrix
    }
    
    /// Determines whether the `NSImage` is in mono color.
    var isMonoColor: Bool {
        let image = self
        let imageRef = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let colorSpace = imageRef?.colorSpace
        if colorSpace?.model == .rgb {
            let rawData = image.tiffRepresentation
            let width = imageRef!.width
            let height = imageRef!.height
            let threshold = 0.001
            
            var fourthCharacter: [Int] = []
            
            for _ in 0...0 {
                var byteIndex = 0
                for _ in 0...Int(width*height)/800 {
                    fourthCharacter.append(Int(rawData![byteIndex+3]))
                    byteIndex += 2400
                }
            }
            
            if fourthCharacter.filter({$0 != 255 && $0 != 0}).isEmpty {
                // (R, G, B, ?)
                var colorPixelsCounter = 0
                var byteIndex = 0
                for _ in 0...Int(width*height)/10 {
                    let red = rawData![byteIndex]
                    let green = rawData![byteIndex + 1]
                    let blue = rawData![byteIndex + 2]
                    if !proximateEqual(lhs: Int(red), rhs: Int(blue), threshold: 2) && !proximateEqual(lhs: Int(red), rhs: Int(green), threshold: 2) {
                        colorPixelsCounter += 1
                        if Double(colorPixelsCounter) / Double(width*height/10) >= threshold {
                            return false
                        }
                    }
                    byteIndex += 40
                }
            } else {
                // (R, G, B)
                var colorPixelsCounter = 0
                var byteIndex = 0
                for _ in 0...Int(width*height)/10 {
                    let red = rawData![byteIndex]
                    let green = rawData![byteIndex + 1]
                    let blue = rawData![byteIndex + 2]
                    if !proximateEqual(lhs: Int(red), rhs: Int(blue), threshold: 2) && !proximateEqual(lhs: Int(red), rhs: Int(green), threshold: 2) {
                        colorPixelsCounter += 1
                        if Double(colorPixelsCounter) / Double(width*height/10) >= threshold {
                            return false
                        }
                    }
                    byteIndex += 30
                }
            }
            
            return true
        } else {
            return true
        }
    }
    
    /// Determines whether the `NSImage` is in full color.
    var isFullColor: Bool {
        return !isMonoColor
    }
    
    convenience init?(sizeFromImage: NSImage, colorMatrix: [[NSColor]]) {
        guard let cgImage = sizeFromImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let representation = NSBitmapImageRep(cgImage: cgImage)
        for i in 0..<Int(representation.size.height) {
            for ii in 0..<Int(representation.size.width) {
                representation.setColor(colorMatrix[i][ii], atX: ii, y: i)
            }
        }
        guard let cgImage = representation.cgImage else { return nil }
        self.init(cgImage: cgImage, size: sizeFromImage.size)
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
    
    /// Write a `NSImage` to the path.
    ///
    /// - Parameters:
    ///   - path: The path to save the image.
    func write(to path: String) {
        guard let data = tiffRepresentation,
              let rep = NSBitmapImageRep(data: data),
              let imageData = rep.representation(using: .png, properties: [:]) else { print("failed to write image to \(path)"); return }
        
        try! imageData.write(to: URL(fileURLWithPath: path, isDirectory: false))
    }
}

extension NSView {
    
    /// The `NSImage` representation of the view.
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
    
    /// Determine whether a string is an English word.
    var isWord: Bool {
        let dictionary = try! FinderItem.loadJSON(from: "/Users/vaida/Data Base/Static/dictionary.json", type: [String: String].self)
        guard !self.contains(" ") else { return false }
        return dictionary.keys.contains(self)
    }
    
    
    /// Extracts digits from a `String`.
    ///
    /// **Example**
    ///
    ///     print("a0123.hi12".extractDigits())
    ///     // prints "(values: [123, 12], indexes: [Range(1..<5), Range(8..<10)])"
    ///
    /// - Returns:
    ///   `values `     The numbers inside the `String`;
    ///   `indexes `    The indexes of these numbers.
    func extractDigits() -> (values: [Int], indexes: [Range<Int>]) {
        let content = self + "a"
        
        var values: [Int] = []
        var indexes: [Range<Int>] = []
        var index: [Int] = []
        var isDigit = false
        
        for i in 0..<content.count {
            if (Int(String([Character](content)[i])) != nil) != isDigit {
                isDigit.toggle()
                index.append(i)
            }
        }
        
        for i in 0..<index.count / 2 {
            let i = i * 2
            indexes.append(index[i]..<index[i+1])
            values.append(Int(String([Character](content)[index[i]..<index[i+1]]))!)
        }
        
        return (values, indexes)
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
}


//MARK: - Supporting Functions

/// Prints a `[[String]]` nicely.
///
/// - Important: `space` is auto-generated content, do not fill.
///
/// - Parameters:
///    - list: The list to be printed.
///    - space: Auto generated content.
func printMatrix<T>(matrix: [[T]], transpose: Bool = false, includeIndex: Bool = false, space: [Int] = []) where T: CustomStringConvertible {
    guard matrix.count > 1 else { print(matrix.first ?? ""); return }
    
    if transpose {
        var newMatrix: [[String]] = [[String]](repeating: [String](repeating: "", count: matrix.count), count: matrix.first!.count)
        for i in 0..<matrix.count {
            for ii in 0..<matrix.first!.count {
                newMatrix[ii][i] = matrix[i][ii].description
            }
        }
        return printMatrix(matrix: newMatrix, includeIndex: includeIndex)
    }
    
    if includeIndex {
        var newMatrix: [[String]] = [[String]](repeating: [String](repeating: "", count: matrix.count), count: matrix.first!.count)
        for i in 0..<matrix.count {
            for ii in 0..<matrix.first!.count {
                newMatrix[ii][i] = matrix[i][ii].description
            }
        }
        newMatrix.insert([Int](0..<matrix.count).map{ $0.description }, at: 0)
        
        return printMatrix(matrix: newMatrix, transpose: true)
    }
    
    var space1: [Int] = space
    while space1.count != matrix.last!.count { space1.append(0) }
    
    for i in matrix {
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
    
    for item in matrix {
        var content = ""
        
        var currentItem = 0
        while currentItem != item.count {
            content += item[currentItem].description
            while content.count < space1[currentItem] { content += " " }
            currentItem += 1
        }
        print(content)
    }
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

/// Asks for user input.
///
/// **Example**
///
///     let _ = input("Please enter")
///     // prints "Please enter: "
///
/// - Note: Pass `content` with `""` to prevent displaying anything.
///
/// - Attention: The return value is `nil` if the user input cannot be interpreted as `Float`.
///
/// - Parameters:
///     - content: The content to be displayed.
///
/// - Returns: The `Float` version of user input; `nil` otherwise.
func input<T>(_ content: String) -> T? where T: BinaryFloatingPoint {
    if !content.isEmpty { print("\(content): ", terminator: "") }
    guard let input = Double(readLine()!) else { fatalError("Error in \(content)") }
    return T(input)
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
/// - Attention: The return value is `nil` if the user input cannot be interpreted as `Int`.
///
/// - Parameters:
///     - content: The content to be displayed.
///
/// - Returns: The `Int` version of user input; `nil` otherwise.
func input(_ content: String) -> Int? {
    if !content.isEmpty { print("\(content): ", terminator: "") }
    guard let input = Int(readLine()!) else { fatalError("Error in \(content)") }
    return input
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
/// - Attention: The return value is `nil` if the user input cannot be interpreted as `[Double]`.
///
/// - Parameters:
///     - content: The content to be displayed.
///
/// - Returns: The `[Double]` version of user input; `nil` otherwise.

func input(_ content: String) -> [Double]? {
    if !content.isEmpty { print("\(content): ", terminator: "") }
    guard let input = readLine() else { fatalError("Error in \(content)") }
    return input.replacingOccurrences(of: " ", with: "").split(separator: ",").map{Double($0)!}
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
func solve<T>(_ lhs: (_ x: T)-> T, _ rhs: T = 0) -> T? where T: BinaryFloatingPoint {
    let delta = T(0.0000000001)
    
    func f(_ x: T) -> T {
        return lhs(x) - rhs
    }
    
    func derivative(at x: T, delta: T = delta) -> T? {
        let content = (f(x+delta) - f(x)) / delta
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
            return x_n - (f(x_n))/(value)
        } else {
            guard !initialValues.isEmpty else { return nil }
            x_n = initialValues.removeFirst()
            return mutateX_n1()
        }
    }
    
    let date = Date()
    var initialValues: [T] = [-1, -10, -100, 1, 10, 100]
    var x_n = initialValues.removeFirst()
    var x_n1 = x_n - (f(x_n))/(derivative(at: x_n) ?? 1)
    
    while abs(x_n1 - x_n) >= delta {
        guard abs(x_n) < T(pow(10.0, 50.0)) else { print("Failed to solve: answer exceeds 10^50"); return nil }
        x_n = x_n1
        guard let value = mutateX_n1() else { return nil }
        x_n1 = value
        
        if date.distance(to: Date()) > 2 { print("Failed to solve: spent more than 2 seconds"); return nil }
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
func shell(_ commands: [String]) -> String? {
    let task = Process()
    let pipe = Pipe()
    let command = commands.reduce("", { $0 + "\n" + $1})
    
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

