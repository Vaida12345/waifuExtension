//
//  FinderItem.swift
//  
//
//  Created by Vaida on 9/18/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation
import PDFKit
import Cocoa

class FinderItem: CustomStringConvertible {
    
    
    //MARK: - Basic Properties
    
    /// The absolute path.
    var path: String
    
    var parent: FinderItem? = nil
    
    
    //MARK: - Instance Properties
    
    /// The files that are **strictly** instead this folder.
    ///
    /// The files that are only inside this folder, not its subfolders.
    var children: [FinderItem]? {
        guard let children = self.rawChildren else { return nil }
        return children.sorted(by: {
            let digitWidth = 20
            
            var lhs = [Character]($0.rawPath)
            var rhs = [Character]($1.rawPath)
            
            for i in $0.rawPath.extractDigits().indexes { for _ in 0...(digitWidth - i.count) { lhs.insert("0", at: i.first!) } }
            for i in $1.rawPath.extractDigits().indexes { for _ in 0...(digitWidth - i.count) { rhs.insert("0", at: i.first!) } }
            
            return String(lhs) < String(rhs)
        })
    }
    
    var description: String {
        return "FinderItem<\(self.path)>"
    }
    
    /// The extension name of the file.
    ///
    /// calculus.pdf -> .pdf
    var extensionName: String? {
        guard self.isFile else { return nil }
        guard self.rawPath.contains(".") else { return nil }
        return String(self.rawPath[self.rawPath.lastIndex(of: ".")!..<self.rawPath.endIndex])
    }
    
    /// The file name of the file.
    var fileName: String? {
        guard let value = try? url.resourceValues(forKeys: [.nameKey]).name else { return nil }
        if value.contains(".") {
            return String(value[..<value.lastIndex(of: ".")!])
        } else {
            return value
        }
    }
    
    /// Determines whether there are files in this folder.
    var hasChildren: Bool {
        guard let rawChildren = self.rawChildren else { return false }
        return !rawChildren.isEmpty
    }
    
    /// Determines whether this folder has subfolder.
    var hasSubfolder: Bool {
        guard let rawChildren = self.rawChildren else { return false }
        for i in rawChildren {
            if i.isDirectory { return true }
        }
        return false
    }
    
    /// The image at the path, if exists.
    var image: NSImage? {
        guard self.isExistence else { return nil }
        return NSImage(contentsOfFile: self.path)
    }
    
    /// Determine whether the file exists at the required position.
    var isExistence: Bool {
        return FileManager.default.fileExists(atPath: self.path)
    }
    
    /// Determines whether a `item` is a directory (instead of file).
    ///
    /// aka, `isFolder`
    var isDirectory: Bool {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: self.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
    
    /// Determines whether a `item` is a file (instead of directory).
    var isFile: Bool {
        !self.isDirectory
    }
    
    /// The absolute path, separated into `String` array.
    var pathArray: [String] {
        return path.split(separator: "/").map({ String($0) })
    }
    
    /// The individual path.
    ///
    /// /Study/Calculus/Materials -> Materials
    private var rawPath: String {
        return self.pathArray.last!
    }
    
    /// The files that are **strictly** instead this file.
    ///
    /// This property does not sort the children, however, please use this to save time.
    private var rawChildren: [FinderItem]? {
        guard let paths = self.findFiles() else { return nil }
        return paths.map({
            let item = FinderItem(at: self.path + "/" + $0)
            item.parent = self
            return item
        })
    }
    
    /// The url of the path.
    var url: URL {
        return URL(fileURLWithPath: self.path)
    }
    
    
    //MARK: - Initializers
    
    init(at path: String) {
        self.path = path
    }
    
    
    //MARK: - Instance Methods
    
    /// Copy the current item to the `path`.
    func copy(to path: String) throws {
        FinderItem(at: path).generateDirectory()
        try FileManager.default.copyItem(at: self.url, to: URL(fileURLWithPath: path))
    }
    
    /// Finds files that are **Strictly** instead this folder.
    ///
    /// - Important: The paths are relative paths.
    ///
    /// - Note: This method ignores `.DS_Store`
    ///
    /// - Returns: Files that are only contained in the folder, not its subfolders.
    private func findFiles() -> [String]? {
        guard self.isDirectory && self.isExistence else { return nil }
        guard var allFiles = FileManager.default.enumerator(atPath: self.path)?.allObjects as? [String] else { return nil }
        allFiles = allFiles.filter({ !$0.contains(".DS_Store") })
        allFiles = allFiles.filter({ !$0.contains("Icon\r") })
        allFiles = allFiles.filter({ !$0.contains("/") })
        return allFiles
    }
    
    /// Generates the desired folders at the path.
    ///
    /// - Precondition: The `path` needs to be begin with `/Users/vaida/`.
    ///
    /// - Note: This function also generates all the folders containing the final folder.
    func generateDirectory() {
        precondition(self.path.contains("/Users/vaida/"))
        var folders = self.pathArray
        if folders.last!.contains(".") { folders.removeLast() }
        
        for i in 1..<folders.count {
            let path = folders[0...i].reduce("", { $0 + "/" + $1 })
            if !FileManager.default.fileExists(atPath: path, isDirectory: nil) {
                try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }
    
    /// Generates the absolute path with an absolute path provided.
    ///
    /// - Note: This method was designed to fit the situation when there are multiple files of the same name at a location.
    ///
    /// - Returns: A path adjusted when there has already been a file there with the same name.
    func generateOutputPath() -> String {
        self.generateDirectory()
        
        if !self.isExistence {
            return path
        } else {
            var counter = 2
            let filePathWithoutExtension = path[..<(path.lastIndex(of: ".") ?? path.endIndex)]
            let fileExtension = self.extensionName ?? ""
            while FileManager.default.fileExists(atPath: "\(filePathWithoutExtension) \(counter)\(fileExtension)") { counter += 1 }
            
            return "\(filePathWithoutExtension) \(counter)\(fileExtension)"
        }
    }
    
    /// Iterates over items in a given folder.
    ///
    /// **Example**
    ///
    ///     iteratedOver { relativePath, absolutePath in
    ///         absolutePath
    ///     }
    ///
    /// - Important: `$0` in `action`: The relative path of each entry.  `$1 `in `action`: The absolute path of each entry.
    ///
    /// - Precondition: The path needs to exist; fatal error otherwise.
    ///
    /// - Remark: This function would iterate in the order of the file, the folder containing the file, the folder containing the folder, ...
    ///
    /// - Note: This function would ignore the folder item of `".DS_Store"`.
    ///
    /// - Parameters:
    ///     - action: The action to be done to each item in the folder.
    func iteratedOver(_ action: ((_ child: FinderItem) -> Void)) {
        
        precondition(self.isExistence)
        guard self.isDirectory else { return }
        
        guard let children = self.children else { return }
        for i in children {
            if i.isDirectory { i.iteratedOver(action) }
            action(i)
        }
    }
    
    /// Open the current file.
    func open() {
        _ = shell(["open \(self.path.replacingOccurrences(of: " ", with: "\\ "))"])
    }
    
    /// The relative path to other item.
    func relativePath(to item: FinderItem) -> String? {
        guard self.path.contains(item.path) else { return nil }
        var path = self.path.replacingOccurrences(of: item.path, with: "")
        path.removeFirst()
        return path
    }
    
    /// Remove the file.
    func removeFile() throws {
        try FileManager.default.removeItem(atPath: self.path)
    }
    
    /// Rename the file.
    ///
    /// - Parameters:
    ///     - newName: The name for the file.
    func renamed(with newName: String) {
        precondition(self.isExistence)
        var value = URLResourceValues()
        value.name = newName
        var url = self.url
        try! url.setResourceValues(value)
    }
    
    /// Rename the file by replacing occurrence.
    func renamed(byReplacingOccurrenceOf occurrence: String, with replacement: String) {
        guard var fileName = fileName else { return }
        fileName = fileName.replacingOccurrences(of: occurrence, with: replacement)
        self.renamed(with: fileName)
    }
    
    /// Save an image as .png
    ///
    /// This method would delete the original file.
    func saveToPNG() throws {
        if self.extensionName?.lowercased() == ".png" { return }
        guard let image = self.image else { throw NSError(domain: "No image found at path \(self.path)", code: -1, userInfo: ["path": self.path]) }
        try self.removeFile()
        let imageData = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
        self.path = self.path.replacingOccurrences(of: self.extensionName!, with: ".png")
        try imageData.write(to: self.url)
    }
    
    
    //MARK: - Type Methods
    
    /// Creates icon at the `folderPath`.
    static func createIcon(at file: FinderItem) {
        file.iteratedOver { child in
            guard child.isFile else { return }
            let child = child
            guard (try? child.saveToPNG()) != nil else { return }
            guard child.extensionName != nil else { return }
            let absolutePath = child.path
            
            let file = absolutePath.split(separator: "/").last!.replacingOccurrences(of: " ", with: "\\ ")
            let fileName = file[file.startIndex..<file.lastIndex(of: ".")!]
            let path2 = absolutePath.replacingOccurrences(of: " ", with: "\\ ")
            
            _ = shell([
            """
            cd \(path2[path2.startIndex..<path2.lastIndex(of: "/")!])
            mkdir tmp.iconset
            
            sips -z 16 16       \(file) --out tmp.iconset/icon_16x16.png
            sips -z 32 32       \(file) --out tmp.iconset/icon_16x16@2x.png
            sips -z 32 32       \(file) --out tmp.iconset/icon_32x32.png
            sips -z 64 64       \(file) --out tmp.iconset/icon_32x32@2x.png
            sips -z 64 64       \(file) --out tmp.iconset/icon_64x64.png
            sips -z 128 128     \(file) --out tmp.iconset/icon_64x64@2x.png
            sips -z 128 128     \(file) --out tmp.iconset/icon_128x128.png
            sips -z 256 256     \(file) --out tmp.iconset/icon_128x128@2x.png
            sips -z 256 256     \(file) --out tmp.iconset/icon_256x256.png
            sips -z 512 512     \(file) --out tmp.iconset/icon_256x256@2x.png
            sips -z 512 512     \(file) --out tmp.iconset/icon_512x512.png
            sips -z 1024 1024   \(file) --out tmp.iconset/icon_512x512@2x.png
            sips -z 1024 1024   \(file) --out tmp.iconset/icon_1024x1024.png
            
            iconutil -c icns tmp.iconset -o \(fileName).icns
            rm -rf tmp.iconset
            """
            ])
        }
    }
    
    /// Creates PDF from images in folders.
    static func createPDF(fromFolder folder: FinderItem, outputPath: String = "/Users/vaida/Downloads/PDF output") {
        
        precondition(folder.isExistence)
        precondition(folder.hasChildren)
        
        if folder.hasSubfolder {
            for i in folder.children! {
                if i.isDirectory && i.hasChildren {
                    createPDF(fromFolder: i, outputPath: outputPath)
                }
            }
        }
        
        // create PDF
        let document = PDFDocument()
        print("create PDF:", folder.fileName ?? "")
        folder.iteratedOver { child in
            guard child.isFile else { return }
            let absolutePath = child.path
            
            guard let image = NSImage(contentsOfFile: absolutePath) else { return }
            let imageWidth = 1080.0
            let imageRef = image.representations.first!
            let frame = NSSize(width: imageWidth, height: imageWidth/Double(imageRef.pixelsWide)*Double(imageRef.pixelsHigh))
            image.size = CGSize(width: imageWidth, height: imageWidth / Double(imageRef.pixelsWide)*Double(imageRef.pixelsHigh))

            let page = PDFPage(image: image)!
            page.setBounds(NSRect(origin: CGPoint.zero, size: frame), for: .mediaBox)
            document.insert(page, at: document.pageCount)
        }
        
        guard document.pageCount != 0  else { return }
        
        let pastePath = outputPath + "/" + folder.fileName! + ".pdf"
        document.write(toFile: FinderItem(at: pastePath).generateOutputPath())
        
    }
    
    /// Decode a file from `path` to the expected `type`.
    static func loadJSON<T>(from path: String, type: T.Type) throws -> T where T: Decodable {
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try decoder.decode(T.self, from: data)
    }
    
    /// Put all files in different folders into one folder.
    static func putFilesToOneFolder(from folder: FinderItem) {
        folder.iteratedOver { child in
            guard child.isFile else { return }
            let newPath = child.relativePath(to: folder)!.replacingOccurrences(of: "/", with: " - ")
            let pastePath = folder.path + "/" + newPath
            try! child.copy(to: FinderItem(at: pastePath).generateOutputPath())
        }
    }
    
    /// Puts all files into different folders.
    ///
    /// - Remark: This function would try to find patterns of the similarity of the names of different files.
    ///
    /// - Parameters:
    ///     - folderSplitter: The keyword indicating it belongs to a different group. If you what the function to find pattern, pass it `nil`.
    ///     - folderPath: The absolute path of the folder containing the files.
    ///     - organizeThreshold: Organize files into one folder only if the number of item exceeds this number.
    ///     - organize: A boolean indicating whether you wish to put these files into different folders as far as possible.
    ///     - ignoringKeywords: Will not put the files which ends with these keywords into separate folders.
    static func putFilesToDifferentFolders(from folder: FinderItem, folderSplitter: String = " - ", organize: Bool = false, organizeThreshold: Int = 10, ignoringKeywords: [String] = []) {
        
        guard let children = folder.children else { return }
        for i in children {
            let pastePath = folder.path + "/" + i.rawPath.replacingOccurrences(of: folderSplitter, with: "/")
            
            let path = FinderItem(at: pastePath).generateOutputPath()
            try! i.copy(to: path)
            try! i.removeFile()
        }
        
        guard organize else { return }
        guard let children = folder.children else { return }
        var folders: [String: Int] = [:]
        
        let separator: (Character) -> Bool = { value in
            value == "-" || value == "[" || value == "]" || value == " " || value == "_"
        }
        
        for i in children {
            let value = String(i.fileName!.split(whereSeparator: separator).first!)
            if !folders.keys.contains(value) {
                folders[value] = 1
            } else {
                folders[value]! += 1
            }
        }
        
        let keys = folders.filter({ $0.value >= organizeThreshold }).keys
        for i in children {
            let value = String(i.fileName!.split(whereSeparator: separator).first!)
            guard keys.contains(value) else { continue }
            
            var pastePath = i.rawPath.replacingOccurrences(of: value, with: "")
            if separator(pastePath.first!) { pastePath.removeFirst() }
            
            let path = folder.path + "/" + value + "/" + pastePath
            try! i.copy(to: path)
            try! i.removeFile()
        }
    }
    
    /// Encode a file with json and save to `path`.
    static func saveJSON<T>(_ file: T, to path: String) throws where T: Encodable {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(file)
        guard let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { throw NSError.init(domain: "String Coding", code: 0, userInfo: nil) }
        try string.write(to: URL(fileURLWithPath: path), atomically: true, encoding: String.Encoding.utf8.rawValue)
    }
    
    /// Rename the file instead the BD-Res.
    static func renameBD(from item: FinderItem, additionalOccurrence: [String] = []) {
        let occurrences: [String] = ["24bit_96kHz"].union(additionalOccurrence).map({ "[" + $0 + "]" })
        item.iteratedOver { item in
            print(item)
            for i in occurrences {
                item.renamed(byReplacingOccurrenceOf: i, with: "")
                item.renamed(byReplacingOccurrenceOf: "  ", with: " ")
            }
        }
    }
}

