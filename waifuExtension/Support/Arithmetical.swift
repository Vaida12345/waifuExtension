//
//  Arithmetical.swift
//
//
//  Created by Vaida on 10/25/21.
//  Copyright © 2022 Vaida. All rights reserved.
//

import Foundation

protocol Arithmetical: Codable, Comparable, ExpressibleByIntegerLiteral, Hashable, LosslessStringConvertible {
    
    associatedtype Magnitude
    
    //MARK: - Instance Properties
    
    /// The absolute value of this instance.
    var magnitude: Self.Magnitude { get }
    
    
    //MARK: - Type Properties
    
    /// The instance representing `zero`.
    static var zero: Self { get }
    
    
    //MARK: - Initializers
    
    /// Creates an instance with an `BinaryInteger`.
    init<T>(_ value: T) where T: BinaryInteger
    
    
    //MARK: - Operator Functions
    
    /// Addition of two instances.
    static func + (_ lhs: Self, _ rhs: Self) -> Self
    
    /// Addition of two instances, and stores in `lhs`.
    static func += (_ lhs: inout Self, _ rhs: Self)
    
    /// Subtraction of two instances.
    static func - (_ lhs: Self, _ rhs: Self) -> Self
    
    /// Subtraction of two instances, and stores in `lhs`.
    static func -= (_ lhs: inout Self, _ rhs: Self)
    
    /// Multiplication of two instances.
    static func * (_ lhs: Self, _ rhs: Self) -> Self
    
    /// Multiplication of two instances, and stores in `lhs`.
    static func *= (_ lhs: inout Self, _ rhs: Self)
    
    /// Division of two instances.
    static func / (_ lhs: Self, _ rhs: Self) -> Self
    
    /// Division of two instances, and stores in `lhs`.
    static func /= (_ lhs: inout Self, _ rhs: Self)
    
    
    //MARK: - Comparison Methods
    
    /// Determines whether the `lhs` is less than the `rhs`.
    static func < (_ lhs: Self, _ rhs: Self) -> Bool
    
    /// Determines whether the `lhs` is equal to the `rhs`.
    static func == (_ lhs: Self, _ rhs: Self) -> Bool
}

extension UInt8: Arithmetical { }
extension UInt16: Arithmetical { }
extension UInt32: Arithmetical { }
extension UInt64: Arithmetical { }

extension Int8: Arithmetical { }
extension Int16: Arithmetical { }
extension Int32: Arithmetical { }
extension Int64: Arithmetical { }

extension Float32: Arithmetical { }
extension Float64: Arithmetical { }
