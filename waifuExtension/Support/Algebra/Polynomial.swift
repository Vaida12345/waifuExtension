//
//  Polynomial.swift
//
//
//  Created by Vaida on 9/7/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation


//MARK: - Polynomial

/// Univariate polynomial
struct Polynomial: Equatable, CustomStringConvertible, Hashable {
    
    
    //MARK: - Basic Properties
    
    /// Coefficients are in the order of power n, n-1, ...
    var coefficients: Vector
    
    
    //MARK: - Instance Properties
    
    /// The degree of polynomial.
    var degree: Int {
        return self.simplified().coefficients.count - 1
    }
    
    /// the list of degree, that is, [n, n-1, ...]
    ///
    /// Note that this list is actually independent of `self.degree`. This depends on the number of coefficients.
    /// As sometime `0` may occur at the leading coefficient position. Degree must ignore this `0`. But `degreeList` cannot it usually share the same index as coefficients.
    var degreeList: [Int] {
        return [Int](0..<self.coefficients.count).sorted(by: >)
    }
    
    /// The leading coefficient, that is, the coefficient of the highest degree
    ///
    /// Can be either `get` or `set`.
    var leadingCoefficient: Fraction {
        get {
            return self.coefficients.filter({ $0 != 0 }).first ?? 0
        }
        set {
            self.coefficients[0] = newValue
        }
    }
    
    /// Determine whether the polynomial only consist of a constant term
    var isConstant: Bool {
        return self.degree == 0
    }
    
    /// Returns the constant term of the polynomial
    ///
    /// Can be either `get` or `set`.
    var constantTerm: Fraction {
        get {
            return self.coefficients.last ?? 0
        }
        set {
            self.coefficients[self.coefficients.count-1] = newValue
        }
    }
    
    /// The discriminant of polynomials
    var discriminant: Fraction {
        guard self.degree >= 1 else { return -1 }
        return Fraction(pow(-1, (self.degree * (self.degree - 1) / 2))) / self.leadingCoefficient * resultant(self, self.derivative)
    }
    
    /// The roots of the polynomial over the reals.
    ///
    /// The value is nil if no roots.
    var roots: [Fraction]? {
        guard discriminant >= 0 else { return nil }
        guard self.degree >= 1 else { return nil }
        
        switch degree {
        case 1:
            guard self.leadingCoefficient != 0 else { return nil }
            return [-1 / self.leadingCoefficient * coefficients.last!]
            
        case 2:
            if self.discriminant == 0 {
                return [-1 * coefficients[1] / ( 2 * coefficients.first! )]
            } else if self.discriminant > 0 {
                return [(-1 * coefficients[1] + sqrt(self.discriminant)) / ( 2 * coefficients.first! ), (-1 * coefficients[1] - sqrt(self.discriminant)) / ( 2 * coefficients.first! )]
            } else {
                return nil
            }
            
        default:
            guard let values = self.factorized() else { return nil }
            var content: [Fraction] = []
            for i in values {
                if let roots = i.roots {
                    content += roots
                }
            }
            return content.removingRepeatedElements()
        }
    }
    
    /// The expression of the polynomial.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 1])
    ///     print(a.expression)
    ///     // prints "1x + 1"
    var expression: String {
        let algebra = Algebra(from: self.simplified())
        var content = ""
        for i in algebra {
            if i.coefficient.sign == .plus {
                content += " + \(i)"
            } else {
                content += " - \(abs(i))"
            }
        }
        content.removeFirst(3)
        return content
    }
    
    /// The values of x where the function cross the x-axis.
    ///
    /// Also known as `self.roots`.
    var xIntercepts: [Fraction]? {
        return self.roots
    }
    
    /// The values of y where the function cross the y-axis.
    var yIntercept: Fraction {
        return self[0]
    }
    
    /// The local minimum of the function.
    ///
    /// The value is `nil` if there is not a local minimum.
    var localMinimum: Fraction? {
        guard self.degree >= 1 else { return self.constantTerm }
        guard var roots = self.derivative.roots else { return nil }
        roots = roots.filter({ self.secondDerivative[$0] > 0 })
        let values = roots.map({ self[$0] })
        guard let min = values.min() else { return nil }
        return roots[values.firstIndex(of: min)!]
    }
    
    /// The local maximum of the function.
    ///
    /// The value is `nil` if there is not a local maximum.
    var localMaximum: Fraction? {
        guard self.degree >= 1 else { return self.constantTerm }
        guard var roots = self.derivative.roots else { return nil }
        roots = roots.filter({ self.secondDerivative[$0] < 0 })
        let values = roots.map({ self[$0] })
        guard let max = values.max() else { return nil }
        return roots[values.firstIndex(of: max)!]
    }
    
    /// The x of (x, y) where the stationary points are.
    ///
    /// The value is `nil` if no stationary points can be found.
    var stationaryPoints: [Fraction]? {
        return self.derivative.roots
    }
    
    /// The x of (x, y) where the points of inflection are.
    ///
    /// The value is `nil` if no PoIs can be found.
    var pointsOfInflection: [Fraction]? {
        return self.derivative.roots
    }
    
    /// The x of (x, y) where the horizontal points of inflection are.
    ///
    /// The value is `nil` if no HPIs can be found.
    var horizontalPointOfInflection: [Fraction]? {
        return self.secondDerivative.roots?.filter({ self.secondDerivative.derivative[$0] != 0 })
    }
    
    /// The latex expression.
    var latexExpression: String {
        return expression
    }
    
    /// Find the derivative of the polynomial.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 2, 1])
    ///     print(a.derivative)
    ///     // prints "Polynomial<alphas: [2, 2]>"
    var derivative: Polynomial {
        var coefficients = [Fraction](self.coefficients.dropLast())
        for i in 0..<coefficients.count { coefficients[i] *= Fraction(self.degreeList[i]) }
        return Polynomial(coefficients: coefficients)
    }
    
    /// Find the second derivative of the polynomial.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 2, 1])
    ///     print(a.secondDerivative)
    ///     // prints "Polynomial<alphas: [2]>"
    var secondDerivative: Polynomial {
        return self.derivative.derivative
    }
    
    /// Integrate the polynomial.
    ///
    /// The constant term of integral is set to zero.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 2, 3])
    ///     print(a.integrate)
    ///     // prints "Polynomial<alphas: [1/3, 1, 3, 0]>"
    var integrate: Polynomial {
        var coefficients = self.coefficients
        for i in 0..<coefficients.count { coefficients[i] /= Fraction(self.degree + 1 - i) }
        coefficients.append(0)
        return Polynomial(coefficients: coefficients)
    }
    
    /// Debug description.
    ///
    /// An example:
    ///
    ///     print(Polynomial(coefficients: [1, 2]).description)
    ///     // prints "Polynomial<alphas: [1, 2]>"
    var description: String {
        return "Polynomial<alphas: \(self.coefficients)>"
    }
    
    
    //MARK: - Initializers
    
    /// Initialize with the coefficients of the polynomial.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 2, 3])
    ///     print(a.expression)
    ///     // prints "1x^2 + 2x^1 + 3"
    ///
    /// - Parameters:
    ///     - coefficients: In the order of power n, n-1, ...
    init(coefficients: Vector) {
        if coefficients.isEmpty{
            self.coefficients = [0]
        } else {
            self.coefficients = coefficients
        }
    }
    
    /// Initialize with the coefficients of the polynomial.
    ///
    /// An example:
    ///
    ///     let a = Polynomial([1, 2, 3])
    ///     print(a.expression)
    ///     // prints "1 + 2x^1 + 3x^2"
    ///
    /// - Parameters:
    ///     - coefficients: In the order of power 1, 2, ...
    init(_ coefficients: Vector) {
        if coefficients.isEmpty{
            self.coefficients = [0]
        } else {
            self.coefficients = coefficients.reversed()
        }
    }
    
    /// Estimate the unknown parameters in a linear regression model with ordinary least squares.
    ///
    /// The degree n should be less than the number of points. Otherwise it would give the polynomial that goes through all the points, which is what happens when n = points.count - 1.
    ///
    /// An example:
    ///
    ///     let points: [Point] = [Point(x: 1, y: 1), Point(x: 2, y: 2), Point(x: 3, y: 2), Point(x: 4, y: 2)]
    ///     print(regression(points: points, degree: 2))
    ///     // prints "Polynomial<alphas: [-1/4, 31/20, -1/4]>"
    ///
    /// - Parameters:
    ///     - points: The points in the form of dictionary to perform regression with.
    ///     - degree: The degree of the desired polynomial.
    init(byRegression points: [Point], degree n: Int) {
        self = regression(points: points, degree: n)
    }
    
    /// Creates an empty `Polynomial`.
    ///
    /// An example:
    ///
    ///     print(Polynomial())
    ///     // prints "Polynomial<alphas: [0]>"
    init() {
        self.init(coefficients: [0])
    }
    
    /// Initialize a polynomial with only one term.
    ///
    /// An example:
    ///
    ///     print(Polynomial(leadingCoefficient: 3, degree: 3))
    ///     // prints "Polynomial<alphas: [3, 0, 0, 0]>"
    ///
    /// - Parameters:
    ///     - leadingCoefficient: The leading coefficient, ie, the coefficient of the term.
    ///     - degree: The degree of the term.
    init(leadingCoefficient: Fraction, degree: Int) {
        var vector: Vector = [leadingCoefficient]
        while vector.count - 1 < degree {
            vector.append(0)
        }
        self.init(coefficients: vector)
    }
    
    
    //MARK: - Instance Methods
    
    /// Determines whether a polynomial is a multiple of another.
    func isMultiple(of other: Polynomial) -> Bool {
        return self / other != nil
    }
    
    /// Removes the unwanted zeros in the coefficients, that is the zero appears at the leading coefficient.
    ///
    /// An example:
    ///
    ///     print(Polynomial(coefficients: [0, 0, 0, 1]).simplified())
    ///     // prints "Polynomial<alphas: [1]>"
    ///
    func simplified() -> Polynomial {
        guard !self.coefficients.allSatisfy({ $0 == 0 }) else { return Polynomial() }
        var content = self
        while content.leadingCoefficient != content.coefficients.first { content.coefficients.removeFirst() }
        return content
    }
    
    /// The function of the polynomial.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 1])
    ///     print(a.function(5))
    ///     // prints "6"
    func function(_ x: Fraction) -> Fraction {
        var content: Fraction = 0
        for i in 0..<self.coefficients.count {
            content += self.coefficients[i] * pow(x, Fraction(self.degreeList[i]))
        }
        return content
    }
    
    /// The function of the polynomial.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 1])
    ///     print(a.function(5))
    ///     // prints "6.0"
    func function(double x: Double) -> Double {
        var content: Double = 0
        for i in 0..<self.coefficients.count {
            content += (Double(self.coefficients[i])) * pow(x, Double(self.degreeList[i]))
        }
        return content
    }
    
    /// Solve the polynomial.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 1])
    ///     print(a.solved())
    ///     // prints "-1.0"
    func solved() -> Double? {
        solve({ x in
            Double(self.function(double: x))
        })
    }
    
    /// Find the x-coordinate of intersection point with another polynomial.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 2, 1])
    ///     let b = Polynomial(coefficients: [1, 1])
    ///     print(a.findIntersection(with: b))
    ///     // prints "Optional([0, -1])"
    ///
    /// - Parameters:
    ///     - polynomial: The right-hand-side polynomial.
    func findIntersection(with polynomial: Polynomial) -> [Fraction]? {
        return (self - polynomial).roots
    }
    
    /// Defined integrate the polynomial.
    ///
    /// An example:
    ///
    ///     let poly = Polynomial(coefficients: [1, 1])
    ///     print(poly.integrate(from: 0, to: 1))
    ///     // prints "3/2"
    func integrate(from a: Fraction, to b: Fraction) -> Fraction {
        return self.integrate[b] - self.integrate[a]
    }
    
    /// Find the rational factors of the polynomial.
    ///
    /// An example:
    ///
    ///     print(Polynomial(coefficients: [1, 2, 1]).factorized() ?? "")
    ///     // prints "[Polynomial<alphas: [1, 1]>, Polynomial<alphas: [1, 1]>]"
    func factorized() -> [Polynomial]? {
        guard self.degree >= 1 else { return nil }
        guard self.discriminant >= 0 else { return nil }
        var factors: [Polynomial] = []
        guard let root = self.solved() else { return nil }
        let root2 = Fraction(root)
        let poly = Polynomial(coefficients: [1, -1 * root2])
        factors.append(poly)
        if let values = (self / poly)?.factorized() {
            factors += values
        } else if let value = self / poly {
            factors.append(value)
        }
        return factors.filter({ $0.degree >= 1 })
    }
    
    /// Create an image of the current polynomial and write to /Users/vaida/Documents/Xcode Data/Plotter/.
    func drawn() {
        let canvas = Canvas()
        canvas.functions.append { x in
            self.function(double: x)
        }
        canvas.titles = [self.expression]
        canvas.draw()
        print("Polynomial drawn to /Users/vaida/Documents/Xcode Data/Plotter/")
    }
    
    /// Find the greatest common divisor of two polynomials by Euclidean division.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 1])
    ///     let b = Polynomial(coefficients: [1, 2, 1])
    ///     print(a.gcd(with: b))
    ///     // prints "Polynomial<alphas: [1, 1]>"
    func greatestCommonDivisor(with rhs: Polynomial) -> Polynomial {
        let a = self.degree > rhs.degree ? self : rhs
        let b = self.degree < rhs.degree ? self : rhs
        var q = Polynomial()
        var r = a
        let d = b.degree
        let c = b.leadingCoefficient
        
        guard d != 0 else { return Polynomial(coefficients: [1]) }
        while r.degree >= d {
            let s = Polynomial(leadingCoefficient: r.leadingCoefficient / c, degree: r.degree - d)
            q = q + s
            r = r - s * b
        }
        return q
    }
    
    
    //MARK: - Operator Functions
    
    /// Adds two polynomials and produces their sum.
    ///
    /// The addition operator (`+`) calculates the sum of its two arguments.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 2, 1])
    ///     let b = Polynomial(coefficients: [1, 1])
    ///     print(a + b)
    ///     // prints "Polynomial<alphas: [1, 3, 2]>"
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    static func + (lhs: Polynomial, rhs: Polynomial) -> Polynomial {
        let (lhs, rhs) = fillZeroEntries(lhs: lhs.coefficients, rhs: rhs.coefficients)
        return Polynomial(coefficients: lhs + rhs)
    }
    
    /// Subtracts one value from another and produces their difference.
    ///
    /// The subtraction operator (`-`) calculates the difference of its two arguments.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 2, 1])
    ///     let b = Polynomial(coefficients: [1, 1])
    ///     print(a - b)
    ///     // prints "Polynomial<alphas: [1, 1, 0]>"
    ///
    /// - Parameters:
    ///   - lhs: A numeric value.
    ///   - rhs: The value to subtract from `lhs`.
    static func - (lhs: Polynomial, rhs: Polynomial) -> Polynomial {
        let (lhs, rhs) = fillZeroEntries(lhs: lhs.coefficients, rhs: rhs.coefficients)
        return Polynomial(coefficients: lhs - rhs)
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 2, 1])
    ///     let b = Polynomial(coefficients: [1, 1])
    ///     print(a * b)
    ///     // prints "Polynomial<alphas: [1, 3, 3, 1]>"
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: Polynomial, rhs: Polynomial) -> Polynomial {
        var coefficients = [Fraction](repeating: 0, count: lhs.degreeList.count + rhs.degreeList.count - 1)
        for i in 0..<lhs.coefficients.count {
            for ii in 0..<rhs.coefficients.count {
                let degree = lhs.degreeList[i] + rhs.degreeList[ii]
                let index = lhs.degreeList.count-1 + rhs.degreeList.count-1 - degree
                coefficients[index] += lhs.coefficients[i] * rhs.coefficients[ii]
            }
        }
        
        return Polynomial(coefficients: coefficients)
    }
    
    /// Returns the quotient of dividing the first value by the second.
    ///
    /// An example:
    ///
    ///     let a = Polynomial(coefficients: [1, 2, 1])
    ///     let b = Polynomial(coefficients: [1, 1])
    ///     print(a / b ?? "")
    ///     // prints "Polynomial<alphas: [1, 1]>"
    ///
    /// `lhs` must be a multiple of `rhs` else the return value is `nil`
    ///
    /// - Parameters:
    ///   - lhs: The value to divide.
    ///   - rhs: The value to divide `lhs` by.
    static func / (lhs: Polynomial, rhs: Polynomial) -> Polynomial? {
        guard lhs.degree >= rhs.degree else { return nil }
        guard lhs != rhs else { return Polynomial(coefficients: [1]) }
        
        var lhsCoefficients = lhs.coefficients
        var coefficients: [Fraction] = []
        for i in 0...lhs.degree-rhs.degree {
            coefficients.append((lhsCoefficients[i])/(rhs.leadingCoefficient))
            for ii in 0...rhs.degree {
                lhsCoefficients[i+ii] -= coefficients[i]*rhs.coefficients[ii]
            }
            
            if i == lhs.degree-rhs.degree {
                guard lhsCoefficients.allSatisfy({ $0 == 0 }) else { continue }
            }
        }
        
        return Polynomial(coefficients: coefficients)
    }
    
    
    //MARK: - Subscript
    
    /// Return the value of function at the index.
    subscript(_ index: Fraction) -> Fraction {
        return self.function(index)
    }
}


//MARK: - Supporting Functions

/// Fill zeros in the coefficient for further calculations. This does the opposite of `.simplified`.
///
/// An example:
///
///     print(fillZeroEntries(lhs: [1, 2, 3], rhs: [1, 2]))
///     // prints "(lhs: [1, 2, 3], rhs: [0, 1, 2])"
private func fillZeroEntries(lhs: Vector, rhs: Vector) -> (lhs: Vector, rhs: Vector) {
    var lhs = lhs
    var rhs = rhs
    
    while lhs.count != rhs.count {
        if lhs.count < rhs.count {
            lhs.insert(0, at: 0)
        } else {
            rhs.insert(0, at: 0)
        }
    }
    return (lhs: lhs, rhs: rhs)
}

/// Raise the power of a polynomial
///
/// An example:
///
///     let a = Polynomial(coefficients: [1, 1])
///     print(pow(a, 2) ?? "")
///     // prints "Polynomial<alphas: [1, 2, 1]>"
///
/// The power needs to be greater or equal to zero, otherwise the return value is `nil`.
///
/// - Parameters:
///     - lhs: the polynomial
///     - rhs: the power
func pow(_ lhs: Polynomial, _ rhs: Int) -> Polynomial {
    precondition(rhs >= 0)
    guard rhs > 0 else { return Polynomial(coefficients: [1]) }
    var content = lhs
    for _ in 0..<rhs-1 {
        content = content * lhs
    }
    return content
}

/// In mathematics, the resultant of two polynomials is a polynomial expression of their coefficients, which is equal to zero if and only if the polynomials have a common root (possibly in a field extension), or, equivalently, a common factor (over their field of coefficients).
///
/// - Parameters:
///     - lhs: the polynomial
///     - rhs: another polynomial
func resultant(_ lhs: Polynomial, _ rhs: Polynomial) -> Fraction {
    return sylvesterMatrix(lhs, rhs).determinant
}

/// In mathematics, a Sylvester matrix is a matrix associated to two univariate polynomials with coefficients in a field or a commutative ring.
///
/// - Parameters:
///     - lhs: the polynomial
///     - rhs: another polynomial
func sylvesterMatrix(_ lhs: Polynomial, _ rhs: Polynomial) -> Matrix {
    var matrix = Matrix(empty: Size(width: lhs.degree + rhs.degree, height: lhs.degree + rhs.degree))
    for i in 0..<rhs.degree {
        for ii in 0...lhs.degree {
            matrix[i][i+ii] = lhs.coefficients[ii]
        }
    }
    
    for i in rhs.degree..<lhs.degree+rhs.degree {
        for ii in 0...rhs.degree {
            matrix[i][i+ii-rhs.degree] = rhs.coefficients[ii]
        }
    }
    
    return matrix
}

/// Estimate the unknown parameters in a linear regression model with ordinary least squares.
///
/// The degree n should be less than the number of points. Otherwise it would give the polynomial that goes through all the points, which is what happens when n = points.count - 1.
///
/// An example:
///
///     let points: [Point] = [Point(x: 1, y: 1), Point(x: 2, y: 2), Point(x: 3, y: 2), Point(x: 4, y: 2)]
///     print(regression(points: points, degree: 2))
///     // prints "Polynomial<alphas: [-1/4, 31/20, -1/4]>"
///
/// - Parameters:
///     - points: The points in the form of dictionary to perform regression with.
///     - degree: The degree of the desired polynomial.
fileprivate func regression(points: [Point], degree n: Int) -> Polynomial {
    let n = n < points.count ? n : points.count - 1
    var x: Matrix = []
    for i in points {
        var vector: Vector = []
        for ii in 0...n { vector.append(pow(i.x, Fraction(ii))) }
        x.append(vector)
    }
    let y: Matrix = [points.map({ $0.y })].transposed()
    
    let coefficients = Array(((x.transposed()*x).inverse!*x.transposed()*y).transposed().first!.reversed())
    return Polynomial(coefficients: coefficients)
}


//MARK: - Rational functions

/// Rational functions are defined as the ratio of polynomials.
struct RationalFunction: CustomStringConvertible {
    
    
    //MARK: - Basic Properties
    
    /// The numerator polynomial.
    var numerator: Polynomial
    
    /// The denominator polynomial.
    var denominator: Polynomial
    
    
    //MARK: - Instance Properties
    
    /// The common factors of the numerator and the denominator.
    var commonFactors: [Polynomial] {
        return (numerator.factorized() ?? []).intersection((denominator.factorized() ?? []))
    }
    
    /// Determine whether the numerator and the denominator has common factors.
    var hasCommonFactors: Bool {
        return !commonFactors.isEmpty
    }
    
    /// The list of `x` where the rational function is undefined.
    var undefinedAt: [Fraction] {
        return denominator.roots ?? []
    }
    
    /// Determine whether the rational function can be solved.
    var hasRoot: Bool {
        return self.roots != nil
    }
    
    /// The roots of the polynomial.
    ///
    /// The value is nil if no roots.
    var roots: [Fraction]? {
        if var roots = numerator.roots {
            roots = roots.filter({ self.denominator[$0] != 0 })
            return !roots.isEmpty ? roots : nil
        }
        return nil
    }
    
    /// The expression of the rational function.
    ///
    /// An example:
    ///
    ///     let numerator = Polynomial(coefficients: [1, 2, 1])
    ///     let denominator = Polynomial(coefficients: [1, 3, 3, 1])
    ///     let rationalFunction = RationalFunction(numerator, denominator)!
    ///
    ///     print(rationalFunction.expression)
    ///     // prints "(x^2 + 2x + 1) / (x^3 + 3x^2 + 3x + 1)"
    var expression: String {
        var content = ""
        if numerator.degree != 0 { content += "(\(numerator.expression))" } else { content += "\(numerator.expression)" }
        content += " / "
        if denominator.degree != 0 { content += "(\(denominator.expression))" } else { content += "\(denominator.expression)" }
        return content
    }
    
    /// The values of x where the function cross the x-axis.
    ///
    /// Also known as `self.roots`.
    var xIntercepts: [Fraction]? {
        return self.roots
    }
    
    /// The values of y where the function cross the y-axis.
    var yIntercept: Fraction? {
        return self[0]
    }
    
    /// The limit of the rational function as x -> +infinity.
    var asymptote: Polynomial {
        if numerator.degree > denominator.degree {
            return (numerator / denominator)!
        } else if numerator.degree == denominator.degree {
            return Polynomial(coefficients: [numerator.leadingCoefficient / denominator.leadingCoefficient])
        } else {
            return Polynomial(coefficients: [0])
        }
    }
    
    /// The vertical asymptotes of the rational functions.
    ///
    /// The is the `x` values at which the rational function is undefined.
    ///
    /// Also known as `self.undefinedAt`.
    var verticalAsymptotes: [Fraction] {
        return self.undefinedAt
    }
    
    /// The local maximum of the function.
    ///
    /// The value is `nil` if there is not a local maximum.
    var localMaximum: Fraction? {
        guard self.asymptote.isConstant && self.asymptote.constantTerm.isFinite else { return nil }
        guard self.verticalAsymptotes.isEmpty else { return nil }
        
        guard var roots = self.derivative?.roots else { return nil }
        roots = roots.filter({ self.secondDerivative?[$0] != nil && self.secondDerivative![$0]! < 0 })
        roots = roots.filter({ self[$0] != nil })
        let values = roots.map({ self[$0]! })
        guard let max = values.max() else { return nil }
        return roots[values.firstIndex(of: max)!]
    }
    
    /// The local minimum of the function.
    ///
    /// The value is `nil` if there is not a local minimum.
    var localMinimum: Fraction? {
        guard self.asymptote.isConstant && self.asymptote.constantTerm != Fraction.negativeInfinity else { return nil }
        guard self.verticalAsymptotes.isEmpty else { return nil }
        
        guard var roots = self.derivative?.roots else { return nil }
        roots = roots.filter({ self.secondDerivative?[$0] != nil && self.secondDerivative![$0]! > 0 })
        roots = roots.filter({ self[$0] != nil })
        let values = roots.map({ self[$0]! })
        guard let min = values.min() else { return nil }
        return roots[values.firstIndex(of: min)!]
    }
    
    /// The x of (x, y) where the stationary points are.
    ///
    /// The value is `nil` if no stationary points can be found.
    var stationaryPoints: [Fraction]? {
        return self.derivative?.roots
    }
    
    /// The x of (x, y) where the points of inflection are.
    ///
    /// The value is `nil` if no PoIs can be found.
    var pointsOfInflection: [Fraction]? {
        return self.secondDerivative?.roots
    }
    
    /// The x of (x, y) where the horizontal points of inflection are.
    ///
    /// The value is `nil` if no HPIs can be found.
    var horizontalPointOfInflection: [Fraction]? {
        return self.secondDerivative?.roots?.filter({ self.secondDerivative?.derivative?[$0] != 0 })
    }
    
    /// The latex expression.
    var latexExpression: String {
        if denominator.degree == 0 && abs(denominator.constantTerm) == 1 { return self.numerator.latexExpression }
        return "\\frac{\(self.numerator.latexExpression)}{\(self.denominator.latexExpression)}"
    }
    
    /// Find the derivative of the rational function.
    ///
    /// An example:
    ///
    ///     let numerator = Polynomial(coefficients: [1, 1])
    ///     let denominator = Polynomial(coefficients: [1, 2, 1])
    ///     let rationalFunction = RationalFunction(numerator, denominator)!
    ///
    ///     print(rationalFunction.derivative?.expression ?? "")
    ///     // prints "(x^2 - 2x - 1) / (x^4 + 4x^3 + 6x^2 + 4x + 1)"
    var derivative: RationalFunction? {
        return RationalFunction(numerator.derivative * denominator - denominator.derivative * numerator , pow(denominator, 2))
    }
    
    /// Find the second of the rational function.
    ///
    /// An example:
    ///
    ///     let numerator = Polynomial(coefficients: [1, 1])
    ///     let denominator = Polynomial(coefficients: [1, 2, 1])
    ///     let rationalFunction = RationalFunction(numerator, denominator)!
    ///
    ///     print(rationalFunction.secondDerivative?.expression ?? "")
    ///     // prints "(2x^5 + 10x^4 + 20x^3 + 20x^2 + 10x + 2) / (x^8 + 8x^7 + 28x^6 + 56x^5 + 70x^4 + 56x^3 + 28x^2 + 8x + 1)"
    var secondDerivative: RationalFunction? {
        if let derivative = self.derivative { return derivative.derivative }
        return nil
    }
    
    /// Debug description.
    ///
    ///
    /// An example:
    ///
    ///     let numerator = Polynomial(coefficients: [1])
    ///     let denominator = Polynomial(coefficients: [1, 1])
    ///     let rationalFunction = RationalFunction(numerator, denominator)!
    ///
    ///     print(rationalFunction)
    ///     // prints "RationalFunction<1 / (x + 1)>"
    var description: String {
        return "RationalFunction<\(self.expression)>"
    }
    
    /// The direction from which to approach the limit.
    ///
    /// The directions contains only two elements: left, right.
    enum Direction: Equatable {
        /// Approach the limit form left-hand-side.
        case left
        
        /// Approach the limit form right-hand-side.
        case right
    }
    
    
    //MARK: - Initializers
    
    /// Initialize a rational function, ie, the ratio of polynomials.
    ///
    /// An example:
    ///
    ///     let numerator = Polynomial(coefficients: [1, 2, 1])
    ///     let denominator = Polynomial(coefficients: [1, 3, 3, 1])
    ///     let rationalFunction = RationalFunction(numerator, denominator)!
    ///
    ///     print(rationalFunction.expression)
    ///     // prints "(x^2 + 2x + 1) / (x^3 + 3x^2 + 3x + 1)"
    ///
    /// - Parameters:
    ///     - numerator: The numerator polynomial.
    ///     - denominator: The denominator polynomial.
    init?(_ numerator: Polynomial, _ denominator: Polynomial) {
        guard denominator != Polynomial() else { return nil }
        self.numerator = numerator
        self.denominator = denominator
    }
    
    
    //MARK: - Instance Methods
    
    /// Eliminate the common factors, if possible.
    ///
    /// An example:
    ///
    ///     let numerator = Polynomial(coefficients: [1, 1])
    ///     let denominator = Polynomial(coefficients: [1, 2, 1])
    ///     let rationalFunction = RationalFunction(numerator, denominator)!
    ///
    ///     print(rationalFunction.reduced().expression)
    ///     // prints "1 / (x + 1)"
    func reduced() -> RationalFunction {
        guard self.hasCommonFactors else { return self }
        var content = self
        for i in self.commonFactors {
            content.numerator = (content.numerator / i)!
            content.denominator = (content.denominator / i)!
        }
        return content
    }
    
    /// The function of the rational function.
    ///
    /// An example:
    ///
    ///     let numerator = Polynomial(coefficients: [1, 1])
    ///     let denominator = Polynomial(coefficients: [1, 2, 1])
    ///     let rationalFunction = RationalFunction(numerator, denominator)!
    ///
    ///     print(rationalFunction.function(1) ?? 0)
    ///     // prints "1/2"
    ///
    /// - Parameters:
    ///     - x: The x position in which to calculate the value.
    func function(_ x: Fraction) -> Fraction? {
        guard x.isFinite && denominator[x] != 0 else { return nil }
        return numerator[x] / denominator[x]
    }
    
    /// The function of the rational function.
    ///
    /// The method was designed for the use of `solve()` only.
    ///
    /// An example:
    ///
    ///     let numerator = Polynomial(coefficients: [1, 1])
    ///     let denominator = Polynomial(coefficients: [1, 2, 1])
    ///     let rationalFunction = RationalFunction(numerator, denominator)!
    ///
    ///     print(rationalFunction.function(double: 1) ?? 0)
    ///     // prints "0.5"
    ///
    /// - Parameters:
    ///     - x: The x position in which to calculate the value.
    func function(double x: Double) -> Double? {
        guard x.isFinite && denominator.function(double: x) != 0 else { return nil }
        return numerator.function(double: x) / denominator.function(double: x)
    }
    
    /// Create an image of the current rational function and write to /Users/vaida/Documents/Xcode Data/Plotter/.
    func drawn() {
        let canvas = Canvas()
        canvas.functions.append { x in
            self.function(double: x)
        }
        canvas.titles = [self.description]
        canvas.draw()
        print("Polynomial drawn to /Users/vaida/Documents/Xcode Data/Plotter/")
    }
    
    /// Find the limit at point x.
    ///
    /// Please note that if x is set to infinity, the return value may be infinity. The suggest method is `self.asymptote`.
    ///
    /// - Parameters:
    ///     - x: The x coordinate of the point to find the limit.
    ///     - direction: The direction from which to approach. It will come to effect only when the function is undefined at x.
    func limit(at x: Fraction, from direction: Direction?) -> Fraction {
        guard x.isFinite else {
            if self.asymptote.isConstant {
                return self.asymptote.constantTerm
            } else {
                if x == Fraction.infinity {
                    return numerator.leadingCoefficient.sign == denominator.leadingCoefficient.sign ? Fraction.infinity : Fraction.negativeInfinity
                } else {
                    return pow(numerator.leadingCoefficient, Fraction(numerator.degree)) * pow(denominator.leadingCoefficient, Fraction(denominator.degree)) > 0 ? Fraction.infinity : Fraction.negativeInfinity
                }
            }
        }
        
        guard self.denominator[0] == 0 else { return self[x]! }
        
        let delta = Fraction(0.0001)
        let value = direction == .left ? x - delta : x + delta
        return self[value]! > 0 ? Fraction.infinity : Fraction.negativeInfinity
    }
    
    /// The transpose of a rational function.
    ///
    /// It does the following:
    ///
    ///     1 / x -> x / 1
    func transposed() -> RationalFunction? {
        return RationalFunction(self.denominator, self.numerator)
    }
    
    
    //MARK: - Operator Functions
    
    /// Adds two rational functions and produces their sum.
    ///
    /// The addition operator (`+`) calculates the sum of its two arguments.
    ///
    /// An example:
    ///
    ///     // a = 1 / (x + 1)
    ///     let a = RationalFunction(Polynomial(coefficients: [1]), Polynomial(coefficients: [1, 1]))!
    ///
    ///     // b = 1 / (x + 2)
    ///     let b = RationalFunction(Polynomial(coefficients: [1]), Polynomial(coefficients: [1, 2]))!
    ///
    ///     print((a+b).expression)
    ///     // prints "(2x + 3) / (x^2 + 3x + 2)"
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    static func + (lhs: RationalFunction, rhs: RationalFunction) -> RationalFunction {
        let lcm = leastCommonFactor(lhs.denominator, rhs.denominator) ?? lhs.denominator * rhs.denominator
        let lhs = lhs.numerator * (lcm / lhs.denominator)!
        let rhs = rhs.numerator * (lcm / rhs.denominator)!
        return RationalFunction(lhs + rhs, lcm)!
    }
    
    /// Subtracts one value from another and produces their difference.
    ///
    /// The subtraction operator (`-`) calculates the difference of its two arguments.
    ///
    /// An example:
    ///
    ///     // a = 1 / (x + 1)
    ///     let a = RationalFunction(Polynomial(coefficients: [1]), Polynomial(coefficients: [1, 1]))!
    ///
    ///     // b = 1 / (x + 2)
    ///     let b = RationalFunction(Polynomial(coefficients: [1]), Polynomial(coefficients: [1, 2]))!
    ///
    ///     print((a-b).expression)
    ///     // prints "1 / (x^2 + 3x + 2)"
    ///
    /// - Parameters:
    ///   - lhs: A numeric value.
    ///   - rhs: The value to subtract from `lhs`.
    static func - (lhs: RationalFunction, rhs: RationalFunction) -> RationalFunction {
        return lhs + (-1 * rhs)
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// An example:
    ///
    ///     // a = 1 / (x + 1)
    ///     let a = RationalFunction(Polynomial(coefficients: [1]), Polynomial(coefficients: [1, 1]))!
    ///
    ///     // b = 1 / (x + 2)
    ///     let b = RationalFunction(Polynomial(coefficients: [1]), Polynomial(coefficients: [1, 2]))!
    ///
    ///     print((a*b).expression)
    ///     // prints "1 / (x^2 + 3x + 2)"
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: RationalFunction, rhs: RationalFunction) -> RationalFunction {
        return RationalFunction(lhs.numerator * rhs.numerator, lhs.denominator * rhs.denominator)!.reduced()
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// An example:
    ///
    ///     // a = 1 / (x + 1)
    ///     let a = RationalFunction(Polynomial(coefficients: [1]), Polynomial(coefficients: [1, 1]))!
    ///
    ///     print((2 * a).expression)
    ///     // prints "2 / (x + 1)"
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: Fraction, rhs: RationalFunction) -> RationalFunction {
        let numerator = Polynomial(coefficients: rhs.numerator.coefficients.map({ $0 * lhs }))
        return RationalFunction(numerator, rhs.denominator)!
    }
    
    /// Returns the quotient of dividing the first value by the second.
    ///
    /// An example:
    ///
    ///     // a = 1 / (x + 1)
    ///     let a = RationalFunction(Polynomial(coefficients: [1]), Polynomial(coefficients: [1, 1]))!
    ///
    ///     // b = 1 / (x + 2)
    ///     let b = RationalFunction(Polynomial(coefficients: [1]), Polynomial(coefficients: [1, 2]))!
    ///
    ///     print((a/b)?.expression ?? "")
    ///     // prints "(x + 2) / (x + 1)"
    ///
    /// `lhs` must be a multiple of `rhs` else the return value is `nil`
    ///
    /// - Parameters:
    ///   - lhs: The value to divide.
    ///   - rhs: The value to divide `lhs` by.
    static func / (lhs: RationalFunction, rhs: RationalFunction) -> RationalFunction? {
        guard let rhs = rhs.transposed() else { return nil }
        return lhs * rhs
    }
    
    
    //MARK: - Subscript
    
    /// Return the value of function at the index.
    ///
    /// An example:
    ///
    ///     let numerator = Polynomial(coefficients: [1, 1])
    ///     let denominator = Polynomial(coefficients: [1, 2, 1])
    ///     let rationalFunction = RationalFunction(numerator, denominator)!
    ///
    ///     print(rationalFunction[1] ?? "")
    ///     // prints "1/2"
    ///
    /// This is a shortcut for `function(index)`.
    ///
    /// - Parameters:
    ///     - x: The x position in which to calculate the value.
    subscript(_ index: Fraction) -> Fraction? {
        return self.function(index)
    }
}

/// The least common factor of lhs and rhs rational functions
private func leastCommonFactor(_ lhs: Polynomial, _ rhs: Polynomial) -> Polynomial? {
    guard let gcd = (lhs / rhs) else { return nil }
    return lhs * rhs / gcd
}
