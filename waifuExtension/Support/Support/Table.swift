//
//  Table.swift
//  cmd
//
//  Created by Vaida on 12/5/21.
//

import Foundation

struct Table: Equatable {
    
    //MARK: - Basic Instance Properties
    
    /// The values of the table.
    var value: [[String]]
    
    /// The titles of the table.
    var titles: [String]
    
    
    //MARK: - Instance Properties
    
    /// The dictionary with the first column as key.
    ///
    /// The titles are ignored.
    var dictionary: [String: [String]] {
        var dictionary: [String: [String]] = [:]
        for i in self.value {
            dictionary[i.first!] = Array(i[1..<i.count])
        }
        return dictionary
    }
    
    /// Express the table in a matrix.
    var matrix: [[String]] {
        if titles.isEmpty {
            return value
        } else {
            return [titles] + value
        }
    }
    
    /// The size of the table.
    var size: Size {
        return Size(width: self.matrix.first?.count ?? 0, height: self.matrix.count)
    }
    
    
    //MARK: - Type Properties
    
    
    
    //MARK: - Initializers
    
    init(value: [[String]] = [], titles: [String] = []) {
        self.value = value
        self.titles = titles
    }
    
    init(dictionary: [String: [String]], titles: [String] = []) {
        self.titles = titles
        var value: [[String]] = []
        for i in dictionary {
            value.append([i.key] + i.value)
        }
        self.value = value
    }
    
    init(_ matrix: [[String]] = []) {
        if !matrix.isEmpty {
            self.titles = matrix[0]
        } else {
            self.titles = []
        }
        if matrix.count >= 2 {
            self.value = Array(matrix[1..<matrix.count])
        } else {
            self.value = []
        }
    }
    
    init(contentsOfFile: String, hasTitle: Bool) throws {
        let contents: String = try String(contentsOfFile: contentsOfFile)
        
        var matrix = contents.components(separatedBy: "\n").map({ $0.components(separatedBy: ",") })
        if matrix.last! == [] || matrix.last! == [""] {
            matrix.removeLast()
        }
        if hasTitle {
            self.titles = matrix[0]
            self.value = Array(matrix[1..<matrix.count])
        } else {
            self.titles = []
            self.value = matrix
        }
    }
    
    
    //MARK: - Instance Methods
    
    /// Append a column to the table.
    ///
    /// - precondition: The number of items in the column should be equal to the number of rows in the table.
    mutating func addColumn(_ column: [String]) {
        precondition(column.count == matrix.count)
        if titles.isEmpty {
            for i in 0..<column.count {
                value[i].append(column[i])
            }
        } else {
            titles.append(column[0])
            for i in 1..<column.count {
                value[i-1].append(column[i])
            }
        }
    }
    
    /// Append a row to the table.
    mutating func addRow(_ row: [String]) {
        self.append(row)
    }
    
    /// Append a row to the table.
    mutating func append(_ row: [String]) {
        self.value.append(row)
    }
    
    /// The column at the given index.
    func column(at index: Int) -> [String] {
        return self.transposed().row(at: index)
    }
    
    /// The columns at the given range.
    func column(at indexes: ClosedRange<Int>) -> [[String]] {
        return self.transposed().rows(at: indexes)
    }
    
    /// The columns at the given range.
    func column(at indexes: Range<Int>) -> [[String]] {
        return self.transposed().rows(at: indexes)
    }
    
    /// The index of column.
    func firstIndex(ofColumn column: [String]) -> Int? {
        return self.transposed().matrix.firstIndex(of: column)
    }
    
    /// The indexes of column.
    func firstIndex(ofColumns columns: [[String]]) -> Range<Int>? {
        return self.transposed().matrix.firstIndex(of: columns)
    }
    
    /// The index of column.
    func firstIndex(ofRow row: [String]) -> Int? {
        return self.matrix.firstIndex(of: row)
    }
    
    /// The indexes of column.
    func firstIndex(ofRows rows: [[String]]) -> Range<Int>? {
        return self.matrix.firstIndex(of: rows)
    }
    
    /// Inserts a new column at the specified position.
    ///
    /// - precondition: The number of items in the column should be equal to the number of rows in the table.
    mutating func insertColumn(_ column: [String], at index: Int) {
        precondition(column.count == matrix.count)
        if titles.isEmpty {
            for i in 0..<column.count {
                value[i].insert(column[i], at: index)
            }
        } else {
            titles.append(column[0])
            for i in 1..<column.count {
                value[i-1].insert(column[i], at: index)
            }
        }
    }
    
    /// Inserts a new row at the specified position.
    mutating func insertRow(_ row: [String], at index: Int) {
        self.value.insert(row, at: index)
    }
    
    /// The item at the given coordinate.
    func item(at coordinate: (x: Int, y: Int)) -> String {
        return self.matrix[coordinate.y][coordinate.x]
    }
    
    /// Print the table.
    @discardableResult func print() -> String {
        return printMatrix(matrix: self.matrix)
    }
    
    /// The row at the given index.
    func row(at index: Int) -> [String] {
        return Array(self.matrix[index])
    }
    
    /// The rows at the given indexes.
    func rows(at indexes: ClosedRange<Int>) -> [[String]] {
        return Array(self.matrix[indexes])
    }
    
    /// The rows at the given indexes.
    func rows(at indexes: Range<Int>) -> [[String]] {
        return Array(self.matrix[indexes])
    }
    
    /// Transpose the table.
    func transposed() -> Table {
        var newMatrix: [[String]] = [[String]](repeating: [String](repeating: "", count: matrix.count), count: matrix.first!.count)
        for i in 0..<matrix.count {
            for ii in 0..<matrix.first!.count {
                newMatrix[ii][i] = matrix[i][ii].description
            }
        }
        return Table(newMatrix)
    }
    
    /// Write the table to path as csv.
    func write(to item: FinderItem) {
        let value = self.matrix.map({ String($0.reduce("", { $0 + "," + $1 }).dropFirst()) }).reduce("", { $0 + "\n" + $1 }).dropFirst()
        
        do {
            try value.write(to: item.url, atomically: true, encoding: .utf8)
        } catch {
            Swift.print("table.write(to:) failed with error: \(error)")
        }
    }
    
    /// Write the table to path as csv.
    func write(to path: String) {
        self.write(to: FinderItem(at: path))
    }
    
    
    //MARK: - Type Methods
    
    
    
    //MARK: - Operator Methods
    
    
    
    //MARK: - Comparison Methods
    
    static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        return lhs.matrix == rhs.matrix
    }
    
    
    
    //MARK: - Substructures
    
    
    
    //MARK: - Subscript
    
    subscript(index: Int) -> [String] {
        return self.matrix[index]
    }
    
    subscript(range: Range<Int>) -> [[String]] {
        return Array(self.matrix[range])
    }
    
    subscript(range: ClosedRange<Int>) -> [[String]] {
        return Array(self.matrix[range])
    }
    
}
