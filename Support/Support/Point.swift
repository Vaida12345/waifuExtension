//
//  Point.swift
//  cmd
//
//  Created by Vaida on 10/17/21.
//

import Foundation

/// A 2D point.
struct Point: Equatable, CustomStringConvertible, LosslessStringConvertible, Comparable, Codable, Hashable {
    
    
    //MARK: - Type Alias
    typealias FloatingPoint = Fraction
    
    
    //MARK: - Basic Properties
    
    var x: FloatingPoint
    var y: FloatingPoint
    
    
    //MARK: - Instance Properties
    
    var cgPoint: CGPoint {
        return CGPoint(x: Double(self.x), y: Double(self.y))
    }
    
    var description: String {
        return "(\(self.x), \(self.y))"
    }
    
    /// Returns a dictionary representation of the specified point.
    var dictionaryRepresentation: [FloatingPoint: FloatingPoint] {
        return [self.x: self.y]
    }
    
    var tuple: (x: FloatingPoint, y: FloatingPoint) {
        return (x, y)
    }
    
    var vector: [Fraction] {
        return [Fraction(x), Fraction(y)]
    }
    
    
    //MARK: - Type Properties
    
    static var zero: Point {
        return Point(x: 0, y: 0)
    }
    
    
    //MARK: - Initialzier
    
    init<T>(x: T, y: T) where T: BinaryFloatingPoint {
        self.x = FloatingPoint(x)
        self.y = FloatingPoint(y)
    }
    
    init<T>(x: T, y: T) where T: BinaryInteger {
        self.x = FloatingPoint(x)
        self.y = FloatingPoint(y)
    }
    
    init<T>(_ x: T, _ y: T) where T: BinaryFloatingPoint {
        self.x = FloatingPoint(x)
        self.y = FloatingPoint(y)
    }
    
    init<T>(_ x: T, _ y: T) where T: BinaryInteger {
        self.x = FloatingPoint(x)
        self.y = FloatingPoint(y)
    }
    
    init<T>(_ value: (x: T, y: T)) where T: BinaryFloatingPoint {
        self.x = FloatingPoint(value.x)
        self.y = FloatingPoint(value.y)
    }
    
    init<T>(_ value: (x: T, y: T)) where T: BinaryInteger {
        self.x = FloatingPoint(value.x)
        self.y = FloatingPoint(value.y)
    }
    
    init(from cgPoint: CGPoint) {
        self.x = FloatingPoint(cgPoint.x)
        self.y = FloatingPoint(cgPoint.y)
    }
    
    /// Creates a point from a canonical dictionary representation.
    init?(from dictionary: [FloatingPoint: FloatingPoint]) {
        guard dictionary.count == 1 else { return nil }
        self.x = dictionary.first!.key
        self.y = dictionary.first!.value
    }
    
    init?(from vector: Vector) {
        guard vector.count == 2 else { return nil }
        self.x = FloatingPoint(vector.first!)
        self.y = FloatingPoint(vector.last!)
    }
    
    init?(_ description: String) {
        if description.filter({ $0 == "/"}).count == 2 {
            let result = description.extractDigits()
            guard result.values.count == 4 else { return nil }
            self.x = FloatingPoint(result.values.first!) / FloatingPoint(result.values[1])
            self.y = FloatingPoint(result.values[2]) / FloatingPoint(result.values.last!)
        } else {
            let result = description.extractDigits()
            guard result.values.count == 2 else { return nil }
            self.x = FloatingPoint(result.values.first!)
            self.y = FloatingPoint(result.values.last!)
        }
    }
    
    
    //MARK: - Instance Methods
    
    /// Returns the point resulting from an affine transformation of an existing point.
    func applying(_ t: CGAffineTransform) -> Point {
        let cgPoint = self.cgPoint.applying(t)
        return Point(from: cgPoint)
    }
    
    /// Calculates the distance between two points.
    func distance(to other: Point) -> FloatingPoint {
        let x = self.x - other.x
        let y = self.y - other.y
        return sqrt(pow(x, 2) + pow(y, 2))
    }
    
    func transformed(by linearTransformation: LinearTransformation) -> Point {
        let vector = linearTransformation.transform(vector: self.vector)
        return Point(from: vector)!
    }
    
    
    //MARK: - Operator Functions
    
    static func == (_ lhs: Point, _ rhs: Point) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    /// This method compares the point's distance to the origin.
    static func < (_ lhs: Point, _ rhs: Point) -> Bool {
        return lhs.x * lhs.x + lhs.y * lhs.y < rhs.x * rhs.x + rhs.y * rhs.y
    }
}
