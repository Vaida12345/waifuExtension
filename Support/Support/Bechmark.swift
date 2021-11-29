//
//  Bechmark.swift
//
//
//  Created by Vaida on 9/28/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation

/// A structure servers to find the time for each iteration.
///
/// Initialize with, for example:
///
///     var bench = Benchmark(items: [
///         .init(title: "Int", sequence: [Int](1...10), action: { item in
///             let _ = item as! Int
///         })
///     ])
///
/// Then, run with:
///
///     bench.run()
///
/// - Important:
/// If you, for example, append items from the sequence. Remove the first item of the resulting sequence.
struct Benchmark {
    
    struct Item {
        var title: String
        var upperBound: Int
        var action: (_ i: Int) -> Void
        var results: [Double] = []
        
        mutating func run() {
            guard results.isEmpty else { return }
            var intervals: [Double] = []
            var counter = 0
            while counter < upperBound {
                let date = Date()
                self.action(counter)
                let interval = date.distance(to: Date())
                intervals.append(interval)
                counter += 1
            }
            self.results = intervals
        }
        
        mutating func saveResults() {
            let item = FinderItem(at: "/Users/vaida/Documents/Xcode Data/Benchmark Results/\(title).json")
            let path = item.generateOutputPath()
            self.run()
            try! FinderItem.saveJSON(self.results, to: path)
        }
        
        init(title: String, upperBound: Int, action: @escaping (_ i: Int) -> Void) {
            self.title = title
            self.upperBound = upperBound
            self.action = action
        }
        
        init(fromResultsAt path: String, name: String? = nil) {
            let results = try! FinderItem.loadJSON(from: path, type: [Double].self)
            self.results = results
            self.title = name ?? FinderItem(at: path).fileName!
            self.upperBound  = 0
            self.action = { _ in  }
        }
    }
    
    var items: [Item]
    
    mutating func run() {
        let date = Date()
        self.items.first!.action(self.items.first!.upperBound - 1)
        let interval = date.distance(to: Date())
        print("benchmark.run(): It would take around \((Double(self.items.count * self.items.first!.upperBound) * interval).expressedAsTime())")
        
        var pointsSets = [Canvas.PointSet(points: [Point.zero], name: "")]
        for i in 0..<items.count {
            self.items[i].run()
            var points: [Point] = []
            for ii in 0..<self.items[i].results.count {
                points.append(Point(x: Double(ii), y: self.items[i].results[ii]))
            }
            pointsSets.append(Canvas.PointSet(points: points, name: self.items[i].title))
        }
        
        let canvas = Canvas(points: pointsSets)
        canvas.lineWidth = {()-> Double in
            let lineWidth = Double(canvas.frame.width) / Double(self.items.map{ $0.upperBound }.max() ?? 1) / 2
            if lineWidth >= 2 { return 2 }
            if lineWidth <= 0.2 { return 0.2 }
            return lineWidth
        }()
        
        canvas.draw()
        
        print("\n----- results -----")
        var matrix: [[String]] = [["Title", "Time Taken", "Min Interval", "Max Interval", "Average"]]
        for i in items {
            var content: [String] = []
            content.append(i.title)
            content.append(i.results.reduce(0, +).expressedAsTime())
            content.append(i.results.filter({ $0 != 0 }).min()?.expressedAsTime() ?? "nan")
            content.append(i.results.max()?.expressedAsTime() ?? "nan")
            content.append(i.results.average().expressedAsTime())
            matrix.append(content)
        }
        printMatrix(matrix: matrix, transpose: true)
        print()
    }
    
    mutating func saveResults() {
        for i in 0..<items.count {
            self.items[i].saveResults()
        }
        print("results saved to: /Users/vaida/Documents/Xcode Data/Benchmark Results/")
    }
    
    init(items: [Item], repeatingCount: Int = 1) {
        var content: [Item] = []
        for _ in 0..<repeatingCount {
            for i in items {
                content.append(i)
            }
        }
        self.items = content
    }
}
