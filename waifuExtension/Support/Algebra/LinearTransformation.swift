//
//  LinearTransformation.swift
//
//
//  Created by Vaida on 9/10/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation

/// Linear transformation are functions between vectors spaces that preserve the vector structure.
///
/// A linear transformation from V to W is a function T: V -> W such that for each u, v in V and a in F:
///
///     T(u+v) = T(u)+T(v)
///     T(a*u) = a*T(u)
struct LinearTransformation: CustomStringConvertible {
    /// The transformation function.
    var T: ((_ vector: Vector) -> Vector) {
        return { vector in
            return (self.representation * [vector].transposed()).transposed().first!
        }
    }
    
    /// The matrix representation of a linear transformation, denoted by `[T]`.
    ///
    /// - Remark:
    ///
    ///       /*
    ///       `[T]`:  `[T(v)][v]` for all `v` in `V`, `T: V -> W`.
    ///             where  `[v]`: the coordinate vector for v with respect to `S`.
    ///                 `[T(v)]`: the coordinate vector for `T(v)` with respect to `S'`.
    ///                     `S`: The standard basis for `V`.
    ///                     `S'`: The standard basis for `W`.
    ///       */
    ///
    /// ***
    ///
    /// Example:
    ///
    ///     let vector: Vector = [1, 1, 1]
    ///     let transformation = LinearTransformation(representation: [[0, 1, -2], [3, 0, 1]])
    ///     print(transformation.representation)
    ///     // prints "[[0, 1, -2], [3, 0, 1]]"
    ///
    /// - Note:
    /// Representation matrix does not need to be reduced. If it is reduced, the transformation would be changed.
    ///
    let representation: Matrix
    
    /// The `n` of R^n, which the lhs vector space `V` represents.
    /// `T: V -> W`
    var lhsVectorSpace: Int {
        return representation.size.width
    }
    
    /// The `n` of R^n, which the lhs vector space `W` represents.
    /// `T: V -> W`
    var rhsVectorSpace: Int {
        return representation.size.height
    }
    
    /// The description for the LinearTransformation
    var description: String {
        return "LinearTransformation<representation: \(self.representation)>"
    }
    
    /// The kernel of current linear transformation.
    ///
    /// The kernel (null space) of T is defined as T.kernel = {u \in U | T(u) = 0} T: U -> V
    var kernel: [Vector] {
        return self.representation.solutionSpace
    }
    
    /// The image of current linear transformation.
    ///
    /// The image (range) of T is defined as T.image = { v \in V | v=T(u) for some u \in U } T: U -> V
    var image: [Vector] {
        return self.representation.columnSpace
    }
    
    /// Determines whether the linear transformation is injective.
    ///
    /// - Invariant: Injective: aka, one-to-one function.
    var isInjective: Bool {
        return self.kernel.allSatisfy({ $0.allSatisfy({ $0 == 0 }) })
    }
    
    /// Determines whether the linear transformation is invertible.
    var isInvertible: Bool {
        return self.representation.isInvertible
    }
    
    /// An enum of either `x` or `y`
    enum Coordinate {
        /// The x-axis of the coordinate.
        case x
        
        /// The y-axis of the coordinate.
        case y
    }
    
    /// Initialize with the function of transformation.
    ///
    /// An example:
    ///
    ///     let vector: Vector = [1, 1, 1]
    ///     let transformation = LinearTransformation(representation: [[0, 1, -2], [3, 0, 1]])
    ///     print(transformation.transform(vector: vector))
    ///     // prints "[-1, 4]"
    ///
    /// An example of finding matrix representation:
    ///
    ///     T(x1, x2, x3) = (x2 - 2*x3, 3*x1 + x3)
    ///
    ///                       [x2 - 2*x3]   [0    1    -2] [x1]
    ///     [T(x1, x2, x3)] = [3*x1 + x3] = [3    0    1 ] [x2]
    ///                                                    [x3]
    ///     // Hence the matrix is [[0, 1, -2], [3, 0, 1]]
    ///
    /// - important: `init(function: ((Vector)->Vector))` can be used instead of this method.
    ///
    /// - Parameters:
    ///     - matrix: The matrix representation of the transformation.
    init(representation matrix: Matrix) {
        self.representation = matrix
    }
    
    /// Initialize with the function of transformation. The transformation maps element in `V` to `W`.
    ///
    /// An example:
    ///
    ///     let transformation = LinearTransformation { vector in
    ///         [vector[1] - 2*vector[2], 3*vector[0] + vector[2]]
    ///     }!
    ///     print(transformation)
    ///     // prints "LinearTransformation<representation: [[0, 1, -2], [3, 0, 1]]>"
    ///     // This initialize a linear transformation of T(x1, x2, x3) = (x2 - 2*x3, 3x1 + x3)
    ///
    /// Initialization may cause error, as the transformation may fail to preserve the vector space structure.
    ///
    /// - Parameters:
    ///     - function: `T: V-> W`
    ///     - v: The `n` of R^n, which the lhs vector space `V` represents.
    ///     - w: The `n` of R^n, which the lhs vector space `W` represents.
    init?(function: ((Vector)->Vector), lhsVectorSpace v: Int? = nil, rhsVectorSpace w: Int? = nil) {
        // check if preserves vector structure
        let vectorA = {()->Vector in
            if let n = v { return [Int](1...n).map({ Fraction($0) }) } else { return [Int](1...10).map({ Fraction($0) }) }
        }()
        let vectorB = {()->Vector in
            if let n = v { return [Int](0..<n).map({ Fraction($0) }) } else { return [Int](0..<10).map({ Fraction($0) }) }
        }()
        guard function(vectorA + vectorB) == function(vectorA) + function(vectorB) else { print("Failed to initialize transformation: it does not preserve vector space structure."); return nil }
        guard function(Fraction(numerator: 1, denominator: 3) * vectorA) == (Fraction(numerator: 1, denominator: 3) * function(vectorA)) else { print("Failed to initialize transformation: it does not preserve vector space structure."); return nil }
        
        // initialize
        var matrix: Matrix = []
        for i in 0..<10 { // Assuming the width of `V` is at most 10.
            var vector = Vector(empty: 10)
            vector[i] = 1
            let result = function(vector)
            guard !result.allSatisfy({ $0 == 0 }) else { break }
            matrix.append(result)
        }
        
        if v != nil {
            guard Int(matrix.size.height) == v else { print("The size of matrix does not match v (\(v!))"); return nil }
        }
        if w != nil {
            guard Int(matrix.size.width) == w else { print("The size of matrix does not match w (\(w!))"); return nil }
        }
        
        self.representation = matrix.transposed()
    }
    
    /// Initialize a geometric linear transformation, which takes (x, y) and reflect in the line y = ax from R^2 to R^2.
    ///
    /// An example:
    ///
    ///     let transformation = LinearTransformation(reflectionOn: Polynomial(coefficients: [5, 0]))
    ///     print(transformation)
    ///     // prints "LinearTransformation<representation: [[-12/13, 5/13], [5/13, 12/13]]>"
    ///     // initialize with the geometric transformation of flection in y = 5x, which is shown in the coefficient.
    ///
    /// - Parameters:
    ///     - line: The line to reflection in. It should be in the form of `[n, 0]`, where `n: y=n*x`. The second coefficient should be zero as it was expected to cross the origin.
    init(reflectionOn line: Polynomial) {
        guard line.degree == 1 else { fatalError("The degree of the line is not 1.") }
        let directionV: Vector = [1, line.coefficients.first!]
        
        let index1 = directionV[0] * directionV[0] * 2 / (pow(directionV.first!, 2) + pow(directionV.last!, 2)) - 1
        let index2 = directionV[1] * directionV[0] * 2 / (pow(directionV.first!, 2) + pow(directionV.last!, 2))
        let index3 = directionV[0] * directionV[1] * 2 / (pow(directionV.first!, 2) + pow(directionV.last!, 2))
        let index4 = directionV[1] * directionV[1] * 2 / (pow(directionV.first!, 2) + pow(directionV.last!, 2)) - 1
        
        self.init(representation: [[index1, index2], [index3, index4]])
    }
    
    /// Initialize a geometric linear transformation, which rotates anti-clockwise by theta around the origin from R^2 to R^2.
    ///
    /// An example:
    ///
    ///     let transformation = LinearTransformation(rotate: .pi / 2)
    ///     print(transformation)
    ///     // prints "LinearTransformation<representation: [[0, 0], [1, 0]]>"
    ///     // initialize with the geometric transformation of rotating anti-clockwise by pi / 2 (90 degrees)
    ///
    /// - Parameters:
    ///     - theta: The angle in radian to rotate, anti-clockwise.
    init(rotate theta: Double) {
        var matrix = [[cos(theta), -1*sin(theta)], [sin(theta), cos(theta)]]
        matrix = matrix.map({ $0.map({ if abs($0) < Double(pow(10, -10)) { return 0 } else { return $0 } }) })
        self.init(representation: matrix.map({$0.map({ Fraction($0) })}))
    }
    
    /// Initialize a geometric linear transformation, which shear a square of `(0, 0), (1, 0), (0, 1), (1, 1)` from R^2 to R^2.
    ///
    /// An example:
    ///
    ///     let transformation = LinearTransformation(shear: .x, by: 2)
    ///     print(transformation)
    ///     // prints "LinearTransformation<representation: [[1, 2], [0, 1]]>"
    ///     // initialize with the geometric transformation of shear by a factor of c along the x-axis
    ///
    /// - Parameters:
    ///     - coordinate: The coordinate to shear. Either `x` or `y`.
    ///     - c: The value to shear.
    init(shear coordinate: Coordinate, by c: Fraction) {
        switch coordinate {
        case .x:
            self.init(representation: [[1, c], [0, 1]])
        case.y:
            self.init(representation: [[0, 1], [1, c]])
        }
    }
    
    /// Transform a vector in a vector space V to vector space W.
    ///
    /// An example:
    ///
    ///     let transformation = LinearTransformation { vector in
    ///         vector.crossProduct(rhs: [1, 1, -1])
    ///     }
    ///     print(transformation.transform(vector: [1, 2, 3]))
    ///     // prints "[-5, 4, -1]"
    ///
    /// It performs
    ///
    ///     T: V -> W
    ///
    /// - Parameters:
    ///     - vector: The vector in vector space V.
    ///
    /// - Returns: A vector in vector space W.
    func transform(vector: Vector) -> Vector {
        return T(vector)
    }
    
    /// Combine the current linear transformation with another.
    ///
    /// - Parameters:
    ///     - rhs: Another a linear transformation.
    func combination(with rhs: LinearTransformation) -> LinearTransformation {
        return LinearTransformation(representation: rhs.representation * self.representation)
    }
    
    /// Finds the transition matrix.
    ///
    /// Example
    ///
    ///     LinearTransformation.findTransitionMatrix(from: [[1, 1], [1, -1]], to: [[1, 0], [0, 1]]).presentMatrix()
    ///     // prints "1    1
    ///     //         1    -1 "
    ///
    /// - Precondition: Both the `lhs` and `rhs` needs to be the basis.
    ///
    /// - Parameters:
    ///     - rhs: The second basis.
    ///     - lhs: The first basis.
    ///
    /// - Returns: The transition matrix.
    static func findTransitionMatrix(from lhs: Matrix, to rhs: Matrix) -> Matrix {
        guard lhs.rank == rhs.rank else { fatalError("At least one of `lhs` or `rhs` is not the basis.") }
        var matrix = Matrix()
        for i in lhs {
            matrix.append(i.findCoordinates(base: rhs).transposed().first!)
        }
        return matrix.transposed()
    }
}
