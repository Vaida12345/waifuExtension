//
//  Fraction.swift
//  cmd
//
//  Created by Vaida on 10/4/21.
//

import Foundation


/// The fraction in the form of `a / b` where `a`, `b` in `R`.
struct Fraction: SignedArithmetical, ExpressibleByFloatLiteral {
    
    //MARK: - Type Alias
    
    /// The Integer type used in `Fraction`.
    ///
    /// The type used to store `numerator` and `denominator`.
    typealias Integer = Int10
    
    /// The FloatingPoint type used in `Fraction`.
    ///
    /// The type is used in the instances such as `round()`, `squareRoot()`, `pow()`.
    typealias FloatingPoint = Double
    
    /// Returns the distance from this value to the given value, expressed as a stride.
    typealias Stride = Self.Integer
    
    
    //MARK: - Basic Instance Properties
    
    /// The numerator of the fraction.
    let numerator: Integer
    
    /// The non-negative denominator of the fraction.
    let denominator: Integer
    
    
    //MARK: - Instance Properties
    
    /// The description of this value.
    var description: String {
        let sign = self.sign == .plus ? "" : "-"
        
        if self.isNaN { return sign + "nan" }
        if self.isInfinite { return sign + "inf" }
        
        if self.denominator == 1 { return self.numerator.description }
        return "\(self.numerator)/\(self.denominator)"
    }
    
    /// The classification of this value.
    var floatingPointClass: FloatingPointClassification {
        if self.denominator.isZero {
            if self.numerator > 0 {
                return .positiveInfinity
            } else if self.numerator.isZero {
                return .signalingNaN
            } else {
                return .negativeInfinity
            }
        }
        
        if self.numerator.isZero && self.sign == .plus { return .positiveZero }
        if self.numerator.isZero && self.sign == .minus { return .negativeZero }
        
        if self.sign == .plus { return .positiveNormal }
        if self.sign == .minus { return .negativeNormal }
        
        fatalError("""
        unexpected.
        It may have result in one of the ignored values.
        negativeSubnormal: A negative, nonzero number that does not use the full precision of the floating-point type.
        positiveSubnormal: A positive, nonzero number that does not use the full precision of the floating-point type.
        quietNaN: A silent NaN (“not a number”) value.
        """)
    }
    
    /// The absolute value.
    var magnitude: Fraction {
        return Fraction(numerator: abs(self.numerator), denominator: self.denominator)
    }
    
    /// A Boolean value indicating whether the instance’s representation is in its canonical form.
    ///
    /// The return value is always `true`.
    var isCanonical: Bool {
        return true
    }
    
    /// Determine whether the `Fraction` is finite.
    var isFinite: Bool {
        return !self.denominator.isZero
    }
    
    /// Determine whether the `Fraction` is infinite.
    ///
    /// negative infinite is also infinite.
    var isInfinite: Bool {
        return self.denominator.isZero
    }
    
    /// Determine whether the `Fraction` is *not a number*.
    ///
    /// This is defined as the same as `undefined`.
    var isNaN: Bool  {
        return self.numerator.isZero && self.denominator.isZero
    }
    
    /// A Boolean value indicating whether this instance is normal.
    ///
    /// The return value is always `true`.
    var isNormal: Bool {
        return true
    }
    
    /// A Boolean value indicating whether the instance is a signaling NaN.
    ///
    /// The return value is same as `isNaN`
    var isSignalingNaN: Bool {
        return self.isNaN
    }
    
    /// A Boolean value indicating whether the instance is subnormal.
    ///
    /// The return value is always `false`.
    var isSubnormal: Bool {
        return false
    }
    
    /// Determine whether the `Fraction` is `0`.
    var isZero: Bool {
        return self.numerator.isZero
    }
    
    /// The LaTex expression of this value
    var latexExpression: String {
        if self.isFinite {
            if abs(self.denominator) == 1 { return "\(self.numerator)" }
            return "\\frac{\(self.numerator)}{\(self.denominator)}"
        } else {
            if self == Fraction.infinity { return "+\\infty" }
            if self == Fraction.negativeInfinity { return "-\\infty" }
            return "undefined"
        }
    }
    
    /// The sign of the `Fraction`.
    ///
    /// `plus` when `numerator >= 0`, `minus` otherwise.
    var sign: FloatingPointSign {
        return self.numerator.isPositive ? .plus : .minus
    }
    
    //MARK: - Type Properties
    
    /// `e` to `100` digits.
    static var e: Fraction {
        let numerator = Int10("27182818284590452353602874713526624977572470936999595749669676277240766303535475945713821785251664274")!
        return Fraction(numerator: numerator, denominator: 100)
    }
    
    /// The greatest finite number.
    ///
    /// The value was set to `Int.max`.
    static var greatestFiniteMagnitude: Fraction {
        return Fraction(numerator: Integer(Int.max), denominator: 1)
    }
    
    /// The (positive) infinity value, which is `1 / 0`.
    ///
    /// However, please note that it is `infinity` for `n / 0` where `n ≠ 0`.
    static var infinity: Fraction {
        return Fraction(numerator: 1, denominator: 0)
    }
    
    /// Determines whether the value is signed.
    static var isSigned: Bool {
        return true
    }
    
    /// The decimal value that represents the smallest possible non-zero value for the underlying representation.
    ///
    /// The value was set to `1 / Int.max`.
    static var leastNonzeroMagnitude: Fraction {
        return Fraction(numerator: 1, denominator: Integer(Int.max))
    }
    
    /// The least positive normal number.
    ///
    /// The value is same as `leastNonzeroMagnitude`.
    static var leastNormalMagnitude: Fraction {
        return self.leastNonzeroMagnitude
    }
    
    /// The (negative) infinity value, which is `-1 / 0`.
    ///
    /// However, please note that it is `infinity` for `n / 0` where `n ≠ 0`.
    static var negativeInfinity: Fraction {
        return Fraction(numerator: -1, denominator: 0)
    }
    
    /// The *not a number* value, which is `0 / 0`.
    ///
    /// This is defined as the same as `undefined`.
    static var nan: Fraction {
        return Fraction(numerator: 0, denominator: 0)
    }
    
    /// `pi` to `100` digits.
    static var pi: Fraction {
        let numerator = Int10("31415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170680")!
        return Fraction(numerator: numerator, denominator: 100)
    }
    
    /// The radix, or base of exponentiation, for a floating-point type.
    ///
    /// The return value is `10`.
    static var radix: Int {
        return 10
    }
    
    /// The `0` value.
    ///
    /// The value was set to `0 / 1`.
    static var zero: Fraction {
        return Fraction(numerator: 0, denominator: 1)
    }
    
    
    //MARK: - Initializers
    
    /// Initialize with the given numerator and denominator.
    ///
    /// Rules to be applied:
    /// - `denominator` would be made positive
    /// - Divide the `numerator` and `denominator` with the greatest common factor.
    init(numerator: Integer, denominator: Integer) {
        let result = Fraction.reduce(numerator: numerator, denominator: denominator)
        
        self.numerator = result.numerator
        self.denominator = result.denominator
    }
    
    /// Initialize with the given numerator and denominator.
    ///
    /// Rules to be applied:
    /// - `denominator` would be made positive
    /// - Divide the `numerator` and `denominator` with the greatest common factor.
    init(numerator: Int, denominator: Int) {
        self.init(numerator: Integer(numerator), denominator: Integer(denominator))
    }
    
    /// Initialize with the given numerator and denominator, both in `FloatingPoint`.
    ///
    /// Exact results were obtained.
    init(floatNumerator: FloatingPoint, floatDenominator: FloatingPoint) {
        let power: Int = 10
        
        let rawNumerator = floatNumerator * FloatingPoint(pow(10, abs(power)))
        let rawDenominator = floatDenominator * FloatingPoint(pow(10, abs(power)))
        
        let result = Fraction.reduce(numerator: Fraction.Integer(rawNumerator), denominator: Fraction.Integer(rawDenominator))
        
        self.numerator = result.numerator
        self.denominator = result.denominator
    }
    
    /// Initialize with a `BinaryInteger`.
    init<Source>(_ value: Source) where Source: BinaryInteger {
        self.init(numerator: Integer(value), denominator: 1)
    }
    
    /// Initialize with a `BinaryInteger`.
    ///
    /// This is actually same as `init<Source>(_ value: Source) where Source : BinaryInteger`.
    init?<Source>(exactly value: Source) where Source: BinaryInteger {
        self.init(numerator: Integer(value), denominator: 1)
    }
    
    /// Initialize with an `Integer`.
    init(_ value: Integer) {
        self.init(numerator: value, denominator: 1)
    }
    
    /// Initialize with an `Int`.
    init(_ value: Int) {
        self.init(numerator: Integer(value), denominator: 1)
    }
    
//    /// Initialize with a `Int10`.
//    init(exactly value: PreciseFloat) {
//        self.init(numerator: Fraction.Integer(value.coefficient), denominator: Int10(1).pow10(abs(value.exponent)))
//    }
//
//    /// Initialize with a `BinaryFloatingPoint`.
//    init<T>(exactly value: T) where T: BinaryFloatingPoint {
//        self.init(PreciseFloat(value))
//    }
//
//    /// Initialize with a `Int10`.
//    ///
//    /// If the length of decimal part of the float is less or equal to 10 or it is a recruiting decimal, a precise fraction would be produced. Otherwise, approximate x.
//    init(_ value: PreciseFloat) {
//        self.init(value.fraction())
//    }
    
    /// Initialize with a `BinaryFloatingPoint`.
    ///
    /// If the length of decimal part of the float is less or equal to 10 or it is a recruiting decimal, a precise fraction would be produced. Otherwise, approximate x.
    init<T>(_ value: T) where T: BinaryFloatingPoint {
        self = FloatingPoint(value).fraction()
    }
    
    /// Initialize and make it `1`.
    init() {
        self.init(1)
    }
    
    /// Creates a new floating-point value using the sign of one value and the magnitude of another.
    init(signOf: Fraction, magnitudeOf: Fraction) {
        self.init(signOf.sign == .plus ? magnitudeOf.magnitude : magnitudeOf.magnitude.opposite())
    }
    
    /// Initialize with a `String`.
    init?(_ value: String) {
        
        if value.contains(".") {
            // initialize with standard floating point instance.
            guard let intPart = Integer(value[value.startIndex..<value.firstIndex(of: ".")!]) else { return nil }
            let decimalPartString = value[value.index(after: value.firstIndex(of: ".")!)..<value.endIndex]
            guard let decimalPart = Integer(decimalPartString) else { return nil }
            
            self = Fraction(intPart) + Fraction(numerator: decimalPart, denominator: Int10(1).pow10(decimalPartString.count))
            return
        } else if value.contains("/") {
            guard let numerator = Integer(value[value.startIndex..<value.firstIndex(of: "/")!]) else { return nil }
            guard let denominator = Integer(value[value.index(after: value.firstIndex(of: "/")!)..<value.endIndex]) else { return nil }
            
            self.init(numerator: numerator, denominator: denominator)
            return
        } else {
            guard let value = Integer(value) else { return nil }
            
            self.init(value)
            return
        }
    }
    
    /// Initialize with itself. Sometimes useful.
    ///
    /// Rules to be applied:
    /// - `denominator` would be made positive
    /// - Divide the `numerator` and `denominator` with the greatest common factor.
    init(_ value: Fraction) {
        self.init(numerator: value.numerator, denominator: value.denominator)
    }
    
    /// Conforming to `ExpressibleByIntegerLiteral`.
    ///
    /// This is not the designed initializer. Use `init(_ value: Integer)` instead.
    init(integerLiteral value: Int) {
        self.init(Integer(value))
    }
    
    /// Conforming to `ExpressibleByFloatLiteral`.
    ///
    /// This is not the designed initializer. Use `init(_ value: PreciseFloat)` instead.
    init(floatLiteral value: FloatLiteralType) {
        self.init(FloatingPoint(value))
    }
    
    
    //MARK: - Instance Methods
    
    /// Returns the result of adding the product of the two given values to this value, computed without intermediate rounding.
    func addingProduct(_ lhs: Fraction, _ rhs: Fraction) -> Fraction {
        return self + lhs * rhs
    }
    
    /// Adds the product of the two given values to this value in place, computed without intermediate rounding.
    mutating func addProduct(_ lhs: Fraction, _ rhs: Fraction) {
        self += lhs * rhs
    }
    
    /// Returns a value that is offset the specified distance from this value.
    func advanced(by n: Integer) -> Fraction {
        let lhs = self
        let rhs = Fraction(n)
        return lhs + rhs
    }
    
    /// Reduce (round) the `Fraction`.
    ///
    ///     1000000 / 3000001 -> 1 / 3
    ///
    /// - Important: Precision may be lost.
    ///
    /// - Remark: It was turned into `FloatingPoint` and turned back into `Fraction`.
    ///
    /// **Sample**
    /// Sample with 10,000 candidates, results in a loss of precision of maximum of 8.6788e-5.
    func approximateReduced() -> Fraction {
        return FloatingPoint(self).fraction(forceApproximate: true)
    }
    
    /// Returns the distance from this value to the given value, expressed as a stride.
    func distance(to other: Fraction) -> Integer {
        let value = abs(self - other)
        return value.numerator / value.denominator
    }
    
    /// Returns a Boolean value indicating whether this instance is equal to the given value.
    func isEqual(to other: Fraction) -> Bool {
        return self.numerator == other.numerator && self.denominator == other.denominator
    }
    
    /// Returns a Boolean value indicating whether this instance is less than the given value.
    func isLess(than other: Fraction) -> Bool {
        return FloatingPoint(self.numerator) / FloatingPoint(self.denominator) < FloatingPoint(other.numerator) / FloatingPoint(other.denominator)
    }
    
    /// Returns a Boolean value indicating whether this instance is less than or equal to the given value.
    func isLessThanOrEqualTo(_ other: Fraction) -> Bool {
        return self.isEqual(to: other) || self.isLess(than: other)
    }
    
    /// Returns a Boolean value indicating whether this instance should precede or tie positions with the given value in an ascending sort.
    func isTotallyOrdered(belowOrEqualTo other: Fraction) -> Bool {
        return self <= other
    }
    
    /// Replaces this value with its additive inverse.
    mutating func negate() {
        self = self.opposite()
    }
    
    /// The square of the `fraction`, or, `self * self`.
    func square() -> Fraction {
        return self * self
    }
    
    /// Returns the square root of the value, rounded to a representable value.
    func squareRoot() -> Fraction {
        return Fraction(floatNumerator: FloatingPoint(self.numerator).squareRoot(), floatDenominator: FloatingPoint(self.denominator).squareRoot())
    }
    
    /// Replaces this value with its square root, rounded to a representable value.
    mutating func formSquareRoot() {
        self = self.squareRoot()
    }
    
    /// The reciprocal.
    func reciprocal() -> Fraction {
        return Fraction(numerator: self.denominator, denominator: self.numerator)
    }
    
    /// Reduce `self` to make it look better.
    ///
    /// Rules applied:
    /// - `denominator` would be made positive
    /// - Divide the `numerator` and `denominator` with the greatest common factor.
    func reduced() -> Fraction {
        let result = Fraction.reduce(numerator: self.numerator, denominator: self.denominator)
        return Fraction(numerator: result.numerator, denominator: result.denominator)
    }
    
    /// Returns the remainder of this value divided by the given value.
    func remainder(dividingBy other: Fraction) -> Fraction {
        let (lhsNumerator, rhsNumerator, denominator) = Fraction.commonDenominator(self, other)
        return Fraction(numerator: lhsNumerator % rhsNumerator, denominator: denominator)
    }
    
    /// Replaces this value with the remainder of itself divided by the given value.
    mutating func formRemainder(dividingBy other: Fraction) {
        self = self.remainder(dividingBy: other)
    }
    
    /// Returns this value rounded to an integral value using the specified rounding rule.
    func rounded(_ rule: FloatingPointRoundingRule) -> Fraction {
        return Fraction((FloatingPoint(self.numerator) / FloatingPoint(self.denominator)).rounded(rule))
    }
    
    /// Rounds the value to an integral value using the specified rounding rule.
    mutating func round(_ rule: FloatingPointRoundingRule) {
        self = self.rounded(rule)
    }
    
    /// Returns this value rounded to an integral value using “schoolbook rounding.”
    func rounded() -> Fraction {
        return self.rounded(.toNearestOrAwayFromZero)
    }
    
    /// Rounds this value to an integral value using “schoolbook rounding.”
    mutating func round() {
        self = self.rounded()
    }
    
    /// The value with same magnitude, but different sign.
    func opposite() -> Fraction {
        var numerator = self.numerator
        numerator = numerator.opposite()
        return Fraction(numerator: numerator, denominator: self.denominator)
    }
    
    /// Returns the remainder of this value divided by the given value using truncating division.
    ///
    /// As I have no idea what this is, this is the same as `remainder(dividingBy: other)`.
    func truncatingRemainder(dividingBy other: Fraction) -> Fraction {
        return remainder(dividingBy: other)
    }
    
    /// Replaces this value with the remainder of itself divided by the given value using truncating division.
    mutating func formTruncatingRemainder(dividingBy other: Fraction) {
        self = self.truncatingRemainder(dividingBy: other)
    }
    
    
    //MARK: - Type Methods
    
    /// Reduce the `numerator` and `denominator` set to make it look better.
    ///
    /// Rules applied:
    /// - `denominator` would be made positive
    /// - Divide the `numerator` and `denominator` with the greatest common factor.
    static func reduce(numerator: Integer, denominator: Integer) -> (numerator: Integer, denominator: Integer) {
        if numerator == denominator { return (1, 1) }
        var divisor = greatestCommonFactor(numerator, denominator)
        guard divisor != 0 else { return (numerator, 0) }
        
        if denominator < 0 { divisor *= -1 }
        return (numerator / divisor, denominator / divisor)
    }
    
    /// Calculate the greatest common factor of two values.
    static func greatestCommonFactor(_ lhs: Integer, _ rhs: Integer) -> Integer {
        var lhs = lhs
        var rhs = rhs
        while rhs != 0 { (lhs, rhs) = (rhs, lhs % rhs) }
        return lhs
    }
    
    /// Calculate the least common multiple of two values.
    static func leastCommonMultiple(_ lhs: Integer, _ rhs: Integer) -> Integer {
        if lhs == rhs { return lhs }
        return lhs * rhs / greatestCommonFactor(lhs, rhs)
    }
    
    /// Calculate the common denominator of two fractions.
    static func commonDenominator(_ lhs: Fraction, _ rhs: Fraction) -> (lhsNumerator: Integer, rhsNumerator: Integer, denominator: Integer) {
        if lhs.denominator == rhs.denominator { return (lhs.numerator, rhs.numerator, lhs.denominator)}
        
        let denominator = leastCommonMultiple(lhs.denominator, rhs.denominator)
        
        let lhsNumerator = lhs.numerator * denominator / lhs.denominator
        let rhsNumerator = rhs.numerator * denominator / rhs.denominator
        
        return (lhsNumerator, rhsNumerator, denominator)
    }
    
    /// Returns the greater of the two given values.
    static func maximum(_ x: Fraction, _ y: Fraction) -> Fraction {
        return x > y ? x : y
    }
    
    /// Returns the value with greater magnitude.
    static func maximumMagnitude(_ x: Fraction, _ y: Fraction) -> Fraction {
        return x.magnitude > y.magnitude ? x : y
    }
    
    /// Returns the lesser of the two given values.
    static func minimum(_ x: Fraction, _ y: Fraction) -> Fraction {
        return x < y ? x : y
    }
    
    /// Returns the value with lesser magnitude.
    static func minimumMagnitude(_ x: Fraction, _ y: Fraction) -> Fraction {
        return x.magnitude < y.magnitude ? x : y
    }
    
    
    //MARK: - Operator Functions
    
    /// Addition of two `Fractions`.
    static func + (_ lhs: Fraction, _ rhs: Fraction) -> Fraction {
        if lhs.isNaN || rhs.isNaN { return Fraction.nan }
        
        // Addition of two positive values.
        if lhs.isInfinite || rhs.isInfinite { return Fraction.infinity }
        
        let (lhsNumerator, rhsNumerator, denominator) = Fraction.commonDenominator(lhs, rhs)
        return Fraction(numerator: lhsNumerator + rhsNumerator, denominator: denominator)
    }
    
    /// Addition of two `Fractions`, and stores in `lhs`.
    static func += (_ lhs: inout Fraction, _ rhs: Fraction) {
        lhs = lhs + rhs
    }
    
    /// Subtraction of two `Fractions`.
    static func - (_ lhs: Fraction, _ rhs: Fraction) -> Fraction {
        if lhs.isNaN || rhs.isNaN { return Fraction.nan }
        
        if lhs == rhs { return 0 }
        
        // Subtraction of two positive values.
        if lhs.isInfinite || rhs.isInfinite {
            switch (lhs.isInfinite, rhs.isInfinite) {
            case (true, true):
                return Fraction.nan
            case (true, false):
                return Fraction.infinity
            case (false, true):
                return Fraction.negativeInfinity
            case (false, false):
                fatalError("unexpected")
            }
        }
        
        let (lhsNumerator, rhsNumerator, denominator) = Fraction.commonDenominator(lhs, rhs)
        return Fraction(numerator: lhsNumerator - rhsNumerator, denominator: denominator)
    }
    
    /// Subtraction of two `Fractions`, and stores in `lhs`.
    static func -= (_ lhs: inout Fraction, _ rhs: Fraction) {
        lhs = lhs - rhs
    }
    
    /// Multiplication of two `Fractions`.
    static func * (_ lhs: Fraction, _ rhs: Fraction) -> Fraction {
        if lhs.isNaN || rhs.isNaN { return Fraction.nan }
        
        // Multiplication of two positive values.
        if lhs.isInfinite || rhs.isInfinite { return Fraction.infinity }
        if lhs.isZero || rhs.isZero { return Fraction.zero }
        
        return Fraction(numerator: lhs.numerator * rhs.numerator, denominator: lhs.denominator * rhs.denominator)
    }
    
    /// Multiplication of two `Fractions`, and stores in `lhs`.
    static func *= (_ lhs: inout Fraction, _ rhs: Fraction) {
        lhs = lhs * rhs
    }
    
    /// Division of two `Fractions`.
    static func / (_ lhs: Fraction, _ rhs: Fraction) -> Fraction {
        if lhs.isNaN || rhs.isNaN { return Fraction.nan }
        
        // Division of two positive values.
        if lhs.isInfinite || rhs.isInfinite {
            switch (lhs.isInfinite, rhs.isInfinite) {
            case (true, true):
                return Fraction.nan
            case (true, false):
                return Fraction.infinity
            case (false, true):
                return Fraction.zero
            case (false, false):
                fatalError("unexpected")
            }
        }
        
        if lhs.isZero { return 0 }
        
        return lhs * rhs.reciprocal()
    }
    
    /// Division of two `Fractions`, and stores in `lhs`.
    static func /= (_ lhs: inout Fraction, _ rhs: Fraction) {
        lhs = lhs / rhs
    }
    
    
    // MARK: - Comparing two instances
    
    static func < (_ lhs: Fraction, _ rhs: Fraction) -> Bool {
        return lhs.isLess(than: rhs)
    }
    
    static func <= (_ lhs: Fraction, _ rhs: Fraction) -> Bool {
        return lhs.isLessThanOrEqualTo(rhs)
    }
    
    static func == (_ lhs: Fraction, _ rhs: Fraction) -> Bool {
        return lhs.isEqual(to: rhs)
    }
}


//MARK: - Supporting Extensions

extension BinaryFloatingPoint where Self: LosslessStringConvertible {
    
    /// Create an instance initialized to `Fraction`.
    init(_ value: Fraction) {
        self.init(Self(value.numerator) / Self(value.denominator))
    }
    
    /// Returns the Fraction form of a float, in the form of Fraction.
    ///
    /// An example:
    ///
    ///       print(0.5.fraction()!)
    ///       // prints "1/2"
    ///
    /// If the length of decimal part the float is less or equal to 10 or it is a recruiting decimal, a precise fraction would be produced.
    ///
    /// Otherwise, approximate x by
    ///
    ///                       1
    ///        d1 + ----------------------
    ///                        1
    ///           d2 + -------------------
    ///                          1
    ///              d3 + ----------------
    ///                            1
    ///                 d4 + -------------
    ///                             1
    ///                    d5 + ----------
    ///                               1
    ///                        d6 + ------
    ///                                 1
    ///                           d7 + ---
    ///                                 d8
    ///
    /// - Parameters:
    ///     - forceApproximate: Determine whether approximation was forced to be used.
    ///
    /// - Returns: `Fraction`
    func fraction(forceApproximate: Bool = false) -> Fraction where Self: LosslessStringConvertible {
        guard self.isFinite else {
            guard !self.isNaN else { fatalError() }
            if self.sign == .plus {
                return Fraction.infinity
            } else {
                return Fraction.negativeInfinity
            }
        }
        guard Self(Fraction.Integer(self)) != self else { return Fraction(Fraction.Integer(self)) }
        
        // if simple
        if !forceApproximate && self.decimalPart.count <= 10 {
            let fraction = Fraction(numerator: Fraction.Integer(Fraction.FloatingPoint(self)*Fraction.FloatingPoint(pow(10, self.decimalPart.count))), denominator: Fraction.Integer(pow(10, self.decimalPart.count)))
            return fraction
        }
        
        // if repeating
        if !forceApproximate && String(self).count > 10 {
            let contentString = String([Character](String(self))[0...10])
            if let repeatingElements = [Character](contentString).findRepeatedElements() {
                let leadingItems = [Character](contentString).firstIndex(of: repeatingElements)!.first! - 2
                let value2 = Fraction.FloatingPoint(contentString)! * Fraction.FloatingPoint(pow(10, leadingItems))
                let value2Mag = pow(10, leadingItems)
                let value3 = value2 * Fraction.FloatingPoint(pow(10, repeatingElements.count))
                let value3Mag = pow(10, repeatingElements.count)
                
                let value = (value3 - Fraction.FloatingPoint(contentString)!).rounded(toDigit: 5)
                if value.isWholeNumber {
                    let fraction =  Fraction(numerator: Fraction.Integer(value), denominator: Fraction.Integer((value3Mag-1)*value2Mag))
                    return fraction
                }
            }
        }
        
        // Approximate x
        var content = Fraction.FloatingPoint(self)
        var dList: [Fraction.Integer] = []
        
        while content != 0 && content.isFinite && dList.count <= 20 {
            dList.append(Fraction.Integer(content))
            content = (1 / (content - Fraction.FloatingPoint(dList.last!)))
            
            guard abs(dList.last!) < 10000 else {
                dList.removeLast()
                break
            }
        }
        
        var numerator: Fraction.Integer = 1
        var denominator: Fraction.Integer = dList.last!
        
        for i in 1..<dList.count {
            let index = dList.count - 1 - i
            
            // add content
            numerator += denominator * dList[index]
            
            // reciprocal
            swap(&numerator, &denominator)
        }
        
        // take reciprocal, as once more was done in loop
        swap(&numerator, &denominator)
        
        // self check
        return Fraction(numerator: numerator, denominator: denominator)
    }
}

extension SignedInteger where Self: LosslessStringConvertible {
    init(_ value: Fraction) {
        self.init(Self(value.numerator) / Self(value.denominator))
    }
}


//MARK: - Supporting Functions

/// An alternative for `.magnitude`.
func abs(_ x: Fraction) -> Fraction {
    return x.magnitude
}

/// Raise the `Int` power of a `Fraction`.
func pow(_ lhs: Fraction, _ rhs: Int) -> Fraction {
    return Fraction(numerator: pow(Int(lhs.numerator), rhs), denominator: pow(Int(lhs.denominator), rhs))
}

/// Raise the power of a `Fraction`.
func pow(_ lhs: Fraction, _ rhs: Fraction) -> Fraction {
    return Fraction(pow(Fraction.FloatingPoint(lhs), Fraction.FloatingPoint(rhs)))
}

/// calculate `e^x`.
///
/// It would iterate for at most 40 times.
func exp(_ item: Fraction) -> Fraction {
    let value = exp(Fraction.FloatingPoint(item))
    let value2 = Fraction(value)
    return value2
}

/// The Natural logarithm
func log(_ item: Fraction) -> Fraction {
    return Fraction(log(Fraction.FloatingPoint(item)))
}

/// The logarithm of log_base value
func log(_ value: Fraction, base: Fraction) -> Fraction {
    return log(value) / log(base)
}

/// The square root.
func sqrt(_ x: Fraction) -> Fraction {
    return x.squareRoot()
}


//MARK: - Trigonometric Functions

/// The sine of `theta`.
///
/// - Parameters:
///     - theta: in radian.
func sin(_ theta: Fraction) -> Fraction {
    return Fraction(sin(Fraction.FloatingPoint(theta)))
}

/// The cosine of `theta`.
///
/// - Parameters:
///     - theta: in radian.
func cos(_ theta: Fraction) -> Fraction {
    return Fraction(cos(Fraction.FloatingPoint(theta)))
}

/// The tangent of `theta`.
///
/// - Parameters:
///     - theta: in radian.
func tan(_ theta: Fraction) -> Fraction {
    return sin(theta) / cos(theta)
}

/// The cosecant of `theta`.
///
/// - Parameters:
///     - theta: in radian.
func csc(_ theta: Fraction) -> Fraction {
    return 1 / sin(theta)
}

/// The secant of `theta`.
///
/// - Parameters:
///     - theta: in radian.
func sec(_ theta: Fraction) -> Fraction {
    return 1 / cos(theta)
}

/// The cotangent of `theta`.
///
/// - Parameters:
///     - theta: in radian.
func cot(_ theta: Fraction) -> Fraction {
    return 1 / tan(theta)
}

/// The hyperbolic sine of `theta`.
///
/// The odd part of the exponential function.
func sinh(_ theta: Fraction) -> Fraction {
    return Fraction(sinh(Fraction.FloatingPoint(theta)))
}

/// The hyperbolic cosine of `theta`.
///
/// The even part of the exponential function.
func cosh(_ theta: Fraction) -> Fraction {
    let value1 = Fraction.FloatingPoint(theta)
    let value2 = cosh(value1)
    return Fraction(value2)
}

/// The hyperbolic tangent of `theta`.
func tanh(_ theta: Fraction) -> Fraction {
    return sinh(theta) / cosh(theta)
}

/// The hyperbolic cotangent of `theta`.
///
/// - Precondition: `theta` ≠ 0.
func coth(_ theta: Fraction) -> Fraction {
    return cosh(theta) / sinh(theta)
}

/// The hyperbolic secant of `theta`.
func sech(_ theta: Fraction) -> Fraction {
    return 1 / cosh(theta)
}

/// The hyperbolic cosecant of `theta`.
///
/// - Precondition: `theta` ≠ 0.
func csch(_ theta: Fraction) -> Fraction {
    return 1 / sinh(theta)
}


//MARK: - Inverse Trigonometric Functions

/// The inverse sine of `z`.
///
/// - Precondition: `|z| ≤ 1`
func arcsin(_ z: Fraction) -> Fraction {
    return Fraction(asin(Fraction.FloatingPoint(z)))
}

/// The inverse cosine of `z`.
///
/// - Precondition: `|z| ≤ 1`
func arccos(_ z: Fraction) -> Fraction {
    return Fraction(acos(Fraction.FloatingPoint(z)))
}

/// The inverse tan of `z`.
///
/// - Precondition: `|z| ≤ 1`
///
/// - Note: By default, it would iterate for at most 200 times, however, the precision is only 10^(-5).
///
/// - Parameters:
///     - iterations: The more iterations, the more time it would take, and more precise it would be.
func arctan(_ z: Fraction, iterations: Int = 200) -> Fraction {
    return Fraction(atan(Fraction.FloatingPoint(z)))
}

/// The inverse secant of `z`.
func arcsec(_ z: Fraction) -> Fraction {
    return arccos(1 / z)
}

/// The inverse cosecant of `z`.
func arccsc(_ z: Fraction) -> Fraction {
    return arcsin(1 / z)
}

/// The inverse cotangent of `z`.
func arccot(_ z: Fraction) -> Fraction {
    return arctan(1 / z)
}

/// The inverse hyperbolic sine of `xs`.
func arsinh(_ x: Fraction) -> Fraction {
    return log(x + (pow(x, 2) + 1).squareRoot())
}

/// The inverse hyperbolic cosine of `x`.
///
/// - Precondition: `x ≥ 1`.
func arcosh(_ x: Fraction) -> Fraction {
    precondition(x >= 1, "mathematical error")
    return log(x + (pow(x, 2) - 1).squareRoot())
}

/// The inverse hyperbolic tangent of `x`.
///
/// - Precondition: `|x| < 1`.
func artanh(_ x: Fraction) -> Fraction {
    precondition(abs(x) < 1, "mathematical error")
    return 1 / 2 * log((1 + x) / (1 - x))
}

/// The inverse hyperbolic cotangent of `x`.
///
/// - Precondition: `|x| > 1`.
func arcoth(_ x: Fraction) -> Fraction {
    precondition(abs(x) > 1, "mathematical error")
    return 1 / 2 * log((x + 1) / (x - 1))
}

/// The inverse hyperbolic secant of `x`.
///
/// - Precondition: `0 < x ≤ 1`.
func arsech(_ x: Fraction) -> Fraction {
    precondition(0 < x && x <= 1, "mathematical error")
    return log((1 + (1 - pow(x, 2)).squareRoot()) / (x))
}

/// The inverse hyperbolic cosecant of `x`.
///
/// - Precondition: `x ≠ 0`.
func arcsch(_ x: Fraction) -> Fraction {
    precondition(x != 0, "mathematical error")
    return log(1 / x + (1 / pow(x, 2) + 1).squareRoot())
}

