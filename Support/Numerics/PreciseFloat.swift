//
//  PreciseFloat.swift
//  cmd
//
//  Created by Vaida on 10/3/21.
//
/*
import Foundation

struct PreciseFloat: BinaryFloatingPoint, ExpressibleByFloatLiteral, CustomStringConvertible, CustomDebugStringConvertible, LosslessStringConvertible, Hashable, Codable {
    
    /// The exponent is `Int` as the magnitude is not expected to exceed `10^(2^63)`.
    typealias Exponent = Int
    
    typealias Coefficient = PreciseUInt
    
    typealias Stride = PreciseInt
    
    typealias Magnitude = PreciseFloat
    
    typealias RawSignificand = PreciseUInt
    
    typealias RawExponent = PreciseUInt

    
    //MARK: Instance Properties
    
    /// `value = coefficient * radix ^ exponent`
    let exponent: Exponent

    let sign: FloatingPointSign

    /// `value = coefficient * radix ^ exponent`
    ///
    /// - Important: `coefficient` is always an integer.
    let coefficient: Coefficient
    
    var calculationPrecision: Int
    
    /// The absolute value.
    var magnitude: PreciseFloat {
        return PreciseFloat(sign: .plus, coefficient: self.coefficient, exponent: self.exponent)
    }
    
    /// The class of this value.
    ///
    /// Ignoring cases of:
    ///
    /// - `negativeSubnormal`
    /// - `positiveSubnormal`
    /// - `negativeZero`
    ///
    /// As they are considered not valid.
    var floatingPointClass: FloatingPointClassification {
        if self.exponent == PreciseFloat.precision {
            if self.sign == .plus {
                if self.coefficient == 3 { return .signalingNaN }
                if self.coefficient == 4 { return .quietNaN }
                if self.coefficient == 10 { return .positiveInfinity }
            } else {
                if self.coefficient == 10 { return .positiveInfinity }
            }
        }
        
        if self.coefficient.isZero { return .positiveZero }
        if self.sign == .plus { return .positiveNormal }
        return .negativeInfinity
    }
    
    /// The value was set to `true`. As I have no idea what it is.
    var isCanonical: Bool {
        return true
    }
    
    var isFinite: Bool {
        return !((self.exponent == PreciseFloat.precision || self.exponent == -PreciseFloat.precision) && self.coefficient != 1)
    }
    
    var isInfinite: Bool {
        return (self.exponent == PreciseFloat.precision || self.exponent == -PreciseFloat.precision) && self.coefficient == 9
    }
    
    var isNaN: Bool  {
        return (self.exponent == PreciseFloat.precision || self.exponent == -PreciseFloat.precision) && self.coefficient == 2
    }
    
    /// The value was set to `true`.
    var isNormal: Bool {
        return true
    }
    
    var isSignalingNaN: Bool {
        return (self.exponent == PreciseFloat.precision || self.exponent == -PreciseFloat.precision) && self.coefficient == 3
    }
    
    /// The value was set to `false`.
    var isSubnormal: Bool {
        return false
    }
    
    var isZero: Bool {
        return self.coefficient.isZero
    }
    
    var nextDown: PreciseFloat {
        if self == PreciseFloat.infinity { return PreciseFloat.greatestFiniteMagnitude }
        if self == PreciseFloat.leastNonzeroMagnitude { return 0 }
        if self.isZero { return -PreciseFloat.leastNonzeroMagnitude }
        if self == -PreciseFloat.greatestFiniteMagnitude { return -PreciseFloat.infinity }
        if self.isNaN || self == -PreciseFloat.infinity { return self }
        return self - PreciseFloat.leastNonzeroMagnitude
    }
    
    var nextUp: PreciseFloat {
        if self == -PreciseFloat.infinity { return -PreciseFloat.greatestFiniteMagnitude }
        if self == -PreciseFloat.leastNonzeroMagnitude { return 0 }
        if self.isZero { return PreciseFloat.leastNonzeroMagnitude }
        if self == PreciseFloat.greatestFiniteMagnitude { return PreciseFloat.infinity }
        if self.isNaN || self == PreciseFloat.infinity { return self }
        return self + PreciseFloat.leastNonzeroMagnitude
    }
    
    // between 1.0 ..< Self.radix
    var significand: PreciseFloat {
        var coefficient = Int(self.coefficient)
        while coefficient >= PreciseFloat.radix {
            coefficient /= PreciseFloat.radix
        }
        return PreciseFloat(sign: .plus, coefficient: PreciseUInt(coefficient), exponent: 0)
    }
    
    /// aka, mathematical epsilon
    var ulp: PreciseFloat {
        guard self.isFinite else { return PreciseFloat.nan }
        return PreciseFloat.ulpOfOne
    }
    
    /// The floating-point value with the same sign and exponent as this value, but with a significand of 1.0.
    var binade: PreciseFloat {
        return PreciseFloat(sign: sign, coefficient: coefficient, exponent: 0)
    }
    
    /// The raw encoding of the value’s exponent field.
    var exponentBitPattern: PreciseUInt {
        return PreciseUInt(self.exponent)
    }
    
    /// The raw encoding of the value’s significand field.
    var significandBitPattern: PreciseUInt {
        return self.coefficient
    }
    
    /// The number of bits required to represent the value’s significand.
    var significandWidth: Int {
        return self.coefficient.bitWidth
    }
    
    var description: String {
        let sign = self.sign == .plus ? "" : "-"
        
        if exponent == PreciseFloat.precision {
            if coefficient == 2 { return sign + "nan" }
            if coefficient == 3 { return sign + "signalingNaN" }
            if coefficient == 4 { return sign + "quietNaN" }
            if coefficient == 9 { return sign + "inf" }
        }
        
        var value = coefficient.description
        if exponent >= 0 {
            var counter = 0
            while counter < exponent {
                value += "0"
                counter += 1
            }
            value += ".0"
        } else if exponent < 0 {
            var counter = 0
            while counter < abs(exponent) {
                value.insert("0", at: value.startIndex)
                counter += 1
            }
            
            value.insert(".", at: value.index(value.endIndex, offsetBy: Int(exponent)))
            
            while value.first == "0" {
                value.removeFirst()
            }
            
            if value.first == "." {
                value.insert("0", at: value.startIndex)
            }
        }
        
        while value.last == "0" {
            value.removeLast()
        }
        
        if value.last == "." {
            value += "0"
        }
        
        if value.isEmpty { value = "0.0" }
        
        return sign + value
    }
    
    var debugDescription: String {
        return "PreciseFloat<\(sign) \(coefficient) * \(PreciseFloat.radix) ^ \(exponent)>"
    }
    
    
    //MARK: Type Properties
    
    /// The precision was set to `1000`.
    static let precision = 1000
    
    /// The value was set to `1 * 10 ^ precision`
    static var greatestFiniteMagnitude: PreciseFloat {
        return PreciseFloat(sign: .plus, coefficient: 1, exponent: precision)
    }
    
    /// The value was set to `9 * 10 ^ precision`
    static var infinity: PreciseFloat {
        return PreciseFloat(sign: .plus, coefficient: 9, exponent: precision)
    }
    
    /// The value was set to `1 * 10 ^ -precision`
    static var leastNonzeroMagnitude: PreciseFloat {
        return PreciseFloat(sign: .plus, coefficient: 1, exponent: -precision)
    }
    
    /// The value was set to `1 * 10 ^ -precision`
    static var leastNormalMagnitude: PreciseFloat {
        return PreciseFloat(sign: .plus, coefficient: 1, exponent: -precision)
    }
    
    /// The value was set to `2 * 10 ^ precision`
    static var nan: PreciseFloat {
        return PreciseFloat(sign: .plus, coefficient: 2, exponent: precision)
    }
    
    /// `pi` to `100` digits.
    static var pi: PreciseFloat {
        let coefficient = PreciseUInt("3141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117068")!
        return PreciseFloat(sign: .plus, coefficient: coefficient, exponent: -99)
    }
    
    /// `e` to `100` digits.
    static var e: PreciseFloat {
        let coefficient = PreciseUInt("2718281828459045235360287471352662497757247093699959574966967627724076630353547594571382178525166427")!
        return PreciseFloat(sign: .plus, coefficient: coefficient, exponent: -99)
    }
    
    /// `value = coefficient * radix ^ exponent`
    static var radix: Int {
        return 10
    }
    
    /// The value was set to `3 * 10 ^ precision`
    static var signalingNaN: PreciseFloat {
        return PreciseFloat(sign: .plus, coefficient: 3, exponent: precision)
    }
    
    /// The value was set to `4 * 10 ^ precision`
    static var quietNaN: PreciseFloat {
        return PreciseFloat(sign: .plus, coefficient: 4, exponent: precision)
    }
    
    /// aka, mathematical epsilon
    ///
    /// The value was set to `1 * 10 ^ -precision`
    static var ulpOfOne: PreciseFloat {
        return PreciseFloat(sign: .plus, coefficient: 1, exponent: -precision)
    }
    
    /// The number of bits used to represent the type’s exponent.
    static var exponentBitCount: Int {
        return Exponent.bitWidth
    }
    
    /// The available number of fractional significand bits.
    ///
    /// The value was set to `1`.
    static var significandBitCount: Int {
        return 1
    }
    
    
    //MARK: Initializers
    
    /// `value = coefficient * radix ^ exponent`
    init(sign: FloatingPointSign, coefficient: PreciseUInt, exponent: Int, calculationPrecision: Int = 100) {
        self.sign = coefficient.isZero ? .plus : sign
        
        if coefficient.isZero {
            self.coefficient = 0
            self.exponent = 0
            self.calculationPrecision = calculationPrecision
            return
        }
        
        var counter = 0
        while coefficient.isMultiple(of: PreciseUInt.pow10(counter + 1)) {
            counter += 1
        }
        
        let coefficient = coefficient / PreciseUInt.pow10(counter)
        let exponent = counter + exponent
        
        self.coefficient = coefficient
        self.exponent = exponent
        self.calculationPrecision = calculationPrecision
    }

    init(_ value: Int) {
        let sign: FloatingPointSign = value.signum() == -1 ? .minus : .plus
        let coefficient = PreciseUInt(value.magnitude)
        let exponent = 0
        
        self.init(sign: sign, coefficient: coefficient, exponent: exponent)
    }

    init(_ value: PreciseInt) {
        let sign: FloatingPointSign = value.signum() == -1 ? .minus : .plus
        let coefficient = value.magnitude
        let exponent = 0
        
        self.init(sign: sign, coefficient: coefficient, exponent: exponent)
    }
    
    init(_ value: PreciseFloat) {
        self = value
    }
    
    init(_ value: Double) {
        print(String(value))
        if String(value).contains("e") {
            // in the form of 1.6495670792428002e-31
            let value = String(value)
            let coefficient = PreciseFloat(String(value[value.startIndex..<value.firstIndex(of: "e")!]))!
            let base = PreciseFloat(String(value[value.index(after: value.firstIndex(of: "e")!)..<value.endIndex]))!
            self = coefficient * pow(10, base)
            return
        }
        self.init(String(value))!
    }
    
    init<Source>(_ value: Source) where Source: BinaryInteger {
        let sign: FloatingPointSign = value.signum() == -1 ? .minus : .plus
        let coefficient = PreciseUInt(value.magnitude)
        let exponent = 0
        
        self.init(sign: sign, coefficient: coefficient, exponent: exponent)
    }
    
    init<Source>(_ value: Source) where Source: BinaryFloatingPoint {
        self.init(Double(value))
    }
    
    init?<Source>(exactly value: Source) where Source : BinaryInteger {
        let sign: FloatingPointSign = value.signum() == -1 ? .minus : .plus
        guard let coefficient = PreciseUInt(exactly: value.magnitude) else { return nil }
        let exponent = 0
        
        self.init(sign: sign, coefficient: coefficient, exponent: exponent)
    }
    
    init(sign: FloatingPointSign, exponent: Int, significand: PreciseFloat) {
        let coefficient = significand.coefficient
        let exponent = exponent + significand.exponent
        
        self.init(sign: sign, coefficient: coefficient, exponent: exponent)
    }
    
    init(signOf: PreciseFloat, magnitudeOf: PreciseFloat) {
        let sign = signOf.sign
        let coefficient = magnitudeOf.coefficient
        let exponent = magnitudeOf.exponent
        
        self.init(sign: sign, coefficient: coefficient, exponent: exponent)
    }
    
    init?<Source>(exactly value: Source) where Source : BinaryFloatingPoint {
        let sign = value.sign
        var coefficient = value.magnitude
        var exponent = 0
        
        while coefficient.remainder(dividingBy: 10) != 0 {
            coefficient *= 10
            exponent -= 1
        }
        
        self.init(sign: sign, coefficient: PreciseUInt(coefficient), exponent: exponent)
    }
    
    init(sign: FloatingPointSign, exponentBitPattern: PreciseUInt, significandBitPattern: PreciseUInt) {
        self.init(Double(sign: sign, exponentBitPattern: UInt(exponentBitPattern), significandBitPattern: UInt64(significandBitPattern)))
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        // Decode sign
        let sign: FloatingPointSign
        switch try container.decode(String.self) {
        case "+":
            sign = .plus
        case "-":
            sign = .minus
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "sign"))
        }
        
        let coefficient = try container.decode(Coefficient.self)
        let exponent = try container.decode(Exponent.self)
        
        self.init(sign: sign, coefficient: coefficient, exponent: exponent)
    }
    
    init?(_ description: String) {
        let sign: FloatingPointSign
        var value = description
        if value.first == "-" {
            sign = .minus
            value.removeFirst()
        } else {
            sign = .plus
        }
        
        if value.contains(".") {
            value.remove(at: value.firstIndex(of: ".")!)
        }
        guard let coefficient = PreciseUInt(value) else { return nil }
        
        var counter = 0
        if description.contains(".") {
            while description[description.index(description.endIndex, offsetBy: counter - 1)] != "." {
                counter -= 1
            }
        }
        
        self.init(sign: sign, coefficient: coefficient, exponent: counter)
    }
    
    init(_ value: Fraction) {
        self = PreciseFloat(value.numerator) / PreciseFloat(value.denominator)
    }
    
    init(integerLiteral value: IntegerLiteralType) {
        let sign: FloatingPointSign = value.signum() == -1 ? .minus : .plus
        let coefficient = PreciseUInt(value.magnitude)
        let exponent = 0
        
        self.init(sign: sign, coefficient: coefficient, exponent: exponent)
    }
    
    init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
    
    
    //MARK: Instance Methods
    
    /// Returns the result of adding the product of the two given values to this value, computed without intermediate rounding.
    func addingProduct(_ lhs: PreciseFloat, _ rhs: PreciseFloat) -> PreciseFloat {
        return self + lhs * rhs
    }
    
    /// Adds the product of the two given values to this value in place, computed without intermediate rounding.
    mutating func addProduct(_ lhs: PreciseFloat, _ rhs: PreciseFloat) {
        self += lhs * rhs
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sign == .plus ? "+" : "-")
        try container.encode(self.coefficient)
        try container.encode(self.exponent)
    }
    
    /// Returns the remainder of this value divided by the given value.
    func remainder(dividingBy other: PreciseFloat) -> PreciseFloat {
        var quotient = self / other
        quotient.round(.towardZero)
        return self - other * quotient
    }
    
    /// Replaces this value with the remainder of itself divided by the given value.
    mutating func formRemainder(dividingBy other: PreciseFloat) {
        self = self.remainder(dividingBy: other)
    }
    
    /// Returns the square root of the value, rounded to a representable value.
    func squareRoot() -> PreciseFloat {
        if self == 0 { return 0 }
        
        // find using newton's method
        let precision = self.calculationPrecision
        
        var xn: PreciseFloat = 1
        var xn1 = xn - (xn * xn - self) / (2 * xn)
        while abs(xn1 - xn) > pow(10, -precision - 1) {
            precondition(xn != 0)
            xn = xn1
            xn1 = xn - (xn * xn - self) / (2 * xn)
        }
        
        var coefficient = xn1.coefficient
        var exponent = xn1.exponent
        
        PreciseFloat.reduceWithPrecision(coefficient: &coefficient, exponent: &exponent, precision: precision)
        
        return PreciseFloat(sign: xn1.sign, coefficient: coefficient, exponent: exponent)
    }
    
    /// Replaces this value with its square root, rounded to a representable value.
    mutating func formSquareRoot() {
        self = self.squareRoot()
    }
    
    /// Returns the remainder of this value divided by the given value using truncating division.
    ///
    /// As I have no idea what this is, this is the same as `remainder(dividingBy: other)`.
    func truncatingRemainder(dividingBy other: PreciseFloat) -> PreciseFloat {
        return remainder(dividingBy: other)
    }
    
    /// Replaces this value with the remainder of itself divided by the given value using truncating division.
    mutating func formTruncatingRemainder(dividingBy other: PreciseFloat) {
        self = self.truncatingRemainder(dividingBy: other)
    }
    
    /// Returns a Boolean value indicating whether this instance is equal to the given value.
    ///
    /// - Important: This determines whether two values are completely equal. This may result in `false` even though two instances are mathematically equal.
    func isEqual(to other: PreciseFloat) -> Bool {
        return self.sign == other.sign && self.coefficient == other.coefficient && self.exponent == other.exponent
    }
    
    /// Returns a Boolean value indicating whether this instance is less than the given value.
    func isLess(than other: PreciseFloat) -> Bool {
        switch (self.sign, other.sign) {
        case (.plus, .plus):
            if self.exponent == other.exponent { return self.coefficient < other.coefficient }
            if self.coefficient == other.coefficient { return self.exponent < other.exponent }
            let max = Swift.max(abs(self.exponent), abs(other.exponent))
            let lhs = self.coefficient * PreciseUInt.pow10(self.exponent + max)
            let rhs = other.coefficient * PreciseUInt.pow10(other.exponent + max)
            return lhs < rhs
        case (.plus, .minus):
            return false
        case (.minus, .plus):
            return true
        case (.minus, .minus):
            return !(self.opposite() < self.opposite())
        }
    }
    
    /// Returns a Boolean value indicating whether this instance is less than or equal to the given value.
    func isLessThanOrEqualTo(_ other: PreciseFloat) -> Bool {
        return self.isEqual(to: other) || self.isLess(than: other)
    }
    
    /// Returns a Boolean value indicating whether this instance should precede or tie positions with the given value in an ascending sort.
    func isTotallyOrdered(belowOrEqualTo other: PreciseFloat) -> Bool {
        return self <= other
    }
    
    /// Replaces this value with its additive inverse.
    mutating func negate() {
        self = self.opposite()
    }
    
    /// Returns this value rounded to an integral value using the specified rounding rule.
    func rounded(_ rule: FloatingPointRoundingRule) -> PreciseFloat {
        guard self.exponent < 0 else { return self }
        
        switch rule {
        case .toNearestOrAwayFromZero:
            var value = self.coefficient / PreciseUInt.pow10(abs(self.exponent) - 1)
            value = value % 10 >= 5 ? value / 10 + 1 : value / 10
            return PreciseFloat(sign: self.sign, coefficient: value, exponent: 0)
        case .toNearestOrEven:
            var value = self.coefficient / PreciseUInt.pow10(abs(self.exponent) - 1)
            if value % 10 == 5 {
                if (value / 10) % 2 == 0 { value = value / 10 } else { value = value / 10 + 1 }
            } else if value % 10 > 5 {
                value = value / 10 + 1
            } else {
                value = value / 10
            }
            return PreciseFloat(sign: self.sign, coefficient: value, exponent: 0)
        case .up:
            var value = self.coefficient / PreciseUInt.pow10(abs(self.exponent))
            if self.sign == .plus { value += 1 }
            return PreciseFloat(sign: self.sign, coefficient: value, exponent: 0)
        case .down:
            var value = self.coefficient / PreciseUInt.pow10(abs(self.exponent))
            if self.sign == .minus { value += 1 }
            return PreciseFloat(sign: self.sign, coefficient: value, exponent: 0)
        case .towardZero:
            let value = self.coefficient / PreciseUInt.pow10(abs(self.exponent))
            return PreciseFloat(sign: self.sign, coefficient: value, exponent: 0)
        case .awayFromZero:
            var value = self.coefficient / PreciseUInt.pow10(abs(self.exponent))
            value += 1
            return PreciseFloat(sign: self.sign, coefficient: value, exponent: 0)
        @unknown default:
            fatalError()
        }
    }
    
    /// Rounds the value to an integral value using the specified rounding rule.
    mutating func round(_ rule: FloatingPointRoundingRule) {
        self = self.rounded(rule)
    }
    
    /// Returns this value rounded to an integral value using “schoolbook rounding.”
    func rounded() -> PreciseFloat {
        return rounded(.toNearestOrAwayFromZero)
    }
    
    /// Rounds this value to an integral value using “schoolbook rounding.”
    mutating func round() {
        self = self.rounded()
    }
    
    /// Returns the distance from this value to the given value, expressed as a stride.
    func distance(to other: PreciseFloat) -> PreciseInt {
        return PreciseInt(abs(self - other))
    }
    
    /// Returns a value that is offset the specified distance from this value.
    func advanced(by n: PreciseInt) -> PreciseFloat {
        return self + PreciseFloat(n)
    }
    
    /// The value with same magnitude, but different sign.
    func opposite() -> PreciseFloat {
        return PreciseFloat(sign: self.sign == .minus ? .plus : .minus, coefficient: self.coefficient, exponent: self.exponent)
    }
    
    /// The reciprocal
    func reciprocal() -> PreciseFloat {
        return 1 / self
    }
    
    fileprivate func reduceWithPrecision(precision: Int) -> PreciseFloat {
        var coefficient = self.coefficient
        var exponent = self.exponent
        
        PreciseFloat.reduceWithPrecision(coefficient: &coefficient, exponent: &exponent, precision: precision)
        
        return PreciseFloat(sign: self.sign, coefficient: coefficient, exponent: exponent, calculationPrecision: self.calculationPrecision)
    }
    
    
    //MARK: Type Methods
    
    /// Returns the greater of the two given values.
    static func maximum(_ x: PreciseFloat, _ y: PreciseFloat) -> PreciseFloat {
        return x > y ? x : y
    }
    
    /// Returns the value with greater magnitude.
    static func maximumMagnitude(_ x: PreciseFloat, _ y: PreciseFloat) -> PreciseFloat {
        return x.magnitude > y.magnitude ? x : y
    }

    /// Returns the lesser of the two given values.
    static func minimum(_ x: PreciseFloat, _ y: PreciseFloat) -> PreciseFloat {
        return x < y ? x : y
    }

    /// Returns the value with lesser magnitude.
    static func minimumMagnitude(_ x: PreciseFloat, _ y: PreciseFloat) -> PreciseFloat {
        return x.magnitude < y.magnitude ? x : y
    }
    
    fileprivate static func reduceWithPrecision(coefficient: inout Coefficient, exponent: inout Exponent, precision: Int) {
        if exponent < -precision {
            while exponent < -precision {
                coefficient /= 10
                exponent += 1
            }
        }
    }
    
    
    //MARK: Operator Functions
    
    /// Add two **positive** `PreciseFloat`
    private static func addition(positive lhs: PreciseFloat, positive rhs: PreciseFloat) -> PreciseFloat {
        if lhs.exponent == rhs.exponent { return PreciseFloat(sign: .plus, coefficient: lhs.coefficient + rhs.coefficient, exponent: lhs.exponent, calculationPrecision: Swift.min(lhs.calculationPrecision, rhs.calculationPrecision)) }
        
        let smaller = lhs.exponent < rhs.exponent ? lhs : rhs
        let larger = lhs.exponent > rhs.exponent ? lhs : rhs
        let delta = larger.exponent - smaller.exponent
        
        let coefficient = smaller.coefficient + larger.coefficient * PreciseUInt.pow10(delta)
        return PreciseFloat(sign: .plus, coefficient: coefficient, exponent: smaller.exponent, calculationPrecision: Swift.min(lhs.calculationPrecision, rhs.calculationPrecision))
    }
    
    /// subtract two **positive** `PreciseFloat`
    static func subtraction(positive lhs: PreciseFloat, positive rhs: PreciseFloat) -> PreciseFloat {
        if lhs.exponent == rhs.exponent {
            let sign: FloatingPointSign = lhs.coefficient > rhs.coefficient ? .plus : .minus
            let coefficient = lhs.coefficient > rhs.coefficient ? lhs.coefficient - rhs.coefficient : rhs.coefficient - lhs.coefficient
            return PreciseFloat(sign: sign, coefficient: coefficient, exponent: lhs.exponent, calculationPrecision: Swift.min(lhs.calculationPrecision, rhs.calculationPrecision))
        }
        
        let smaller = lhs.exponent < rhs.exponent ? lhs : rhs
        let larger = lhs.exponent > rhs.exponent ? lhs : rhs
        let delta = larger.exponent - smaller.exponent
        
        let sign: FloatingPointSign = lhs.magnitude > rhs.magnitude ? .plus : .minus
        
        let coefficient: PreciseUInt
        if larger.coefficient * PreciseUInt.pow10(delta) < smaller.coefficient {
            coefficient = smaller.coefficient - larger.coefficient * PreciseUInt.pow10(delta)
        } else {
            coefficient = larger.coefficient * PreciseUInt.pow10(delta) - smaller.coefficient
        }
        
        return PreciseFloat(sign: sign, coefficient: coefficient, exponent: smaller.exponent, calculationPrecision: Swift.min(lhs.calculationPrecision, rhs.calculationPrecision))
    }
    
    static func + (_ lhs: PreciseFloat, _ rhs: PreciseFloat) -> PreciseFloat {
        switch (lhs.sign, rhs.sign) {
        case (.plus, .plus):
            return addition(positive: lhs, positive: rhs)
        case (.plus, .minus):
            return subtraction(positive: lhs, positive: rhs)
        case (.minus, .plus):
            return subtraction(positive: rhs, positive: lhs)
        case (.minus, .minus):
            return addition(positive: lhs, positive: rhs).opposite()
        }
    }
    
    static func += (_ lhs: inout PreciseFloat, _ rhs: PreciseFloat) {
        lhs = lhs + rhs
    }
    
    static func - (_ lhs: PreciseFloat, _ rhs: PreciseFloat) -> PreciseFloat {
        switch (lhs.sign, rhs.sign) {
        case (.plus, .plus):
            return subtraction(positive: lhs, positive: rhs)
        case (.plus, .minus):
            return addition(positive: lhs, positive: rhs)
        case (.minus, .plus):
            return addition(positive: lhs, positive: rhs).opposite()
        case (.minus, .minus):
            return subtraction(positive: lhs.opposite(), positive: rhs.opposite()).opposite()
        }
    }
    
    static func -= (_ lhs: inout PreciseFloat, _ rhs: PreciseFloat) {
        lhs = lhs - rhs
    }
    
    static func * (_ lhs: PreciseFloat, _ rhs: PreciseFloat) -> PreciseFloat {
        if lhs == 1 { return rhs }
        if lhs == -1 { return rhs.opposite() }
        if rhs == 1 { return lhs }
        if rhs == -1 { return lhs.opposite() }
        
        let coefficient = lhs.coefficient * rhs.coefficient
        let sign: FloatingPointSign = lhs.sign == rhs.sign ? .plus : .minus
        let exponent = lhs.exponent + rhs.exponent
        
        return PreciseFloat(sign: sign, coefficient: coefficient, exponent: exponent, calculationPrecision: Swift.min(lhs.calculationPrecision, rhs.calculationPrecision))
    }
    
    static func *= (_ lhs: inout PreciseFloat, _ rhs: PreciseFloat) {
        lhs = lhs * rhs
    }
    
    static func / (_ lhs: PreciseFloat, _ rhs: PreciseFloat) -> PreciseFloat {
        if rhs == 1 { return lhs }
        if rhs == 0 { return lhs.sign == .plus ? PreciseFloat.infinity : -PreciseFloat.infinity }
        if rhs == -1 { return lhs.opposite() }
        if lhs == 0 { return 0 }
        
        let precision = min(lhs.calculationPrecision, rhs.calculationPrecision) + abs(lhs.exponent - rhs.exponent)
        
        let lhsValue = lhs.coefficient * PreciseUInt.pow10(precision)
        let rhsValue = rhs.coefficient
        
        var coefficient = lhsValue / rhsValue
        let sign: FloatingPointSign = lhs.sign == rhs.sign ? .plus : .minus
        var exponent = lhs.exponent - rhs.exponent  - precision
        
        PreciseFloat.reduceWithPrecision(coefficient: &coefficient, exponent: &exponent, precision: precision)
        
        return PreciseFloat(sign: sign, coefficient: coefficient, exponent: exponent, calculationPrecision: precision)
    }
    
    static func /= (_ lhs: inout PreciseFloat, _ rhs: PreciseFloat) {
        lhs = lhs / rhs
    }
}

extension Double {
    init(_ value: PreciseFloat) {
        self.init(String(value))!
    }
}

extension BinaryFloatingPoint {
    init(_ value: PreciseFloat) {
        self.init(Double(value))
    }
}

func pow(_ lhs: PreciseFloat, _ rhs: Int) -> PreciseFloat {
    let sign: FloatingPointSign = rhs.isMultiple(of: 2) ? .plus : lhs.sign
    let coefficient = pow(lhs.coefficient, rhs)
    let exponent = lhs.exponent * rhs
    
    return PreciseFloat(sign: sign, coefficient: coefficient, exponent: exponent)
}

func pow(_ lhs: PreciseFloat, _ rhs: PreciseFloat, precision: Int? = nil) -> PreciseFloat {
    let precision = precision ?? Swift.min(lhs.calculationPrecision, rhs.calculationPrecision)
    
    // calculate using exp.
    var lhs = lhs
    var rhs = rhs
    lhs.calculationPrecision = precision
    rhs.calculationPrecision = precision
    
    var value = exp(rhs * log(lhs))
    value.calculationPrecision = Swift.min(lhs.calculationPrecision, rhs.calculationPrecision)
    return value.reduceWithPrecision(precision: precision)
}

/// calculate `e^x`.
///
/// It would iterate for at most 20 times.
func exp(_ item: PreciseFloat) -> PreciseFloat {
    if item == 1 { return PreciseFloat.e }
    var value: PreciseFloat = 1
    value.calculationPrecision = item.calculationPrecision
    var newValue: PreciseFloat = item
    var counter = 2
    
    while newValue > pow(10, -item.calculationPrecision - 1) && counter <= 20 {
        value += newValue
        newValue = pow(item, counter) / PreciseFloat(PreciseInt(counter).factorial)
        counter += 1
    }
    
    return value.reduceWithPrecision(precision: item.calculationPrecision)
}

/// The Natural logarithm
func log(_ item: PreciseFloat) -> PreciseFloat {
    // use newton's method
    var yn: PreciseFloat = 1
    yn.calculationPrecision = item.calculationPrecision
    
    var yn1 = yn + 2 * (item - exp(yn)) / (item + exp(yn))
    yn1.calculationPrecision = item.calculationPrecision
    
    while abs(yn1 - yn) > pow(10, -item.calculationPrecision - 1) {
        yn = yn1
        yn.calculationPrecision = item.calculationPrecision
        yn1 = yn + 2 * (item - exp(yn)) / (item + exp(yn))
        yn1.calculationPrecision = item.calculationPrecision
    }
    
    return yn1.reduceWithPrecision(precision: item.calculationPrecision)
}

/// The `sin` of `theta`.
///
/// - Parameters:
///     - theta: in radian.
func sin(_ theta: PreciseFloat, precision: Int? = nil) -> PreciseFloat {
    switch theta.remainder(dividingBy: 2 * PreciseFloat.pi) {
    case 0:
        return 0
    case 0.5*PreciseFloat.pi:
        return 1
    case 1*PreciseFloat.pi:
        return 0
    case 1.5*PreciseFloat.pi:
        return -1
    default:
        break
    }
    
    let precision = precision ?? theta.calculationPrecision
    var value: PreciseFloat = 0
    value.calculationPrecision = precision
    var counter: Int = 1
    var delta = theta
    delta.calculationPrecision = precision
    while abs(delta) > pow(10, -1 * precision - 1) && counter < 30 {
        value += delta
        delta = PreciseFloat(pow(-1, counter)) / PreciseFloat(PreciseInt(2*counter + 1).factorial) * pow(theta, 2*counter + 1)
        counter += 1
    }
    
    return value.reduceWithPrecision(precision: precision)
}

/// The `cos` of `theta`.
///
/// - Parameters:
///     - theta: in radian.
func cos(_ theta: PreciseFloat, precision: Int? = nil) -> PreciseFloat {
    switch theta.remainder(dividingBy: 2 * PreciseFloat.pi) {
    case 0:
        return 1
    case 0.5*PreciseFloat.pi:
        return 0
    case 1*PreciseFloat.pi:
        return -1
    case 1.5*PreciseFloat.pi:
        return 0
    default:
        break
    }
    
    let precision = precision ?? theta.calculationPrecision
    var value: PreciseFloat = 0
    value.calculationPrecision = precision
    var counter: Int = 1
    var delta: PreciseFloat = 1
    delta.calculationPrecision = precision
    while abs(delta) > pow(10, -1 * precision - 1) && counter < 30 {
        value += delta
        delta = PreciseFloat(pow(-1, counter)) / PreciseFloat(PreciseInt(2*counter).factorial) * pow(theta, 2*counter)
        counter += 1
    }
    return value.reduceWithPrecision(precision: precision)
}

/// The `tan` of `theta`.
///
/// - Parameters:
///     - theta: in radian.
func tan(_ theta: PreciseFloat, precision: Int? = nil) -> PreciseFloat {
    return sin(theta, precision: precision) / cos(theta, precision: precision)
}

/// The arcsin of `z`.
///
/// - Precondition: `|z| ≤ 1`
func arcsin(_ z: PreciseFloat, precision: Int? = nil) -> PreciseFloat {
    precondition(abs(z) <= 1, "mathematical error: z should be less than 1")
    
    switch z {
    case -1:
        return -1 / 2 * PreciseFloat.pi
    case -0.5:
        return -1 / 6 * PreciseFloat.pi
    case 0:
        return 0
    case 0.5:
        return 1 / 6 * PreciseFloat.pi
    case 1:
        return 1 / 2 * PreciseFloat.pi
    default:
        break
    }
    
    let precision = precision ?? z.calculationPrecision
    var value: PreciseFloat = 0
    value.calculationPrecision = precision
    var counter: Int = 1
    var delta: PreciseFloat = z
    delta.calculationPrecision = precision
    while abs(delta) > pow(10, -1 * precision - 1) && counter < 11 {
        value += delta
        delta = PreciseFloat((2*counter).factorial) / pow(pow(2, counter) * PreciseFloat(counter.factorial), 2) * pow(z, 2*counter+1) / PreciseFloat(2*counter+1)
        counter += 1
    }
    return value.reduceWithPrecision(precision: precision)
}

/// The arccos of `z`.
///
/// - Precondition: `|z| ≤ 1`
func arccos(_ z: PreciseFloat, precision: Int? = nil) -> PreciseFloat {
    return PreciseFloat.pi / 2 - arcsin(z, precision: precision)
}

/// The arctan of `z`.
///
/// - Precondition: `|z| ≤ 1`
///
/// - Note: By default, it would iterate for at most 200 times, however, the precision is only 10^(-5).
///
/// - Parameters:
///     - iterations: The more iterations, the more time it would take, and more precise it would be.
func arctan(_ z: PreciseFloat, precision: Int? = nil, iterations: Int = 200) -> PreciseFloat {
    precondition(abs(z) <= 1, "mathematical error: z should be less than 1")
    
    switch z {
    case -1:
        return -1 / 4 * PreciseFloat.pi
    case 0:
        return 0
    case 1:
        return 1 / 4 * PreciseFloat.pi
    default:
        break
    }
    
    let precision = precision ?? z.calculationPrecision
    
    var value: PreciseFloat = 0
    value.calculationPrecision = precision
    
    var delta: PreciseFloat = z
    delta.calculationPrecision = precision
    
    var counter: Int = 1
    while abs(delta) > pow(10, -1 * precision - 1) && counter <= iterations {
        value += delta
        delta = pow(-1, counter) * pow(z, 2 * counter + 1) / PreciseFloat(2 * counter + 1)
        counter += 1
    }
    return value.reduceWithPrecision(precision: precision)
}

func log(_ value: PreciseFloat, base: PreciseFloat) -> PreciseFloat {
    return log(value) / log(base)
}

/// The square root.
func sqrt(_ x: PreciseFloat) -> PreciseFloat {
    return x.squareRoot()
}
*/
