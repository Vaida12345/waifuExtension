//
//  Complex.swift
//  cmd
//
//  Created by Vaida on 10/25/21.
//

import Foundation

struct Complex: SignedArithmetical, ExpressibleByFloatLiteral {
    
    //MARK: - Basic Instance Properties
    
    /// The real part of the complex number.
    let realPart: Fraction
    
    /// The imaginary part of the complex number.
    let imaginaryPart: Fraction
    
    
    //MARK: - Instance Properties
    
    /// The argument of the complex number.
    var argument: Fraction {
        return arctan(self.imaginaryPart / self.realPart)
    }
    
    /// For any complex number z = x + iy (x, y ∈ R), the conjugate is defined by \hat{z} = x − iy.
    var conjugate: Complex {
        return Complex(real: self.realPart, imaginary: self.imaginaryPart.opposite())
    }
    
    /// The description of this value.
    var description: String {
        if self.realPart.isZero {
            return "\(self.imaginaryPart)i"
        } else if self.imaginaryPart.isZero {
            return self.realPart.description
        } else {
            return "\(self.realPart.assignedSign())\(self.imaginaryPart.assignedSign())i"
        }
    }
    
    /// The modulus (or absolute value).
    var modulus: Fraction {
        return (self.realPart.square() + self.imaginaryPart.square()).squareRoot()
    }
    
    /// The absolute value.
    var magnitude: Complex {
        return Complex(self.realPart.magnitude, self.imaginaryPart.magnitude)
    }
    
    /// Determine whether the `Complex` is `0`.
    var isZero: Bool {
        return self.realPart.isZero && self.imaginaryPart.isZero
    }
    
    
    //MARK: - Type Properties
    
    /// The imaginary unit.
    static var i: Complex {
        return Complex(0, 1)
    }
    
    /// The `0` value.
    static var zero: Complex {
        return Complex(0, 0)
    }
    
    static var isSigned: Bool {
        return false
    }
    
    
    //MARK: - Initializers
    
    /// Initialize a complex number.
    init(_ realPart: Fraction, _ imaginaryPart: Fraction) {
        self.realPart = realPart
        self.imaginaryPart = imaginaryPart
    }
    
    /// Initialize a complex number.
    init(real realPart: Fraction, imaginary imaginaryPart: Fraction) {
        self.realPart = realPart
        self.imaginaryPart = imaginaryPart
    }
    
    /// Initialize a complex number.
    init<T>(_ realPart: T, _ imaginaryPart: T) where T: BinaryInteger {
        self.realPart = Fraction(realPart)
        self.imaginaryPart = Fraction(imaginaryPart)
    }
    
    /// Initialize a complex number.
    init<T>(_ realPart: T, _ imaginaryPart: T) where T: BinaryFloatingPoint {
        self.realPart = Fraction(realPart)
        self.imaginaryPart = Fraction(imaginaryPart)
    }
    
    /// Initialize a complex number.
    init(_ realPart: Fraction) {
        self.realPart = realPart
        self.imaginaryPart = 0
    }
    
    /// Initialize a complex number.
    init<T>(_ realPart: T) where T: BinaryInteger {
        self.realPart = Fraction(realPart)
        self.imaginaryPart = 0
    }
    
    /// Initialize a complex number.
    init<T>(_ realPart: T) where T: BinaryFloatingPoint {
        self.realPart = Fraction(realPart)
        self.imaginaryPart = 0
    }
    
    /// Initialize a complex number.
    init(exponentPolar r: Fraction, theta: Fraction) {
        self.realPart = r * cos(theta)
        self.imaginaryPart = r * sin(theta)
    }
    
    /// Initialize a complex number.
    init(exponentPolar r: Double, theta: Double) {
        self.realPart = Fraction(r * cos(theta))
        self.imaginaryPart = Fraction(r * sin(theta))
    }
    
    /// Initialize a complex number.
    init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
    
    /// Initialize a complex number.
    init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
    
    /// Initialize a complex number.
    init?(_ description: String) {
        guard description.contains("i") else {
            guard let value = Fraction(description.replacingOccurrences(of: " ", with: "")) else { return nil }
            self.init(value)
            return
        }
        guard description.contains("+") else {
            let description = description.replacingOccurrences(of: "i", with: "")
            guard let value = Fraction(description.replacingOccurrences(of: " ", with: "")) else { return nil }
            self.init(0, value)
            return
        }
        
        var real = String(description.split(separator: "+").first!)
        var imaginary = String(description.split(separator: "+").last!)
        
        real = real.replacingOccurrences(of: " ", with: "")
        imaginary = imaginary.replacingOccurrences(of: " ", with: "")
        imaginary = imaginary.replacingOccurrences(of: "i", with: "")
        
        guard let real = Fraction(real) else { return nil }
        guard let imaginary = Fraction(imaginary) else { return nil }
        self.init(real: real, imaginary: imaginary)
    }
    
    
    //MARK: - Instance Methods
    
    /// Replaces this value with its additive inverse.
    mutating func negate() {
        self = self.opposite()
    }
    
    /// The square of the `fraction`, or, `self * self`.
    func square() -> Complex {
        return self * self
    }
    
    /// The `n`th root of a `Complex`.
    func squareRoot(n: Int) -> [Complex] {
        let r = pow(self.modulus, -n)
        var exponents: [Fraction] = []
        for i in 0..<n {
            exponents.append(1 / Fraction(n) * (self.argument + 2 * Fraction(i) * .pi))
        }
        var values: [Complex] = []
        for i in exponents {
            values.append(Complex(exponentPolar: r, theta: i))
        }
        return values
    }
    
    /// The reciprocal.
    func reciprocal() -> Complex {
        return 1 / self
    }
    
    /// The value with same magnitude, but different sign.
    func opposite() -> Complex {
        return Complex(self.realPart.opposite(), self.imaginaryPart.opposite())
    }
    
    
    //MARK: - Type Methods
    
    
    
    //MARK: - Operator Functions
    
    /// Addition of two `Complex`s.
    static func + (_ lhs: Complex, _ rhs: Complex) -> Complex {
        return Complex(real: lhs.realPart + rhs.realPart, imaginary: rhs.imaginaryPart + rhs.imaginaryPart)
    }
    
    /// Addition of two `Complex`s, and stores in `lhs`.
    static func += (_ lhs: inout Complex, _ rhs: Complex) {
        lhs = lhs + rhs
    }
    
    /// Subtraction of two `Complex`s.
    static func - (_ lhs: Complex, _ rhs: Complex) -> Complex {
        return Complex(real: lhs.realPart - rhs.realPart, imaginary: rhs.imaginaryPart - rhs.imaginaryPart)
    }
    
    /// Subtraction of two `Complex`s, and stores in `lhs`.
    static func -= (_ lhs: inout Complex, _ rhs: Complex) {
        lhs = lhs - rhs
    }
    
    /// Multiplication of two `Complex`s.
    static func * (_ lhs: Complex, _ rhs: Complex) -> Complex {
        let a = lhs.realPart
        let b = lhs.imaginaryPart
        let c = rhs.realPart
        let d = rhs.imaginaryPart
        
        return Complex(real: a*c - b*d, imaginary: b*c + a*d)
    }
    
    /// Multiplication of two `Complex`s, and stores in `lhs`.
    static func *= (_ lhs: inout Complex, _ rhs: Complex) {
        lhs = lhs * rhs
    }
    
    /// Division of two `Complex`s.
    static func / (_ lhs: Complex, _ rhs: Complex) -> Complex {
        if rhs.imaginaryPart.isZero {
            return Complex(real: lhs.realPart / rhs.realPart, imaginary: lhs.imaginaryPart / rhs.realPart)
        }
        
        return (lhs * rhs.conjugate) / (rhs * rhs.conjugate)
    }
    
    /// Division of two `Complex`s, and stores in `lhs`.
    static func /= (_ lhs: inout Complex, _ rhs: Complex) {
        lhs = lhs / rhs
    }
    
    
    // MARK: - Comparing two instances
    
    static func == (_ lhs: Complex, _ rhs: Complex) -> Bool {
        return lhs.realPart == rhs.realPart && lhs.imaginaryPart == rhs.imaginaryPart
    }
    
    /// Compares their distance to the origin.
    static func < (lhs: Complex, rhs: Complex) -> Bool {
        return lhs.realPart.square() + lhs.imaginaryPart.square() < rhs.realPart.square() + rhs.realPart.square()
    }
}

/// The modulus (or absolute value).
///
/// To find the magnitude, use `.magnitude`.
func abs(_ x: Complex) -> Fraction {
    return x.modulus
}

/// Raise the power of a `Complex`.
func pow(_ value: Complex, _ exponent: Int) -> Complex {
    if exponent == -1 { return value.reciprocal()}
    if exponent == 0 { return Complex(1, 0)}
    precondition(exponent > 1)
    
    var output = Complex(1, 0)
    var counter = 0
    while counter < exponent {
        output *= value
        counter += 1
    }
    return output
}
