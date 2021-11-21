//
//  Int10.swift
//  cmd
//
//  Created by Vaida on 11/8/21.
//

import Foundation

/// A structure of arbitrary-precise Unsigned Integer of radix 10.
struct UInt10: Arithmetical {
    
    //MARK: - Basic Instance Properties
    
    /// The words of the `Int`, in radix 10.
    ///
    /// - Important: The words are in reversed order.
    var words: [Word] = []
    
    
    //MARK: - Instance Properties
    
    /// The description of this value.
    var description: String {
        return self.normalized().words.reversed().reduce("", { $0 + String($1.content) })
    }
    
    /// Determine whether the `UInt10` is `0`.
    var isZero: Bool {
        return self.words.allSatisfy({ $0 == 0 }) || self.words.isEmpty
    }
    
    var magnitude: UInt10 {
        return self
    }
    
    
    //MARK: - Type Properties
    
    /// The `0` value.
    ///
    /// The value was set to `<UInt10: [0]>`.
    static var zero: Self {
        return self.init(words: [0])
    }
    
    static var isSigned: Bool {
        return false
    }
    
    
    //MARK: - Initializers
    
    /// Creates an instance with its words.
    ///
    /// - Important: The words are in reversed order.
    ///
    /// **Example**
    ///
    ///     print(UInt10(words: [1, 2, 3]))
    ///     // prints "321"
    ///
    /// - Parameters:
    ///    - words: The words in radix 10.
    init(words: [Word]) {
        self.words = words
    }
    
    /// Creates an instance with empty words.
    ///
    /// - Important: It creates an instance of `<UInt10: []>`, which is not `zero`.
    ///
    /// **Example**
    ///
    ///     print(UInt10())
    ///     // prints ""
    private init() {
        self.init(words: [])
    }
    
    /// Creates an instance with an `UnsignedInteger`.
    ///
    /// - Parameters:
    ///    - value: The unsigned Integer as an argument.
    init<T>(_ value: T) where T: UnsignedInteger {
        var content: [Word] = []
        var value = value
        while value >= 10 {
            content.append(UInt10.Word(UInt8(value % 10)))
            value /= 10
        }
        content.append(UInt10.Word(UInt8(value)))
        self.words = content
    }
    
    /// Creates an instance with an `BinaryInteger`.
    init<T>(_ value: T) where T : BinaryInteger {
        self.init(UInt(value))
    }
    
    /// Creates an instance with a `String`.
    ///
    /// - Attention: The initialization fails if the `String` does not represent a `UInt`.
    ///
    /// - Parameters:
    ///    - value: The string as an argument.
    init?(_ value: String) {
        var words: [Word] = []
        for i in value {
            guard let value = UInt8(String(i)) else { return nil }
            words.append(UInt10.Word(value))
        }
        self.init(words: words.reversed())
    }
    
    /// Creates an instance with a `Substring`.
    ///
    /// - Attention: The initialization fails if the `Substring` does not represent a `UInt`.
    ///
    /// - Parameters:
    ///    - value: The string as an argument.
    init?(_ value: Substring) {
        var words: [Word] = []
        for i in value {
            guard let value = UInt8(String(i)) else { return nil }
            words.append(UInt10.Word(value))
        }
        self.init(words: words.reversed())
    }
    
    /// Creates an instance with an `UnsignedInteger`.
    ///
    /// - Parameters:
    ///    - value: The unsigned Integer as an argument.
    init(integerLiteral value: UInt) {
        self.init(value)
    }
    
    /// Creates an instance from data.
    ///
    /// - Note: The `UInt10` is stored in the form of `UInt`.
    ///
    /// - Parameters:
    ///    - decoder: The decoder used.
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let stringWords = try container.decode(String.self)
        let words: [Word] = stringWords.reversed().map({ Word(UInt8(String($0))!) })
        self.init(words: words)
    }
    
    
    //MARK: - Instance Methods
    
    /// Encodes an `UInt10`.
    ///
    /// - Note: The `UInt10` is stored in the form of `UInt`.
    ///
    /// - Parameters:
    ///    - encoder: The encoder used.
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.normalized().words.reversed().map({ $0.content }).reduce("", { $0 + String($1) }))
    }
    
    /// Extends the words of this `UInt10`.
    ///
    /// - Important: This is a supporting function. Please use `subscript` instead.
    ///
    /// - Parameters:
    ///    - index: The index to which extended.
    ///    - value: The value to be extended by.
    mutating private func extend(with value: Word, index: Int) {
        precondition(index >= self.words.count, "Please use subscript directly.")
        while self.words.count <= index + 1 { self.words.append(0) }
        self.words[index] = value
    }
    
    /// Determines whether the instance is a multiple of another.
    func isMultiple(of: UInt10) -> Bool {
        return Self.divide(lhs: self, rhs: of).remainder.isZero
    }
    
    /// Remove the unwanted zeros.
    mutating func normalize() {
        self = self.normalized()
    }
    
    /// Remove the unwanted zeros.
    func normalized() -> Self {
        var value = self
        while value.words.last == 0 && value.words.count != 1 {
            value.words.removeLast()
        }
        return value
    }
    
    /// Returns a value that equals to `self` \* 10 ^ `power`.
    ///
    /// **Example**
    ///
    ///     print(1.pow10(2))
    ///     // prints "100"
    ///
    /// - Parameters:
    ///    - power: The power to raise.
    ///
    /// - Returns: The value with the raised power.
    func pow10(_ power: Int) -> Self {
        var content = Array(self.words.reversed())
        content.append(contentsOf: [Word](repeating: Word(0), count: power))
        return Self.init(words: content.reversed())
    }
    
    /// Calculates and returns the quotient and remainder of dividing `self` by `dividingBy`.
    ///
    /// - Parameters:
    ///    - dividingBy: The value as a divisor.
    func quotientAndRemainder(dividingBy: UInt10) -> (quotient: UInt10, remainder: UInt10) {
        let result = Self.divide(lhs: self, rhs: dividingBy)
        return (result.quotient, result.remainder)
    }
    
    /// Returns an instance with its words revered.
    ///
    /// - Important: As this function will return an instance different from the original one, use with care.
    private func reversed() -> Self {
        return Self.init(words: self.words.reversed())
    }
    
    /// The square of the `fraction`, or, `self * self`.
    func square() -> UInt10 {
        return self * self
    }
    
    
    //MARK: - Type Methods
    
    /// A supporting function for `+ (_, _)`.
    static private func addingLoop(lhs: inout Self, rhs: Word, at index: Int) {
        let result = lhs[index].addingReportingOverflow(rhs)
        if result.overflow {
            addingLoop(lhs: &lhs, rhs: 1, at: index + 1)
        }
        lhs[index] = result.partialValue
    }
    
    /// A supporting function for `/ (_, _)`.
    static private func divide(lhs: Self, rhs: Self) -> (quotient: Self, remainder: Self) {
        precondition(rhs != 0, "Division by zero")
        
        
        // Use `UInt` to accelerate results.
        guard lhs > Self(UInt.max) && rhs > Self(UInt.max) else {
            let result = UInt(lhs).quotientAndRemainder(dividingBy: UInt(rhs))
            return (Self(result.quotient), Self(result.remainder))
        }
        
        var remainders: Self = lhs
        var quotients: Self = Self()
        
        let lhs = lhs.normalized()
        let rhs = rhs.normalized()
        
        var index = 0
        while index < lhs.words.count && remainders >= rhs {
            let lhsSmall = Self(words: Array(remainders.words[lhs.words.count - (index+rhs.words.count)..<remainders.words.count]))
            guard lhsSmall >= rhs else { index += 1; quotients.words.append(0); continue }
            
            var result: Word = 0
            while (Self(words: [result]) + 1) * rhs <= lhsSmall { result += 1 }
            
            quotients.words.append(result)
            
            remainders -= (Self(words: [result]) * rhs).pow10(lhs.words.count - rhs.words.count - quotients.words.count + 1)
            remainders.normalize()
            
            index += 1
        }
        if quotients.words.isEmpty { quotients.words = [0] }
        quotients = quotients.reversed()
        
        while (lhs - remainders) != quotients * rhs {
            quotients.words.insert(0, at: 0)
        }
        
        return (quotients, remainders)
    }
    
    
    //MARK: - Operator Methods
    
    /// Addition of two `UInt10`s.
    static func + (_ lhs: Self, _ rhs: Self) -> Self {
        var answer = lhs
        var index = 0
        
        while index < rhs.words.count {
            addingLoop(lhs: &answer, rhs: rhs[index], at: index)
            
            index += 1
        }
        
        return answer
    }
    
    /// Addition of two `UInt10`s, and stores in `lhs`.
    static func += (_ lhs: inout Self, _ rhs: Self) {
        lhs = lhs + rhs
    }
    
    /// Subtraction of two `UInt10`s.
    static func - (_ lhs: Self, _ rhs: Self) -> Self {
        precondition(lhs >= rhs)
        var lhs = lhs
        var index = 0
        
        while index < rhs.words.count {
            subtractLoop(lhs: &lhs, rhs: rhs[index], index: index)
            
            index += 1
        }
        
        func subtractLoop(lhs: inout Self, rhs: Word, index: Int) {
            let result = lhs[index].subtractingReportingOverflow(rhs)
            if result.overflow {
                subtractLoop(lhs: &lhs, rhs: 1, index: index + 1)
            }
            lhs[index] = result.partialValue
        }
        
        return lhs
    }
    
    /// Subtraction of two `UInt10`s, and stores in `lhs`.
    static func -= (_ lhs: inout Self, _ rhs: Self) {
        lhs = lhs - rhs
    }
    
    /// Multiplication of two `UInt10`s.
    static func * (_ lhs: Self, _ rhs: Self) -> Self {
        var answer: Self = Self.init(words: [])
        
        var index = 0
        var carry: Word = 0
        while index < rhs.words.count || carry != 0 {
            var index2 = 0
            while index2 < lhs.words.count || carry != 0 {
                let result = lhs[index2].multipliedFullWidth(by: rhs[index])
                addingLoop(lhs: &answer, rhs: carry, at: index + index2)
                addingLoop(lhs: &answer, rhs: result.low, at: index2 + index)
                carry = result.high
                
                index2 += 1
            }
            
            index += 1
        }
        
        assert(answer.words.allSatisfy({ $0 < 10 }), answer.words.description)
        return answer
    }
    
    /// Multiplication of two `UInt10`s, and stores in `lhs`.
    static func *= (_ lhs: inout Self, _ rhs: Self) {
        lhs = lhs * rhs
    }
    
    /// Division of two `UInt10`s.
    static func / (_ lhs: Self, _ rhs: Self) -> Self {
        let result = divide(lhs: lhs, rhs: rhs)
        return result.quotient
    }
    
    /// Division of two `UInt10`s, and stores in `lhs`.
    static func /= (_ lhs: inout Self, _ rhs: Self) {
        lhs = lhs / rhs
    }
    
    /// The remainder of division of two `UInt10`s.
    static func % (_ lhs: Self, _ rhs: Self) -> Self {
        let result = divide(lhs: lhs, rhs: rhs)
        return result.remainder
    }
    
    /// The remainder of division of two `UInt10`s, and stores in `lhs`.
    static func %= (_ lhs: inout Self, _ rhs: Self) {
        lhs = lhs % rhs
    }
    
    
    //MARK: - Comparison Methods
    
    /// Determines whether the `lhs` is less than the `rhs`.
    static func < (_ lhs: Self, _ rhs: Self) -> Bool {
        guard lhs != rhs else { return false }
        guard lhs.normalized().words.count == rhs.normalized().words.count else { return lhs.normalized().words.count < rhs.normalized().words.count }
        var index = lhs.words.count - 1
        while true {
            if lhs[index] < rhs[index]  {
                return true
            } else if lhs[index] > rhs[index]  {
                return false
            }
            
            index -= 1
        }
        assert(false)
    }
    
    /// Determines whether the `lhs` is equal to the `rhs`.
    static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        return lhs.normalized().words == rhs.normalized().words
    }
    
    
    
    //MARK: - Substructures
    
    /// Each individual word, ranged from 0 to 9 inclusive.
    struct Word: Arithmetical {
        
        /// The main content of this word, ranged from 0 to 9 inclusive.
        var content: UInt8
        
        var magnitude: UInt10.Word {
            return self
        }
        
        var description: String {
            return self.content.description
        }
        
        static var zero: UInt10.Word {
            return self.init(0)
        }
        
        static var isSigned: Bool {
            return false
        }
        
        init(_ value: UInt8) {
            self.content = value
        }
        
        init(integerLiteral value: UInt8) {
            self.content = value
        }
        
        init<T>(_ value: T) where T : BinaryInteger {
            self.init(UInt8(value))
        }
        
        init?(_ description: String) {
            guard let value = UInt8(description) else { return nil }
            self.init(value)
        }
        
        /// Returns the sum of this value and the given value, along with a Boolean value indicating whether overflow occurred in the operation.
        ///
        /// - Parameters:
        ///     - rhs: The value to add to this value.
        func addingReportingOverflow(_ rhs: Word) -> (partialValue: Word, overflow: Bool) {
            precondition(self < 10 && rhs < 10)
            if self + rhs < 10 {
                return (self + rhs, false)
            } else {
                return (self + rhs - 10, true)
            }
        }
        
        /// Returns the difference obtained by subtracting the given value from this value, along with a Boolean value indicating whether overflow occurred in the operation.
        func subtractingReportingOverflow(_ other: Word) -> (partialValue: Word, overflow: Bool) {
            precondition(self < 10 && other < 10)
            if self >= other {
                return (self - other, false)
            } else {
                return (10 + self - other, true)
            }
        }
        
        /// Returns a tuple containing the high and low parts of the result of multiplying this value by the given value.
        func multipliedFullWidth(by other: Word) -> (high: Word, low: Word) {
            precondition(self < 10 && other < 10)
            return (self * other / 10, self * other % 10)
        }
        
        /// Returns a tuple containing the quotient and remainder of dividing the `dividend` by `self`.
        func dividingFullWidth(_ dividend: (high: Word, low: Word)) -> (quotient: Word, remainder: Word) {
            let result = (dividend.high * 10 + dividend.low) / self
            return (result / 10, result % 10)
        }
        
        /// Returns a tuple containing the quotient and remainder of dividing the `dividend` by `self`.
        func dividingFullWidth(_ dividend: Word) -> (quotient: Word, remainder: Word) {
            let result = dividend / self
            return (result / 10, result % 10)
        }
        
        
        static func + (_ lhs: Word, _ rhs: Word) -> Word {
            return Word(lhs.content + rhs.content)
        }
        
        static func += (_ lhs: inout Word, _ rhs: Word) {
            lhs = lhs + rhs
        }
        
        static func - (_ lhs: Word, _ rhs: Word) -> Word {
            return Word(lhs.content - rhs.content)
        }
        
        static func -= (_ lhs: inout Word, _ rhs: Word) {
            lhs = lhs - rhs
        }
        
        static func * (_ lhs: Word, _ rhs: Word) -> Word {
            return Word(lhs.content * rhs.content)
        }
        
        static func *= (_ lhs: inout Word, _ rhs: Word) {
            lhs = lhs * rhs
        }
        
        static func / (_ lhs: Word, _ rhs: Word) -> Word {
            return Word(lhs.content / rhs.content)
        }
        
        static func /= (_ lhs: inout Word, _ rhs: Word) {
            lhs = lhs / rhs
        }
        
        static func % (_ lhs: Word, _ rhs: Word) -> Word {
            return Word(lhs.content % rhs.content)
        }
        
        static func %= (_ lhs: inout Word, _ rhs: Word) {
            lhs = lhs % rhs
        }
        
        static func < (_ lhs: Word, _ rhs: Word) -> Bool {
            return lhs.content < rhs.content
        }
        
        static func == (_ lhs: Word, _ rhs: Word) -> Bool {
            return lhs.content == rhs.content
        }
    }
    
    //MARK: - Subscript
    
    /// Returns the value at the given index of words.
    ///
    /// - Important: The index can be `>= self.words.count`, under which condition its words will be extended.
    subscript(index: Int) -> Word {
        get {
            if index < self.words.count {
                return self.words[index]
            } else {
                return Word(0)
            }
        }
        
        set {
            if index < self.words.count {
                self.words[index] = newValue
            } else {
                self.extend(with: newValue, index: index)
            }
        }
    }
    
}


//MARK: - Int 10

/// A structure of arbitrary-precise Signed Integer of radix 10.
struct Int10: SignedArithmetical {
    
    //MARK: - Basic Instance Properties
    
    /// The inventory storing the `UInt10`.
    var inventory: UInt10
    
    /// The bool determining whether the value is positive.
    ///
    /// - Note: `0` is not positive.
    var isPositive: Bool
    
    
    //MARK: - Instance Properties
    
    /// The description of this instance.
    var description: String {
        return (self.signum() == -1 ? "-" : "") + self.inventory.description
    }
    
    /// All the factors of current Int. If `self` is less than or equal to 1, the only factor was set to 1.
    var factors: [Self] {
        guard abs(self) > 1 else { return [1] }
        var content: [Self] = []
        var counter: Self = 1
        let double = Double(self)
        while counter < Self(double.magnitude.squareRoot()) {
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
    
    /// The absolute value of this instance.
    var magnitude: Int10 {
        return Int10(isPositive: true, magnitude: self.inventory)
    }
    
    /// Determines whether the value is zero.
    var isZero: Bool {
        return self.inventory.isZero
    }
    
    
    //MARK: - Type Properties
    
    /// Returns the value representing `zero`.
    static var zero: Self {
        return Self(isPositive: false, magnitude: 0)
    }
    
    static var isSigned: Bool {
        return false
    }
    
    
    //MARK: - Initializers
    
    /// Creates an instance with a `BinaryInteger`.
    init<T>(_ value: T) where T: BinaryInteger {
        self.isPositive = value.signum() == 1 ? true : false
        self.inventory = UInt10(UInt(value.magnitude))
    }
    
    /// Creates an instance with a `BinaryFloatingPoint`.
    init<T>(_ value: T) where T: BinaryFloatingPoint {
        self.isPositive = value.sign == .plus ? true : false
        self.inventory = UInt10(UInt(value.magnitude))
    }
    
    /// Creates an instance with a `BinaryInteger`.
    init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
    
    /// Creates an instance with its positivity and magnitude.
    init(isPositive: Bool, magnitude: UInt10) {
        self.inventory = magnitude
        self.isPositive = magnitude == 0 ? false : isPositive
    }
    
    /// Creates an instance from a `String`.
    init?(_ description: String) {
        if description.first == "-" {
            guard let magnitude = UInt10(String(description.dropFirst())) else { return nil }
            self.init(isPositive: false, magnitude: magnitude)
        }
        guard let magnitude = UInt10(description) else { return nil }
        self.init(isPositive: true, magnitude: magnitude)
    }
    
    /// Creates an instance from a `Substring`.
    init?(_ description: Substring) {
        if description.first == "-" {
            guard let magnitude = UInt10(String(description.dropFirst())) else { return nil }
            self.init(isPositive: false, magnitude: magnitude)
        }
        guard let magnitude = UInt10(description) else { return nil }
        self.init(isPositive: true, magnitude: magnitude)
    }
    
    /// Creates an instance from data.
    ///
    /// - Note: `Int10` is stored in the form of "+/-" with UInt representation.
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var string = try container.decode(String.self)
        let stringSign = string.removeFirst()
        
        let words: [UInt10.Word] = string.reversed().map({ UInt10.Word(UInt8(String($0))!) })
        self.init(isPositive: stringSign == "+", magnitude: UInt10(words: words))
    }
    
    
    //MARK: - Instance Methods
    
    /// Encodes this instance with `encoder`.
    ///
    /// - Note: `Int10` is stored in the form of "+/-" with UInt representation.
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode((self.isPositive ? "+" : "-") + self.inventory.normalized().words.reversed().map({ $0.content }).reduce("", { $0 + String($1) }))
    }
    
    /// Returns -1 if this value is negative and 1 if it’s positive; otherwise, 0.
    func signum() -> Int {
        if self.inventory.isZero {
            return 0
        } else if self.isPositive {
            return 1
        } else {
            return -1
        }
    }
    
    /// The square of the `fraction`, or, `self * self`.
    func square() -> Int10 {
        return self * self
    }
    
    /// Returns the square root of the value, if possible.
    func squareRoot() -> Int10? {
        guard let dictionary = try? FinderItem.loadJSON(from: "/Users/vaida/Data Base/Static/sqrtTable.json", type: [Int10: Int10].self) else { return nil }
        return dictionary[self]
    }
    
    /// Returns the value with same magnitude, but different sign.
    func opposite() -> Self {
        return Self(isPositive: !self.isPositive, magnitude: inventory)
    }
    
    /// The quotient and remainder from dividing two instances.
    func quotientAndRemainder(dividingBy: Int10) -> (quotient: Int10, remainder: Int10) {
        let sign = self.signum() == dividingBy.signum() ? true : false
        let result = self.inventory.quotientAndRemainder(dividingBy: dividingBy.inventory)
        return (Int10(isPositive: sign, magnitude: result.quotient), Int10(isPositive: sign, magnitude: result.remainder))
    }
    
    /// Determines whether `self` is a multiple of `other`.
    func isMultiple(of: Int10) -> Bool {
        return self.inventory.isMultiple(of: of.inventory)
    }
    
    
    //MARK: - Type Methods
    
    /// Remove the unwanted zeros.
    mutating func normalize() {
        self = self.normalized()
    }
    
    /// Remove the unwanted zeros.
    func normalized() -> Self {
        return Self(isPositive: self.isPositive, magnitude: self.inventory.normalized())
    }
    
    /// Returns a value that equals to `self` \* 10 ^ `power`.
    ///
    /// **Example**
    ///
    ///     print(1.pow10(2))
    ///     // prints "100"
    ///
    /// - Parameters:
    ///    - power: The power to raise.
    ///
    /// - Returns: The value with the raised power.
    func pow10(_ power: Int) -> Self {
        return Self(isPositive: self.isPositive, magnitude: self.inventory.pow10(power))
    }
    
    
    //MARK: - Operator Methods
    
    static func + (_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs.signum(), rhs.signum()) {
        case (1, 1):
            return Self(isPositive: true, magnitude: lhs.inventory + rhs.inventory)
        case (_, 0):
            return lhs
        case (0, _):
            return rhs
        case (1, -1):
            if lhs.inventory > rhs.inventory {
                return Self(isPositive: true, magnitude: lhs.inventory - rhs.inventory)
            } else {
                return Self(isPositive: false, magnitude: rhs.inventory - lhs.inventory)
            }
        case (-1, 1):
            if lhs.inventory > rhs.inventory {
                return Self(isPositive: false, magnitude: lhs.inventory - rhs.inventory)
            } else {
                return Self(isPositive: true, magnitude: rhs.inventory - lhs.inventory)
            }
        case (-1, -1):
            return Self(isPositive: false, magnitude: lhs.inventory + rhs.inventory)
        case (_, _):
            fatalError("Unexpected")
        }
    }
    
    static func += (_ lhs: inout Self, _ rhs: Self) {
        lhs = lhs + rhs
    }
    
    static func - (_ lhs: Self, _ rhs: Self) -> Self {
        return lhs + rhs.opposite()
    }
    
    static func -= (_ lhs: inout Self, _ rhs: Self) {
        lhs = lhs - rhs
    }
    
    static func * (_ lhs: Self, _ rhs: Self) -> Self {
        if lhs.inventory.isZero || rhs.inventory.isZero { return 0 }
        
        switch lhs.signum() == rhs.signum() {
        case true:
            return Self(isPositive: true, magnitude: lhs.inventory * rhs.inventory)
        case false:
            return Self(isPositive: false, magnitude: lhs.inventory * rhs.inventory)
        }
    }
    
    static func *= (_ lhs: inout Self, _ rhs: Self) {
        lhs = lhs * rhs
    }
    
    static func / (_ lhs: Self, _ rhs: Self) -> Self {
        switch lhs.signum() == rhs.signum() {
        case true:
            return Self(isPositive: true, magnitude: lhs.inventory / rhs.inventory)
        case false:
            return Self(isPositive: false, magnitude: lhs.inventory / rhs.inventory)
        }
    }
    
    static func /= (_ lhs: inout Self, _ rhs: Self) {
        lhs = lhs / rhs
    }
    
    static func % (_ lhs: Self, _ rhs: Self) -> Self {
        switch lhs.signum() == rhs.signum() {
        case true:
            return Self(isPositive: true, magnitude: lhs.inventory % rhs.inventory)
        case false:
            return Self(isPositive: false, magnitude: lhs.inventory % rhs.inventory)
        }
    }
    
    static func %= (_ lhs: inout Self, _ rhs: Self) {
        lhs = lhs % rhs
    }
    
    
    //MARK: - Comparison Methods
    
    /// Determines whether the `lhs` is less than the `rhs`.
    static func < (_ lhs: Self, _ rhs: Self) -> Bool {
        switch (lhs.signum(), rhs.signum()) {
        case (1, 1):
            return lhs.inventory < rhs.inventory
        case (1, 0):
            return false
        case (1, -1):
            return false
        case (0, 1):
            return true
        case (0, 0):
            return false
        case (0, -1):
            return false
        case (-1, 1):
            return false
        case (-1, 0):
            return false
        case (-1, -1):
            return !(lhs.inventory < rhs.inventory)
        case (_, _):
            fatalError("Unexpected")
        }
    }
    
    /// Determines whether two instances are equal.
    static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        return lhs.signum() == rhs.signum() && lhs.inventory == rhs.inventory
    }
}

extension UnsignedInteger where Self: LosslessStringConvertible {
    init(_ value: UInt10) {
        self.init(value.description)!
    }
}

extension BinaryInteger where Self: LosslessStringConvertible {
    init(_ value: Int10) {
        self.init(value.description)!
    }
}

extension BinaryFloatingPoint where Self: LosslessStringConvertible {
    init(_ value: Int10) {
        self.init(value.description)!
    }
}

func abs(_ value: Int10) -> Int10 {
    return Int10(isPositive: true, magnitude: value.inventory)
}


