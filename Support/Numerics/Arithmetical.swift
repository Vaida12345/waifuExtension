//
//  Arithmetical.swift
//  cmd
//
//  Created by Vaida on 10/25/21.
//

import Foundation

protocol Arithmetical: Codable, Comparable, ExpressibleByIntegerLiteral, Hashable, LosslessStringConvertible {
    
    
    //MARK: - Instance Properties
    
    /// The absolute value of this instance.
    var magnitude: Self { get }
    
    
    //MARK: - Type Properties
    
    /// The instance representing `zero`.
    static var zero: Self { get }
    
    /// Determines whether the value is signed.
    static var isSigned: Bool { get }
    
    
    //MARK: - Initializers
    
    /// Creates an instance with an `BinaryInteger`.
    init<T>(_ value: T) where T: BinaryInteger
    
    
    //MARK: - Operator Functions
    
    /// Addition of two instances.
    static func + (_ lhs: Self, _ rhs: Self) -> Self
    
    /// Addition of two instances, , and stores in `lhs`.
    static func += (_ lhs: inout Self, _ rhs: Self)
    
    /// Subtraction of two instances.
    static func - (_ lhs: Self, _ rhs: Self) -> Self
    
    /// Subtraction of two instances, , and stores in `lhs`.
    static func -= (_ lhs: inout Self, _ rhs: Self)
    
    /// Multiplication of two instances.
    static func * (_ lhs: Self, _ rhs: Self) -> Self
    
    /// Multiplication of two instances, , and stores in `lhs`.
    static func *= (_ lhs: inout Self, _ rhs: Self)
    
    /// Division of two instances.
    static func / (_ lhs: Self, _ rhs: Self) -> Self
    
    /// Division of two instances, , and stores in `lhs`.
    static func /= (_ lhs: inout Self, _ rhs: Self)
    
    
    //MARK: - Comparison Methods
    
    /// Determines whether the `lhs` is less than the `rhs`.
    static func < (_ lhs: Self, _ rhs: Self) -> Bool
    
    /// Determines whether the `lhs` is equal to the `rhs`.
    static func == (_ lhs: Self, _ rhs: Self) -> Bool
}

protocol SignedArithmetical: Arithmetical {
    
    //MARK: - Instance Methods
    
    /// Returns the value with same magnitude, but different sign.
    func opposite() -> Self
}

extension Int: Arithmetical {
    
    var magnitude: Int {
        return abs(self)
    }
    
}

extension Double: Arithmetical {
    
    static var isSigned: Bool {
        return true
    }
    
}

extension SignedArithmetical {
    
    /// Assign the sign to the value.
    ///
    /// `1 -> " + 1"`
    func assignedSign(negative: Bool = false) -> String {
        if negative { return (self).opposite().assignedSign() }
        if self >= Self.zero {
            return " + \(self.magnitude)"
        } else {
            return " - \(self.magnitude)"
        }
    }
}

/// Returns the magnitude of this instance.
func abs<T>(_ value: T) -> T where T: Arithmetical {
    return value.magnitude
}
