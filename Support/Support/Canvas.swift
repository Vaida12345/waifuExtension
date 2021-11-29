//
//  Canvas.swift
//
//
//  Created by Vaida on 9/10/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation
import Cocoa

/// Designed only for points that are in the first quadrant.
///
/// **Do not use until finished**
//struct Canvas {
//
//    struct PointSet {
//        var points: [Point]
//        var name: String
//        var color: NSColor
//        let lineWidth: Double
//        static var index: Int = 1
//
//        // computed variables.
//        var domain: (min: Double, max: Double) {
//            if self.points.isEmpty { return (-10, 10) }
//            let min = self.points.map({ $0.x }).min()!
//            let max = self.points.map({ $0.x }).max()!
//            return (min, max)
//        }
//
//        var range: (min: Double, max: Double) {
////            if self.points.isEmpty { return (-10, 10) }
//            var min: Double = -10
//            var max: Double = 10
//            for i in self.points {
//                if let value = i.y { min = min < value ? min : value }
//                if let value = i.y { max = max > value ? max : value }
//            }
//            return (min, max)
//        }
//
//        init(points: [Point], name: String = "Point Set \(index + 1)", color: NSColor = NSColor(_colorLiteralRed: generateRandomValue(), green: generateRandomValue(), blue: generateRandomValue(), alpha: 1), lineWidth: Double = 1) {
//            self.points = points
//            self.name = name
//            self.color = color
//            self.lineWidth = lineWidth
//            PointSet.index += 1
//        }
//
//        static private func generateRandomValue() -> Float {
//            return Float([Int](0...255).randomElement()!) / 255
//        }
//    }
//
//    struct Point {
//        var x: Double
//        var y: Double?
//
//        init<T>(x: T, y: T) where T: BinaryFloatingPoint {
//            self.x = Double(x)
//            self.y = Double(y)
//        }
//    }
//
//    // constant values
//
//    let points: [PointSet]
//
//    let domain: (min: Double, max: Double)
//
//    let range: (min: Double, max: Double)
//
//    let size: Size
//
//    let aspectRatio: Bool
//
//    // Changeable values
//
//    var axisLabels: (x: String, y: String) = ("x", "y")
//
//
//    // private values
//
//    private var graph: NSView = NSView()
//
//
//    // computed variables
//
//    var xScaleFactor: Double {
//        return abs(self.domain.max - self.domain.min) / Double(self.size.width)
//    }
//
//    var yScaleFactor: Double {
//        return aspectRatio ? xScaleFactor : abs(self.range.max - self.range.min) / Double(self.size.width)
//    }
//
//
//    init(points: [PointSet], aspectRatio: Bool = false, size: Size = Size(width: 2000, height: 1000)) {
//        self.points = points
//        self.aspectRatio = aspectRatio
//
//        self.domain = (points.map({ $0.domain.min }).min() ?? -10, points.map({ $0.domain.max }).max() ?? 10)
//        self.range = (points.map({ $0.range.min }).min() ?? -10, points.map({ $0.range.max }).max() ?? 10)
//        self.size = size
//    }
//
//    private func drawAxis() -> NSView {
//        let view = NSView()
//        view.frame = CGRect(origin: CGPoint.zero, size: CGSize(size))
//
//        let xAxisValues = abs(self.domain.max - self.domain.min).expressedAsScientific()
//        let yAxisValues = abs(self.range.max - self.range.min).expressedAsScientific()
//
//        // x axis
//        for i in Int(self.domain.min*10/Double(pow(10, xAxisValues.power))-1)...Int(self.domain.max*10/Double(pow(10, xAxisValues.power))+1) {
//            let subview = drawLine(fromPoint: Point(x: Double(i)*Double(pow(10, xAxisValues.power)), y: range.min), toPoint: Point(x: Double(i)*Double(pow(10, xAxisValues.power)), y: range.max), color: NSColor.black, width: 2)
//            view.addSubview(subview)
//        }
//
//        // y axis
//        for i in Int(self.range.min*10/Double(pow(10, yAxisValues.power))-1)...Int(self.range.max*10/Double(pow(10, yAxisValues.power))+1) {
//            let subview = drawLine(fromPoint: Point(x: Double(i)*Double(pow(10, yAxisValues.power)), y: range.min), toPoint: Point(x: Double(i)*Double(pow(10, yAxisValues.power)), y: range.max), color: NSColor.black, width: 2)
//            view.addSubview(subview)
//        }
//
//        return view
//    }
//
//    private func drawLine(fromPoint: Point, toPoint: Point, color: NSColor, width: Double) -> NSView {
//        let view = NSView()
//        view.frame = CGRect(origin: CGPoint.zero, size: CGSize(size))
//        guard fromPoint.y != nil && toPoint.y != nil else { return view }
//
//        let fromX = (fromPoint.x - domain.min) * xScaleFactor
//        let fromY = (fromPoint.y! - range.min) * yScaleFactor
//        let toX = (toPoint.x - domain.min) * xScaleFactor
//        let toY = (toPoint.y! - range.min) * yScaleFactor
//
//        let path = CGMutablePath()
//        let layer = CAShapeLayer()
//        layer.lineWidth = width
//        layer.strokeColor = color.cgColor
//        path.move(to: CGPoint(x: fromX, y: fromY))
//        path.addLine(to: CGPoint(x: toX, y: toY))
//        layer.path = path
//        view.layer = layer
//
//        return view
//    }
//
//    mutating func draw() {
//        self.graph = self.drawAxis()
//        self.graph.image.write(to: FolderAction.generateOutputPath(at: "/Users/vaida/Documents/Xcode Data/Plotter/item.jpg"))
//        print(self.graph)
//    }
//}
//
//extension CGSize {
//    init(_ size: Size) {
//        self.init(width: size.width, height: size.height)
//    }
//}

//MARK: Canvas, old.

/// A canvas made to draw functions.
///
///
///     let canvas = Canvas()
///
/// add functions with
///
///     canvas.functions.append { x in
///         return x
///     }
///
///
/// Ask the canvas to draw functions with
///
///     canvas.draw()
///
/// if you want to modify any self-generated variables, modify after assigning functions
///
/// By default, the graph is to-scale. It could be modified by:
///
///     canvas.toScale.toggle()
///
/// By default, the grid line of the graphs is on. It could be modified by:
///
///     canvas.showGrid.toggle()
///
/// Set titles for the functions by:
///
///     canvas.titles = ["f(x)", "g(x)"]
///
/// By default, the size of the canvas is (2200, 1000). It could be modified by:
///
///     canvas.frame = CGRect(x: 0, y: 0, width: 2200, height: 1000)
///
/// By default, the canvas domain is (-5, 5). It could be modified by:
///
///     canvas.domain = (-5, 5)
///
/// The width of line of graph could be modified by:
///
///     canvas.lineWidth = 2
///
/// The color of each graph was chosen from a color list randomly. The color list could be modified by:
///
///     canvas.colors.append(.blue)
///
/// Like graph of functions, the line width and color of axis could also be modified:
///
///     canvas.axisLineWidth = 5
///     canvas.axisLineColor = .gray
///
class Canvas: NSView {
    
    struct PointSet: Equatable, CustomStringConvertible {
        var points: [Point]
        var name: String
        var color: NSColor
        let lineWidth: Double
        static var index: Int = 1

        // computed variables.
        var domain: (min: Double, max: Double) {
            if self.points.isEmpty { return (-10, 10) }
            let min = self.points.map({ $0.x }).min()!
            let max = self.points.map({ $0.x }).max()!
            return (Double(min), Double(max))
        }

        var range: (min: Double, max: Double) {
            if self.points.isEmpty { return (-10, 10) }
            let min: Double = Double(points.map{ $0.y }.min() ?? -10)
            let max: Double = Double(points.map{ $0.y }.max() ?? 10)
            return (min, max)
        }
        
        var description: String {
            return "\(self.points.map({ $0.description }))"
        }

        init(points: [Point], name: String = "Point Set \(index)", color: NSColor = NSColor(_colorLiteralRed: generateRandomValue(), green: generateRandomValue(), blue: generateRandomValue(), alpha: 1), lineWidth: Double = 1) {
            self.points = points
            self.name = name
            self.color = color
            self.lineWidth = lineWidth
            PointSet.index += 1
        }

        static private func generateRandomValue() -> Float {
            return Float([Int](0...255).randomElement()!) / 255
        }
    }
        
    // constant values

    var points: [PointSet] = []
    
    //MARK:- mutable variables
    /// the main part of canvas, the functions to be drawn
    var functions: [(Double)->(Double?)] = [] { didSet { setAll() } }
    
    var origin: (Double, Double) = (0, 0)  //pixels
    
    /// this is the mathematical domain. do not change
    private var mathematicalDomain: (Double, Double) = (-50, 50)
    
    /// change the domain of canvas. Please change this after appending all the functions
    var domain: (Double, Double) = (-5, 5)  { didSet { setAll(by: "domain") } }
    
    /// range here is ONLY for drawing. To determine the REAL range, use localMinimum and localMaximum. Do not change
    var range: (Double, Double) = (-10, 10)  //points
    
    /// determines whether the graph is to-scale
    var toScale: Bool = true { didSet { setAll() } }
    
    /// set the line width of each graph
    var lineWidth: Double = 2
    
    /// set the color used in drawing these graphs
    var colors: [NSColor] = [.blue, .red, .cyan, .green, .orange, .purple, .systemPink, .magenta, .systemIndigo, .systemTeal]
    
    /// set the line width of axis
    var axisLineWidth: Double = 5
    
    /// set the line color of axis
    var axisLineColor: NSColor = .gray
    
    /// set whether show grid lines
    var showGrid = true
    
    /// set the titles of functions
    ///
    /// the number of titles must be equal to number of functions
    ///
    ///     titles.count == functions.count
    var titles: [String] = []
    
    //MARK:- non mutable variables
    var xScaleFactor: Double {
        return Double(self.frame.width - 200) / Double(domain.1 - domain.0)
    }
    
    var yScaleFactor: Double {
        if toScale {
            return xScaleFactor
        } else {
            return Double(self.frame.height) / Double(range.1 - range.0)
        }
    }
    
    /// The graph was calculated by doing calculations with f(x) with vary tiny Delta x. Delta x is generated so that there will be one point in each pixel, which is enough.
    var xStepper: Double {
        return Double(domain.1 - domain.0) / Double(self.frame.width - 200)
    }
    
    /// the minimum value of y for the domain given,  depending on domain
    var localMinimum: Double {
        guard !functions.isEmpty else { return 0.0 }
        var content = Double.infinity
        var x: Double = mathematicalDomain.0
        while x <= mathematicalDomain.1 {
            for f in functions {
                guard let y = f(x) else { continue }
                content = y < content ? y : content
            }
            x += xStepper
        }
        
        return content
    }
    
    /// the maximum value of y for the domain given,  depending on domain
    var localMaximum: Double {
        guard !functions.isEmpty else { return 0.0 }
        var content = -1 * Double.infinity // some random number
        var x: Double = mathematicalDomain.0
        while x <= mathematicalDomain.1 {
            for f in functions {
                guard let y = f(x) else { continue }
                content = y > content ? y : content
            }
            x += xStepper
        }
        
        return content
    }
    
    //MARK:- supporting functions
    
    // depending on domain, range
    private func setOrigin() {
        guard !functions.isEmpty else { return }
        self.origin.0 = Double(self.frame.width - 200) * abs(domain.0) / Double(domain.1 - domain.0)
        self.origin.1 = Double(self.frame.height) * abs(range.0) / Double(range.1 - range.0)
    }
    
    private func setDomain() {
        guard !functions.isEmpty else { return }
        
        // lower bound
        var lowerBound = mathematicalDomain.0
        while functions.map({$0(lowerBound)}).filter({$0 != nil}).count == 0 {
            lowerBound += xStepper
        }
        mathematicalDomain.0 = lowerBound
        
        //upper bound
        var upperBound = mathematicalDomain.1
        while functions.map({$0(upperBound)}).filter({$0 != nil}).count == 0 {
            upperBound -= xStepper
        }
        mathematicalDomain.1 = upperBound
    }
    
    // depending on local minimum and domain and domain
    private func setRange() {
        guard !functions.isEmpty else { return }
        if toScale {
            let rangeLength = Double(self.frame.height) / yScaleFactor
            if localMinimum >= 0 {
                range.0 = 0
                range.1 = rangeLength
            } else if localMaximum <= 0 {
                range.0 = -1 * rangeLength
                range.1 = 0
            } else if localMinimum > -1 * rangeLength / 2 && localMaximum > rangeLength / 2 {
                range.0 = localMinimum
                range.1 = range.0 + rangeLength
            } else if localMaximum < rangeLength / 2 && localMinimum < -1 * rangeLength / 2 {
                range.1 = localMaximum
                range.0 = localMaximum - rangeLength
            } else {
                range.0 = -1 * rangeLength / 2
                range.1 = rangeLength / 2
            }
        } else {
            if localMaximum < 0 {
                range.0 = localMinimum
                range.1 = 0
            } else if localMinimum > 0 {
                range.0 = 0
                range.1 = localMaximum
            }
        }
    }
    
    /// draw each individual lines, in the frame of the coordinate
    private func drawLine(from: (Double, Double), to: (Double, Double), color: NSColor, width: Double? = nil, on view: NSView? = nil) {
        let path = CGMutablePath()
        let layer = CAShapeLayer()
        layer.lineWidth = CGFloat(width ?? ((color == axisLineColor) ? axisLineWidth : lineWidth))
        layer.strokeColor = color.cgColor
        path.move(to: CGPoint(x: from.0 * xScaleFactor + origin.0, y: from.1 * yScaleFactor + origin.1))
        path.addLine(to: CGPoint(x: to.0 * xScaleFactor + origin.0, y: to.1 * yScaleFactor + origin.1))
        layer.path = path
        
        let view = view ?? self
        
        if view.layer == nil {
            view.layer = layer
        } else {
            view.layer!.addSublayer(layer)
        }
    }
    
    private func setAll(by: String = "") {
        if by != "domain" {
            setDomain()
        }
        setRange()
        setOrigin()
    }
    
    // MARK:- functions
    func draw() {
        
        if !self.points.isEmpty {
            self.toScale = false
            self.domain = (points.map({ $0.domain.min }).min() ?? -10, points.map({ $0.domain.max }).max() ?? 10)
            self.range = (points.map({ $0.range.min }).min() ?? -10, points.map({ $0.range.max }).max() ?? 10)
            
            if self.range.1 - self.range.0 == 0 {
                range = (self.range.1 - 1, self.range.1 + 1)
            }
            
            self.titles = points.map{ $0.name }
        }
        
        guard self.domain.1 - self.domain.0 > 0 else {
            print("Failed to draw: The domain is zero.")
            return
        }
        
        // MARK: draw axis
        // all axis in function coordinate system
        
        //small functions make life easier
        func getComponentDivisor(size: Double) -> Double {
            let number = abs(size)
            switch number {
            case 0:
                return 1*(size.sign == .plus ? 1: -1)
            case 1...2:
                return 0.25*(size.sign == .plus ? 1: -1)
            case 2...5:
                return 0.5*(size.sign == .plus ? 1: -1)
            case 5...10:
                return 1*(size.sign == .plus ? 1: -1)
            default:
                fatalError("Check for \(number)")
            }
        }
        
        func getTextField(string: String) -> NSTextField  {
            let textField = NSTextField(string: string)
            textField.backgroundColor = .white
            textField.font = NSFont(name: "Avenir", size: 16)
            textField.isBordered = false
            textField.textColor = axisLineColor
            textField.alignment = .right
            return textField
        }
        
        //MARK:- x axis
        if range.0 < 0 && range.1 > 0 {
            // x axis line
            drawLine(from: (domain.0, 0), to: (domain.1, 0), color: axisLineColor)
            
            // x axis intervals
            let width = domain.1 - domain.0
            let leadingTerm = width.expressedAsScientific().0
            let digits = width.expressedAsScientific().1
//
//            for i in 0..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
//                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) <= domain.1 else { continue }
//                drawLine(from: (Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), 0), to: (Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), lineWidth * 6 / xScaleFactor), color: axisLineColor, width: axisLineWidth / 2)
//                drawLine(from: (-1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), 0), to: (-1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), lineWidth * 6 / xScaleFactor), color: axisLineColor, width: axisLineWidth / 2)
//            }
            
            // text power
            let textField = getTextField(string: "x10^\(digits)")
            textField.frame = CGRect(x: Double(self.frame.width - 200)-60-axisLineWidth, y: self.origin.1+axisLineWidth/2, width: 60, height: 20)
            self.addSubview(textField)
            
            // axis texts
            for i in 1..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) <= domain.1 else { continue }
                let labelRight = getTextField(string: "\(Double(i)*getComponentDivisor(size: leadingTerm))")
                labelRight.frame = CGRect(x: origin.0 + xScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth / 2, y: origin.1 - axisLineWidth/2 - 20, width: 60, height: 20)
                labelRight.alignment = .left
                self.addSubview(labelRight)
                
                let labelLeft = getTextField(string: "\(-1*Double(i)*getComponentDivisor(size: leadingTerm))")
                labelLeft.frame = CGRect(x: origin.0 - xScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth / 2, y: origin.1 - axisLineWidth/2 - 20, width: 60, height: 20)
                labelLeft.alignment = .left
                self.addSubview(labelLeft)
            }
        } else if range.0 == 0 && range.1 > 0 {
            // range = [0, +infty)
            // x axis line
            drawLine(from: (domain.0, axisLineWidth/2/yScaleFactor), to: (domain.1, axisLineWidth/2/yScaleFactor), color: axisLineColor)
            
            // x axis intervals
            let width = domain.1 - domain.0
            let leadingTerm = width.expressedAsScientific().0
            let digits = width.expressedAsScientific().1
//
//            for i in 0..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
//                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) <= domain.1 else { continue }
//                drawLine(from: (Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), 0), to: (Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), lineWidth * 6 / xScaleFactor), color: axisLineColor, width: axisLineWidth / 2)
//                drawLine(from: (-1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), 0), to: (-1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), lineWidth * 6 / xScaleFactor), color: axisLineColor, width: axisLineWidth / 2)
//            }
            
            // text power
            let textField = getTextField(string: "x10^\(digits)")
            textField.frame = CGRect(x: Double(self.frame.width - 200)-60-axisLineWidth, y: self.origin.1+axisLineWidth/2+axisLineWidth, width: 60, height: 20)
            self.addSubview(textField)
            
            // axis texts
            for i in 1..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) <= domain.1 else { continue }
                let labelRight = getTextField(string: "\(Double(i)*getComponentDivisor(size: leadingTerm))")
                labelRight.frame = CGRect(x: origin.0 + xScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth/2, y: origin.1 + axisLineWidth/2 + axisLineWidth, width: 60, height: 20)
                labelRight.alignment = .left
                self.addSubview(labelRight)
                
                let labelLeft = getTextField(string: "\(-1*Double(i)*getComponentDivisor(size: leadingTerm))")
                labelLeft.frame = CGRect(x: origin.0 - xScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth/2, y: origin.1 + axisLineWidth/2 + axisLineWidth, width: 60, height: 20)
                labelLeft.alignment = .left
                self.addSubview(labelLeft)
            }
        }  else if range.1 == 0 && range.0 < 0 {
            // x axis line
            drawLine(from: (domain.0, -axisLineWidth/2/yScaleFactor), to: (domain.1, -axisLineWidth/2/yScaleFactor), color: axisLineColor)
            
            // x axis intervals
            let width = domain.1 - domain.0
            let leadingTerm = width.expressedAsScientific().0
            let digits = width.expressedAsScientific().1

//            for i in 0..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
//                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) <= domain.1 else { continue }
//                drawLine(from: (Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), 0) , to: (Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), -1*lineWidth * 6 / xScaleFactor), color: axisLineColor, width: axisLineWidth / 2)
//                drawLine(from: (-1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), 0), to: (-1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)), -1*lineWidth * 6 / xScaleFactor), color: axisLineColor, width: axisLineWidth / 2)
//            }
            
            // text power
            let textField = getTextField(string: "x10^\(digits)")
            textField.frame = CGRect(x: Double(self.frame.width - 200)-60-axisLineWidth, y: self.origin.1-axisLineWidth-20, width: 60, height: 20)
            self.addSubview(textField)
            
            // axis texts
            for i in 1..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) <= domain.1 else { continue }
                let labelRight = getTextField(string: "\(Double(i)*getComponentDivisor(size: leadingTerm))")
                labelRight.frame = CGRect(x: origin.0 + xScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth/2, y: origin.1 - axisLineWidth - 20, width: 60, height: 20)
                labelRight.alignment = .left
                self.addSubview(labelRight)
                
                let labelLeft = getTextField(string: "\(-1*Double(i)*getComponentDivisor(size: leadingTerm))")
                labelLeft.frame = CGRect(x: origin.0 - xScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth/2, y: origin.1 - axisLineWidth - 20, width: 60, height: 20)
                labelLeft.alignment = .left
                self.addSubview(labelLeft)
            }
        }
        
        // show x grid
        if showGrid  {
            for i in 0..<Int((domain.1 - domain.0).expressedAsScientific().0 / getComponentDivisor(size: (domain.1 - domain.0).expressedAsScientific().0)) {
                let width = domain.1 - domain.0
                let leadingTerm = width.expressedAsScientific().0
                let digits = width.expressedAsScientific().1
                let divisor = getComponentDivisor(size: leadingTerm)
                
                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) <= domain.1 else { continue }
                
                drawLine(from: (divisor * pow(10, Double(digits))*Double(i), range.0), to: (divisor * pow(10, Double(digits))*Double(i), range.1), color: axisLineColor, width: 0.5)
                drawLine(from: (-1*divisor * pow(10, Double(digits))*Double(i), range.0), to: (-1*divisor * pow(10, Double(digits))*Double(i), range.1), color: axisLineColor, width: 0.5)
            }
        }
        
        
        //MARK:- y axis
        if domain.0 < 0 && domain.1 > 0 {
            // y axis line
            drawLine(from: (0, range.0), to: (0, range.1), color: axisLineColor)
            
            // y axis intervals
            let height = range.1 - range.0
            let leadingTerm = height.expressedAsScientific().0
            let digits = height.expressedAsScientific().1
//
//            for i in 0..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
//                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) < range.1 else { continue }
//                drawLine(from: (0, Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), to: (lineWidth * 6 / yScaleFactor, Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), color: axisLineColor, width: axisLineWidth / 2)
//                drawLine(from: (0, -1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), to: (lineWidth * 6 / yScaleFactor, -1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), color: axisLineColor, width: axisLineWidth / 2)
//            }
            
            if range.1 == 0 {
                // text power
                let textField = getTextField(string: "x10^\(digits)")
                textField.frame = CGRect(x: self.origin.0+axisLineWidth/2, y: 0, width: 60, height: 20)
                textField.alignment = .left
                self.addSubview(textField)
            } else {
                // text power
                let textField = getTextField(string: "x10^\(digits)")
                textField.frame = CGRect(x: self.origin.0+axisLineWidth/2, y: Double(self.frame.height)-20, width: 60, height: 20)
                textField.alignment = .left
                self.addSubview(textField)
            }
            
            
            // axis texts
            for i in 1..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) < range.1 else { continue }
                let labelRight = getTextField(string: "\(Double(i)*getComponentDivisor(size: leadingTerm))")
                labelRight.frame = CGRect(x: origin.0 - axisLineWidth/2 - 60, y: origin.1 + yScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth / 2, width: 60, height: 20)
                self.addSubview(labelRight)
                
                let labelLeft = getTextField(string: "\(-1*Double(i)*getComponentDivisor(size: leadingTerm))")
                labelLeft.frame = CGRect(x: origin.0 - axisLineWidth/2 - 60, y: origin.1 - yScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth / 2, width: 60, height: 20)
                self.addSubview(labelLeft)
            }
        } else if domain.0 == 0 && domain.1 > 0 {
            // y axis line
            drawLine(from: (axisLineWidth/2/xScaleFactor, range.0), to: (axisLineWidth/2/xScaleFactor, range.1), color: axisLineColor)
            
            // y axis intervals
            let height = range.1 - range.0
            let leadingTerm = height.expressedAsScientific().0
            let digits = height.expressedAsScientific().1
//
//            for i in 0..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
//                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) < range.1 else { continue }
//                drawLine(from: (0, Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), to: (lineWidth * 6 / yScaleFactor, Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), color: axisLineColor, width: axisLineWidth / 2)
//                drawLine(from: (0, -1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), to: (lineWidth * 6 / yScaleFactor, -1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), color: axisLineColor, width: axisLineWidth / 2)
//            }
            
            if range.1 == 0 {
                // text power
                let textField = getTextField(string: "x10^\(digits)")
                textField.frame = CGRect(x: self.origin.0+axisLineWidth, y: 0, width: 60, height: 20)
                textField.alignment = .left
                self.addSubview(textField)
            } else {
                // text power
                let textField = getTextField(string: "x10^\(digits)")
                textField.frame = CGRect(x: self.origin.0+axisLineWidth, y: Double(self.frame.height)-20, width: 60, height: 20)
                textField.alignment = .left
                self.addSubview(textField)
            }
            
            
            // axis texts
            for i in 1..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) < range.1 else { continue }
                let labelRight = getTextField(string: "\(Double(i)*getComponentDivisor(size: leadingTerm))")
                labelRight.frame = CGRect(x: origin.0 + axisLineWidth, y: origin.1 + yScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth/2, width: 60, height: 20)
                labelRight.alignment = .left
                self.addSubview(labelRight)
                
                let labelLeft = getTextField(string: "\(-1*Double(i)*getComponentDivisor(size: leadingTerm))")
                labelLeft.frame = CGRect(x: origin.0 + axisLineWidth, y: origin.1 - yScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth/2, width: 60, height: 20)
                labelLeft.alignment = .left
                self.addSubview(labelLeft)
            }
        } else if domain.0 < 0 && domain.1 == 0 {
            // y axis line
            drawLine(from: (domain.1 - axisLineWidth/2/xScaleFactor, range.0), to: (domain.1 - axisLineWidth/2/xScaleFactor, range.1), color: axisLineColor)
            
            // y axis intervals
            let width = range.1 - range.0
            let leadingTerm = width.expressedAsScientific().0
            let digits = width.expressedAsScientific().1
//
//            for i in 0..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
//                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) < range.1 else { continue }
//                drawLine(from: (0, Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), to: (-1*lineWidth * 6 / yScaleFactor, Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), color: axisLineColor, width: axisLineWidth / 2)
//                drawLine(from: (0, -1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), to: (-1*lineWidth * 6 / yScaleFactor, -1*Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits))), color: axisLineColor, width: axisLineWidth / 2)
//            }
            
            if range.1 == 0 {
                // text power
                let textField = getTextField(string: "x10^\(digits)")
                textField.frame = CGRect(x: self.origin.0-axisLineWidth-60, y: 0, width: 60, height: 20)
                self.addSubview(textField)
            } else {
                // text power
                let textField = getTextField(string: "x10^\(digits)")
                textField.frame = CGRect(x: self.origin.0-axisLineWidth-60, y: Double(self.frame.height)-20, width: 60, height: 20)
                self.addSubview(textField)
            }
            
            
            // axis texts
            for i in 1..<Int(leadingTerm / getComponentDivisor(size: leadingTerm)) {
                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) < range.1 else { continue }
                let labelRight = getTextField(string: "\(Double(i)*getComponentDivisor(size: leadingTerm))")
                labelRight.frame = CGRect(x: origin.0 - axisLineWidth - 60, y: origin.1 + yScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth/2, width: 60, height: 20)
                self.addSubview(labelRight)
                
                let labelLeft = getTextField(string: "\(-1*Double(i)*getComponentDivisor(size: leadingTerm))")
                labelLeft.frame = CGRect(x: origin.0 - axisLineWidth - 60, y: origin.1 - yScaleFactor * Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) + axisLineWidth/2, width: 60, height: 20)
                self.addSubview(labelLeft)
            }
        }
        
        // show y grid
        if showGrid {
            for i in 0..<Int((range.1 - range.0).expressedAsScientific().0 / getComponentDivisor(size: (range.1 - range.0).expressedAsScientific().0)) {
                let width = range.1 - range.0
                let leadingTerm = width.expressedAsScientific().0
                let digits = width.expressedAsScientific().1
                let divisor = getComponentDivisor(size: leadingTerm)
                
                guard Double(i) * getComponentDivisor(size: leadingTerm) * pow(10, Double(digits)) < range.1 else { continue }
                drawLine(from: (domain.0, divisor * pow(10, Double(digits))*Double(i)), to: (domain.1, divisor * pow(10, Double(digits))*Double(i)), color: axisLineColor, width: 0.5)
                drawLine(from: (domain.0, -1*divisor * pow(10, Double(digits))*Double(i)), to: (domain.1, -1*divisor * pow(10, Double(digits))*Double(i)), color: axisLineColor, width: 0.5)
            }
        }
        
        // MARK:- draw functions
        let view = NSView(frame: self.frame)
        let colorsBackup = colors
        for i in 0..<functions.count {
            if colors.isEmpty {
                colors = colorsBackup
            }
            let color = colors.remove(at: [Int](0..<colors.count).randomElement()!)
            
            // titles
            if !titles.isEmpty {
                let textField = getTextField(string: titles[i])
                textField.textColor = color
                textField.frame = CGRect(x: Double(self.frame.width-190), y: Double(self.frame.height) - 20 - 20*Double(i), width: 160, height: 20)
                self.addSubview(textField)
                
                let path = CGMutablePath()
                let layer = CAShapeLayer()
                layer.lineWidth = CGFloat(lineWidth)
                layer.strokeColor = color.cgColor
                path.move(to: CGPoint(x: Double(self.frame.width-35), y: Double(self.frame.height) - 10 - 20*Double(i)))
                path.addLine(to: CGPoint(x: Double(self.frame.width-5), y: Double(self.frame.height) - 10 - 20*Double(i)))
                layer.path = path
                
                if self.layer == nil {
                    self.layer = layer
                } else {
                    self.layer!.addSublayer(layer)
                }
            }
            
            // draw functions
            var x: Double = mathematicalDomain.0
            while x <= mathematicalDomain.1 {
                guard let y = functions[i](x) else { x += xStepper; continue }
                guard let y1 = functions[i](x + xStepper) else { x += xStepper; continue }
                drawLine(from: (x, y), to: (x + xStepper, y1), color: color, on: view)
                
                x += xStepper
            }
        }
        
        self.addSubview(view)
        
        // MARK:- draw points
        let pointsSubview = NSView(frame: self.frame)
        for i in self.points {
            if i.points == [Point(x: 0, y: 0)] { continue }
            
            // titles
            let textField = getTextField(string: i.name)
            textField.textColor = i.color
            textField.frame = CGRect(x: Double(self.frame.width-190), y: Double(self.frame.height) - 20 - 20*Double(self.points.firstIndex(of: i)!), width: 160, height: 20)
            self.addSubview(textField)
            
            let path = CGMutablePath()
            let layer = CAShapeLayer()
            layer.lineWidth = CGFloat(i.lineWidth)
            layer.strokeColor = i.color.cgColor
            path.move(to: CGPoint(x: Double(self.frame.width-35), y: Double(self.frame.height) - 10 - 20*Double(self.points.firstIndex(of: i)!)))
            path.addLine(to: CGPoint(x: Double(self.frame.width-5), y: Double(self.frame.height) - 10 - 20*Double(self.points.firstIndex(of: i)!)))
            layer.path = path
            
            if self.layer == nil {
                self.layer = layer
            } else {
                self.layer!.addSublayer(layer)
            }
            
            for ii in 0..<i.points.count-1 {
                drawLine(from: (Double(i.points[ii].tuple.x), Double(i.points[ii].tuple.y)), to: (Double(i.points[ii+1].tuple.x), Double(i.points[ii+1].tuple.y)), color: i.color, width: self.lineWidth, on: pointsSubview)
            }
        }
        self.addSubview(pointsSubview)
        
        let image = self.image
        let imageData = NSBitmapImageRep(data: image.tiffRepresentation!)?.representation(using: .jpeg, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)])
        let path = FinderItem(at: "/Users/vaida/Documents/Xcode Data/Plotter/item.jpg").generateOutputPath()
        try! imageData!.write(to: URL(fileURLWithPath: path))
        print(shell(["open \(path.replacingOccurrences(of: " ", with: "\\ "))"]) ?? "")
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 2000, height: 1000)) //default canvas size
    }
    
    init(points: [PointSet]) {
        var points = points
        if !points.map({ $0.points }).contains([Point(x: 0, y: 0)]) {
            points.insert(PointSet(points: [Point(x: 0, y: 0)]), at: 0)
        }
        self.points = points
        super.init(frame: CGRect(x: 0, y: 0, width: 2000, height: 1000)) //default canvas size
    }
    
    init<T>(pointsFromSequence: [[T]], names: [String]? = nil) where T: BinaryFloatingPoint {
        precondition(!pointsFromSequence.isEmpty, "No points provided!")
        var pointsSets = [Canvas.PointSet(points: [Point.zero], name: "")]
        for i in 0..<pointsFromSequence.count {
            var points: [Point] = []
            for ii in 0..<pointsFromSequence[i].count {
                points.append(Point(x: Double(ii), y: Double(pointsFromSequence[i][ii])))
            }
            if let names = names {
                if names.count > i {
                    pointsSets.append(Canvas.PointSet(points: points, name: names[i]))
                    continue
                }
            }
            pointsSets.append(Canvas.PointSet(points: points))
        }
        
        self.points = pointsSets
        super.init(frame: CGRect(x: 0, y: 0, width: 2000, height: 1000)) //default canvas size
    }
    
    /// Example:
    ///
    ///     let canvas = Canvas.init(pointsFromDynamicalSystems: [
    ///         { item in
    ///             return (item[0] + item[1])
    ///         },
    ///         { item in
    ///             return (item[0] - item[1])
    ///         },
    ///     ], names: ["1", "2"], numberOfCalculations: 100, initialValues: [1, 1])
    ///      canvas.draw()
    init(pointsFromDynamicalSystems dynamicalSystems: [(_ x: Int, _ items: [Double])->Double], names: [String]? = nil, numberOfCalculations: Int, initialValues: [Double]) {
        var startingPoints = initialValues
        var nextPoints = startingPoints
        var results: [[Double]] = []
        var x = 0
        
        while x <= numberOfCalculations {
            results.append(startingPoints)
            for i in 0..<dynamicalSystems.count {
                nextPoints[i] = dynamicalSystems[i](x, startingPoints)
            }
            guard nextPoints.allSatisfy({ $0.isFinite }) else { break }
            startingPoints = nextPoints
            
            x += 1
        }
        
        printMatrix(matrix: results, includeIndex: true)
        
        var newMatrix: [[Double]] = [[Double]](repeating: [Double](repeating: 0.0, count: results.count), count: results.first!.count)
        for i in 0..<results.count {
            for ii in 0..<results.first!.count {
                newMatrix[ii][i] = results[i][ii]
            }
        }
        
        var pointsSets = [Canvas.PointSet(points: [Point.zero], name: "")]
        for i in 0..<newMatrix.count {
            var points: [Point] = []
            for ii in 0..<newMatrix[i].count {
                points.append(Point(x: Double(ii), y: Double(newMatrix[i][ii])))
            }
            if let names = names {
                if names.count > i {
                    pointsSets.append(Canvas.PointSet(points: points, name: names[i]))
                    continue
                }
            }
            pointsSets.append(Canvas.PointSet(points: points))
        }
        
        self.points = pointsSets
        super.init(frame: CGRect(x: 0, y: 0, width: 2000, height: 1000)) //default canvas size
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CGPoint {
    init<T>(x: T, y: T) where T: BinaryFloatingPoint {
        self.init(x: Double(x), y: Double(y))
    }
}

extension CGRect {
    init<T>(x: T, y: T, width: T, height: T) where T: BinaryFloatingPoint {
        self.init(x: Double(x), y: Double(y), width: Double(width), height: Double(height))
    }
}

