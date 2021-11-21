//
//  Matrix.swift
//
//
//  Created by Vaida on 9/3/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation

typealias Vector = [Fraction]

extension Vector {
    
    /// Find the ||u|| of a vector.
    ///
    /// An example:
    ///
    ///     let vector = Vector([3, 4])
    ///     print(vector.length)
    ///     // prints "5"
    ///
    /// - Returns: The ||u||.
    var length: Fraction {
        var content = Fraction(0)
        for i in self {
            content += pow(i, 2)
        }
        return sqrt(content)
    }
    
    /// Find the unit vector behind a vector.
    ///
    /// An example:
    ///
    ///     let vector = Vector([3, 4])
    ///     print(vector.unitVector())
    ///     // prints "[3/5, 4/5]"
    ///
    /// - Returns: The unit vector behind a vector.
    var unitVector: Vector {
        return self.map({ $0 / self.length })
    }
    
    /// The latex expression.
    var latexExpression: String {
        var content = "\\begin{bmatrix} "
        for i in self {
            content += i.latexExpression
            content += " & "
        }
        content.removeLast(3)
        content += " \\end{bmatrix}"
        return content
    }
    
    /// Create an empty vector of the length.
    ///
    /// An example:
    ///
    ///     let vector = Vector(empty: 3)
    ///     print(vector)
    ///     // prints "[0, 0, 0]"
    init(empty length: Int) {
        self = [Fraction](repeating: 0, count: length)
    }
    
    /// Initialize with an array of float
    init<T>(with content: [T]) where T: BinaryFloatingPoint, T: LosslessStringConvertible {
        self = content.map({Fraction($0)})
    }
    
    /// Adds each entry of two vectors and produces their sum.
    ///
    /// The addition operator (`+`) calculates the sum of its two arguments.
    ///
    /// An example:
    ///
    ///     let vectorA: Vector = [1, 2, 3]
    ///     let vectorB: Vector = [4, 5, 6]
    ///     print(vectorA + vectorB)
    ///     // prints "[5, 7, 9]"
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    static func + (lhs: Vector, rhs: Vector) -> Vector {
        guard lhs.count == rhs.count else { fatalError("failed to add vector \(lhs) and \(rhs): different vector length") }
        var content = lhs
        for i in 0..<content.count {
            content[i] = lhs[i] + rhs[i]
        }
        return content
    }
    
    /// Subtracts one value from another and produces their difference.
    ///
    /// The subtraction operator (`-`) calculates the difference of its two arguments.
    ///
    /// An example:
    ///
    ///     let vectorA: Vector = [1, 2, 3]
    ///     let vectorB: Vector = [4, 5, 6]
    ///     print(vectorA - vectorB)
    ///     // prints "[-3, -3, -3]"
    ///
    /// - Parameters:
    ///   - lhs: A numeric value.
    ///   - rhs: The value to subtract from `lhs`.
    static func - (lhs: Vector, rhs: Vector) -> Vector {
        guard lhs.count == rhs.count else { fatalError("failed to find difference between vector \(lhs) and \(rhs): different vector length") }
        var content = lhs
        for i in 0..<content.count {
            content[i] = lhs[i] - rhs[i]
        }
        return content
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// It returns the sum of the product of each two elements of two vectors in the same position.
    ///
    /// An example:
    ///
    ///     let vectorA: Vector = [1, 2, 3]
    ///     let vectorB: Vector = [4, 5, 6]
    ///     print(vectorA * vectorB)
    ///     // prints "32"
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: Vector, rhs: Vector) -> Fraction {
        guard lhs.count == rhs.count else { fatalError("failed to multiply vector \(lhs) and \(rhs): different vector length") }
        var content = Fraction(0)
        for i in 0..<lhs.count {
            content += lhs[i] * rhs[i]
        }
        return content
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// An example:
    ///
    ///     let vector: Vector = [1, 2, 3]
    ///     print(2 * vector)
    ///     // prints "[2, 4, 6]"
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: Fraction, rhs: Vector) -> Vector {
        return rhs.map({ $0 * lhs })
    }
    
    /// Find the angle of the current vector with another vector.
    ///
    /// An example:
    ///
    ///     let vector = Vector([3, 4])
    ///     print(vector.angle(with: Vector([8, 6])))
    ///     // prints "0.283794109208328"
    ///
    /// - Parameters:
    ///    - rhs: Another vector
    ///
    /// - Returns: The angle of the current vector with another vector, in `Radians`.
    func angle(with rhs: Vector) -> Double {
        let cos = (self * rhs) / (self.length * rhs.length)
        return acos(Double(cos))
    }
    
    /// Determine whether the two vectors are perpendicular.
    ///
    /// - Parameters:
    ///     - rhs: A second vector
    ///
    /// - Returns: A bool indicating whether the two lines are perpendicular
    func isPerpendicular(to rhs: Vector) -> Bool {
        return self * rhs == 0
    }
    
    /// Find the distance between two vectors with sqrt.
    ///
    /// - Parameters:
    ///     - rhs: A second vector
    ///
    /// - Returns: The distance.
    func distance(to rhs: Vector) -> Double {
        guard self.count == rhs.count else { fatalError("\(self).distance(to: \(rhs): the sizes of two vectors are not the same.") }
        var content: Double = 0.0
        for i in 0..<self.count {
            content += pow((Double(self[i]) - Double(rhs[i])), 2.0)
        }
        return pow(content, 0.5)
    }
    
    /// Sometimes, you may encounter the most unpleasant fractions within the Vector. Use this method to simplify the results.
    ///
    /// An example:
    ///
    ///     let vector: Vector = [169/20, -169/70, -169/14]
    ///     print(vector.simplified())
    ///     // prints "[7, -2, -10]"
    func simplified() -> Vector {
        var multiplier: Fraction.Integer = 1
        var content = self
        for i in self {
            multiplier *= i.denominator
        }
        
        content = content.map({ $0 * Fraction(multiplier) })
        var factors: Set<Fraction.Integer> = Set(content.first!.numerator.factors)
        for i in content {
            factors.formIntersection(Set(i.numerator.factors))
        }
        var dividend = factors.sorted(by: {abs($0)<abs($1)}).last ?? 1
        if self.allSatisfy({ $0 < 0 }) { dividend *= -1 }
        return content.map({ $0 / Fraction(dividend) })
    }
    
    /// Find the transpose of a matrix.
    ///
    /// **Example**
    ///
    ///     let vector: Vector = [1, 2, 3]
    ///     print(vector.transposed())
    ///     /*
    ///                     [1]
    ///     [1, 2, 3]   ->  [2]
    ///                     [3]
    ///     */
    ///
    /// - Returns: The transpose of a matrix.
    func transposed() -> Matrix {
        let matrix = self
        var newMatrix: [[Fraction]] = [[Fraction]](repeating: [Fraction](repeating: 0, count: 1), count: matrix.count)
        for i in 0..<matrix.count {
            newMatrix[i][0] = matrix[i]
        }
        return newMatrix
    }
    
    /// Find the projection of current vector in the axis of u.
    ///
    /// An example:
    ///
    ///     let vector = Vector([1, 0, -1])
    ///     print(vector.projection(to: Vector([2, 4, 4])))
    ///     // prints "(parallel: [-1/9, -2/9, -2/9], vertical: [10/9, 2/9, -7/9])"
    ///
    ///- Parameters:
    ///   - u: Another vector
    ///
    /// - Returns: (parallel vector, vertical vector)
    func projection(to u: Vector) -> (parallel: Vector, vertical: Vector) {
        let v = self
        let upper = {()-> Fraction in
            var content = Fraction(0)
            for i in 0 ..< u.count {
                content += u[i]*v[i]
            }
            return content
        }()
        let lower = {()-> Fraction in
            var content = Fraction(0)
            for i in 0 ..< u.count {
                content += u[i]*u[i]
            }
            return content
        }()
        
        let k = upper / lower
        var parallelVector = Vector()
        var verticalVector = Vector(empty: v.count)
        
        for i in u {
            parallelVector.append(k*(i))
        }
        
        for i in 0..<u.count {
            verticalVector[i] = v[i] - k*u[i]
        }
        
        return (parallelVector, verticalVector)
    }
    
    /// Find the area of a parallelogram sided current vector and rhs vector.
    ///
    /// An example:
    ///
    ///     let vector = Vector([3, 4])
    ///     print(vector.parallelogramArea(with: Vector([8, 6])))
    ///     // prints "14"
    ///
    ///- Parameters:
    ///   - vector: Another side of parallelogram.
    ///
    /// - Returns: The area of the parallelogram.
    func parallelogramArea(with vector: Vector) -> Fraction {
        return self.crossProduct(rhs: vector).length
    }
    
    /// Find the volume of a parallelogram sided lhs vector and rhs vector with current vector in height.
    ///
    /// An example:
    ///
    ///     let vector = Vector([1, 4, 2])
    ///     print(vector.parallelogramVolume(baseA: [3, 4, 4], baseB: [4, 5, 1]))
    ///     // prints "34"
    ///
    ///- Parameters:
    ///   - baseA: A base vector
    ///   - baseB: A base vector
    ///
    /// - Returns: The volume of the parallelogram.
    func parallelogramVolume(baseA: Vector, baseB: Vector) -> Fraction {
        return abs((self * baseA.crossProduct(rhs: baseB)))
    }
    
    /// Find the vector cross product (aka, x).
    ///
    /// An example:
    ///
    ///     let vectorA = Vector([1, 2, 3])
    ///     let vectorB = Vector([4, 5, 6])
    ///     print(vectorA.crossProduct(rhs: vectorB))
    ///     // prints "[-3, 6, -3]"
    ///
    /// - Parameters:
    ///   - rhs: The rhs vector
    ///
    /// - Returns: The vector of answers.
    func crossProduct(rhs: Vector) -> Vector {
        let lhs = self
        var content: [Fraction] = []
        guard lhs.count != 2 else { return Vector([Matrix([lhs, rhs]).determinant]) }
        for i in 0..<lhs.count {
            content.append(Matrix([[Fraction](repeating: Fraction(0.0), count: lhs.count), lhs, rhs]).cofactor(at: (1, i+1)))
        }
        return Vector(content)
    }
    
    /// Determine whether the vector is a combination of the components array of vectors.
    ///
    /// An example:
    ///
    ///     let matrix = Matrix([[1, 3, 1, 2], [-2, -10, -1, 2]])
    ///     let vector = Vector([3, 13, 2, 0])
    ///     print(vector.findLinearCombination(of: matrix))
    ///     // prints "Optional([1, -1])"
    ///
    /// - Parameters:
    ///   - matrix: The components vectors
    ///
    /// - Returns: The array of alphas if the vector is a combination of the array of vectors `nil` if can not find alphas.
    func findLinearCombination(of matrix: Matrix) -> [Fraction]? {
        var components = matrix
        guard components.allSatisfy({ $0.count == self.count }) else { print("\(self) is not a combination of \(matrix): \(components) and \(self) have different item count"); return nil }
        components.append(self)
        components = Matrix(components).transposed()
        guard components.rank < components.first!.count else { print("\(self) is not a combination of \(matrix): \(components).rank == number of columns in \(components)"); return nil }
        
        if let answer = Matrix(components).solved() {
            return [Fraction](answer[0..<matrix.rank])
        } else {
            return nil
        }
    }
    
    /// Determine whether the vector is a combination of the components array of vectors.
    ///
    /// An example:
    ///
    ///     let matrix = Matrix([[1, 3, 1, 2], [-2, -10, -1, 2]])
    ///     let vector = Vector([3, 13, 2, 0])
    ///     print(vector.isLinearCombination(of: matrix))
    ///     // prints "true"
    ///
    /// - Parameters:
    ///   - matrix: The components vectors.
    func isLinearCombination(of matrix: Matrix) -> Bool {
        return self.findLinearCombination(of: matrix) != nil
    }
    
    /// Find the coordinate of the vector with respect to a base.
    ///
    /// An example:
    ///
    ///     let vector: Vector = [1, 5]
    ///     print(vector.findCoordinates(base: [[2, 1], [-1, 1]]))
    ///      // prints "[[2], [3]]"
    ///
    /// - Returns: The array of alphas.
    func findCoordinates(base: [Vector]) -> Matrix {
        var matrix = base
        matrix.append(self)
        return Matrix([matrix.transposed().solved()!]).transposed()
    }
    
    /// Transform the current vector by a linear transformation.
    ///
    /// An example:
    ///
    ///     let vector: Vector = [1, 2, 3]
    ///     let transformation = LinearTransformation { vector in
    ///         vector.crossProduct(rhs: [1, 1, -1])
    ///     }
    ///     print(vector.transformed(by: transformation))
    ///     // prints "[-5, 4, -1]"
    ///
    /// - Parameters:
    ///     - transformation: The transformation to be performed onto the vector.
    /// - Returns: The vector after transformation.
    func transformed(by transformation: LinearTransformation) -> Vector {
        return transformation.transform(vector: self)
    }
}

//MARK: - Matrix
typealias Matrix = [[Fraction]]

extension Matrix {
    
    
    //MARK: - Instance Properties
    
    /// The characteristic polynomial
    ///
    /// - Invariant: characteristic polynomial: det(A - lambda \* I)
    var characteristicPolynomial: Polynomial? {
        precondition(self.size.width <= 3, "\(self).characteristicPolynomial: sorry, not support calculating characteristic polynomial for more than degree 3.")
        guard self.isSquareMatrix else { return nil }
        switch self.size.width {
        case 2:
            let a = self[0][0]
            let b = self[0][1]
            let c = self[1][0]
            let d = self[1][1]
            return Polynomial(coefficients: [1, 0 - a - d, -1 * b * c + a * d])
            
        case 3:
            // -c e g + b f g + c d h - a f h - b d i + a e i + b d lambda - a e lambda + c g lambda + f h lambda - a i lambda - e i lambda + a lambda^2 + e lambda^2 + i lambda^2 - lambda^3
            let a = self[0][0]
            let b = self[0][1]
            let c = self[0][2]
            let d = self[1][0]
            let e = self[1][1]
            let f = self[1][2]
            let g = self[2][0]
            let h = self[2][1]
            let i = self[2][2]
            
            return Polynomial(coefficients: [-1, a + e + i, b*d - a*e + c*g + f*h - a*i - e*i, -1 * c*e*g + b*f*g + c*d*h - a*f*h - b*d*i + a*e*i])
            
        default:
            return nil
        }
    }
    
    /// Diagonalize the current instance.
    ///
    /// - Invariant: `self == D * P * D^{-1}`
    var diagonalize: (P: Matrix, D: Matrix, PInverse: Matrix)? {
        guard self.isDiagonalizable else { return nil }
        var P: Matrix = []
        var DVector: Vector = []
        
        guard let eigenvectors = self.eigenvectors else { return nil }
        for i in eigenvectors {
            P.append(i.eigenvector)
            DVector.append(i.eigenvalue)
        }
        
        P = P.transposed()
        let D = Matrix(diagonal: DVector)
        precondition(self == P * D * P.inverse!)
        return (P, D, P.inverse!)
    }

    /// The eigenvalues of this (square) matrix.
    ///
    /// - Invariant: The eigenvalue, lambda, satisfies T(v) = lambda v, where T: V -> V, a linear transformation.
    ///
    /// - Important: Accuracy may be lost.
    var eigenvalues: [Fraction]? {
        guard self.isSquareMatrix else { return nil }
        precondition(self.size.width <= 3, "\(self).eigenvalues: sorry, not support calculating eigenvalues for more than degree 3.")
        
        if self.size.width == 2 {
            let trace = self.trace!
            let delta = trace.square() - 4 * self.determinant
            guard delta >= 0 else { return nil }
            return [(trace + delta.squareRoot()) / 2, (trace - delta.squareRoot()) / 2]
        } else if self.size.width == 3 {
            let polynomial = self.characteristicPolynomial!
            return polynomial.roots
        }
        
        return nil
    }
    
    /// The eigenvectors of this (square) matrix.
    ///
    /// - Invariant: The eigenvectors, v, satisfies T(v) = lambda v, where T: V -> V, a linear transformation.
    ///
    /// - Important: Accuracy may be lost, due to `eigenvalues`.
    var eigenvectors: [(eigenvalue: Fraction, eigenvector: Vector)]? {
        guard let eigenvalues = eigenvalues else { return nil }
        var content: [(eigenvalue: Fraction, eigenvector: Vector)] = []
        
        for i in eigenvalues {
            let A = self - i * Matrix(identity: self.size.width)
            var B = A
            for ii in 0..<B.count { B[ii].append(0) }
            
            let solutionSpace = A.solutionSpace
            for ii in solutionSpace {
                content.append((eigenvalue: i, eigenvector: ii))
            }
        }
        
        return content.isEmpty ? nil : content.removingRepeatedElements(by: { $0.eigenvector == $1.eigenvector && $0.eigenvalue == $1.eigenvalue })
    }
    
    /// The size of the matrix.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 2, 3], [4, 5, 6]]
    ///     print(matrix.size)
    ///     // prints "(3.0, 2.0)"
    var size: Size {
        guard !self.isEmpty else { return Size.zero }
        return Size(width: self.first!.count, height: self.count)
    }
    
    /// Determine whether the matrix is a square matrix.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    ///     print(matrix.isSquareMatrix)
    ///     // prints "true"
    ///
    /// Square matrix: The number of rows in the matrix is equal to the number of columns.
    var isSquareMatrix: Bool {
        guard !self.isEmpty else { return false }
        return self.size.width == self.size.height
    }
    
    /// Determine whether the matrix is a row matrix.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 2, 3]]
    ///     print(matrix.isRowMatrix)
    ///     // prints "true"
    ///
    /// Row matrix: The number of rows of the matrix is 1.
    var isRowMatrix: Bool {
        return self.size.height == 1
    }
    
    /// Determine whether the matrix is a column matrix.s
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 2, 3]]
    ///     print(matrix.isRowMatrix)
    ///     // prints "true"
    ///
    /// Column matrix: The number of columns of the matrix is 1.
    var isColumnMatrix: Bool {
        return self.size.width == 1
    }
    
    /// Determine whether the matrix is diagonalizable.
    ///
    /// - Invariant: A n x n matrix is diagonalizable if it has n eigenvalues, hence n eigenvectors.
    var isDiagonalizable: Bool {
        guard self.isSquareMatrix else { return false }
        guard let value = self.eigenvalues else { return false }
        return value.count == self.size.width
    }
    
    /// Determine whether the matrix is a diagonal matrix.
    var isDiagonalMatrix: Bool {
        guard self.isSquareMatrix else { return false }
        for i in 0..<self.count {
            for ii in 0..<self[i].count {
                if i == ii { continue }
                if self[i][ii] != 0 { return false }
            }
        }
        return true
    }
    
    /// Determine whether the instance is an orthogonal matrix.
    ///
    /// - Invariant: An orthogonal matrix Q is a real n x n matrix such that Q^{-1} = Q^T.
    var isOrthogonal: Bool {
        guard self.isSquareMatrix else { return false }
        return (self.transposed() * self).isIdentityMatrix
    }
    
    /// Determine whether the matrix is a zero matrix.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[0, 0, 0], [0, 0, 0]]
    ///     print(matrix.isZeroMatrix)
    ///     // prints "true"
    ///
    /// Zero matrix: The entries of the matrix consist only of zeros.
    var isZeroMatrix: Bool {
        return self.allSatisfy({ $0.allSatisfy({ $0 == 0 }) })
    }
    
    /// Determine whether the matrix is an identity matrix.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 0], [0, 1]]
    ///     print(matrix.isIdentityMatrix)
    ///     // prints "true"
    ///
    /// Identity matrix: The diagonal entries are ones, the others are zeros.
    var isIdentityMatrix: Bool {
        guard self.isSquareMatrix else { return false }
        for i in 0..<Int(self.size.height) {
            for ii in 0..<Int(self.size.width) {
                if i == ii {
                    if self[i][ii] != 1 {
                        return false
                    }
                } else {
                    if self[i][ii] != 0 {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    /// Determine whether the matrix is an elementary matrix.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[0, 1], [1, 0]]
    ///     print(matrix.isElementaryMatrix)
    ///     // prints "true"
    ///
    /// Elementary matrix: A matrix that can be obtained by a single row operation to the identity matrix.
    var isElementaryMatrix: Bool {
        guard self.isSquareMatrix else { return false }
        if self.sorted().isIdentityMatrix { return true }
        
        var operationCounter = 0
        var matrix = self
        var leadingTermList = [Bool](repeating: false, count: matrix.first!.count)
        
        for i in 0..<Int(matrix.size.height) {
            guard let leadingTermIndex = getLeadingTermIndex(row: matrix[i]) else { continue }
            leadingTermList[leadingTermIndex].toggle()
            let leadingTerm = matrix[i][leadingTermIndex]
            
            if leadingTerm != Fraction(1) { matrix[i] = matrix[i].map{$0 / leadingTerm}; operationCounter += 1 }
            
            //change remaining rows
            for ii in 0..<Int(matrix.size.height) {
                guard ii != i else { continue }
                guard matrix[ii][leadingTermIndex] != Fraction(0) else { continue }
                
                let multiplier = matrix[ii][leadingTermIndex]
                
                for iii in 0..<Int(matrix.size.width) {
                    matrix[ii][iii] = matrix[ii][iii] - multiplier * matrix[i][iii]
                }
                operationCounter += 1
            }
        }
        
        func getLeadingTermIndex(row: [Fraction]) -> Int? {
            var index = 0
            while leadingTermList[index] == true || row[index] == 0 {
                index += 1
                guard index < leadingTermList.count else { return nil }
            }
            return index
        }
        
        if operationCounter <= 1 && matrix.isIdentityMatrix {
            return true
        }
        
        return false
    }
    
    /// Determines whether the matrix is invertible.
    var isInvertible: Bool {
        guard self.isSquareMatrix else { return false }
        guard self.determinant != 0  else { return false }
        return true
    }
    
    /// Determines whether a matrix is a symmetric matrix.
    ///
    /// - Invariant: for a symmetric matrix, A^T = A
    var isSymmetricMatrix: Bool {
        guard self.isSquareMatrix else { return false }
        for i in 0..<(self.size.width-1) {
            for ii in (i+1)..<self.size.width {
                guard self[i][ii] == self[ii][i] else { return false }
            }
        }
        return true
    }
    
    /// The array of indexes leading entries in each row. Index start form `0`.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 0, 0], [0, 1, 0], [0, 0, 0]]
    ///     print(matrix.leadingEntries)
    ///     // prints "[Optional(0), Optional(1), nil]"
    ///
    /// The leading entry of a row in a matrix is the first nonzero entry in that row.
    ///
    /// If a row does not have a leading entry, the value is `nil`.
    ///
    /// The indexes are in Swift's index, ie, start with 0.
    var leadingEntries: [Int?] {
        guard !self.isEmpty else { return [nil] }
        let matrix = self.reduced()
        var entries = [Int?](repeating: nil, count: Int(self.size.height))
        for i in 0..<Int(self.size.height) {
            for ii in 0..<Int(self.size.width) {
                if matrix[i][ii] != 0 {
                    entries[i] = ii
                    break
                }
            }
        }
        
        return entries
    }
    
    /// The array of free variables entries. ie, the columns without a leading entry
    ///
    /// **example**
    ///
    ///     let matrix: Matrix = [[1, 0, 0], [0, 1, 0], [0, 0, 0]]
    ///     print(matrix.freeVariables)
    ///     // prints "[2]"
    ///
    /// - Invariant: Free variables: The rows without a leading entry.
    ///
    /// - Note: The indexes are in Swift's index, ie, start with 0
    var freeVariables: [Int] {
        var indexes = [Int](0..<self.size.width)
        for i in self.leadingEntries {
            guard let i = i else { continue }
            indexes.remove(at: indexes.firstIndex(of: i)!)
        }
        return indexes
    }
    
    /// get the rank of a matrix
    ///
    /// **Example**
    ///
    ///     let matrix = Matrix([[0, 0, 1, 1], [0, 1, 1, 0], [1, 1, 1, 0]])
    ///     print(matrix.rank)
    ///     // prints "3"
    ///
    /// Rank: The number of non-zero rows in the reduced row-echelon form.
    var rank: Int {
        let reducedMatrix = self.reduced()
        return reducedMatrix.filter({!$0.allSatisfy({$0 == 0})}).count
    }
    
    /// get the determinant of a matrix
    ///
    /// **Example**
    ///
    ///     let matrix = Matrix([[0, 0, 1, 1], [0, 1, 1, 0], [1, 1, 1, 0]])
    ///     print(matrix.determinant)
    ///     // prints "-1"
    ///
    /// The determinant is a function that maps each  matrix  to a number, denoted det(A) or |A| , that satisfies:
    /// - Adding one row to another does not change determinant
    /// - Multiplying any row by a scalar  multiplies the determinant by
    /// - The determinant of the identity matrix  is 1
    var determinant: Fraction {
        let matrix = self
        guard matrix.count != 1 else {
            return matrix.first!.first!
        }
        
        guard matrix.count != 2 else {
            return matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0]
        }
        
        //By default, calculate by the row with most 0
        let row = {()-> Int in
            var zeroCounter: [Int] = []
            let _ = matrix.map{zeroCounter.append($0.filter {$0 == Fraction(0.0)}.count)}
            return zeroCounter.firstIndex(of: zeroCounter.max()!)! + 1
        }()
        
        var determinant = Fraction(0)
        
        for k in 1...matrix.count {
            let lhs = Matrix(matrix).item(at: (i: row, j: k))
            let rhs = Matrix(matrix).cofactor(at: (i: row, j: k))
            let delta = lhs * rhs
            determinant += delta
        }
        
        return determinant
    }
    
    /// Find the trace of a matrix.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    ///     print(matrix.trace ?? "")
    ///     // prints "15"
    ///
    /// Trace: The sum of the diagonal entries.
    var trace: Fraction? {
        guard self.isSquareMatrix else { print("failed to find trace for \(self): it is not a square matrix"); return nil }
        var content = Fraction(0)
        for i in 0..<self.count { content += self[i][i] }
        return content
    }
    
    /// Check whether the vectors in array span R^n.
    ///
    /// **Example**
    ///
    ///     let matrix = Matrix([[2, -1, 1], [4, 0, 2]])
    ///     print(matrix.canSpanRn)
    ///     // prints "2"
    ///
    /// - Returns: the n of R^n
    var canSpanRn: Int {
        var matrix = self.transposed()
        for i in 0..<matrix.count {
            matrix[i].append(0)
        }
        return Matrix(matrix).reduced().rank
    }
    
    /// Find the dimension of a matrix.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    ///     print(matrix.dimension)
    ///     // prints "2"
    ///
    /// The dimension of a vector space `V` is the number of vectors in the basis for V.
    ///
    /// The dimension could be infinity. However, the variable ignores that.
    var dimension: Int {
        return self.findBasis().count
    }
    
    /// Find the inverse of a matrix.
    ///
    /// **Example**
    ///
    ///     let a: Matrix = [[2, -1, 6], [-1, 2, 8], [-1, 2, 9]]
    ///     print(a.inverse)
    ///     /*
    ///      1    2          -2     1
    ///      3    4     ->   3/2    -1/2
    ///      */
    ///
    /// - Returns: The inverse of a matrix, if possible.
    var inverse: Matrix? {
        guard self.isSquareMatrix else { print("failed to find inverse of \(self): it is not a square matrix"); return nil }
        guard self.determinant != 0  else { print("failed to find inverse of \(self): determinant equal to 0"); return nil }
        var content = self
        for i in 0..<content.count {
            for ii in 0..<content.count {
                if i == ii {
                    content[i].append(1)
                } else {
                    content[i].append(0)
                }
            }
        }
        content = content.reduced()
        
        var lhsResult = Matrix(empty: Size(width: self.count, height: self.count))
        var rhsResult = Matrix(empty: Size(width: self.count, height: self.count))
        
        for i in 0..<content.count {
            for ii in 0..<content.first!.count {
                if ii < self.count {
                    lhsResult[i][ii] = content[i][ii]
                } else {
                    rhsResult[i][ii - self.count] = content[i][ii]
                }
            }
        }
        
        if lhsResult.isIdentityMatrix {
            return rhsResult
        } else {
            print("failed to find inverse of \(self): the reduced lhs \(content) does not contain a identity matrix")
            return nil
        }
    }
    
    /// Find the nullity of a matrix.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    ///     print(matrix.nullity)
    ///     // prints "2"
    ///
    /// - Invariant: Nullity: The number of basis in solution space.
    var nullity: Int  {
        return self.columnSpace.count
    }
    
    /// The latex expression.
    var latexExpression: String {
        var content = "\\begin{bmatrix}\n"
        for i in self {
            for ii in i {
                content += ii.latexExpression
                content += " & "
            }
            content.removeLast(3)
            content += "\\\\"
            content += "\n"
        }
        content += "\\end{bmatrix}"
        return content
    }
    
    /// The singular value is the square roots of eigenvalues of `self*self^T`
    var singularValues: Vector {
        return (self * self.transposed()).eigenvalues!.map({ sqrt($0) })
    }
    
    /// `self = Q1 * D * Q2^T`
    ///
    /// Q1: m x m orthogonal matrix
    /// Q2: n x n orthogonal matrix
    /// D : m x n matrix, `D_ii >= 0,  D_ij = 0, when i ≠ j`
    var singularValueDecomposition: (Q1: Matrix, D: Matrix, Q2: Matrix) {
        let Q1 = (self * self.transposed()).eigenvectors!.map{ $0.eigenvector.unitVector }.transposed()
        let Q2 = (self.transposed() * self).eigenvectors!.map{ $0.eigenvector.unitVector }.transposed()
        var D = Matrix(zeroes: self.size)
        var counter = 0
        let singularValues = self.singularValues
        for i in 0..<self.size.height {
            for ii in 0..<self.size.width {
                if i == ii {
                    D[i][ii] = singularValues[counter]
                    counter += 1
                }
            }
        }
        return (Q1, D, Q2)
    }
    
    /// Find the basis for the solution space of current matrix.
    ///
    /// **Example**
    ///
    ///      let matrix: Matrix = [[1, 2, 1, 1], [3, 6, 4, 1]]
    ///      print(matrix.solutionSpace)
    ///      // prints "[[-2, 1, 0, 0], [-3, 0, 2, 1]]"
    ///
    /// - Returns: the matrix containing the basis for solution space
    var solutionSpace: Matrix {
        var matrix = self.reduced().map({ $0.map({ -1 * $0 }) })
        for i in self.reduced().freeVariables {
            var vector = [Fraction](repeating: 0, count: matrix.first!.count)
            vector[i] = 1
            matrix.append(vector)
        }
        matrix = matrix.sorted().transposed()
        var content = Matrix()
        for i in self.reduced().freeVariables { content.append(matrix[i]) }
        return content.map({ [Fraction]($0[0..<self.first!.count]) })
    }
    
    /// Find the basis for the column space of current matrix.
    ///
    /// **Example**
    ///
    ///      let matrix: Matrix = [[1, -1, 2, -2], [2, 0, 1, 0], [5, -3, 7, -6], [1, 1, -1, 3]]
    ///      print(matrix.solutionSpace)
    ///      // prints "[[1, 2, 5, 1], [-1, 0, -3, 1], [-2, 0, -6, 3]]"
    ///
    /// - Returns: the matrix containing the basis for column space
    var columnSpace: Matrix {
        var content = Matrix()
        for i in self.reduced().leadingEntries {
            guard let i = i else { continue }
            content.append(self.transposed()[i])
        }
        return content
    }
    
    /// Find the basis for the row space of current matrix.
    ///
    /// **Example**
    ///
    ///      let matrix: Matrix = [[1, -1, 2, -2], [2, 0, 1, 0], [5, -3, 7, -6], [1, 1, -1, 3]]
    ///      print(matrix.solutionSpace)
    ///      // prints "[[1, -1, 2, -2], [2, 0, 1, 0], [1, 1, -1, 3]]"
    ///
    /// - Returns: the matrix containing the basis for row space
    var rowSpace: Matrix {
        var content = Matrix()
        for i in self.reduced().leadingEntries {
            guard let i = i else { continue }
            content.append(self[i])
        }
        return content
    }
    
    /// Determine whether the vectors in array is dependent
    ///
    /// self: The unprocessed matrix. The rows of the matrix are vectors. (Instead of column, which is written in the form to calculate by hand.)
    var isLinearDependent: Bool {
        return self.findLinearDependency() != nil
    }
    
    /// An enumeration of finding basis for span of set in vectors in R^n.
    ///
    ///
    /// The cases of this enumeration:
    ///
    ///     case column, row
    ///
    enum FindBasisMethod {
        case column, row
    }
    
    
    //MARK: - Initialers
    
    /// Initialize with `[[Fraction]]`.
    init(_ content: [[Fraction]]) {
        guard !content.isEmpty else { self = []; return }
        guard content.allSatisfy({ $0.count == content.first!.count }) else { fatalError("fail to initialize matrix with \(content): it is not a matrix") }
        self = content
    }
    
    /// Initialize with `[[Int]]`.
    init(_ content: [[Int]]) {
        guard !content.isEmpty else { self = []; return }
        guard content.allSatisfy({ $0.count == content.first!.count }) else { fatalError("fail to initialize matrix with \(content): it is not a matrix") }
        self = content.map({ $0.map({ Fraction($0) }) })
    }
    
    /// Initialize with `[[Double]]`.
    ///
    /// As this involves changing floating point into fraction, it may results in `nil`.
    init?<T>(with content: [[T]]) where T: BinaryFloatingPoint, T: LosslessStringConvertible {
        guard !content.isEmpty else { self = []; return }
        guard content.allSatisfy({ $0.count == content.first!.count }) else { fatalError("fail to initialize matrix with \(content): it is not a matrix") }
        self = content.map({$0.map({Fraction($0)})})
    }
    
    /// Initialize a matrix of specific size of entries zero.
    ///
    /// **Example**
    ///
    ///     let matrix = Matrix(empty: CGSize(width: 2, height: 3))
    ///     matrix.presentMatrix()
    ///     /* prints """
    ///               0    0
    ///               0    0
    ///               0    0
    ///               """
    ///     */
    init(empty size: Size) {
        self = Matrix(repeating: Vector(repeating: 0, count: size.width), count: size.height)
    }
    
    /// Initialize an identity matrix.
    ///
    /// **Example**
    ///
    ///     let matrix = Matrix(identity: 3)
    ///     matrix.presentMatrix()
    ///     /* prints """
    ///               1    0    0
    ///               0    1    0
    ///               0    0    1
    ///               """
    ///     */
    init(identity n : Int) {
        var content = Matrix(empty: Size(width: n, height: n))
        for i in 0..<n {
            for ii in 0..<n {
                if i == ii {
                    content[i][ii] = 1
                } else {
                    content[i][ii] = 0
                }
            }
        }
        self = content
    }
    
    /// Initialize an identity matrix.
    ///
    /// **Example**
    ///
    ///     let matrix = Matrix(identity: 3)
    ///     matrix.presentMatrix()
    ///     /* prints """
    ///               1    0    0
    ///               0    1    0
    ///               0    0    1
    ///               """
    ///     */
    init(diagonal: Vector) {
        var content = Matrix(empty: Size(width: diagonal.count, height: diagonal.count))
        for i in 0..<content.size.width {
            for ii in 0..<content.size.height {
                if i == ii {
                    content[i][ii] = diagonal[i]
                } else {
                    content[i][ii] = 0
                }
            }
        }
        self = content
    }
    
    /// Initialize with a matrix full of zeros.
    init(zeroes size: Size) {
        self = Matrix(repeating: Vector(repeating: 0, count: size.width), count: size.height)
    }
    
    
    //MARK: - Instance Methods
    
    /// The algebraic multiplicity of an eigenvalue.
    ///
    /// - Invariant: algebraic multiplicity: The multiplicity of lambda as a root of the characteristic polynomial, ie, the largest integer k that (lambda - lambda\_i)^k divides the polynomial.

    func algebraicMultiplicity(of lambda: Fraction) -> Int? {
        guard self.isSquareMatrix else { return nil }
        guard let characteristicPolynomial = characteristicPolynomial else { return nil }

        var value = 0
        while characteristicPolynomial.isMultiple(of: pow(Polynomial(coefficients: [1, -1 * lambda]), value + 1)) {
            value += 1
        }
        
        return value
    }
    
    /// The geometric multiplicity of an eigenvalue.
    ///
    /// - Invariant: geometric multiplicity: The maximum number of linearly independent eigenvectors associated with lambda.
    func geometricMultiplicity(of lambda: Fraction) -> Int? {
        guard self.isSquareMatrix else { return nil }
        return self.size.width - (self - lambda * Matrix(identity: self.size.width)).rank
    }
    
    /// Sort a matrix. Only useful when the array is in its reduced row-echelon form.
    ///
    /// **Example**
    ///
    ///      let matrix = Matrix([[1, 0, 0], [0, 0, 1], [0, 1, 0]])
    ///      matrix.sorted().presentMatrix()
    ///      /* prints """
    ///                1    0    0
    ///                0    1    0
    ///                0    0    1
    ///                """
    ///      */
    ///
    /// The zero rows are put to the end of the matrix:
    ///
    ///     let matrix = Matrix([[0, 0, 0], [0, 0, 0], [0, 1, 0]])
    ///     print(matrix.sorted())
    ///     // prints "[[0, 1, 0], [0, 0, 0], [0, 0, 0]]"
    ///
    func sorted() -> Matrix {
        guard !self.leadingEntries.containsDuplicatedItems(ignore: [nil]) else {print("\(self).sorted(): please make sure it is in reduced row echelon form."); return self }
        var dictionary: [(Vector, Int)] = []
        for i in 0..<self.leadingEntries.count {
            if self.leadingEntries[i] != nil {
                dictionary.append((self[i], self.leadingEntries[i]!))
            } else {
                dictionary.append((self[i], Int(self.size.height)))
            }
        }
        return dictionary.sorted(by: ({$0.1 < $1.1})).map({ $0.0 })
    }
    
    /// print the matrix
    ///
    /// **Example**
    ///
    ///     let matrix = Matrix([[0, 0, 1, 1], [0, 1, 1, 0], [1, 1, 1, 0]])
    ///     matrix.presentMatrix()
    ///     // prints """
    ///               0    0    1    1
    ///               0    1    1    0
    ///               1    1    1    0
    ///               """
    ///
    func presentMatrix() {
        printMatrix(matrix: self.map{$0.map{String($0)}})
        print()
    }
    
    /// find reduced row-echelon matrix
    ///
    /// **Example**
    ///
    ///     let matrix = Matrix([[0, 0, 1, 1], [0, 1, 1, 0], [1, 1, 1, 0]])
    ///     matrix.reduced().presentMatrix()
    ///     // prints """
    ///               0    0    1    1
    ///               0    1    0    -1
    ///               1    0    0    0
    ///               """
    ///
    /// - Returns: the reduced row-echelon matrix
    func reduced() -> Matrix {
        var matrix = self
        let lengthOfX = matrix.first!.count
        let lengthOfY = matrix.count // import
        var leadingTermList = [Bool](repeating: false, count: matrix.first!.count)
        
        for i in 0..<lengthOfY {
            guard let leadingTermIndex = getLeadingTermIndex(row: matrix[i]) else { continue }
            leadingTermList[leadingTermIndex].toggle()
            let leadingTerm = matrix[i][leadingTermIndex]
            
            if leadingTerm != Fraction(1) { matrix[i] = matrix[i].map{$0 / leadingTerm} }
            
            //change remaining rows
            for ii in 0..<lengthOfY {
                guard ii != i else { continue }
                guard matrix[ii][leadingTermIndex] != Fraction(0) else { continue }
                
                let multiplier = matrix[ii][leadingTermIndex]
                
                for iii in 0..<lengthOfX {
                    matrix[ii][iii] = matrix[ii][iii] - multiplier * matrix[i][iii]
                }
            }
        }
        
        func getLeadingTermIndex(row: [Fraction]) -> Int? {
            var index = 0
            while leadingTermList[index] == true || row[index] == 0 {
                index += 1
                guard index < leadingTermList.count else { return nil }
            }
            return index
        }
        
        return matrix
    }
    
    /// Find answers to an augmented matrix
    ///
    /// **Example**
    ///
    ///     let matrix = Matrix([[0, 0, 1, 1], [0, 1, 1, 0], [1, 1, 1, 0]])
    ///     print(matrix.solved())
    ///     // prints "Optional([1, -1, 0])"
    ///
    /// - Returns: the array of answers, `nil` if can not form reduced row-echelon augmented matrix
    func solved() -> [Fraction]? {
        let matrix = self.reduced()
        
        guard matrix.rank == matrix.size.width - 1 else { return nil }
        guard matrix.filter({$0.reduce(0, {$0 + $1}) != 0}).allSatisfy({ $0.dropLast().reduce(0, {$0 + $1}) == 1 }) else { return nil }
        return matrix.map({ $0.last! })
    }
    
    /// Find the transpose of a matrix.
    ///
    /// **Example**
    ///
    ///     let matrix = Matrix([[1, 2], [3, 4], [5, 6]])
    ///     print(matrix.transposed())
    ///     /*
    ///     1    2          1    3    5
    ///     3    4     ->   2    4    6
    ///     5    6
    ///     */
    ///
    /// - Returns: the transpose of a matrix
    func transposed() -> Matrix {
        let matrix = self
        var newMatrix: [[Fraction]] = [[Fraction]](repeating: [Fraction](repeating: 0, count: matrix.count), count: matrix.first!.count)
        for i in 0..<matrix.count {
            for ii in 0..<matrix.first!.count {
                newMatrix[ii][i] = matrix[i][ii]
            }
        }
        return newMatrix
    }
    
    /// Find the cofactor of a matrix in the position provided.
    ///
    /// - Parameters:
    ///   - position: The position in Math coordinate, start with 1.
    ///
    /// - Returns: The cofactor.
    func cofactor(at position: (i: Int, j: Int)) -> Fraction {
        
        let newArray = {()->[[Fraction]] in
            var content = self
            content.remove(at: position.i - 1)
            for i in 0..<content.count {
                content[i].remove(at: position.j - 1)
            }
            return content
        }()
        
        return Fraction(pow(-1, (position.i+position.j))) * Matrix(newArray).determinant
    }
    
    /// Find the determinant of a matrix.
    ///
    /// - Parameters:
    ///     - position: The position in Math coordinate, start with 1.
    ///
    /// - Returns: The item.
    func item(at position: (i: Int, j: Int)) -> Fraction {
        return self[position.i - 1][position.j - 1]
    }
    
    /// Find the dependencies of the vectors in the matrix.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 2], [0, 2], [1, 0], [-1, 1]]
    ///     print(matrix.findLinearDependency() ?? "")
    ///     // prints "[([1, 0], [(1, [1, 2]), (-1, [0, 2])]), ([-1, 1], [(-1, [1, 2]), (3/2, [0, 2])])]"
    ///
    /// - Important: self: The unprocessed matrix. The rows of the matrix are vectors. (Instead of column, which is written in the form to calculate by hand.)
    ///
    /// - Returns: The array of answers, in the form of (dependent vector, list of dependencies). Where  list of dependencies is in the form of (alpha, the dependent). `nil` if independent.
    func findLinearDependency() -> [(Vector, [(Fraction, Vector)])]? {
        var components = self
        guard self.rank < self.count else { print("\(self) is independent: its rank == number of columns"); return nil }
        //        if self.isSquareMatrix { guard self.determinant != 0 else { print("\(self) is independent: its determinant is not equal to zero"); return nil } }
        guard components.allSatisfy({ $0.count == components.first!.count }) else { print("failed to find linear dependency of \(self): it have different item count"); return nil }
        components = Matrix(components).transposed()
        
        let reducedMatrix = Matrix(components).reduced()
        var output: [(Vector, [(Fraction, Vector)])] = []
        
        for i in 0..<self.count {
            guard !reducedMatrix.leadingEntries.contains(i) else { continue }
            let vector = self[i]
            let reducedVector = reducedMatrix.transposed()[i]
            var dependentList: [(Fraction, Vector)] = []
            let alphas = reducedVector
            
            var list: [Vector]  = []
            for ii in reducedMatrix.leadingEntries {
                guard ii != nil else { continue }
                list.append(self[ii!])
            }
            for ii in 0..<list.count {
                dependentList.append((alphas[ii], list[ii]))
            }
            output.append((vector, dependentList))
        }
        
        // auto check
        guard output.allSatisfy({ content in
            var result = [Fraction](repeating: 0, count: content.0.count)
            for i in content.1 { result = result + i.1.map({ $0 * i.0 }) }
            return content.0 == result
        }) else { print("Failure, \(self).findLinearDependency(): auto check failed. \n reduced matrix: \(reducedMatrix), output: \(output)"); return nil }
        
        return output
    }
    
    /// Find basis for the span of set of vectors in R^n.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, -1, 2, 1], [1, -3, 0, 5], [1, 0, 3, -1]]
    ///     print(matrix.findBasis())
    ///     // prints "[[1, -1, 2, 1], [1, -3, 0, 5]]"
    ///
    /// This method also support finding basis with row method. (By default, it uses column method)
    ///
    ///     let matrix: Matrix = [[1, -1, 2, 1], [1, -3, 0, 5], [1, 0, 3, -1]]
    ///     print(matrix.findBasis(method: .row))
    ///     // prints "[[1, 0, 3, -1], [0, 1, 1, -2]]"
    ///
    /// The method for find basis:
    ///
    /// - column method: Give a basis that will be a subset of the original set of vectors
    /// - row method: Give a basis that will usually not be a subset of the original set of vectors
    ///
    /// - Parameters:
    ///     - method: the method use for finding basis. Choose from .column and .row. The default value if .column
    /// - Returns: the matrix containing the basis
    func findBasis(method: FindBasisMethod = .column) -> Matrix {
        if method == .column {
            var content: Matrix = []
            let reducedMatrix = self.transposed().reduced()
            for i in reducedMatrix.leadingEntries {
                if i != nil { content.append(self[i!]) }
            }
            return content
        } else {
            let reducedMatrix = self.reduced()
            return reducedMatrix.filter({ !$0.allSatisfy({ $0 == 0 }) })
        }
    }
    
    /// Sometimes, you may encounter the most unpleasant fractions within the `Matrix`. Use this method to simplify the results.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[169/20, -169/70, -169/14]]
    ///     print(matrix.simplified())
    ///     // prints "[7, -2, -10]"
    func simplified() -> Matrix {
        return self.map({ $0.simplified() })
    }
    
    //MARK: - Operator Functions
    
    /// Adds two values and produces their sum.
    ///
    /// The addition operator (`+`) calculates the sum of its two arguments.
    ///
    /// **Example**
    ///
    ///     let matrixA: Matrix = [[1, 2, 3], [4, 5, 6]]
    ///     let matrixB: Matrix = [[2, 3, 4], [5, 6, 7]]
    ///     (matrixA + matrixB).presentMatrix()
    ///     /* prints """
    ///               3    5     7
    ///               9    11    13
    ///               """
    ///     */
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    static func + (lhs: Matrix, rhs: Matrix) -> Matrix {
        guard lhs.size == rhs.size else { fatalError("failed to add matrixes \(lhs) and \(rhs): different matrix size") }
        var content = lhs
        for i in 0..<content.count {
            for ii in 0..<content.first!.count {
                content[i][ii] = lhs[i][ii] + rhs[i][ii]
            }
        }
        return content
    }
    
    static func += (_ lhs: inout Matrix, _ rhs: Matrix) {
        lhs = lhs + rhs
    }
    
    /// Subtracts one value from another and produces their difference.
    ///
    /// The subtraction operator (`-`) calculates the difference of its two arguments.
    ///
    /// **Example**
    ///
    ///     let matrixA: Matrix = [[1, 2, 3], [4, 5, 6]]
    ///     let matrixB: Matrix = [[2, 3, 4], [5, 6, 7]]
    ///     (matrixA - matrixB).presentMatrix()
    ///     /* prints """
    ///               -1    -1    -1
    ///               -1    -1    -1
    ///               """
    ///     */
    ///
    /// - Parameters:
    ///   - lhs: A numeric value.
    ///   - rhs: The value to subtract from `lhs`.
    static func - (lhs: Matrix, rhs: Matrix) -> Matrix {
        guard lhs.size == rhs.size else { fatalError("failed to find difference between matrixes \(lhs) and \(rhs): different matrix size") }
        var content = lhs
        for i in 0..<content.count {
            for ii in 0..<content.first!.count {
                content[i][ii] = lhs[i][ii] - rhs[i][ii]
            }
        }
        return content
    }
    
    static func -= (_ lhs: inout Matrix, _ rhs: Matrix) {
        lhs = lhs - rhs
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// **Example**
    ///
    ///     let matrix: Matrix = [[1, 2, 3], [4, 5, 6]]
    ///     (2 * matrixB).presentMatrix()
    ///     /* prints """
    ///               2    4     6
    ///               8    10    12
    ///               """
    ///     */
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: Fraction, rhs: Matrix) -> Matrix {
        return rhs.map({$0.map({$0 * lhs})})
    }
    
    /// Multiplies two values and produces their product.
    ///
    /// The multiplication operator (`*`) calculates the product of its two arguments.
    ///
    /// **Example**
    ///
    ///     let matrixA: Matrix = [[1, 2, 3], [4, 5, 6]]
    ///     let matrixB: Matrix = [[2, 3], [4, 5], [6, 7]]
    ///     (matrixA * matrixB).presentMatrix()
    ///     /* prints """
    ///               28    34
    ///               64    79
    ///               """
    ///     */
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    static func * (lhs: Matrix, rhs: Matrix) -> Matrix {
        guard lhs.size.width == rhs.size.height else { print("failed to multiply \(lhs) and \(rhs): the width of \(lhs) is not equal to the height of \(rhs)"); exit(1) }
        guard lhs.size != Size.zero && rhs.size != Size.zero else { fatalError("failed to multiply \(lhs) and \(rhs): one of \(lhs) or \(rhs) is empty") }
        var content = Matrix(repeating: Vector(repeating: 0, count: Int(rhs.size.width)), count: Int(lhs.size.height))
        for i in 1...content.count {
            for ii in 1...content.first!.count {
                var item = Fraction(0)
                for iii in 1...Int(lhs.size.width) {
                    item += lhs.item(at: (i: i, j: iii)) * rhs.item(at: (i: iii, j: ii))
                }
                
                content[i-1][ii-1] = item
            }
        }
        return content
    }
    
    static func *= (_ lhs: inout Matrix, _ rhs: Matrix) {
        lhs = lhs * rhs
    }
}


//MARK: - Supporting functions

/// Raise the power of a matrix.
///
/// - Precondition: `rhs >= -1`
func pow(_ lhs: Matrix, _ rhs: Int) -> Matrix? {
    guard lhs.isSquareMatrix else { return nil }
    guard rhs >= -1 else { return nil }
    if rhs == -1 { return lhs.inverse }
    if rhs == 0 { return Matrix(identity: lhs.size.width) }
    if rhs == 1 { return lhs }
    
    var value = lhs
    for _ in 1..<rhs {
        value *= lhs
    }
    return value
}
