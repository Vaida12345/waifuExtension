//
//  Expression.swift
//
//
//  Created by Vaida on 9/13/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

/*
import Foundation

/// Do not use until further notice.
class Expression: CustomStringConvertible {
    
    struct Item: CustomStringConvertible {
        /// The real part of this `Item`.
        var value: Fraction?
        
        /// The name of the variable. This explicitly suggests that this Item is a variable.
        var variable: String?
        
        /// The imaginary part of this `Item`.
        var imaginary: Fraction?
        
        /// Determine whether this `Item` is a value.
        ///
        /// If `true`, `isVariable` would be `false`.
        var isValue: Bool {
            return value != nil
        }
        
        /// Determine whether this `Item` belongs to `C`.
        ///
        /// If `true`, `isVariable` would be `false`.
        var isImaginary: Bool {
            return imaginary != nil
        }
        
        /// Determine whether this `Item` is a variable.
        ///
        /// If `true`, `isValue` and `isImaginary` would be `false`.
        var isVariable: Bool {
            return variable != nil
        }
        
        /// This description of this `Item`.
        var description: String {
            if self.isValue {
                return self.value!.description
            } else if self.isImaginary {
                return "\(self.value!) + \(self.imaginary!)i"
            } else {
                return variable!
            }
        }
        
        /// Initialize a real `Item` with a fraction.
        ///
        /// - Parameters:
        ///     - value: The value of the real part of the `Item`.
        init(value: Fraction) {
            self.value = value
        }
        
        /// Initialize a variable with its name.
        ///
        /// - Parameters:
        ///     - name: The name of the variable.
        init(variable name: String) {
            self.variable = name
        }
        
        /// Initialize an imaginary `Item`.
        ///
        /// - Parameters:
        ///     - real: The value of the real part of the `Item`.
        ///     - imaginary: The value of the imaginary part of the `Item`.
        init(real: Fraction, imaginary: Fraction) {
            self.value = real
            self.imaginary = imaginary
        }
        
        /// Addition, does not take variable into account.
        static func + (_ lhs: Item, _ rhs: Item) -> Item {
            if lhs.isImaginary || rhs.isImaginary {
                return Item(real: (lhs.value ?? 0) + (rhs.value ?? 0), imaginary: (lhs.imaginary ?? 0) + (rhs.imaginary ?? 0))
            } else {
                return Item(value: (lhs.value ?? 0) + (rhs.value ?? 0))
            }
        }
    }
    
    enum Operation: String {
        
        /// The addition "+" of two `Expression`s.
        case addition = "+"
        
        /// The subtraction "-" of two `Expression`s.
        case subtraction = "-"
        
        /// The multiplication "*" of two `Expression`s.
        case multiplication = "*"
        
        /// The division "÷" of two `Expression`s.
        case division = "÷"
    }
    
    /// The lhs `Expression`.
    var lhs: Expression?
    
    /// The operation to be done to lhs and rhs.
    var operation: Operation?
    
    /// The rhs `Expression`.
    var rhs: Expression?
    
    /// If it is not an expression, this is the value.
    var value: Item?
    
    /// Determine whether this `Expression` is an expression.
    ///
    /// If `true`, `isValue` would be `false`.
    var isExpression: Bool {
        return lhs != nil  && operation != nil && rhs != nil
    }
    
    /// Determine whether this `Expression` is a value.
    ///
    /// If `true`, `isExpression` would be `false`.
    var isValue: Bool {
        return value != nil
    }
    
    /// This description of this `Expression`.
    var description: String {
        if self.isValue {
            return value!.description
        } else {
            return "(\(self.lhs!.description) \(operation!.rawValue) \(self.rhs!.description))"
        }
    }
    
    /// Initialize an expression with two `Expression`s and a `Operation`.
    init(_ lhs: Expression, _ operation: Operation, _ rhs: Expression) {
        self.lhs = lhs
        self.operation = operation
        self.rhs = rhs
    }
    
    /// Initialize a value with the `Item` provided.
    init(_ value: Item) {
        self.value = value
    }
    
    /// Addition
    static func + (_ lhs: Expression, _ rhs: Expression) -> Expression {
        return Expression(lhs, .addition, rhs)
    }
    
    /// Calculate the expression as far as possible
    func calculate() -> Expression {
        if self.isValue {
            return self
        } else {
            if lhs!.isValue && rhs!.isValue {
                guard !self.lhs!.value!.isVariable && !self.rhs!.value!.isVariable else { return self }
                switch self.operation {
                case .addition:
                    return Expression(self.lhs!.value! + self.rhs!.value!)
                default:
                    fatalError()
                }
            } else if lhs!.isExpression && rhs!.isValue {
                return Expression(lhs!.calculate(), self.operation!, rhs!)
            } else if lhs!.isValue && rhs!.isExpression {
                return Expression(lhs!, self.operation!, rhs!.calculate())
            } else {
                return Expression(lhs!.calculate(), self.operation!, rhs!.calculate())
            }
        }
    }
}

 */
