//
//  Algebra.swift
//
//
//  Created by Vaida on 9/13/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation

//MARK: - AlgebraTerm

/// Each individual term in the algebra.
///
/// Terms are defined in the form of  c
///
/// Examples:
///
///     let one = Term(coefficient: 1, base: "", power: 0)
///     // This defines one as 1 * "" ^ 0, which is 1.
///
///     let x = Term(coefficient: 1, base: "x", power: 1)
///     // This defines x as 1 * "x" ^ 1, which is x.
struct AlgebraTerm: Equatable, CustomStringConvertible, Hashable, Comparable {
    
    /// The coefficient of the term.
    ///
    /// Terms are defined in the form of `coefficient * base1 ^ power1 * base2 ^ power2 * ...`.
    var coefficient: Fraction
    
    /// The base of the term.
    ///
    /// Terms are defined in the form o `coefficient * base1 ^ power1 * base2 ^ power2 * ...`.
    var bases: [String]
    
    /// The power of the term.
    ///
    /// Terms are defined in the form of `coefficient * base1 ^ power1 * base2 ^ power2 * ...`.
    var powers: [Fraction]
    
    /// Determine whether this term is a value.
    ///
    /// It is a value if all powers are `zero`, where term is defined as `coefficient * base1 ^ power1 * base2 ^ power2 * ...`.
    var isValue: Bool {
        guard !powers.isEmpty else { return true }
        return powers.allSatisfy({ $0 == 0 })
    }
    
    /// Determine whether this term is a variable.
    ///
    /// It is a variable if at least one power is not `zero`, where term is defined as `coefficient * base1 ^ power1 * base2 ^ power2 * ...`.
    var isVariable: Bool {
        return !isValue
    }
    
    /// The description of this term.
    var description: String {
        if self.isValue {
            return self.coefficient.description
        } else {
            var content = ""
            
            if self.coefficient.sign == .minus { content += "-" }
            if abs(self.coefficient) != 1 { content += self.coefficient.description }
            
            for i in 0..<self.bases.count {
                content += self.bases[i]
                
                if self.powers[i] != 1 && self.powers[i].sign == .plus {
                    content += "^\(self.powers[i])"
                } else if self.powers[i] != 1 && self.powers[i].sign == .minus {
                    content += "^(\(self.powers[i]))"
                }
                
                if i != self.bases.count - 1 {
                    content += "*"
                }
            }
            
            return content
        }
    }
    
    /// Initialize a term.
    ///
    /// Terms are defined in the form of  `coefficient * base1 ^ power1 * base2 ^ power2 * ...`.
    ///
    /// Examples:
    ///
    ///     let one = AlgebraTerm(coefficient: 1, base: "", power: 0)
    ///     // This defines one as 1 * "" ^ 0, which is 1.
    ///
    ///     let x = AlgebraTerm(coefficient: 1, base: "x", power: 1)
    ///     // This defines x as 1 * "x" ^ 1, which is x.
    init(coefficient: Fraction, base: String, power: Fraction) {
        self.coefficient = coefficient
        self.bases = [base]
        self.powers = [power]
    }
    
    /// Initialize a term.
    ///
    /// Terms are defined in the form of coefficient * base ^ power
    fileprivate init(coefficient: Fraction, bases: [String], powers: [Fraction]) {
        self.coefficient = coefficient
        self.bases = bases
        self.powers = powers
    }
    
    /// Initialize a constant term.
    ///
    /// Terms are defined in the form of coefficient * base ^ power
    ///
    /// Examples:
    ///
    ///     let one = AlgebraTerm(1)
    ///     // This defines one as 1 * "" ^ 0, which is 1.
    init(_ value: Fraction) {
        self.coefficient = value
        self.bases = []
        self.powers = []
    }
    
    /// Initialize a variable term.
    ///
    /// Terms are defined in the form of coefficient * base ^ power
    ///
    /// Examples:
    ///
    ///     let x = AlgebraTerm("x")
    ///     // This defines x as 1 * "x" ^ 1, which is x.
    init(_ variableName: String) {
        self.coefficient = 1
        self.bases = [variableName]
        self.powers = [1]
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: AlgebraTerm, rhs: AlgebraTerm) -> AlgebraTerm {
        var variableNames: [String: Fraction] = [:]
        
        var content = lhs
        content.bases.append(contentsOf: rhs.bases)
        content.powers.append(contentsOf: rhs.powers)
        
        for i in 0..<content.bases.count {
            if !variableNames.keys.contains(content.bases[i]) {
                variableNames[content.bases[i]] = content.powers[i]
            } else {
                variableNames[content.bases[i]]! += content.powers[i]
            }
        }
        
        return AlgebraTerm(coefficient: lhs.coefficient * rhs.coefficient, bases: [String](variableNames.keys), powers: [Fraction](variableNames.values))
    }
    
    /// Returns the quotient of dividing the first value by the second.
    ///
    /// - Parameters:
    ///   - lhs: The value to divide.
    ///   - rhs: The value to divide `lhs` by.
    static func / (lhs: AlgebraTerm, rhs: AlgebraTerm) -> AlgebraTerm {
        return lhs * pow(rhs, -1)
    }
    
    /// Determine whether the lhs is less than the rhs.
    ///
    /// If lhs and rhs has the same bases and powers, the coefficients are compared.
    /// If their sum of powers are the same, their alphabetic sum of variables are compared.
    /// Otherwise the sum of their powers are compared.
    ///
    /// - Parameters:
    ///   - lhs: The first value to compare.
    ///   - rhs: The second value to compare.
    static func < (lhs: AlgebraTerm, rhs: AlgebraTerm) -> Bool {
        if lhs.bases == rhs.bases && lhs.powers == rhs.powers {
            return lhs.coefficient < rhs.coefficient
        } else if lhs.powers.reduce(0, +) == rhs.powers.reduce(0, +) {
            return lhs.bases.map({ alphabet.firstIndex(of: $0)! }).reduce(0, +) < rhs.bases.map({ alphabet.firstIndex(of: $0)! }).reduce(0, +)
        } else {
            return lhs.powers.reduce(0, +) < rhs.powers.reduce(0, +)
        }
    }
}

func pow(_ lhs: AlgebraTerm, _ rhs: Fraction) -> AlgebraTerm {
    return AlgebraTerm(coefficient: pow(lhs.coefficient, rhs), bases: lhs.bases, powers: lhs.powers.map({ pow($0, rhs) }))
}

func abs(_ value: AlgebraTerm) -> AlgebraTerm {
    return AlgebraTerm(coefficient: abs(value.coefficient), bases: value.bases, powers: value.powers)
}

//MARK: - Algebra

/// A linear Algebra.
typealias Algebra = [AlgebraTerm]

extension Algebra {
    
    /// Initialize algebra with its terms.
    init(_ terms: [AlgebraTerm]) {
        self = terms.sorted()
    }
    
    /// Initialize with a Polynomial.
    ///
    /// This is not the designed initializer.
    init(from polynomial: Polynomial) {
        var term: [AlgebraTerm] = []
        for i in 0..<polynomial.degreeList.count-1 {
            term.append(AlgebraTerm(coefficient: polynomial.coefficients[i], base: "x", power: Fraction(polynomial.degreeList[i])))
        }
        term.append(AlgebraTerm(polynomial.constantTerm))
        self = term
    }
    
    /// Adds two algebra expressions and produces their sum.
    ///
    /// The addition operator (`+`) calculates the sum of its two arguments.
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    static func + (lhs: Algebra, rhs: Algebra) -> Algebra {
        var content = lhs
        content.append(contentsOf: rhs)
        return content.reduced()
    }
    
    /// Adds two values and stores the result in the left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    static func += (lhs: inout Algebra, rhs: Algebra) {
        lhs = (lhs + rhs).sorted()
    }
    
    /// Subtracts one value from another and produces their difference.
    ///
    /// The subtraction operator (`-`) calculates the difference of its two arguments.
    ///
    /// - Parameters:
    ///   - lhs: A numeric value.
    ///   - rhs: The value to subtract from `lhs`.
    static func - (lhs: Algebra, rhs: Algebra) -> Algebra {
        return (lhs + (AlgebraTerm(-1) * rhs )).sorted()
    }
    
    /// Subtracts one value from another and stores the result in the left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: A numeric value.
    ///   - rhs: The value to subtract from `lhs`.
    static func -= (lhs: inout Algebra, rhs: Algebra) {
        lhs = (lhs - rhs).sorted()
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: AlgebraTerm, rhs: Algebra) -> Algebra {
        return rhs.map({ $0 * lhs }).sorted()
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: Algebra, rhs: AlgebraTerm) -> Algebra {
        return lhs.map({ $0 * rhs }).sorted()
    }
    
    /// Multiplies two values and stores the result in the left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func *= (lhs: inout Algebra, rhs: AlgebraTerm) {
        lhs = (lhs * rhs).sorted()
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: Algebra, rhs: Algebra) -> Algebra {
        var value = Algebra()
        for i in lhs { value += rhs * i }
        return value.sorted()
    }
    
    /// Multiplies two values and stores the result in the left-hand-side variable.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func *= (lhs: inout Algebra, rhs: Algebra) {
        lhs = (lhs * rhs).sorted()
    }
    
    /// Returns the quotient of dividing the first value by the second.
    ///
    /// - Parameters:
    ///   - lhs: The value to divide.
    ///   - rhs: The value to divide `lhs` by.
    static func / (lhs: Algebra, rhs: AlgebraTerm) -> Algebra {
        return lhs.map({ $0 / rhs }).sorted()
    }
    
    /// Calculate the quotient of dividing the first value by the second and stores the result in the left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: The value to divide.
    ///   - rhs: The value to divide `lhs` by.
    static func /= (lhs: inout Algebra, rhs: AlgebraTerm) {
        lhs = (lhs / rhs).sorted()
    }
    
    /// Reduced an algebra to a nicer form.
    ///
    /// It transforms:
    ///
    ///     [0, 2x, -x, x^2] -> [0, x, x^2]
    func reduced() -> Algebra {
        var dictionary: [AlgebraTerm: Fraction] = [:]
        
        for i in self {
            if !dictionary.keys.contains(AlgebraTerm(coefficient: 0, bases: i.bases, powers: i.powers)) {
                dictionary[AlgebraTerm(coefficient: 0, bases: i.bases, powers: i.powers)] = i.coefficient
            } else {
                dictionary[AlgebraTerm(coefficient: 0, bases: i.bases, powers: i.powers)]! += i.coefficient
            }
        }
        
        var algebra = Algebra()
        for i in dictionary {
            algebra.append(AlgebraTerm(coefficient: i.value, bases: i.key.bases, powers: i.key.powers))
        }
        
        return algebra.sorted()
    }
}
