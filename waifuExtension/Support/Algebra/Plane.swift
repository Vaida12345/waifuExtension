//
//  Plane.swift
//
//
//  Created by Vaida on 9/3/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation

/// A 2-D or 3-D  Line
/// if you want to create a 2-D Line, initialize with the last entry of vector equal to zero.
struct Line: CustomStringConvertible {
    /// The point which the line passes.
    var point: Vector
    
    /// The direction in which the line goes.
    var directionV: Vector
    
    var vectorForm: String {
        return "\(self.point) + \(self.directionV) * t"
    }
    
    var parametricEquations: String {
        return """
            x = \(point[0])\(directionV[0].assignedSign())t
            y = \(point[1])\(directionV[1].assignedSign())t
            z = \(point[2])\(directionV[2].assignedSign())t
            """
    }
    
    var cartesianForm: String {
        return "(x\(point[0].assignedSign(negative: true)))/(\(directionV[0])) = (y\(point[1].assignedSign(negative: true)))/(\(directionV[1])) = (z\(point[2].assignedSign(negative: true)))/(\(directionV[2])) "
    }
    
    var description: String {
        return self.vectorForm
    }
    
    /// initialize with vector form
    init(though point: Vector, t v: Vector) {
        self.point = point.simplified()
        self.directionV = v.simplified()
    }
    
    /// initialize with parametric equations
    init(x: (x0: Fraction, a: Fraction), y: (y0: Fraction, b: Fraction), z: (z0: Fraction, c: Fraction)) {
        self.init(though: [x.x0, y.y0, z.z0], t: [x.a, y.b, z.c])
    }
    
    /// initialize with cartesian form or parametric equations
    init(x0: Fraction, a: Fraction, y0: Fraction, b: Fraction, z0: Fraction, c: Fraction) {
        self.init(though: [x0, y0, z0], t: [a, b, c])
    }
    
    /// The function of the line
    func f(_ t: Fraction) -> Vector {
        return point + (t * directionV)
    }
    
    /// Determine whether the line intersect with another line.
    /// Whether there is a point lying  on both lines
    /// - Parameters:
    ///     - rhs: a second line
    /// - Returns: a bool indicating whether the two lines intersect
    func isIntersection(with rhs: Line) -> Bool {
        // t for x
        let tx = solve { x in
            Double(self.point[0]) + Double(self.directionV[0]) * x
        }
        // t for y
        let ty = solve { x in
            Double(self.point[1]) + Double(self.directionV[1]) * x
        }
        // t for z
        let tz = solve { x in
            Double(self.point[2]) + Double(self.directionV[2]) * x
        }
        return tx == ty && tx == tz
    }
    
    /// Determine whether the line is parallel to another line.
    /// Whether their direction vectors are the parallel
    /// - Parameters:
    ///     - rhs: a second line
    /// - Returns: a bool indicating whether the two lines are parallel
    func isParallel(with rhs: Line) -> Bool {
        return self.directionV.distance(to: rhs.directionV) == 0
    }
    
    /// Determine whether the line is skew to another line.
    /// Whether they do not intersect and are not parallel
    /// - Parameters:
    ///     - rhs: a second line
    /// - Returns: a bool indicating whether the two lines are skew
    func isSkew(with rhs: Line) -> Bool  {
        return !self.isIntersection(with: rhs) && !self.isParallel(with: rhs)
    }
}

/// A 3-D Plane
struct Plane: CustomStringConvertible {
    /// The point which the line passes.
    var point: Vector
    
    /// A direction in which the line goes.
    var directionU: Vector
    
    /// A direction in which the line goes.
    var directionV: Vector
    
    /// the normal vector of a plane
    var normal: Vector {
        return directionU.crossProduct(rhs: directionV).simplified()
    }
    
    var vectorForm: String {
        return "\(point) + s * \(directionU) + v * \(directionV)"
    }
    
    var pointNormalForm: String {
        return "(r - \(point)) · \(self.normal) = 0"
    }
    
    var cartesianForm: String {
        return "\(self.normal[0])x + \(self.normal[1])y + \(self.normal[2])z = \(self.normal[0]*point[0] + self.normal[1]*point[1] + self.normal[2]*point[2])"
    }
    
    var description: String {
        return self.vectorForm
    }
    
    /// initialize with vector form
    init(though point: Vector, s u: Vector, t v: Vector) {
        self.point = point.simplified()
        self.directionU = u.simplified()
        self.directionV = v.simplified()
    }
    
    /// initialize with point normal form
    init(though point: Vector, normal: Vector) {
        self.init(normal: normal, d: point * normal)
    }
    
    /// initialize with cartesian form
    init(normal: Vector, d: Fraction) {
        let pointA = Vector([d / normal[0], 0, 0])
        let pointB = Vector([0, d / normal[1], 0])
        let pointC = Vector([0, 0, d / normal[2]])
        
        self.init(though: pointA, though: pointB, though: pointC)
    }
    
    /// initialize with three points that the plane passes
    init(though pointA: Vector, though pointB: Vector, though pointC: Vector) {
        let u = pointB - pointA
        let v = pointC - pointA
        self.init(though: pointA, s: u, t: v)
    }
    
    /// initialize with a point the plane passes and a line it contains
    init(though point: Vector, contains line: Line) {
        self.init(though: point, though: line.f(0), though: line.f(1))
    }
    
    /// The function of the plane
    func f(t: Fraction, s: Fraction) -> Vector {
        return point + (s * directionU) + (t * directionV)
    }
}
