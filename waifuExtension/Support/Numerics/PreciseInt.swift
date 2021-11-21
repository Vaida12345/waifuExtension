//
//  PreciseInt.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2015-12-27.
//  Copyright © 2016-2017 Károly Lőrentey.
//
/*
//MARK: PreciseInt

/// An arbitary precision signed integer type, also known as a "big integer".
///
/// Operations on big integers never overflow, but they might take a long time to execute.
/// The amount of memory (and address space) available is the only constraint to the magnitude of these numbers.
///
/// This particular big integer type uses base-2^64 digits to represent integers.
///
/// `PreciseInt` is essentially a tiny wrapper that extends `PreciseUInt` with a sign bit and provides signed integer
/// operations. Both the underlying absolute value and the negative/positive flag are available as read-write 
/// properties.
///
/// Not all algorithms of `PreciseUInt` are available for `PreciseInt` values; for example, there is no square root or
/// primality test for signed integers. When you need to call one of these, just extract the absolute value:
///
/// ```Swift
/// PreciseInt(255).magnitude.isPrime()   // Returns false
/// ```
///
public struct PreciseInt: SignedInteger {
    public enum Sign {
        case plus
        case minus
    }

    public typealias Magnitude = PreciseUInt

    /// The type representing a digit in `PreciseInt`'s underlying number system.
    public typealias Word = PreciseUInt.Word
    
    public static var isSigned: Bool {
        return true
    }

    /// The absolute value of this integer.
    public var magnitude: PreciseUInt

    /// True iff the value of this integer is negative.
    public var sign: Sign

    /// Initializes a new big integer with the provided absolute number and sign flag.
    public init(sign: Sign, magnitude: PreciseUInt) {
        self.sign = (magnitude.isZero ? .plus : sign)
        self.magnitude = magnitude
    }

    /// Return true iff this integer is zero.
    ///
    /// - Complexity: O(1)
    public var isZero: Bool {
        return magnitude.isZero
    }

    /// Returns `-1` if this value is negative and `1` if it’s positive; otherwise, `0`.
    ///
    /// - Returns: The sign of this number, expressed as an integer of the same type.
    public func signum() -> PreciseInt {
        switch sign {
        case .plus:
            return isZero ? 0 : 1
        case .minus:
            return -1
        }
    }
}

//
//  PreciseUInt.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2015-12-26.
//  Copyright © 2016-2017 Károly Lőrentey.
//

/// An arbitary precision unsigned integer type, also known as a "big integer".
///
/// Operations on big integers never overflow, but they may take a long time to execute.
/// The amount of memory (and address space) available is the only constraint to the magnitude of these numbers.
///
/// This particular big integer type uses base-2^64 digits to represent integers; you can think of it as a wrapper
/// around `Array<UInt64>`. (In fact, `PreciseUInt` only uses an array if there are more than two digits.)
public struct PreciseUInt: UnsignedInteger {
    /// The type representing a digit in `PreciseUInt`'s underlying number system.
    public typealias Word = UInt
    
    /// The storage variants of a `PreciseUInt`.
    enum Kind {
        /// Value consists of the two specified words (low and high). Either or both words may be zero.
        case inline(Word, Word)
        /// Words are stored in a slice of the storage array.
        case slice(from: Int, to: Int)
        /// Words are stored in the storage array.
        case array
    }
    
    internal fileprivate (set) var kind: Kind // Internal for testing only
    internal fileprivate (set) var storage: [Word] // Internal for testing only; stored separately to prevent COW copies
    
    /// Initializes a new PreciseUInt with value 0.
    public init() {
        self.kind = .inline(0, 0)
        self.storage = []
    }
    
    internal init(word: Word) {
        self.kind = .inline(word, 0)
        self.storage = []
    }
    
    internal init(low: Word, high: Word) {
        self.kind = .inline(low, high)
        self.storage = []
    }
    
    /// Initializes a new PreciseUInt with the specified digits. The digits are ordered from least to most significant.
    public init(words: [Word]) {
        self.kind = .array
        self.storage = words
        normalize()
    }
    
    internal init(words: [Word], from startIndex: Int, to endIndex: Int) {
        self.kind = .slice(from: startIndex, to: endIndex)
        self.storage = words
        normalize()
    }
}

extension PreciseUInt {
    public static var isSigned: Bool {
        return false
    }
    
    /// Return true iff this integer is zero.
    ///
    /// - Complexity: O(1)
    public var isZero: Bool {
        switch kind {
        case .inline(0, 0): return true
        case .array: return storage.isEmpty
        default:
            return false
        }
    }
    
    /// Returns `1` if this value is, positive; otherwise, `0`.
    ///
    /// - Returns: The sign of this number, expressed as an integer of the same type.
    public func signum() -> PreciseUInt {
        return isZero ? 0 : 1
    }
}

extension PreciseUInt {
    mutating func ensureArray() {
        switch kind {
        case let .inline(w0, w1):
            kind = .array
            storage = w1 != 0 ? [w0, w1]
            : w0 != 0 ? [w0]
            : []
        case let .slice(from: start, to: end):
            kind = .array
            storage = Array(storage[start ..< end])
        case .array:
            break
        }
    }
    
    var capacity: Int {
        guard case .array = kind else { return 0 }
        return storage.capacity
    }
    
    mutating func reserveCapacity(_ minimumCapacity: Int) {
        switch kind {
        case let .inline(w0, w1):
            kind = .array
            storage.reserveCapacity(minimumCapacity)
            if w1 != 0 {
                storage.append(w0)
                storage.append(w1)
            }
            else if w0 != 0 {
                storage.append(w0)
            }
        case let .slice(from: start, to: end):
            kind = .array
            var words: [Word] = []
            words.reserveCapacity(Swift.max(end - start, minimumCapacity))
            words.append(contentsOf: storage[start ..< end])
            storage = words
        case .array:
            storage.reserveCapacity(minimumCapacity)
        }
    }
    
    /// Gets rid of leading zero digits in the digit array and converts slices into inline digits when possible.
    internal mutating func normalize() {
        switch kind {
        case .slice(from: let start, to: var end):
            assert(start >= 0 && end <= storage.count && start <= end)
            while start < end, storage[end - 1] == 0 {
                end -= 1
            }
            switch end - start {
            case 0:
                kind = .inline(0, 0)
                storage = []
            case 1:
                kind = .inline(storage[start], 0)
                storage = []
            case 2:
                kind = .inline(storage[start], storage[start + 1])
                storage = []
            case storage.count:
                assert(start == 0)
                kind = .array
            default:
                kind = .slice(from: start, to: end)
            }
        case .array where storage.last == 0:
            while storage.last == 0 {
                storage.removeLast()
            }
        default:
            break
        }
    }
    
    /// Set this integer to 0 without releasing allocated storage capacity (if any).
    mutating func clear() {
        self.load(0)
    }
    
    /// Set this integer to `value` by copying its digits without releasing allocated storage capacity (if any).
    mutating func load(_ value: PreciseUInt) {
        switch kind {
        case .inline, .slice:
            self = value
        case .array:
            self.storage.removeAll(keepingCapacity: true)
            self.storage.append(contentsOf: value.words)
        }
    }
}

extension PreciseUInt {
    //MARK: Collection-like members
    
    /// The number of digits in this integer, excluding leading zero digits.
    var count: Int {
        switch kind {
        case let .inline(w0, w1):
            return w1 != 0 ? 2
            : w0 != 0 ? 1
            : 0
        case let .slice(from: start, to: end):
            return end - start
        case .array:
            return storage.count
        }
    }
    
    /// Get or set a digit at a given index.
    ///
    /// - Note: Unlike a normal collection, it is OK for the index to be greater than or equal to `endIndex`.
    ///   The subscripting getter returns zero for indexes beyond the most significant digit.
    ///   Setting these extended digits automatically appends new elements to the underlying digit array.
    /// - Requires: index >= 0
    /// - Complexity: The getter is O(1). The setter is O(1) if the conditions below are true; otherwise it's O(count).
    ///    - The integer's storage is not shared with another integer
    ///    - The integer wasn't created as a slice of another integer
    ///    - `index < count`
    subscript(_ index: Int) -> Word {
        get {
            precondition(index >= 0)
            switch (kind, index) {
            case (.inline(let w0, _), 0): return w0
            case (.inline(_, let w1), 1): return w1
            case (.slice(from: let start, to: let end), _) where index < end - start:
                return storage[start + index]
            case (.array, _) where index < storage.count:
                return storage[index]
            default:
                return 0
            }
        }
        set(word) {
            precondition(index >= 0)
            switch (kind, index) {
            case let (.inline(_, w1), 0):
                kind = .inline(word, w1)
            case let (.inline(w0, _), 1):
                kind = .inline(w0, word)
            case let (.slice(from: start, to: end), _) where index < end - start:
                replace(at: index, with: word)
            case (.array, _) where index < storage.count:
                replace(at: index, with: word)
            default:
                extend(at: index, with: word)
            }
        }
    }
    
    private mutating func replace(at index: Int, with word: Word) {
        ensureArray()
        precondition(index < storage.count)
        storage[index] = word
        if word == 0, index == storage.count - 1 {
            normalize()
        }
    }
    
    private mutating func extend(at index: Int, with word: Word) {
        guard word != 0 else { return }
        reserveCapacity(index + 1)
        precondition(index >= storage.count)
        storage.append(contentsOf: repeatElement(0, count: index - storage.count))
        storage.append(word)
    }
    
    /// Returns an integer built from the digits of this integer in the given range.
    internal func extract(_ bounds: Range<Int>) -> PreciseUInt {
        switch kind {
        case let .inline(w0, w1):
            let bounds = bounds.clamped(to: 0 ..< 2)
            if bounds == 0 ..< 2 {
                return PreciseUInt(low: w0, high: w1)
            }
            else if bounds == 0 ..< 1 {
                return PreciseUInt(word: w0)
            }
            else if bounds == 1 ..< 2 {
                return PreciseUInt(word: w1)
            }
            else {
                return PreciseUInt()
            }
        case let .slice(from: start, to: end):
            let s = Swift.min(end, start + Swift.max(bounds.lowerBound, 0))
            let e = Swift.max(s, (bounds.upperBound > end - start ? end : start + bounds.upperBound))
            return PreciseUInt(words: storage, from: s, to: e)
        case .array:
            let b = bounds.clamped(to: storage.startIndex ..< storage.endIndex)
            return PreciseUInt(words: storage, from: b.lowerBound, to: b.upperBound)
        }
    }
    
    internal func extract<Bounds: RangeExpression>(_ bounds: Bounds) -> PreciseUInt where Bounds.Bound == Int {
        return self.extract(bounds.relative(to: 0 ..< Int.max))
    }
}

extension PreciseUInt {
    internal mutating func shiftRight(byWords amount: Int) {
        assert(amount >= 0)
        guard amount > 0 else { return }
        switch kind {
        case let .inline(_, w1) where amount == 1:
            kind = .inline(w1, 0)
        case .inline(_, _):
            kind = .inline(0, 0)
        case let .slice(from: start, to: end):
            let s = start + amount
            if s >= end {
                kind = .inline(0, 0)
            }
            else {
                kind = .slice(from: s, to: end)
                normalize()
            }
        case .array:
            if amount >= storage.count {
                storage.removeAll(keepingCapacity: true)
            }
            else {
                storage.removeFirst(amount)
            }
        }
    }
    
    internal mutating func shiftLeft(byWords amount: Int) {
        assert(amount >= 0)
        guard amount > 0 else { return }
        guard !isZero else { return }
        switch kind {
        case let .inline(w0, 0) where amount == 1:
            kind = .inline(0, w0)
        case let .inline(w0, w1):
            let c = (w1 == 0 ? 1 : 2)
            storage.reserveCapacity(amount + c)
            storage.append(contentsOf: repeatElement(0, count: amount))
            storage.append(w0)
            if w1 != 0 {
                storage.append(w1)
            }
            kind = .array
        case let .slice(from: start, to: end):
            var words: [Word] = []
            words.reserveCapacity(amount + count)
            words.append(contentsOf: repeatElement(0, count: amount))
            words.append(contentsOf: storage[start ..< end])
            storage = words
            kind = .array
        case .array:
            storage.insert(contentsOf: repeatElement(0, count: amount), at: 0)
        }
    }
}

extension PreciseUInt {
    //MARK: Low and High
    
    /// Split this integer into a high-order and a low-order part.
    ///
    /// - Requires: count > 1
    /// - Returns: `(low, high)` such that
    ///   - `self == low.add(high, shiftedBy: middleIndex)`
    ///   - `high.width <= floor(width / 2)`
    ///   - `low.width <= ceil(width / 2)`
    /// - Complexity: Typically O(1), but O(count) in the worst case, because high-order zero digits need to be removed after the split.
    internal var split: (high: PreciseUInt, low: PreciseUInt) {
        precondition(count > 1)
        let mid = middleIndex
        return (self.extract(mid...), self.extract(..<mid))
    }
    
    /// Index of the digit at the middle of this integer.
    ///
    /// - Returns: The index of the digit that is least significant in `self.high`.
    internal var middleIndex: Int {
        return (count + 1) / 2
    }
    
    /// The low-order half of this PreciseUInt.
    ///
    /// - Returns: `self[0 ..< middleIndex]`
    /// - Requires: count > 1
    internal var low: PreciseUInt {
        return self.extract(0 ..< middleIndex)
    }
    
    /// The high-order half of this PreciseUInt.
    ///
    /// - Returns: `self[middleIndex ..< count]`
    /// - Requires: count > 1
    internal var high: PreciseUInt {
        return self.extract(middleIndex ..< count)
    }
}

extension PreciseUInt {
    static func pow10(_ power: Int) -> PreciseUInt {
        return pow(10, power)
    }
}


//
//  Random.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-04.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt {
    /// Create a big unsigned integer consisting of `width` uniformly distributed random bits.
    ///
    /// - Parameter width: The maximum number of one bits in the result.
    /// - Parameter generator: The source of randomness.
    /// - Returns: A big unsigned integer less than `1 << width`.
    public static func randomInteger<RNG: RandomNumberGenerator>(withMaximumWidth width: Int, using generator: inout RNG) -> PreciseUInt {
        var result = PreciseUInt.zero
        var bitsLeft = width
        var i = 0
        let wordsNeeded = (width + Word.bitWidth - 1) / Word.bitWidth
        if wordsNeeded > 2 {
            result.reserveCapacity(wordsNeeded)
        }
        while bitsLeft >= Word.bitWidth {
            result[i] = generator.next()
            i += 1
            bitsLeft -= Word.bitWidth
        }
        if bitsLeft > 0 {
            let mask: Word = (1 << bitsLeft) - 1
            result[i] = (generator.next() as Word) & mask
        }
        return result
    }
    
    /// Create a big unsigned integer consisting of `width` uniformly distributed random bits.
    ///
    /// - Note: I use a `SystemRandomGeneratorGenerator` as the source of randomness.
    ///
    /// - Parameter width: The maximum number of one bits in the result.
    /// - Returns: A big unsigned integer less than `1 << width`.
    public static func randomInteger(withMaximumWidth width: Int) -> PreciseUInt {
        var rng = SystemRandomNumberGenerator()
        return randomInteger(withMaximumWidth: width, using: &rng)
    }
    
    /// Create a big unsigned integer consisting of `width-1` uniformly distributed random bits followed by a one bit.
    ///
    /// - Note: If `width` is zero, the result is zero.
    ///
    /// - Parameter width: The number of bits required to represent the answer.
    /// - Parameter generator: The source of randomness.
    /// - Returns: A random big unsigned integer whose width is `width`.
    public static func randomInteger<RNG: RandomNumberGenerator>(withExactWidth width: Int, using generator: inout RNG) -> PreciseUInt {
        // width == 0 -> return 0 because there is no room for a one bit.
        // width == 1 -> return 1 because there is no room for any random bits.
        guard width > 1 else { return PreciseUInt(width) }
        var result = randomInteger(withMaximumWidth: width - 1, using: &generator)
        result[(width - 1) / Word.bitWidth] |= 1 << Word((width - 1) % Word.bitWidth)
        return result
    }
    
    /// Create a big unsigned integer consisting of `width-1` uniformly distributed random bits followed by a one bit.
    ///
    /// - Note: If `width` is zero, the result is zero.
    /// - Note: I use a `SystemRandomGeneratorGenerator` as the source of randomness.
    ///
    /// - Returns: A random big unsigned integer whose width is `width`.
    public static func randomInteger(withExactWidth width: Int) -> PreciseUInt {
        var rng = SystemRandomNumberGenerator()
        return randomInteger(withExactWidth: width, using: &rng)
    }
    
    /// Create a uniformly distributed random unsigned integer that's less than the specified limit.
    ///
    /// - Precondition: `limit > 0`.
    ///
    /// - Parameter limit: The upper bound on the result.
    /// - Parameter generator: The source of randomness.
    /// - Returns: A random big unsigned integer that is less than `limit`.
    public static func randomInteger<RNG: RandomNumberGenerator>(lessThan limit: PreciseUInt, using generator: inout RNG) -> PreciseUInt {
        precondition(limit > 0, "\(#function): 0 is not a valid limit")
        let width = limit.bitWidth
        var random = randomInteger(withMaximumWidth: width, using: &generator)
        while random >= limit {
            random = randomInteger(withMaximumWidth: width, using: &generator)
        }
        return random
    }
    
    /// Create a uniformly distributed random unsigned integer that's less than the specified limit.
    ///
    /// - Precondition: `limit > 0`.
    /// - Note: I use a `SystemRandomGeneratorGenerator` as the source of randomness.
    ///
    /// - Parameter limit: The upper bound on the result.
    /// - Returns: A random big unsigned integer that is less than `limit`.
    public static func randomInteger(lessThan limit: PreciseUInt) -> PreciseUInt {
        var rng = SystemRandomNumberGenerator()
        return randomInteger(lessThan: limit, using: &rng)
    }
}

//
//  GCD.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt {
    //MARK: Greatest Common Divisor
    
    /// Returns the greatest common divisor of `self` and `b`.
    ///
    /// - Complexity: O(count^2) where count = max(self.count, b.count)
    public func greatestCommonDivisor(with b: PreciseUInt) -> PreciseUInt {
        // This is Stein's algorithm: https://en.wikipedia.org/wiki/Binary_GCD_algorithm
        if self.isZero { return b }
        if b.isZero { return self }
        
        let az = self.trailingZeroBitCount
        let bz = b.trailingZeroBitCount
        let twos = Swift.min(az, bz)
        
        var (x, y) = (self >> az, b >> bz)
        if x < y { swap(&x, &y) }
        
        while !x.isZero {
            x >>= x.trailingZeroBitCount
            if x < y { swap(&x, &y) }
            x -= y
        }
        return y << twos
    }
    
    /// Returns the [multiplicative inverse of this integer in modulo `modulus` arithmetic][inverse],
    /// or `nil` if there is no such number.
    ///
    /// [inverse]: https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm#Modular_integers
    ///
    /// - Returns: If `gcd(self, modulus) == 1`, the value returned is an integer `a < modulus` such that `(a * self) % modulus == 1`. If `self` and `modulus` aren't coprime, the return value is `nil`.
    /// - Requires: modulus > 1
    /// - Complexity: O(count^3)
    public func inverse(_ modulus: PreciseUInt) -> PreciseUInt? {
        precondition(modulus > 1)
        var t1 = PreciseInt(0)
        var t2 = PreciseInt(1)
        var r1 = modulus
        var r2 = self
        while !r2.isZero {
            let quotient = r1 / r2
            (t1, t2) = (t2, t1 - PreciseInt(quotient) * t2)
            (r1, r2) = (r2, r1 - quotient * r2)
        }
        if r1 > 1 { return nil }
        if t1.sign == .minus { return modulus - t1.magnitude }
        return t1.magnitude
    }
}

extension PreciseInt {
    /// Returns the greatest common divisor of `a` and `b`.
    ///
    /// - Complexity: O(count^2) where count = max(a.count, b.count)
    public func greatestCommonDivisor(with b: PreciseInt) -> PreciseInt {
        return PreciseInt(self.magnitude.greatestCommonDivisor(with: b.magnitude))
    }
    
    /// Returns the [multiplicative inverse of this integer in modulo `modulus` arithmetic][inverse],
    /// or `nil` if there is no such number.
    ///
    /// [inverse]: https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm#Modular_integers
    ///
    /// - Returns: If `gcd(self, modulus) == 1`, the value returned is an integer `a < modulus` such that `(a * self) % modulus == 1`. If `self` and `modulus` aren't coprime, the return value is `nil`.
    /// - Requires: modulus.magnitude > 1
    /// - Complexity: O(count^3)
    public func inverse(_ modulus: PreciseInt) -> PreciseInt? {
        guard let inv = self.magnitude.inverse(modulus.magnitude) else { return nil }
        return PreciseInt(self.sign == .plus || inv.isZero ? inv : modulus.magnitude - inv)
    }
}

//
//  Hashable.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt: Hashable {
    //MARK: Hashing
    
    /// Append this `PreciseUInt` to the specified hasher.
    public func hash(into hasher: inout Hasher) {
        var counter = 0
        while counter < self.words.count {
            hasher.combine(self.words[counter])
            counter += 1
        }
    }
}

extension PreciseInt: Hashable {
    /// Append this `PreciseInt` to the specified hasher.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sign)
        hasher.combine(magnitude)
    }
}

//
//  Strideable.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2017-08-11.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt: Strideable {
    /// A type that can represent the distance between two values ofa `PreciseUInt`.
    public typealias Stride = PreciseInt
    
    /// Adds `n` to `self` and returns the result. Traps if the result would be less than zero.
    public func advanced(by n: PreciseInt) -> PreciseUInt {
        return n.sign == .minus ? self - n.magnitude : self + n.magnitude
    }
    
    /// Returns the (potentially negative) difference between `self` and `other` as a `PreciseInt`. Never traps.
    public func distance(to other: PreciseUInt) -> PreciseInt {
        return PreciseInt(other) - PreciseInt(self)
    }
}

extension PreciseInt: Strideable {
    public typealias Stride = PreciseInt
    
    /// Returns `self + n`.
    public func advanced(by n: Stride) -> PreciseInt {
        return self + n
    }
    
    /// Returns `other - self`.
    public func distance(to other: PreciseInt) -> Stride {
        return other - self
    }
}


//
//  Addition.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt {
    //MARK: Addition
    
    /// Add `word` to this integer in place.
    /// `word` is shifted `shift` words to the left before being added.
    ///
    /// - Complexity: O(max(count, shift))
    internal mutating func addWord(_ word: Word, shiftedBy shift: Int = 0) {
        precondition(shift >= 0)
        var carry = word
        var i = shift
        while carry > 0 {
            let (d, c) = self[i].addingReportingOverflow(carry)
            self[i] = d
            carry = (c ? 1 : 0)
            i += 1
        }
    }
    
    /// Add the digit `d` to this integer and return the result.
    /// `d` is shifted `shift` words to the left before being added.
    ///
    /// - Complexity: O(max(count, shift))
    internal func addingWord(_ word: Word, shiftedBy shift: Int = 0) -> PreciseUInt {
        var r = self
        r.addWord(word, shiftedBy: shift)
        return r
    }
    
    /// Add `b` to this integer in place.
    /// `b` is shifted `shift` words to the left before being added.
    ///
    /// - Complexity: O(max(count, b.count + shift))
    internal mutating func add(_ b: PreciseUInt, shiftedBy shift: Int = 0) {
        precondition(shift >= 0)
        var carry = false
        var bi = 0
        let bc = b.count
        while bi < bc || carry {
            let ai = shift + bi
            let (d, c) = self[ai].addingReportingOverflow(b[bi])
            if carry {
                let (d2, c2) = d.addingReportingOverflow(1)
                self[ai] = d2
                carry = c || c2
            }
            else {
                self[ai] = d
                carry = c
            }
            bi += 1
        }
    }
    
    /// Add `b` to this integer and return the result.
    /// `b` is shifted `shift` words to the left before being added.
    ///
    /// - Complexity: O(max(count, b.count + shift))
    internal func adding(_ b: PreciseUInt, shiftedBy shift: Int = 0) -> PreciseUInt {
        var r = self
        r.add(b, shiftedBy: shift)
        return r
    }
    
    /// Increment this integer by one. If `shift` is non-zero, it selects
    /// the word that is to be incremented.
    ///
    /// - Complexity: O(count + shift)
    internal mutating func increment(shiftedBy shift: Int = 0) {
        self.addWord(1, shiftedBy: shift)
    }
    
    /// Add `a` and `b` together and return the result.
    ///
    /// - Complexity: O(max(a.count, b.count))
    public static func +(a: PreciseUInt, b: PreciseUInt) -> PreciseUInt {
        return a.adding(b)
    }
    
    /// Add `a` and `b` together, and store the sum in `a`.
    ///
    /// - Complexity: O(max(a.count, b.count))
    public static func +=(a: inout PreciseUInt, b: PreciseUInt) {
        a.add(b, shiftedBy: 0)
    }
}

extension PreciseInt {
    /// Add `a` to `b` and return the result.
    public static func +(a: PreciseInt, b: PreciseInt) -> PreciseInt {
        switch (a.sign, b.sign) {
        case (.plus, .plus):
            return PreciseInt(sign: .plus, magnitude: a.magnitude + b.magnitude)
        case (.minus, .minus):
            return PreciseInt(sign: .minus, magnitude: a.magnitude + b.magnitude)
        case (.plus, .minus):
            if a.magnitude >= b.magnitude {
                return PreciseInt(sign: .plus, magnitude: a.magnitude - b.magnitude)
            }
            else {
                return PreciseInt(sign: .minus, magnitude: b.magnitude - a.magnitude)
            }
        case (.minus, .plus):
            if b.magnitude >= a.magnitude {
                return PreciseInt(sign: .plus, magnitude: b.magnitude - a.magnitude)
            }
            else {
                return PreciseInt(sign: .minus, magnitude: a.magnitude - b.magnitude)
            }
        }
    }
    
    /// Add `b` to `a` in place.
    public static func +=(a: inout PreciseInt, b: PreciseInt) {
        a = a + b
    }
}

//
//  Data Conversion.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-04.
//  Copyright © 2016-2017 Károly Lőrentey.
//

import Foundation

extension PreciseUInt {
    //MARK: NSData Conversion
    
    /// Initialize a PreciseInt from bytes accessed from an UnsafeRawBufferPointer
    public init(_ buffer: UnsafeRawBufferPointer) {
        // This assumes Word is binary.
        precondition(Word.bitWidth % 8 == 0)
        
        self.init()
        
        let length = buffer.count
        guard length > 0 else { return }
        let bytesPerDigit = Word.bitWidth / 8
        var index = length / bytesPerDigit
        var c = bytesPerDigit - length % bytesPerDigit
        if c == bytesPerDigit {
            c = 0
            index -= 1
        }
        
        var word: Word = 0
        var counter = 0
        while counter < buffer.count {
            word <<= 8
            word += Word(buffer[counter])
            c += 1
            if c == bytesPerDigit {
                self[index] = word
                index -= 1
                c = 0
                word = 0
            }
            
            counter += 1
        }
        assert(c == 0 && word == 0 && index == -1)
    }
    
    
    /// Initializes an integer from the bits stored inside a piece of `Data`.
    /// The data is assumed to be in network (big-endian) byte order.
    public init(_ data: Data) {
        // This assumes Word is binary.
        precondition(Word.bitWidth % 8 == 0)
        
        self.init()
        
        let length = data.count
        guard length > 0 else { return }
        let bytesPerDigit = Word.bitWidth / 8
        var index = length / bytesPerDigit
        var c = bytesPerDigit - length % bytesPerDigit
        if c == bytesPerDigit {
            c = 0
            index -= 1
        }
        let word: Word = data.withUnsafeBytes { buffPtr in
            var word: Word = 0
            let p = buffPtr.bindMemory(to: UInt8.self)
            var counter = 0
            while counter < p.count {
                let byte = p[counter]
                word <<= 8
                word += Word(byte)
                c += 1
                if c == bytesPerDigit {
                    self[index] = word
                    index -= 1
                    c = 0
                    word = 0
                }
                
                counter += 1
            }
            return word
        }
        assert(c == 0 && word == 0 && index == -1)
    }
    
    /// Return a `Data` value that contains the base-256 representation of this integer, in network (big-endian) byte order.
    public func serialize() -> Data {
        // This assumes Digit is binary.
        precondition(Word.bitWidth % 8 == 0)
        
        let byteCount = (self.bitWidth + 7) / 8
        
        guard byteCount > 0 else { return Data() }
        
        var data = Data(count: byteCount)
        data.withUnsafeMutableBytes { buffPtr in
            let p = buffPtr.bindMemory(to: UInt8.self)
            var i = byteCount - 1
            var counter = 0
            while counter < self.words.count {
                var word = words[counter]
                
                var counter2 = 0
                while counter2 < Word.bitWidth / 8 {
                    p[i] = UInt8(word & 0xFF)
                    word >>= 8
                    if i == 0 {
                        assert(word == 0)
                        break
                    }
                    i -= 1
                    counter2 += 1
                }
                
                counter += 1
            }
        }
        return data
    }
}

extension PreciseInt {
    
    /// Initialize a PreciseInt from bytes accessed from an UnsafeRawBufferPointer,
    /// where the first byte indicates sign (0 for positive, 1 for negative)
    public init(_ buffer: UnsafeRawBufferPointer) {
        // This assumes Word is binary.
        precondition(Word.bitWidth % 8 == 0)
        
        self.init()
        
        let length = buffer.count
        
        // Serialized data for a PreciseInt should contain at least 2 bytes: one representing
        // the sign, and another for the non-zero magnitude. Zero is represented by an
        // empty Data struct, and negative zero is not supported.
        guard length > 1, let firstByte = buffer.first else { return }
        
        // The first byte gives the sign
        // This byte is compared to a bitmask to allow additional functionality to be added
        // to this byte in the future.
        self.sign = firstByte & 0b1 == 0 ? .plus : .minus
        
        self.magnitude = PreciseUInt(UnsafeRawBufferPointer(rebasing: buffer.dropFirst(1)))
    }
    
    /// Initializes an integer from the bits stored inside a piece of `Data`.
    /// The data is assumed to be in network (big-endian) byte order with a first
    /// byte to represent the sign (0 for positive, 1 for negative)
    public init(_ data: Data) {
        // This assumes Word is binary.
        // This is the same assumption made when initializing PreciseUInt from Data
        precondition(Word.bitWidth % 8 == 0)
        
        self.init()
        
        // Serialized data for a PreciseInt should contain at least 2 bytes: one representing
        // the sign, and another for the non-zero magnitude. Zero is represented by an
        // empty Data struct, and negative zero is not supported.
        guard data.count > 1, let firstByte = data.first else { return }
        
        // The first byte gives the sign
        // This byte is compared to a bitmask to allow additional functionality to be added
        // to this byte in the future.
        self.sign = firstByte & 0b1 == 0 ? .plus : .minus
        
        // The remaining bytes are read and stored as the magnitude
        self.magnitude = PreciseUInt(data.dropFirst(1))
    }
    
    /// Return a `Data` value that contains the base-256 representation of this integer, in network (big-endian) byte order and a prepended byte to indicate the sign (0 for positive, 1 for negative)
    public func serialize() -> Data {
        // Create a data object for the magnitude portion of the PreciseInt
        let magnitudeData = self.magnitude.serialize()
        
        // Similar to PreciseUInt, a value of 0 should return an initialized, empty Data struct
        guard magnitudeData.count > 0 else { return magnitudeData }
        
        // Create a new Data struct for the signed PreciseInt value
        var data = Data(capacity: magnitudeData.count + 1)
        
        // The first byte should be 0 for a positive value, or 1 for a negative value
        // i.e., the sign bit is the LSB
        data.append(self.sign == .plus ? 0 : 1)
        
        data.append(magnitudeData)
        return data
    }
}

//
//  Bitwise Ops.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

//MARK: Bitwise Operations

extension PreciseUInt {
    /// Return the ones' complement of `a`.
    ///
    /// - Complexity: O(a.count)
    public static prefix func ~(a: PreciseUInt) -> PreciseUInt {
        return PreciseUInt(words: a.words.map { ~$0 })
    }
    
    /// Calculate the bitwise OR of `a` and `b`, and store the result in `a`.
    ///
    /// - Complexity: O(max(a.count, b.count))
    public static func |= (a: inout PreciseUInt, b: PreciseUInt) {
        a.reserveCapacity(b.count)
        var i = 0
        while i < b.count {
            a[i] |= b[i]
            i += 1
        }
    }
    
    /// Calculate the bitwise AND of `a` and `b` and return the result.
    ///
    /// - Complexity: O(max(a.count, b.count))
    public static func &= (a: inout PreciseUInt, b: PreciseUInt) {
        var i = 0
        while i < Swift.max(a.count, b.count) {
            a[i] &= b[i]
            i += 1
        }
    }
    
    /// Calculate the bitwise XOR of `a` and `b` and return the result.
    ///
    /// - Complexity: O(max(a.count, b.count))
    public static func ^= (a: inout PreciseUInt, b: PreciseUInt) {
        a.reserveCapacity(b.count)
        var i = 0
        while i < b.count {
            a[i] ^= b[i]
            i += 1
        }
    }
}

extension PreciseInt {
    public static prefix func ~(x: PreciseInt) -> PreciseInt {
        switch x.sign {
        case .plus:
            return PreciseInt(sign: .minus, magnitude: x.magnitude + 1)
        case .minus:
            return PreciseInt(sign: .plus, magnitude: x.magnitude - 1)
        }
    }
    
    public static func &(lhs: inout PreciseInt, rhs: PreciseInt) -> PreciseInt {
        let left = lhs.words
        let right = rhs.words
        // Note we aren't using left.count/right.count here; we account for the sign bit separately later.
        let count = Swift.max(lhs.magnitude.count, rhs.magnitude.count)
        var words: [UInt] = []
        words.reserveCapacity(count)
        
        var i = 0
        while i < count {
            words.append(left[i] & right[i])
            i += 1
        }
        if lhs.sign == .minus && rhs.sign == .minus {
            words.twosComplement()
            return PreciseInt(sign: .minus, magnitude: PreciseUInt(words: words))
        }
        return PreciseInt(sign: .plus, magnitude: PreciseUInt(words: words))
    }
    
    public static func |(lhs: inout PreciseInt, rhs: PreciseInt) -> PreciseInt {
        let left = lhs.words
        let right = rhs.words
        // Note we aren't using left.count/right.count here; we account for the sign bit separately later.
        let count = Swift.max(lhs.magnitude.count, rhs.magnitude.count)
        var words: [UInt] = []
        words.reserveCapacity(count)
        
        var i = 0
        while i < count {
            words.append(left[i] | right[i])
            i += 1
        }
        if lhs.sign == .minus || rhs.sign == .minus {
            words.twosComplement()
            return PreciseInt(sign: .minus, magnitude: PreciseUInt(words: words))
        }
        return PreciseInt(sign: .plus, magnitude: PreciseUInt(words: words))
    }
    
    public static func ^(lhs: inout PreciseInt, rhs: PreciseInt) -> PreciseInt {
        let left = lhs.words
        let right = rhs.words
        // Note we aren't using left.count/right.count here; we account for the sign bit separately later.
        let count = Swift.max(lhs.magnitude.count, rhs.magnitude.count)
        var words: [UInt] = []
        words.reserveCapacity(count)
        
        var i = 0
        while i < count {
            words.append(left[i] ^ right[i])
            i += 1
        }
        if (lhs.sign == .minus) != (rhs.sign == .minus) {
            words.twosComplement()
            return PreciseInt(sign: .minus, magnitude: PreciseUInt(words: words))
        }
        return PreciseInt(sign: .plus, magnitude: PreciseUInt(words: words))
    }
    
    public static func &=(lhs: inout PreciseInt, rhs: PreciseInt) {
        lhs = lhs & rhs
    }
    
    public static func |=(lhs: inout PreciseInt, rhs: PreciseInt) {
        lhs = lhs | rhs
    }
    
    public static func ^=(lhs: inout PreciseInt, rhs: PreciseInt) {
        lhs = lhs ^ rhs
    }
}

//
//  Comparable.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

import Foundation

extension PreciseUInt: Comparable {
    //MARK: Comparison
    
    /// Compare `a` to `b` and return an `NSComparisonResult` indicating their order.
    ///
    /// - Complexity: O(count)
    public static func compare(_ a: PreciseUInt, _ b: PreciseUInt) -> ComparisonResult {
        if a.count != b.count { return a.count > b.count ? .orderedDescending : .orderedAscending }
        
        var i = a.count - 1
        while i >= 0 {
            let ad = a[i]
            let bd = b[i]
            if ad != bd { return ad > bd ? .orderedDescending : .orderedAscending }
            i -= 1
        }
        return .orderedSame
    }
    
    /// Return true iff `a` is equal to `b`.
    ///
    /// - Complexity: O(count)
    public static func ==(a: PreciseUInt, b: PreciseUInt) -> Bool {
        return PreciseUInt.compare(a, b) == .orderedSame
    }
    
    /// Return true iff `a` is less than `b`.
    ///
    /// - Complexity: O(count)
    public static func <(a: PreciseUInt, b: PreciseUInt) -> Bool {
        return PreciseUInt.compare(a, b) == .orderedAscending
    }
}

extension PreciseInt: Comparable {
    /// Return true iff `a` is equal to `b`.
    public static func ==(a: PreciseInt, b: PreciseInt) -> Bool {
        return a.sign == b.sign && a.magnitude == b.magnitude
    }
    
    /// Return true iff `a` is less than `b`.
    public static func <(a: PreciseInt, b: PreciseInt) -> Bool {
        switch (a.sign, b.sign) {
        case (.plus, .plus):
            return a.magnitude < b.magnitude
        case (.plus, .minus):
            return false
        case (.minus, .plus):
            return true
        case (.minus, .minus):
            return a.magnitude > b.magnitude
        }
    }
}


//
//  Words and Bits.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2017-08-11.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension Array where Element == UInt {
    mutating func twosComplement() {
        var increment = true
        var i = 0
        while i < self.count {
            if increment {
                (self[i], increment) = (~self[i]).addingReportingOverflow(1)
            }
            else {
                self[i] = ~self[i]
            }
            
            i += 1
        }
    }
}

extension PreciseUInt {
    public subscript(bitAt index: Int) -> Bool {
        get {
            precondition(index >= 0)
            let (i, j) = index.quotientAndRemainder(dividingBy: Word.bitWidth)
            return self[i] & (1 << j) != 0
        }
        set {
            precondition(index >= 0)
            let (i, j) = index.quotientAndRemainder(dividingBy: Word.bitWidth)
            if newValue {
                self[i] |= 1 << j
            }
            else {
                self[i] &= ~(1 << j)
            }
        }
    }
}

extension PreciseUInt {
    /// The minimum number of bits required to represent this integer in binary.
    ///
    /// - Returns: floor(log2(2 * self + 1))
    /// - Complexity: O(1)
    public var bitWidth: Int {
        guard count > 0 else { return 0 }
        return count * Word.bitWidth - self[count - 1].leadingZeroBitCount
    }
    
    /// The number of leading zero bits in the binary representation of this integer in base `2^(Word.bitWidth)`.
    /// This is useful when you need to normalize a `PreciseUInt` such that the top bit of its most significant word is 1.
    ///
    /// - Note: 0 is considered to have zero leading zero bits.
    /// - Returns: A value in `0...(Word.bitWidth - 1)`.
    /// - SeeAlso: width
    /// - Complexity: O(1)
    public var leadingZeroBitCount: Int {
        guard count > 0 else { return 0 }
        return self[count - 1].leadingZeroBitCount
    }
    
    /// The number of trailing zero bits in the binary representation of this integer.
    ///
    /// - Note: 0 is considered to have zero trailing zero bits.
    /// - Returns: A value in `0...width`.
    /// - Complexity: O(count)
    public var trailingZeroBitCount: Int {
        guard count > 0 else { return 0 }
        let i = self.words.firstIndex { $0 != 0 }!
        return i * Word.bitWidth + self[i].trailingZeroBitCount
    }
}

extension PreciseInt {
    public var bitWidth: Int {
        guard !magnitude.isZero else { return 0 }
        return magnitude.bitWidth + 1
    }
    
    public var trailingZeroBitCount: Int {
        // Amazingly, this works fine for negative numbers
        return magnitude.trailingZeroBitCount
    }
}

extension PreciseUInt {
    public struct Words: RandomAccessCollection {
        private let value: PreciseUInt
        
        fileprivate init(_ value: PreciseUInt) { self.value = value }
        
        public var startIndex: Int { return 0 }
        public var endIndex: Int { return value.count }
        
        public subscript(_ index: Int) -> Word {
            return value[index]
        }
    }
    
    public var words: Words { return Words(self) }
    
    public init<Words: Sequence>(words: Words) where Words.Element == Word {
        let uc = words.underestimatedCount
        if uc > 2 {
            self.init(words: Array(words))
        }
        else {
            var it = words.makeIterator()
            guard let w0 = it.next() else {
                self.init()
                return
            }
            guard let w1 = it.next() else {
                self.init(word: w0)
                return
            }
            if let w2 = it.next() {
                var words: [UInt] = []
                words.reserveCapacity(Swift.max(3, uc))
                words.append(w0)
                words.append(w1)
                words.append(w2)
                while let word = it.next() {
                    words.append(word)
                }
                self.init(words: words)
            }
            else {
                self.init(low: w0, high: w1)
            }
        }
    }
}

extension PreciseInt {
    public struct Words: RandomAccessCollection {
        public typealias Indices = CountableRange<Int>
        
        private let value: PreciseInt
        private let decrementLimit: Int
        
        fileprivate init(_ value: PreciseInt) {
            self.value = value
            switch value.sign {
            case .plus:
                self.decrementLimit = 0
            case .minus:
                assert(!value.magnitude.isZero)
                self.decrementLimit = value.magnitude.words.firstIndex(where: { $0 != 0 })!
            }
        }
        
        public var count: Int {
            switch value.sign {
            case .plus:
                if let high = value.magnitude.words.last, high >> (Word.bitWidth - 1) != 0 {
                    return value.magnitude.count + 1
                }
                return value.magnitude.count
            case .minus:
                let high = value.magnitude.words.last!
                if high >> (Word.bitWidth - 1) != 0 {
                    return value.magnitude.count + 1
                }
                return value.magnitude.count
            }
        }
        
        public var indices: Indices { return 0 ..< count }
        public var startIndex: Int { return 0 }
        public var endIndex: Int { return count }
        
        public subscript(_ index: Int) -> UInt {
            // Note that indices above `endIndex` are accepted.
            if value.sign == .plus {
                return value.magnitude[index]
            }
            if index <= decrementLimit {
                return ~(value.magnitude[index] &- 1)
            }
            return ~value.magnitude[index]
        }
    }
    
    public var words: Words {
        return Words(self)
    }
    
    public init<S: Sequence>(words: S) where S.Element == Word {
        var words = Array(words)
        if (words.last ?? 0) >> (Word.bitWidth - 1) == 0 {
            self.init(sign: .plus, magnitude: PreciseUInt(words: words))
        }
        else {
            words.twosComplement()
            self.init(sign: .minus, magnitude: PreciseUInt(words: words))
        }
    }
}

//
//  Square Root.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

//MARK: Square Root

extension PreciseUInt {
    /// Returns the integer square root of a big integer; i.e., the largest integer whose square isn't greater than `value`.
    ///
    /// - Returns: floor(sqrt(self))
    public func squareRoot() -> PreciseUInt {
        // This implementation uses Newton's method.
        guard !self.isZero else { return PreciseUInt() }
        var x = PreciseUInt(1) << ((self.bitWidth + 1) / 2)
        var y: PreciseUInt = 0
        while true {
            y.load(self)
            y /= x
            y += x
            y >>= 1
            if x == y || x == y - 1 { break }
            x = y
        }
        return x
    }
}

extension PreciseInt {
    /// Returns the integer square root of a big integer; i.e., the largest integer whose square isn't greater than `value`.
    ///
    /// - Requires: self >= 0
    /// - Returns: floor(sqrt(self))
    public func squareRoot() -> PreciseInt {
        precondition(self.sign == .plus)
        return PreciseInt(sign: .plus, magnitude: self.magnitude.squareRoot())
    }
}

//
//  Division.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

//MARK: Full-width multiplication and division

// TODO: Return to `where Magnitude == Self` when SR-13491 is resolved
extension FixedWidthInteger {
    private var halfShift: Self {
        return Self(Self.bitWidth / 2)
        
    }
    private var high: Self {
        return self &>> halfShift
    }
    
    private var low: Self {
        let mask: Self = 1 &<< halfShift - 1
        return self & mask
    }
    
    private var upshifted: Self {
        return self &<< halfShift
    }
    
    private var split: (high: Self, low: Self) {
        return (self.high, self.low)
    }
    
    private init(_ value: (high: Self, low: Self)) {
        self = value.high.upshifted + value.low
    }
    
    /// Divide the double-width integer `dividend` by `self` and return the quotient and remainder.
    ///
    /// - Requires: `dividend.high < self`, so that the result will fit in a single digit.
    /// - Complexity: O(1) with 2 divisions, 6 multiplications and ~12 or so additions/subtractions.
    internal func fastDividingFullWidth(_ dividend: (high: Self, low: Self.Magnitude)) -> (quotient: Self, remainder: Self) {
        // Division is complicated; doing it with single-digit operations is maddeningly complicated.
        // This is a Swift adaptation for "divlu2" in Hacker's Delight,
        // which is in turn a C adaptation of Knuth's Algorithm D (TAOCP vol 2, 4.3.1).
        precondition(dividend.high < self)
        
        // This replaces the implementation in stdlib, which is much slower.
        // FIXME: Speed up stdlib. It should use full-width idiv on Intel processors, and
        // fall back to a reasonably fast algorithm elsewhere.
        
        // The trick here is that we're actually implementing a 4/2 long division using half-words,
        // with the long division loop unrolled into two 3/2 half-word divisions.
        // Luckily, 3/2 half-word division can be approximated by a single full-word division operation
        // that, when the divisor is normalized, differs from the correct result by at most 2.
        
        /// Find the half-word quotient in `u / vn`, which must be normalized.
        /// `u` contains three half-words in the two halves of `u.high` and the lower half of
        /// `u.low`. (The weird distribution makes for a slightly better fit with the input.)
        /// `vn` contains the normalized divisor, consisting of two half-words.
        ///
        /// - Requires: u.high < vn && u.low.high == 0 && vn.leadingZeroBitCount == 0
        func quotient(dividing u: (high: Self, low: Self), by vn: Self) -> Self {
            let (vn1, vn0) = vn.split
            // Get approximate quotient.
            let (q, r) = u.high.quotientAndRemainder(dividingBy: vn1)
            let p = q * vn0
            // q is often already correct, but sometimes the approximation overshoots by at most 2.
            // The code that follows checks for this while being careful to only perform single-digit operations.
            if q.high == 0 && p <= r.upshifted + u.low { return q }
            let r2 = r + vn1
            if r2.high != 0 { return q - 1 }
            if (q - 1).high == 0 && p - vn0 <= r2.upshifted + u.low { return q - 1 }
            //assert((r + 2 * vn1).high != 0 || p - 2 * vn0 <= (r + 2 * vn1).upshifted + u.low)
            return q - 2
        }
        /// Divide 3 half-digits by 2 half-digits to get a half-digit quotient and a full-digit remainder.
        ///
        /// - Requires: u.high < v && u.low.high == 0 && vn.width = width(Digit)
        func quotientAndRemainder(dividing u: (high: Self, low: Self), by v: Self) -> (quotient: Self, remainder: Self) {
            let q = quotient(dividing: u, by: v)
            // Note that `uh.low` masks off a couple of bits, and `q * v` and the
            // subtraction are likely to overflow. Despite this, the end result (remainder) will
            // still be correct and it will fit inside a single (full) Digit.
            let r = Self(u) &- q &* v
            assert(r < v)
            return (q, r)
        }
        
        // Normalize the dividend and the divisor (self) such that the divisor has no leading zeroes.
        let z = Self(self.leadingZeroBitCount)
        let w = Self(Self.bitWidth) - z
        let vn = self << z
        
        let un32 = (z == 0 ? dividend.high : (dividend.high &<< z) | ((dividend.low as! Self) &>> w)) // No bits are lost
        let un10 = dividend.low &<< z
        let (un1, un0) = un10.split
        
        // Divide `(un32,un10)` by `vn`, splitting the full 4/2 division into two 3/2 ones.
        let (q1, un21) = quotientAndRemainder(dividing: (un32, (un1 as! Self)), by: vn)
        let (q0, rn) = quotientAndRemainder(dividing: (un21, (un0 as! Self)), by: vn)
        
        // Undo normalization of the remainder and combine the two halves of the quotient.
        let mod = rn >> z
        let div = Self((q1, q0))
        return (div, mod)
    }
    
    /// Return the quotient of the 3/2-word division `x/y` as a single word.
    ///
    /// - Requires: `(x.0, x.1) <= y && y.0.high != 0`
    /// - Returns: The exact value when it fits in a single word, otherwise `Self`.
    static func approximateQuotient(dividing x: (Self, Self, Self), by y: (Self, Self)) -> Self {
        // Start with q = (x.0, x.1) / y.0, (or Word.max on overflow)
        var q: Self
        var r: Self
        if x.0 == y.0 {
            q = Self.max
            let (s, o) = x.0.addingReportingOverflow(x.1)
            if o { return q }
            r = s
        }
        else {
            (q, r) = y.0.fastDividingFullWidth((x.0, (x.1 as! Magnitude)))
        }
        // Now refine q by considering x.2 and y.1.
        // Note that since y is normalized, q * y - x is between 0 and 2.
        let (ph, pl) = q.multipliedFullWidth(by: y.1)
        if ph < r || (ph == r && pl <= x.2) { return q }
        
        let (r1, ro) = r.addingReportingOverflow(y.0)
        if ro { return q - 1 }
        
        let (pl1, so) = pl.subtractingReportingOverflow((y.1 as! Magnitude))
        let ph1 = (so ? ph - 1 : ph)
        
        if ph1 < r1 || (ph1 == r1 && pl1 <= x.2) { return q - 1 }
        return q - 2
    }
}

extension PreciseUInt {
    //MARK: Division
    
    /// Divide this integer by the word `y`, leaving the quotient in its place and returning the remainder.
    ///
    /// - Requires: y > 0
    /// - Complexity: O(count)
    internal mutating func divide(byWord y: Word) -> Word {
        precondition(y > 0)
        if y == 1 { return 0 }
        
        var remainder: Word = 0
        var i = count - 1
        while i >= 0 {
            let u = self[i]
            (self[i], remainder) = y.fastDividingFullWidth((remainder, u))
            i  -= 1
        }
        return remainder
    }
    
    /// Divide this integer by the word `y` and return the resulting quotient and remainder.
    ///
    /// - Requires: y > 0
    /// - Returns: (quotient, remainder) where quotient = floor(x/y), remainder = x - quotient * y
    /// - Complexity: O(x.count)
    internal func quotientAndRemainder(dividingByWord y: Word) -> (quotient: PreciseUInt, remainder: Word) {
        var div = self
        let mod = div.divide(byWord: y)
        return (div, mod)
    }
    
    /// Divide `x` by `y`, putting the quotient in `x` and the remainder in `y`.
    /// Reusing integers like this reduces the number of allocations during the calculation.
    static func divide(_ x: inout PreciseUInt, by y: inout PreciseUInt) {
        // This is a Swift adaptation of "divmnu" from Hacker's Delight, which is in
        // turn a C adaptation of Knuth's Algorithm D (TAOCP vol 2, 4.3.1).
        
        precondition(!y.isZero)
        
        // First, let's take care of the easy cases.
        if x < y {
            (x, y) = (0, x)
            return
        }
        if y.count == 1 {
            // The single-word case reduces to a simpler loop.
            y = PreciseUInt(x.divide(byWord: y[0]))
            return
        }
        
        // In the hard cases, we will perform the long division algorithm we learned in school.
        // It works by successively calculating the single-word quotient of the top y.count + 1
        // words of x divided by y, replacing the top of x with the remainder, and repeating
        // the process one word lower.
        //
        // The tricky part is that the algorithm needs to be able to do n+1/n word divisions,
        // but we only have a primitive for dividing two words by a single
        // word. (Remember that this step is also tricky when we do it on paper!)
        //
        // The solution is that the long division can be approximated by a single full division
        // using just the most significant words. We can then use multiplications and
        // subtractions to refine the approximation until we get the correct quotient word.
        //
        // We could do this by doing a simple 2/1 full division, but Knuth goes one step further,
        // and implements a 3/2 division. This results in an exact approximation in the
        // vast majority of cases, eliminating an extra subtraction over big integers.
        //
        // The function `approximateQuotient` above implements Knuth's 3/2 division algorithm.
        // It requires that the divisor's most significant word is larger than
        // Word.max / 2. This ensures that the approximation has tiny error bounds,
        // which is what makes this entire approach viable.
        // To satisfy this requirement, we will normalize the division by multiplying
        // both the divisor and the dividend by the same (small) factor.
        let z = y.leadingZeroBitCount
        y <<= z
        x <<= z // We'll calculate the remainder in the normalized dividend.
        var quotient = PreciseUInt()
        assert(y.leadingZeroBitCount == 0)
        
        // We're ready to start the long division!
        let dc = y.count
        let d1 = y[dc - 1]
        let d0 = y[dc - 2]
        var product: PreciseUInt = 0
        var j = x.count - 1
        while j >= dc {
            // Approximate dividing the top dc+1 words of `remainder` using the topmost 3/2 words.
            let r2 = x[j]
            let r1 = x[j - 1]
            let r0 = x[j - 2]
            let q = Word.approximateQuotient(dividing: (r2, r1, r0), by: (d1, d0))
            
            // Multiply the entire divisor with `q` and subtract the result from remainder.
            // Normalization ensures the 3/2 quotient will either be exact for the full division, or
            // it may overshoot by at most 1, in which case the product will be greater
            // than the remainder.
            product.load(y)
            product.multiply(byWord: q)
            if product <= x.extract(j - dc ..< j + 1) {
                x.subtract(product, shiftedBy: j - dc)
                quotient[j - dc] = q
            }
            else {
                // This case is extremely rare -- it has a probability of 1/2^(Word.bitWidth - 1).
                x.add(y, shiftedBy: j - dc)
                x.subtract(product, shiftedBy: j - dc)
                quotient[j - dc] = q - 1
            }
            
            j -= 1
        }
        // The remainder's normalization needs to be undone, but otherwise we're done.
        x >>= z
        y = x
        x = quotient
    }
    
    /// Divide `x` by `y`, putting the remainder in `x`.
    mutating func formRemainder(dividingBy y: PreciseUInt, normalizedBy shift: Int) {
        precondition(!y.isZero)
        assert(y.leadingZeroBitCount == 0)
        if y.count == 1 {
            let remainder = self.divide(byWord: y[0] >> shift)
            self.load(PreciseUInt(remainder))
            return
        }
        self <<= shift
        if self >= y {
            let dc = y.count
            let d1 = y[dc - 1]
            let d0 = y[dc - 2]
            var product: PreciseUInt = 0
            var j = self.count
            while j > dc {
                let r2 = self[j]
                let r1 = self[j - 1]
                let r0 = self[j - 2]
                let q = Word.approximateQuotient(dividing: (r2, r1, r0), by: (d1, d0))
                product.load(y)
                product.multiply(byWord: q)
                if product <= self.extract(j - dc ..< j + 1) {
                    self.subtract(product, shiftedBy: j - dc)
                }
                else {
                    self.add(y, shiftedBy: j - dc)
                    self.subtract(product, shiftedBy: j - dc)
                }
                
                j -= 1
            }
        }
        self >>= shift
    }
    
    
    /// Divide this integer by `y` and return the resulting quotient and remainder.
    ///
    /// - Requires: `y > 0`
    /// - Returns: `(quotient, remainder)` where `quotient = floor(self/y)`, `remainder = self - quotient * y`
    /// - Complexity: O(count^2)
    public func quotientAndRemainder(dividingBy y: PreciseUInt) -> (quotient: PreciseUInt, remainder: PreciseUInt) {
        var x = self
        var y = y
        PreciseUInt.divide(&x, by: &y)
        return (x, y)
    }
    
    /// Divide `x` by `y` and return the quotient.
    ///
    /// - Note: Use `divided(by:)` if you also need the remainder.
    public static func /(x: PreciseUInt, y: PreciseUInt) -> PreciseUInt {
        return x.quotientAndRemainder(dividingBy: y).quotient
    }
    
    /// Divide `x` by `y` and return the remainder.
    ///
    /// - Note: Use `divided(by:)` if you also need the remainder.
    public static func %(x: PreciseUInt, y: PreciseUInt) -> PreciseUInt {
        var x = x
        let shift = y.leadingZeroBitCount
        x.formRemainder(dividingBy: y << shift, normalizedBy: shift)
        return x
    }
    
    /// Divide `x` by `y` and store the quotient in `x`.
    ///
    /// - Note: Use `divided(by:)` if you also need the remainder.
    public static func /=(x: inout PreciseUInt, y: PreciseUInt) {
        var y = y
        PreciseUInt.divide(&x, by: &y)
    }
    
    /// Divide `x` by `y` and store the remainder in `x`.
    ///
    /// - Note: Use `divided(by:)` if you also need the remainder.
    public static func %=(x: inout PreciseUInt, y: PreciseUInt) {
        let shift = y.leadingZeroBitCount
        x.formRemainder(dividingBy: y << shift, normalizedBy: shift)
    }
}

extension PreciseInt {
    /// Divide this integer by `y` and return the resulting quotient and remainder.
    ///
    /// - Requires: `y > 0`
    /// - Returns: `(quotient, remainder)` where `quotient = floor(self/y)`, `remainder = self - quotient * y`
    /// - Complexity: O(count^2)
    public func quotientAndRemainder(dividingBy y: PreciseInt) -> (quotient: PreciseInt, remainder: PreciseInt) {
        var a = self.magnitude
        var b = y.magnitude
        PreciseUInt.divide(&a, by: &b)
        return (PreciseInt(sign: self.sign == y.sign ? .plus : .minus, magnitude: a),
                PreciseInt(sign: self.sign, magnitude: b))
    }
    
    /// Divide `a` by `b` and return the quotient. Traps if `b` is zero.
    public static func /(a: PreciseInt, b: PreciseInt) -> PreciseInt {
        return PreciseInt(sign: a.sign == b.sign ? .plus : .minus, magnitude: a.magnitude / b.magnitude)
    }
    
    /// Divide `a` by `b` and return the remainder. The result has the same sign as `a`.
    public static func %(a: PreciseInt, b: PreciseInt) -> PreciseInt {
        return PreciseInt(sign: a.sign, magnitude: a.magnitude % b.magnitude)
    }
    
    /// Return the result of `a` mod `b`. The result is always a nonnegative integer that is less than the absolute value of `b`.
    public func modulus(_ mod: PreciseInt) -> PreciseInt {
        let remainder = self.magnitude % mod.magnitude
        return PreciseInt(
            self.sign == .minus && !remainder.isZero
            ? mod.magnitude - remainder
            : remainder)
    }
}

extension PreciseInt {
    /// Divide `a` by `b` storing the quotient in `a`.
    public static func /=(a: inout PreciseInt, b: PreciseInt) { a = a / b }
    /// Divide `a` by `b` storing the remainder in `a`.
    public static func %=(a: inout PreciseInt, b: PreciseInt) { a = a % b }
}


//
//  Codable.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2017-8-11.
//  Copyright © 2016-2017 Károly Lőrentey.
//


// Little-endian to big-endian
struct Units<Unit: FixedWidthInteger, Words: RandomAccessCollection>: RandomAccessCollection
where Words.Element: FixedWidthInteger, Words.Index == Int {
    typealias Word = Words.Element
    let words: Words
    init(of type: Unit.Type, _ words: Words) {
        precondition(Word.bitWidth % Unit.bitWidth == 0 || Unit.bitWidth % Word.bitWidth == 0)
        self.words = words
    }
    var count: Int { return (words.count * Word.bitWidth + Unit.bitWidth - 1) / Unit.bitWidth }
    var startIndex: Int { return 0 }
    var endIndex: Int { return count }
    subscript(_ index: Int) -> Unit {
        let index = count - 1 - index
        if Unit.bitWidth == Word.bitWidth {
            return Unit(words[index])
        }
        else if Unit.bitWidth > Word.bitWidth {
            let c = Unit.bitWidth / Word.bitWidth
            var unit: Unit = 0
            var j = 0
            var i = (c * index)
            while i < Swift.min(c * (index + 1), words.endIndex) {
                unit |= Unit(words[i]) << j
                j += Word.bitWidth
                
                i += 1
            }
            return unit
        }
        // Unit.bitWidth < Word.bitWidth
        let c = Word.bitWidth / Unit.bitWidth
        let i = index / c
        let j = index % c
        return Unit(truncatingIfNeeded: words[i] >> (j * Unit.bitWidth))
    }
}

extension Array where Element: FixedWidthInteger {
    // Big-endian to little-endian
    init<Unit: FixedWidthInteger>(count: Int?, generator: () throws -> Unit?) rethrows {
        typealias Word = Element
        precondition(Word.bitWidth % Unit.bitWidth == 0 || Unit.bitWidth % Word.bitWidth == 0)
        self = []
        if Unit.bitWidth == Word.bitWidth {
            if let count = count {
                self.reserveCapacity(count)
            }
            while let unit = try generator() {
                self.append(Word(unit))
            }
        }
        else if Unit.bitWidth > Word.bitWidth {
            let wordsPerUnit = Unit.bitWidth / Word.bitWidth
            if let count = count {
                self.reserveCapacity(count * wordsPerUnit)
            }
            while let unit = try generator() {
                var shift = Unit.bitWidth - Word.bitWidth
                while shift >= 0 {
                    self.append(Word(truncatingIfNeeded: unit >> shift))
                    shift -= Word.bitWidth
                }
            }
        }
        else {
            let unitsPerWord = Word.bitWidth / Unit.bitWidth
            if let count = count {
                self.reserveCapacity((count + unitsPerWord - 1) / unitsPerWord)
            }
            var word: Word = 0
            var c = 0
            while let unit = try generator() {
                word <<= Unit.bitWidth
                word |= Word(unit)
                c += Unit.bitWidth
                if c == Word.bitWidth {
                    self.append(word)
                    word = 0
                    c = 0
                }
            }
            if c > 0 {
                self.append(word << c)
                var shifted: Word = 0
                var counter = 0
                while counter < self.indices.count {
                    let i = self.indices[counter]
                    let word = self[i]
                    self[i] = shifted | (word >> c)
                    shifted = word << (Word.bitWidth - c)
                    
                    counter += 1
                }
            }
        }
        self.reverse()
    }
}

extension PreciseInt: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        // Decode sign
        let sign: PreciseInt.Sign
        switch try container.decode(String.self) {
        case "+":
            sign = .plus
        case "-":
            sign = .minus
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath,
                                                    debugDescription: "Invalid big integer sign"))
        }
        
        // Decode magnitude
        let words = try [UInt](count: container.count?.advanced(by: -1)) { () -> UInt64? in
            guard !container.isAtEnd else { return nil }
            return try container.decode(UInt64.self)
        }
        let magnitude = PreciseUInt(words: words)
        
        self.init(sign: sign, magnitude: magnitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sign == .plus ? "+" : "-")
        let units = Units(of: UInt64.self, self.magnitude.words)
        if units.isEmpty {
            try container.encode(0 as UInt64)
        }
        else {
            try container.encode(contentsOf: units)
        }
    }
}

extension PreciseUInt: Codable {
    public init(from decoder: Decoder) throws {
        let value = try PreciseInt(from: decoder)
        guard value.sign == .plus else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "PreciseUInt cannot hold a negative value"))
        }
        self = value.magnitude
    }
    
    public func encode(to encoder: Encoder) throws {
        try PreciseInt(sign: .plus, magnitude: self).encode(to: encoder)
    }
}

//
//  Multiplication.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt {
    
    //MARK: Multiplication
    
    /// Multiply this big integer by a single word, and store the result in place of the original big integer.
    ///
    /// - Complexity: O(count)
    public mutating func multiply(byWord y: Word) {
        guard y != 0 else { self = 0; return }
        guard y != 1 else { return }
        var carry: Word = 0
        let c = self.count
        var i = 0
        while i < c {
            let (h, l) = self[i].multipliedFullWidth(by: y)
            let (low, o) = l.addingReportingOverflow(carry)
            self[i] = low
            carry = (o ? h + 1 : h)
            
            i += 1
        }
        self[c] = carry
    }
    
    /// Multiply this big integer by a single Word, and return the result.
    ///
    /// - Complexity: O(count)
    public func multiplied(byWord y: Word) -> PreciseUInt {
        var r = self
        r.multiply(byWord: y)
        return r
    }
    
    /// Multiply `x` by `y`, and add the result to this integer, optionally shifted `shift` words to the left.
    ///
    /// - Note: This is the fused multiply/shift/add operation; it is more efficient than doing the components
    ///   individually. (The fused operation doesn't need to allocate space for temporary big integers.)
    /// - Returns: `self` is set to `self + (x * y) << (shift * 2^Word.bitWidth)`
    /// - Complexity: O(count)
    public mutating func multiplyAndAdd(_ x: PreciseUInt, _ y: Word, shiftedBy shift: Int = 0) {
        precondition(shift >= 0)
        guard y != 0 && x.count > 0 else { return }
        guard y != 1 else { self.add(x, shiftedBy: shift); return }
        var mulCarry: Word = 0
        var addCarry = false
        let xc = x.count
        var xi = 0
        while xi < xc || addCarry || mulCarry > 0 {
            let (h, l) = x[xi].multipliedFullWidth(by: y)
            let (low, o) = l.addingReportingOverflow(mulCarry)
            mulCarry = (o ? h + 1 : h)
            
            let ai = shift + xi
            let (sum1, so1) = self[ai].addingReportingOverflow(low)
            if addCarry {
                let (sum2, so2) = sum1.addingReportingOverflow(1)
                self[ai] = sum2
                addCarry = so1 || so2
            }
            else {
                self[ai] = sum1
                addCarry = so1
            }
            xi += 1
        }
    }
    
    /// Multiply this integer by `y` and return the result.
    ///
    /// - Note: This uses the naive O(n^2) multiplication algorithm unless both arguments have more than
    ///   `PreciseUInt.directMultiplicationLimit` words.
    /// - Complexity: O(n^log2(3))
    public func multiplied(by y: PreciseUInt) -> PreciseUInt {
        // This method is mostly defined for symmetry with the rest of the arithmetic operations.
        return self * y
    }
    
    /// Multiplication switches to an asymptotically better recursive algorithm when arguments have more words than this limit.
    public static var directMultiplicationLimit: Int = 1024
    
    /// Multiply `a` by `b` and return the result.
    ///
    /// - Note: This uses the naive O(n^2) multiplication algorithm unless both arguments have more than
    ///   `PreciseUInt.directMultiplicationLimit` words.
    /// - Complexity: O(n^log2(3))
    public static func *(lhs: PreciseUInt, rhs: PreciseUInt) -> PreciseUInt {
        let xc = lhs.count
        let yc = rhs.count
        if xc == 0 { return PreciseUInt() }
        if yc == 0 { return PreciseUInt() }
        if yc == 1 { return lhs.multiplied(byWord: rhs[0]) }
        if xc == 1 { return rhs.multiplied(byWord: lhs[0]) }
        
        if Swift.min(xc, yc) <= PreciseUInt.directMultiplicationLimit {
            // Long multiplication.
            let left = (xc < yc ? rhs : lhs)
            let right = (xc < yc ? lhs : rhs)
            var result = PreciseUInt()
            var i = right.count - 1
            while i >= 0 {
                result.multiplyAndAdd(left, right[i], shiftedBy: i)
                i -= 1
            }
            return result
        }
        
        if yc < xc {
            let (xh, xl) = lhs.split
            var r = xl * rhs
            r.add(xh * rhs, shiftedBy: lhs.middleIndex)
            return r
        }
        else if xc < yc {
            let (yh, yl) = rhs.split
            var r = yl * lhs
            r.add(yh * lhs, shiftedBy: rhs.middleIndex)
            return r
        }
        
        let shift = lhs.middleIndex
        
        // Karatsuba multiplication:
        // x * y = <a,b> * <c,d> = <ac, ac + bd - (a-b)(c-d), bd> (ignoring carry)
        let (a, b) = lhs.split
        let (c, d) = rhs.split
        
        let high = a * c
        let low = b * d
        let xp = a >= b
        let yp = c >= d
        let xm = (xp ? a - b : b - a)
        let ym = (yp ? c - d : d - c)
        let m = xm * ym
        
        var r = low
        r.add(high, shiftedBy: 2 * shift)
        r.add(low, shiftedBy: shift)
        r.add(high, shiftedBy: shift)
        if xp == yp {
            r.subtract(m, shiftedBy: shift)
        }
        else {
            r.add(m, shiftedBy: shift)
        }
        return r
    }
    
    /// Multiply `a` by `b` and store the result in `a`.
    public static func *=(a: inout PreciseUInt, b: PreciseUInt) {
        a = a * b
    }
}

extension PreciseInt {
    /// Multiply `a` with `b` and return the result.
    public static func *(a: PreciseInt, b: PreciseInt) -> PreciseInt {
        return PreciseInt(sign: a.sign == b.sign ? .plus : .minus, magnitude: a.magnitude * b.magnitude)
    }
    
    /// Multiply `a` with `b` in place.
    public static func *=(a: inout PreciseInt, b: PreciseInt) { a = a * b }
}


//
//  Exponentiation.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt {
    //MARK: Exponentiation
    
    /// Returns this integer raised to the power `exponent`.
    ///
    /// This function calculates the result by [successively squaring the base while halving the exponent][expsqr].
    ///
    /// [expsqr]: https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// - Note: This function can be unreasonably expensive for large exponents, which is why `exponent` is
    ///         a simple integer value. If you want to calculate big exponents, you'll probably need to use
    ///         the modulo arithmetic variant.
    /// - Returns: 1 if `exponent == 0`, otherwise `self` raised to `exponent`. (This implies that `0.power(0) == 1`.)
    /// - SeeAlso: `PreciseUInt.power(_:, modulus:)`
    /// - Complexity: O((exponent * self.count)^log2(3)) or somesuch. The result may require a large amount of memory, too.
    public func power(_ exponent: Int) -> PreciseUInt {
        if exponent == 0 { return 1 }
        if exponent == 1 { return self }
        if exponent < 0 {
            precondition(!self.isZero)
            return self == 1 ? 1 : 0
        }
        if self <= 1 { return self }
        var result = PreciseUInt(1)
        var b = self
        var e = exponent
        while e > 0 {
            if e & 1 == 1 {
                result *= b
            }
            e >>= 1
            b *= b
        }
        
        return result
    }
    
    /// Returns the remainder of this integer raised to the power `exponent` in modulo arithmetic under `modulus`.
    ///
    /// Uses the [right-to-left binary method][rtlb].
    ///
    /// [rtlb]: https://en.wikipedia.org/wiki/Modular_exponentiation#Right-to-left_binary_method
    ///
    /// - Complexity: O(exponent.count * modulus.count^log2(3)) or somesuch
    public func power(_ exponent: PreciseUInt, modulus: PreciseUInt) -> PreciseUInt {
        precondition(!modulus.isZero)
        if modulus == (1 as PreciseUInt) { return 0 }
        let shift = modulus.leadingZeroBitCount
        let normalizedModulus = modulus << shift
        var result = PreciseUInt(1)
        var b = self
        b.formRemainder(dividingBy: normalizedModulus, normalizedBy: shift)
        
        var counter1 = 0
        while counter1 < exponent.words.count {
            var e = exponent.words[counter1]
            
            var counter2 = 0
            while counter2 < Word.bitWidth {
                if e & 1 == 1 {
                    result *= b
                    result.formRemainder(dividingBy: normalizedModulus, normalizedBy: shift)
                }
                e >>= 1
                b *= b
                b.formRemainder(dividingBy: normalizedModulus, normalizedBy: shift)
                
                counter2 += 1
            }
            
            counter1 += 1
        }
        return result
    }
}

extension PreciseInt {
    /// Returns this integer raised to the power `exponent`.
    ///
    /// This function calculates the result by [successively squaring the base while halving the exponent][expsqr].
    ///
    /// [expsqr]: https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// - Note: This function can be unreasonably expensive for large exponents, which is why `exponent` is
    ///         a simple integer value. If you want to calculate big exponents, you'll probably need to use
    ///         the modulo arithmetic variant.
    /// - Returns: 1 if `exponent == 0`, otherwise `self` raised to `exponent`. (This implies that `0.power(0) == 1`.)
    /// - SeeAlso: `PreciseUInt.power(_:, modulus:)`
    /// - Complexity: O((exponent * self.count)^log2(3)) or somesuch. The result may require a large amount of memory, too.
    public func power(_ exponent: Int) -> PreciseInt {
        return PreciseInt(sign: self.sign == .minus && exponent & 1 != 0 ? .minus : .plus,
                          magnitude: self.magnitude.power(exponent))
    }
    
    /// Returns the remainder of this integer raised to the power `exponent` in modulo arithmetic under `modulus`.
    ///
    /// Uses the [right-to-left binary method][rtlb].
    ///
    /// [rtlb]: https://en.wikipedia.org/wiki/Modular_exponentiation#Right-to-left_binary_method
    ///
    /// - Complexity: O(exponent.count * modulus.count^log2(3)) or somesuch
    public func power(_ exponent: PreciseInt, modulus: PreciseInt) -> PreciseInt {
        precondition(!modulus.isZero)
        if modulus.magnitude == 1 { return 0 }
        if exponent.isZero { return 1 }
        if exponent == 1 { return self.modulus(modulus) }
        if exponent < 0 {
            precondition(!self.isZero)
            guard magnitude == 1 else { return 0 }
            guard sign == .minus else { return 1 }
            guard exponent.magnitude[0] & 1 != 0 else { return 1 }
            return PreciseInt(modulus.magnitude - 1)
        }
        let power = self.magnitude.power(exponent.magnitude,
                                         modulus: modulus.magnitude)
        if self.sign == .plus || exponent.magnitude[0] & 1 == 0 || power.isZero {
            return PreciseInt(power)
        }
        return PreciseInt(modulus.magnitude - power)
    }
}



//
//  Floating Point Conversion.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2017-08-11.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt {
    public init?<T: BinaryFloatingPoint>(exactly source: T) {
        guard source.isFinite else { return nil }
        guard !source.isZero else { self = 0; return }
        guard source.sign == .plus else { return nil }
        let value = source.rounded(.towardZero)
        guard value == source else { return nil }
        assert(value.floatingPointClass == .positiveNormal)
        assert(value.exponent >= 0)
        let significand = value.significandBitPattern
        self = (PreciseUInt(1) << value.exponent) + PreciseUInt(significand) >> (T.significandBitCount - Int(value.exponent))
    }
    
    public init<T: BinaryFloatingPoint>(_ source: T) {
        self.init(exactly: source.rounded(.towardZero))!
    }
}

extension PreciseInt {
    public init?<T: BinaryFloatingPoint>(exactly source: T) {
        switch source.sign{
        case .plus:
            guard let magnitude = PreciseUInt(exactly: source) else { return nil }
            self = PreciseInt(sign: .plus, magnitude: magnitude)
        case .minus:
            guard let magnitude = PreciseUInt(exactly: -source) else { return nil }
            self = PreciseInt(sign: .minus, magnitude: magnitude)
        }
    }
    
    public init<T: BinaryFloatingPoint>(_ source: T) {
        self.init(exactly: source.rounded(.towardZero))!
    }
}

extension BinaryFloatingPoint where RawExponent: FixedWidthInteger, RawSignificand: FixedWidthInteger {
    public init(_ value: PreciseInt) {
        guard !value.isZero else { self = 0; return }
        let v = value.magnitude
        let bitWidth = v.bitWidth
        var exponent = bitWidth - 1
        let shift = bitWidth - Self.significandBitCount - 1
        var significand = value.magnitude >> (shift - 1)
        if significand[0] & 3 == 3 { // Handle rounding
            significand >>= 1
            significand += 1
            if significand.trailingZeroBitCount >= Self.significandBitCount {
                exponent += 1
            }
        }
        else {
            significand >>= 1
        }
        let bias = 1 << (Self.exponentBitCount - 1) - 1
        guard exponent <= bias else { self = Self.infinity; return }
        significand &= 1 << Self.significandBitCount - 1
        self = Self.init(sign: value.sign == .plus ? .plus : .minus,
                         exponentBitPattern: RawExponent(bias + exponent),
                         significandBitPattern: RawSignificand(significand))
    }
    
    public init(_ value: PreciseUInt) {
        self.init(PreciseInt(sign: .plus, magnitude: value))
    }
}

//
//  Shifts.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt {
    
    //MARK: Shift Operators
    
    internal func shiftedLeft(by amount: Word) -> PreciseUInt {
        guard amount > 0 else { return self }
        
        let ext = Int(amount / Word(Word.bitWidth)) // External shift amount (new words)
        let up = Word(amount % Word(Word.bitWidth)) // Internal shift amount (subword shift)
        let down = Word(Word.bitWidth) - up
        
        var result = PreciseUInt()
        if up > 0 {
            var i = 0
            var lowbits: Word = 0
            while i < self.count || lowbits > 0 {
                let word = self[i]
                result[i + ext] = word << up | lowbits
                lowbits = word >> down
                i += 1
            }
        }
        else {
            var i = 0
            while i < self.count {
                result[i + ext] = self[i]
                i += 1
            }
        }
        return result
    }
    
    internal mutating func shiftLeft(by amount: Word) {
        guard amount > 0 else { return }
        
        let ext = Int(amount / Word(Word.bitWidth)) // External shift amount (new words)
        let up = Word(amount % Word(Word.bitWidth)) // Internal shift amount (subword shift)
        let down = Word(Word.bitWidth) - up
        
        if up > 0 {
            var i = 0
            var lowbits: Word = 0
            while i < self.count || lowbits > 0 {
                let word = self[i]
                self[i] = word << up | lowbits
                lowbits = word >> down
                i += 1
            }
        }
        if ext > 0 && self.count > 0 {
            self.shiftLeft(byWords: ext)
        }
    }
    
    internal func shiftedRight(by amount: Word) -> PreciseUInt {
        guard amount > 0 else { return self }
        guard amount < self.bitWidth else { return 0 }
        
        let ext = Int(amount / Word(Word.bitWidth)) // External shift amount (new words)
        let down = Word(amount % Word(Word.bitWidth)) // Internal shift amount (subword shift)
        let up = Word(Word.bitWidth) - down
        
        var result = PreciseUInt()
        if down > 0 {
            var highbits: Word = 0
            var i = self.count - 1
            while i >= ext {
                let word = self[i]
                result[i - ext] = highbits | word >> down
                highbits = word << up
                
                i -= 1
            }
        }
        else {
            var i = self.count - 1
            while i >= ext {
                result[i - ext] = self[i]
                
                i -= 1
            }
        }
        return result
    }
    
    internal mutating func shiftRight(by amount: Word) {
        guard amount > 0 else { return }
        guard amount < self.bitWidth else { self.clear(); return }
        
        let ext = Int(amount / Word(Word.bitWidth)) // External shift amount (new words)
        let down = Word(amount % Word(Word.bitWidth)) // Internal shift amount (subword shift)
        let up = Word(Word.bitWidth) - down
        
        if ext > 0 {
            self.shiftRight(byWords: ext)
        }
        if down > 0 {
            var i = self.count - 1
            var highbits: Word = 0
            while i >= 0 {
                let word = self[i]
                self[i] = highbits | word >> down
                highbits = word << up
                i -= 1
            }
        }
    }
    
    public static func >>=<Other: BinaryInteger>(lhs: inout PreciseUInt, rhs: Other) {
        if rhs < (0 as Other) {
            lhs <<= (0 - rhs)
        }
        else if rhs >= lhs.bitWidth {
            lhs.clear()
        }
        else {
            lhs.shiftRight(by: UInt(rhs))
        }
    }
    
    public static func <<=<Other: BinaryInteger>(lhs: inout PreciseUInt, rhs: Other) {
        if rhs < (0 as Other) {
            lhs >>= (0 - rhs)
            return
        }
        lhs.shiftLeft(by: Word(exactly: rhs)!)
    }
    
    public static func >><Other: BinaryInteger>(lhs: PreciseUInt, rhs: Other) -> PreciseUInt {
        if rhs < (0 as Other) {
            return lhs << (0 - rhs)
        }
        if rhs > Word.max {
            return 0
        }
        return lhs.shiftedRight(by: UInt(rhs))
    }
    
    public static func <<<Other: BinaryInteger>(lhs: PreciseUInt, rhs: Other) -> PreciseUInt {
        if rhs < (0 as Other) {
            return lhs >> (0 - rhs)
        }
        return lhs.shiftedLeft(by: Word(exactly: rhs)!)
    }
}

extension PreciseInt {
    func shiftedLeft(by amount: Word) -> PreciseInt {
        return PreciseInt(sign: self.sign, magnitude: self.magnitude.shiftedLeft(by: amount))
    }
    
    mutating func shiftLeft(by amount: Word) {
        self.magnitude.shiftLeft(by: amount)
    }
    
    func shiftedRight(by amount: Word) -> PreciseInt {
        let m = self.magnitude.shiftedRight(by: amount)
        return PreciseInt(sign: self.sign, magnitude: self.sign == .minus && m.isZero ? 1 : m)
    }
    
    mutating func shiftRight(by amount: Word) {
        magnitude.shiftRight(by: amount)
        if sign == .minus, magnitude.isZero {
            magnitude.load(1)
        }
    }
    
    public static func &<<(left: PreciseInt, right: PreciseInt) -> PreciseInt {
        return left.shiftedLeft(by: right.words[0])
    }
    
    public static func &<<=(left: inout PreciseInt, right: PreciseInt) {
        left.shiftLeft(by: right.words[0])
    }
    
    public static func &>>(left: PreciseInt, right: PreciseInt) -> PreciseInt {
        return left.shiftedRight(by: right.words[0])
    }
    
    public static func &>>=(left: inout PreciseInt, right: PreciseInt) {
        left.shiftRight(by: right.words[0])
    }
    
    public static func <<<Other: BinaryInteger>(lhs: PreciseInt, rhs: Other) -> PreciseInt {
        guard rhs >= (0 as Other) else { return lhs >> (0 - rhs) }
        return lhs.shiftedLeft(by: Word(rhs))
    }
    
    public static func <<=<Other: BinaryInteger>(lhs: inout PreciseInt, rhs: Other) {
        if rhs < (0 as Other) {
            lhs >>= (0 - rhs)
        }
        else {
            lhs.shiftLeft(by: Word(rhs))
        }
    }
    
    public static func >><Other: BinaryInteger>(lhs: PreciseInt, rhs: Other) -> PreciseInt {
        guard rhs >= (0 as Other) else { return lhs << (0 - rhs) }
        return lhs.shiftedRight(by: Word(rhs))
    }
    
    public static func >>=<Other: BinaryInteger>(lhs: inout PreciseInt, rhs: Other) {
        if rhs < (0 as Other) {
            lhs <<= (0 - rhs)
        }
        else {
            lhs.shiftRight(by: Word(rhs))
        }
    }
}


//
//  Subtraction.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt {
    //MARK: Subtraction
    
    /// Subtract `word` from this integer in place, returning a flag indicating if the operation
    /// caused an arithmetic overflow. `word` is shifted `shift` words to the left before being subtracted.
    ///
    /// - Note: If the result indicates an overflow, then `self` becomes the two's complement of the absolute difference.
    /// - Complexity: O(count)
    internal mutating func subtractWordReportingOverflow(_ word: Word, shiftedBy shift: Int = 0) -> Bool {
        precondition(shift >= 0)
        var carry: Word = word
        var i = shift
        let count = self.count
        while carry > 0 && i < count {
            let (d, c) = self[i].subtractingReportingOverflow(carry)
            self[i] = d
            carry = (c ? 1 : 0)
            i += 1
        }
        return carry > 0
    }
    
    /// Subtract `word` from this integer, returning the difference and a flag that is true if the operation
    /// caused an arithmetic overflow. `word` is shifted `shift` words to the left before being subtracted.
    ///
    /// - Note: If `overflow` is true, then the returned value is the two's complement of the absolute difference.
    /// - Complexity: O(count)
    internal func subtractingWordReportingOverflow(_ word: Word, shiftedBy shift: Int = 0) -> (partialValue: PreciseUInt, overflow: Bool) {
        var result = self
        let overflow = result.subtractWordReportingOverflow(word, shiftedBy: shift)
        return (result, overflow)
    }
    
    /// Subtract a digit `d` from this integer in place.
    /// `d` is shifted `shift` digits to the left before being subtracted.
    ///
    /// - Requires: self >= d * 2^shift
    /// - Complexity: O(count)
    internal mutating func subtractWord(_ word: Word, shiftedBy shift: Int = 0) {
        let overflow = subtractWordReportingOverflow(word, shiftedBy: shift)
        precondition(!overflow)
    }
    
    /// Subtract a digit `d` from this integer and return the result.
    /// `d` is shifted `shift` digits to the left before being subtracted.
    ///
    /// - Requires: self >= d * 2^shift
    /// - Complexity: O(count)
    internal func subtractingWord(_ word: Word, shiftedBy shift: Int = 0) -> PreciseUInt {
        var result = self
        result.subtractWord(word, shiftedBy: shift)
        return result
    }
    
    /// Subtract `other` from this integer in place, and return a flag indicating if the operation caused an
    /// arithmetic overflow. `other` is shifted `shift` digits to the left before being subtracted.
    ///
    /// - Note: If the result indicates an overflow, then `self` becomes the twos' complement of the absolute difference.
    /// - Complexity: O(count)
    public mutating func subtractReportingOverflow(_ b: PreciseUInt, shiftedBy shift: Int = 0) -> Bool {
        precondition(shift >= 0)
        var carry = false
        var bi = 0
        let bc = b.count
        let count = self.count
        while bi < bc || (shift + bi < count && carry) {
            let ai = shift + bi
            let (d, c) = self[ai].subtractingReportingOverflow(b[bi])
            if carry {
                let (d2, c2) = d.subtractingReportingOverflow(1)
                self[ai] = d2
                carry = c || c2
            }
            else {
                self[ai] = d
                carry = c
            }
            bi += 1
        }
        return carry
    }
    
    /// Subtract `other` from this integer, returning the difference and a flag indicating arithmetic overflow.
    /// `other` is shifted `shift` digits to the left before being subtracted.
    ///
    /// - Note: If `overflow` is true, then the result value is the twos' complement of the absolute value of the difference.
    /// - Complexity: O(count)
    public func subtractingReportingOverflow(_ other: PreciseUInt, shiftedBy shift: Int) -> (partialValue: PreciseUInt, overflow: Bool) {
        var result = self
        let overflow = result.subtractReportingOverflow(other, shiftedBy: shift)
        return (result, overflow)
    }
    
    /// Subtracts `other` from `self`, returning the result and a flag indicating arithmetic overflow.
    ///
    /// - Note: When the operation overflows, then `partialValue` is the twos' complement of the absolute value of the difference.
    /// - Complexity: O(count)
    public func subtractingReportingOverflow(_ other: PreciseUInt) -> (partialValue: PreciseUInt, overflow: Bool) {
        return self.subtractingReportingOverflow(other, shiftedBy: 0)
    }
    
    /// Subtract `other` from this integer in place.
    /// `other` is shifted `shift` digits to the left before being subtracted.
    ///
    /// - Requires: self >= other * 2^shift
    /// - Complexity: O(count)
    public mutating func subtract(_ other: PreciseUInt, shiftedBy shift: Int = 0) {
        let overflow = subtractReportingOverflow(other, shiftedBy: shift)
        precondition(!overflow)
    }
    
    /// Subtract `b` from this integer, and return the difference.
    /// `b` is shifted `shift` digits to the left before being subtracted.
    ///
    /// - Requires: self >= b * 2^shift
    /// - Complexity: O(count)
    public func subtracting(_ other: PreciseUInt, shiftedBy shift: Int = 0) -> PreciseUInt {
        var result = self
        result.subtract(other, shiftedBy: shift)
        return result
    }
    
    /// Decrement this integer by one.
    ///
    /// - Requires: !isZero
    /// - Complexity: O(count)
    public mutating func decrement(shiftedBy shift: Int = 0) {
        self.subtract(1, shiftedBy: shift)
    }
    
    /// Subtract `b` from `a` and return the result.
    ///
    /// - Requires: a >= b
    /// - Complexity: O(a.count)
    public static func -(a: PreciseUInt, b: PreciseUInt) -> PreciseUInt {
        return a.subtracting(b)
    }
    
    /// Subtract `b` from `a` and store the result in `a`.
    ///
    /// - Requires: a >= b
    /// - Complexity: O(a.count)
    public static func -=(a: inout PreciseUInt, b: PreciseUInt) {
        a.subtract(b)
    }
}

extension PreciseInt {
    public mutating func negate() {
        guard !magnitude.isZero else { return }
        self.sign = self.sign == .plus ? .minus : .plus
    }
    
    /// Subtract `b` from `a` and return the result.
    public static func -(a: PreciseInt, b: PreciseInt) -> PreciseInt {
        return a + -b
    }
    
    /// Subtract `b` from `a` in place.
    public static func -=(a: inout PreciseInt, b: PreciseInt) { a = a - b }
}


//
//  Integer Conversion.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2017-08-11.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt {
    public init?<T: BinaryInteger>(exactly source: T) {
        guard source >= (0 as T) else { return nil }
        if source.bitWidth <= 2 * Word.bitWidth {
            var it = source.words.makeIterator()
            self.init(low: it.next() ?? 0, high: it.next() ?? 0)
            precondition(it.next() == nil, "Length of BinaryInteger.words is greater than its bitWidth")
        }
        else {
            self.init(words: source.words)
        }
    }
    
    public init<T: BinaryInteger>(_ source: T) {
        precondition(source >= (0 as T), "PreciseUInt cannot represent negative values")
        self.init(exactly: source)!
    }
    
    public init<T: BinaryInteger>(truncatingIfNeeded source: T) {
        self.init(words: source.words)
    }
    
    public init<T: BinaryInteger>(clamping source: T) {
        if source <= (0 as T) {
            self.init()
        }
        else {
            self.init(words: source.words)
        }
    }
}

extension PreciseInt {
    public init() {
        self.init(sign: .plus, magnitude: 0)
    }
    
    /// Initializes a new signed big integer with the same value as the specified unsigned big integer.
    public init(_ integer: PreciseUInt) {
        self.magnitude = integer
        self.sign = .plus
    }
    
    public init<T>(_ source: T) where T : BinaryInteger {
        if source >= (0 as T) {
            self.init(sign: .plus, magnitude: PreciseUInt(source))
        }
        else {
            var words = Array(source.words)
            words.twosComplement()
            self.init(sign: .minus, magnitude: PreciseUInt(words: words))
        }
    }
    
    public init?<T>(exactly source: T) where T : BinaryInteger {
        self.init(source)
    }
    
    public init<T>(clamping source: T) where T : BinaryInteger {
        self.init(source)
    }
    
    public init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
        self.init(source)
    }
}

extension PreciseUInt: ExpressibleByIntegerLiteral {
    /// Initialize a new big integer from an integer literal.
    public init(integerLiteral value: UInt64) {
        self.init(value)
    }
}

extension PreciseInt: ExpressibleByIntegerLiteral {
    /// Initialize a new big integer from an integer literal.
    public init(integerLiteral value: Int64) {
        self.init(value)
    }
}



//
//  String Conversion.swift
//  PreciseInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension PreciseUInt {
    
    //MARK: String Conversion
    
    /// Calculates the number of numerals in a given radix that fit inside a single `Word`.
    ///
    /// - Returns: (chars, power) where `chars` is highest that satisfy `radix^chars <= 2^Word.bitWidth`. `power` is zero
    ///   if radix is a power of two; otherwise `power == radix^chars`.
    fileprivate static func charsPerWord(forRadix radix: Int) -> (chars: Int, power: Word) {
        var power: Word = 1
        var overflow = false
        var count = 0
        while !overflow {
            let (p, o) = power.multipliedReportingOverflow(by: Word(radix))
            overflow = o
            if !o || p == 0 {
                count += 1
                power = p
            }
        }
        return (count, power)
    }
    
    /// Initialize a big integer from an ASCII representation in a given radix. Numerals above `9` are represented by
    /// letters from the English alphabet.
    ///
    /// - Requires: `radix > 1 && radix < 36`
    /// - Parameter `text`: A string consisting of characters corresponding to numerals in the given radix. (0-9, a-z, A-Z)
    /// - Parameter `radix`: The base of the number system to use, or 10 if unspecified.
    /// - Returns: The integer represented by `text`, or nil if `text` contains a character that does not represent a numeral in `radix`.
    public init?<S: StringProtocol>(_ text: S, radix: Int = 10) {
        precondition(radix > 1)
        let (charsPerWord, power) = PreciseUInt.charsPerWord(forRadix: radix)
        
        var words: [Word] = []
        var end = text.endIndex
        var start = end
        var count = 0
        while start != text.startIndex {
            start = text.index(before: start)
            count += 1
            if count == charsPerWord {
                guard let d = Word.init(text[start ..< end], radix: radix) else { return nil }
                words.append(d)
                end = start
                count = 0
            }
        }
        if start != end {
            guard let d = Word.init(text[start ..< end], radix: radix) else { return nil }
            words.append(d)
        }
        
        if power == 0 {
            self.init(words: words)
        }
        else {
            self.init()
            var counter = words.count - 1
            while counter >= 0 {
                let d = words[counter]
                self.multiply(byWord: power)
                self.addWord(d)
                
                counter -= 1
            }
        }
    }
}

extension PreciseInt {
    /// Initialize a big integer from an ASCII representation in a given radix. Numerals above `9` are represented by
    /// letters from the English alphabet.
    ///
    /// - Requires: `radix > 1 && radix < 36`
    /// - Parameter `text`: A string optionally starting with "-" or "+" followed by characters corresponding to numerals in the given radix. (0-9, a-z, A-Z)
    /// - Parameter `radix`: The base of the number system to use, or 10 if unspecified.
    /// - Returns: The integer represented by `text`, or nil if `text` contains a character that does not represent a numeral in `radix`.
    public init?<S: StringProtocol>(_ text: S, radix: Int = 10) {
        var magnitude: PreciseUInt?
        var sign: Sign = .plus
        if text.first == "-" {
            sign = .minus
            let text = text.dropFirst()
            magnitude = PreciseUInt(text, radix: radix)
        }
        else if text.first == "+" {
            let text = text.dropFirst()
            magnitude = PreciseUInt(text, radix: radix)
        }
        else {
            magnitude = PreciseUInt(text, radix: radix)
        }
        guard let m = magnitude else { return nil }
        self.magnitude = m
        self.sign = sign
    }
}

extension String {
    /// Initialize a new string with the base-10 representation of an unsigned big integer.
    ///
    /// - Complexity: O(v.count^2)
    public init(_ v: PreciseUInt) { self.init(v, radix: 10, uppercase: false) }
    
    /// Initialize a new string representing an unsigned big integer in the given radix (base).
    ///
    /// Numerals greater than 9 are represented as letters from the English alphabet,
    /// starting with `a` if `uppercase` is false or `A` otherwise.
    ///
    /// - Requires: radix > 1 && radix <= 36
    /// - Complexity: O(count) when radix is a power of two; otherwise O(count^2).
    public init(_ v: PreciseUInt, radix: Int, uppercase: Bool = false) {
        precondition(radix > 1)
        let (charsPerWord, power) = PreciseUInt.charsPerWord(forRadix: radix)
        
        guard !v.isZero else { self = "0"; return }
        
        var parts: [String]
        if power == 0 {
            parts = v.words.map { String($0, radix: radix, uppercase: uppercase) }
        }
        else {
            parts = []
            var rest = v
            while !rest.isZero {
                let mod = rest.divide(byWord: power)
                parts.append(String(mod, radix: radix, uppercase: uppercase))
            }
        }
        assert(!parts.isEmpty)
        
        self = ""
        var first = true
        
        var counter = parts.count - 1
        while counter >= 0 {
            let part = parts[counter]
            let zeroes = charsPerWord - part.count
            assert(zeroes >= 0)
            if !first && zeroes > 0 {
                // Insert leading zeroes for mid-Words
                self += String(repeating: "0", count: zeroes)
            }
            first = false
            self += part
            
            counter -= 1
        }
    }
    
    /// Initialize a new string representing a signed big integer in the given radix (base).
    ///
    /// Numerals greater than 9 are represented as letters from the English alphabet,
    /// starting with `a` if `uppercase` is false or `A` otherwise.
    ///
    /// - Requires: radix > 1 && radix <= 36
    /// - Complexity: O(count) when radix is a power of two; otherwise O(count^2).
    public init(_ value: PreciseInt, radix: Int = 10, uppercase: Bool = false) {
        self = String(value.magnitude, radix: radix, uppercase: uppercase)
        if value.sign == .minus {
            self = "-" + self
        }
    }
}

extension PreciseUInt: CustomStringConvertible {
    /// Return the decimal representation of this integer.
    public var description: String {
        return String(self, radix: 10)
    }
}

extension PreciseInt: CustomStringConvertible {
    /// Return the decimal representation of this integer.
    public var description: String {
        return String(self, radix: 10)
    }
}

extension PreciseUInt: CustomPlaygroundDisplayConvertible {
    
    /// Return the playground quick look representation of this integer.
    public var playgroundDescription: Any {
        let text = String(self)
        return text + " (\(self.bitWidth) bits)"
    }
}

extension PreciseInt: CustomPlaygroundDisplayConvertible {
    
    /// Return the playground quick look representation of this integer.
    public var playgroundDescription: Any {
        let text = String(self)
        return text + " (\(self.magnitude.bitWidth) bits)"
    }
}

func pow(_ lhs: PreciseUInt, _ rhs: Int) -> PreciseUInt {
    return lhs.power(rhs)
}

func pow(_ lhs: PreciseInt, _ rhs: Int) -> PreciseInt {
    return lhs.power(rhs)
}

extension PreciseInt {
    init(_ float: PreciseFloat) {
        var value = float.coefficient
        var exponent = float.exponent
        
        while exponent > 0 {
            value *= 10
            exponent -= 1
        }
        
        while exponent < 0 {
            value /= 10
            exponent += 1
        }
        
        self.init(value)
        self.sign = float.sign == .plus ? .plus : .minus
    }
}

*/
