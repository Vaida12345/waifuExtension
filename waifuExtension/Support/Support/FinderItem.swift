//
//  FinderItem.swift
//
//
//  Created by Vaida on 9/18/21.
//  Copyright © 2022 Vaida. All rights reserved.
//

import AVFoundation
import Cocoa
import Foundation

struct FinderItem: Codable, Copyable, CustomStringConvertible, Equatable, Hashable, Identifiable {
    
    //MARK: - Basic Properties
    
    /// The absolute path.
    var path: String
    
    /// The path relative.
    var relativePath: String? = nil
    
    
    //MARK: - Instance Properties
    
    /// Returns the files that are inside this folder, or its subfolders.
    var allChildren: [FinderItem]? {
        guard let items = FileManager.default.enumerator(atPath: self.path)?.allObjects as? [String] else { return nil }
        return items.sorted { $0.compare($1, options: .numeric) == .orderedAscending }.map { i in
            var item = FinderItem(at: self.path + "/" + i)
            item.relativePath = item.relativePath(to: self)
            return item
        }
    }
    
    /// Returns the audio / video asset at the path, if exists.
    var avAsset: AVAsset? {
        guard AVAsset(url: self.url).isReadable else { return nil }
        return AVAsset(url: self.url)
    }
    
    /// Returns the files that are **strictly** inside this folder.
    ///
    /// The files that are only inside this folder, not its subfolders.
    ///
    /// - Note: `children` are sorted by name.
    var children: [FinderItem]? {
        guard let paths = self.findFiles() else { return nil }
        return paths.sorted { $0.compare($1, options: .numeric) == .orderedAscending }.map({
            FinderItem(at: self.path + "/" + $0)
        })
    }
    
    /// Returns the description of the `FinderItem`.
    ///
    /// In the form of `FinderItem<\(self.path)>`.
    var description: String {
        "FinderItem<\(self.path)>"
    }
    
    /// The extension name of the file.
    ///
    /// calculus.pdf -> .pdf
    var extensionName: String {
        get {
            guard self.name.contains(".") else { return "" }
            return String(self.name[self.name.lastIndex(of: ".")!..<self.name.endIndex])
        }
        set {
            try! self.renamed(with: self.fileName + newValue)
        }
    }
    
    /// The file name of the file.
    ///
    /// calculus.pdf -> calculus
    var fileName: String {
        get {
            if self.name.contains(".") {
                return String(self.name[..<self.name.lastIndex(of: ".")!])
            } else {
                return self.name
            }
        }
        set {
            try! self.renamed(with: newValue + self.extensionName)
        }
    }
    
    /// Returns the total displayable size of the file in bytes (this may include space used by metadata).
    ///
    /// Use `.expressAsFileSize()` to express as file size.
    ///
    /// - Attention: The return value is `nil` if the file does not exist.
    var fileSize: Int? {
        if self.isDirectory {
            return self.children!.reduce(0, { $0 + ($1.fileSize ?? 0) })
        } else {
            return try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        }
    }
    
    /// Determines whether there are files in this folder.
    ///
    /// The return value is `nil` if the files doesn't exist.
    var hasChildren: Bool {
        self.findFiles() != nil && !self.findFiles()!.isEmpty
    }
    
    /// Determines whether this folder has subfolder.
    var hasSubfolder: Bool {
        !(children?.allSatisfy({ $0.isFile }) ?? true)
    }
    
    /// The icon of the file.
    ///
    /// The return value is `nil` if the files doesn't exist, or, there is no tiff representation behind.
    var icon: NSImage? {
        get {
            guard self.isExistence else { return nil }
            let icon = NSWorkspace.shared.icon(forFile: self.path)
            guard icon.tiffRepresentation != nil else { return nil }
            return icon
        }
        set {
            guard let newValue = newValue else { return }
            self.setIcon(image: newValue)
        }
    }
    
    var id: UUID
    
    /// Returns the image at the path, if exists.
    var image: NSImage? {
        get {
            guard self.isExistence else { return nil }
            return NSImage(contentsOfFile: self.path)
        }
        set {
            guard let newValue = newValue else { return }
            if self.isExistence { try! self.removeFile() }
            newValue.write(to: self.path)
        }
    }
    
    /// Determines whether the file exists at the required position.
    var isExistence: Bool {
        FileManager.default.fileExists(atPath: self.path)
    }
    
    /// Returns the `NSItemProvider` at the `url`, if exists.
    var itemProvider: NSItemProvider? {
        NSItemProvider(contentsOf: self.url)
    }
    
    /// Determines whether a `item` is a directory (instead of file).
    ///
    /// The return value is `false` if the files doesn't exist.
    var isDirectory: Bool {
        guard let value = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else { return false }
        return value
    }
    
    /// Determines whether a `item` is a file (instead of directory).
    ///
    /// The return value is `false` if the files doesn't exist.
    var isFile: Bool {
        guard let value = try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile else { return false }
        return value
    }
    
    /// The full name of the file.
    var name: String {
        get {
            return (try? url.resourceValues(forKeys: [.nameKey]).name) ?? self.pathArray.last ?? self.path
        }
        set {
            try! self.renamed(with: newValue)
        }
    }
    
    /// Returns the absolute path, separated into `String` array.
    var pathArray: [String] {
        path.split(separator: "/").map({ String($0) })
    }
    
    /// Returns the path to run in shell.
    var shellPath: String {
        self.path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: " ", with: "\\ ")
            .replacingOccurrences(of: "(", with: "\\(")
            .replacingOccurrences(of: ")", with: "\\)")
            .replacingOccurrences(of: "[", with: "\\[")
            .replacingOccurrences(of: "]", with: "\\]")
            .replacingOccurrences(of: "{", with: "\\{")
            .replacingOccurrences(of: "}", with: "\\}")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "~", with: "\\~")
            .replacingOccurrences(of: "!", with: "\\!")
            .replacingOccurrences(of: "@", with: "\\@")
            .replacingOccurrences(of: "#", with: "\\#")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "&", with: "\\&")
            .replacingOccurrences(of: "*", with: "\\*")
            .replacingOccurrences(of: "=", with: "\\=")
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\'", with: "\\\'")
            .replacingOccurrences(of: "<", with: "\\<")
            .replacingOccurrences(of: ">", with: "\\>")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "?", with: "\\?")
    }
    
    /// Returns the text at the path, if exists.
    var text: String? {
        get {
            guard self.isExistence else { return nil }
            return try? String(contentsOf: self.url)
        }
        set {
            guard let newValue = newValue else { return }
            if self.isExistence { try! self.removeFile() }
            try! newValue.write(to: self.url, atomically: true, encoding: .utf8)
        }
    }
    
    /// The `UTType` of the file.
    var type: UTType? {
        try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
    }
    
    /// Returns the url of the path.
    var url: URL {
        get { return URL(fileURLWithPath: self.path) }
        set { self.path = newValue.path }
    }
    
    
    //MARK: - Initializers
    
    /// Creates an instance with an absolute path.
    ///
    /// - Parameters:
    ///    - path: The absolute path.
    init(at path: String) {
        self.path = path
        self.id = UUID()
    }
    
    /// Creates an instance with an absolute path.
    ///
    /// - Parameters:
    ///    - path: The absolute path.
    init(at path: Substring) {
        self.path = String(path)
        self.id = UUID()
    }
    
    /// Creates an instance with a url.
    ///
    /// - Parameters:
    ///    - url: The file url.
    init(at url: URL) {
        self.path = url.path
        self.id = UUID()
    }
    
    /// Creates an instance from itself.
    ///
    /// - Parameters:
    ///    - instance: The instance to initialize with.
    init(_ instance: FinderItem) {
        self.path = instance.path
        self.id = UUID()
    }
    
    /// Creates an instance with an absolute path.
    ///
    /// - Parameters:
    ///    - path: The absolute path.
    init?(at path: String?) {
        guard let path = path else { return nil }
        self.path = path
        self.id = UUID()
    }
    
    /// Creates an instance with an absolute path.
    ///
    /// - Parameters:
    ///    - path: The absolute path.
    init?(at path: Substring?) {
        guard let path = path else { return nil }
        self.path = String(path)
        self.id = UUID()
    }
    
    /// Creates an instance with a url.
    ///
    /// - Parameters:
    ///    - url: The file url.
    init?(at url: URL?) {
        guard let url = url else { return nil }
        self.path = url.path
        self.id = UUID()
    }
    
    /// Creates an instance from itself.
    ///
    /// - Parameters:
    ///    - instance: The instance to initialize with.
    init?(_ instance: FinderItem?) {
        guard let instance = instance else { return nil }
        self.path = instance.path
        self.id = UUID()
    }
    
    
    //MARK: - Instance Methods
    
    /// Copies the current item to the `path`.
    ///
    /// - Note: It creates the folder at the copied item path.
    ///
    /// - Parameters:
    ///    - path: The absolute path of the copied item.
    func copy(to path: String) throws {
        if self.isFile {
            try FinderItem(at: path).generateDirectory()
        } else if self.isDirectory {
            try FinderItem(at: self.pathArray.dropLast().reduce("", { $0 + "/" + $1 })).generateDirectory(isFolder: true)
        }
        try FileManager.default.copyItem(at: self.url, to: URL(fileURLWithPath: path))
    }
    
    /// Finds files that are **Strictly** instead this folder.
    ///
    /// - Important: The paths are relative paths.
    ///
    /// - Note: This method ignores `.DS_Store`.
    ///
    /// - Attention: The return value is `nil` if the file doesn't exist or it is not a folder.
    ///
    /// - Returns: Files that are only contained in the folder, not its subfolders; `nil` otherwise.
    private func findFiles() -> [String]? {
        guard self.isDirectory && self.isExistence else { return nil }
        guard let allFiles = FileManager.default.enumerator(atPath: self.path)?.allObjects as? [String] else { return nil }
        return allFiles.filter({ !$0.contains(".DS_Store") })
            .filter({ !$0.contains("Icon\r") })
            .filter({ !$0.contains("/") })
    }
    
    /// Hashes the essential components of this value by feeding them into the given hasher.
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.path)
        hasher.combine(self.relativePath)
    }
    
    /// Generates the desired folders at the path.
    ///
    /// - Note: This function also generates all the folders containing the final folder.
    ///
    /// - Parameters:
    ///    - isFolder: Determines whether the `FinderItem` path is a folder. Required only if the folder name contains ".".
    func generateDirectory(isFolder: Bool = false) throws {
        var folders = self.pathArray
        if !isFolder && folders.last!.contains(".") { folders.removeLast() }
        
        var i = 0
        while i + 1 < folders.count {
            i += 1
            
            let path = folders[0...i].reduce("", { $0 + "/" + $1 })
            if !FileManager.default.fileExists(atPath: path, isDirectory: nil) {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }
    
    /// Generates the absolute path with an absolute path provided.
    ///
    /// - Note: This method was designed to fit the situation when there are multiple files of the same name at a location.
    ///
    /// - Returns: A path adjusted when there has already been a file there with the same name.
    func generateOutputPath() -> String {
        do {
            try self.generateDirectory()
        } catch {
            
        }
        
        if !self.isExistence {
            return path
        } else {
            if self.name.contains(".") {
                var counter = 2
                let filePathWithoutExtension = self.extensionName
                let fileExtension = self.extensionName
                while FileManager.default.fileExists(atPath: "\(filePathWithoutExtension) \(counter)\(fileExtension)") { counter += 1 }
                
                return "\(filePathWithoutExtension) \(counter)\(fileExtension)"
            } else {
                var counter = 2
                while FileManager.default.fileExists(atPath: "\(self.pathArray.dropLast().reduce("", { $0 + "/" + $1 }))/\(self.fileName) \(counter)") { counter += 1 }
                
                return "\(self.pathArray.dropLast().reduce("", { $0 + "/" + $1 }))/\(self.fileName) \(counter)"
            }
        }
    }
    
    /// Iterates over items in a given folder.
    ///
    /// **Example**
    ///
    ///     iterated { child in
    ///
    ///     }
    ///
    /// - Remark: This function would iterate in the order of the file, the folder containing the file, the folder containing the folder, ...
    ///
    /// - Note: This function would ignore the folder item of `".DS_Store"`.
    ///
    /// - Parameters:
    ///     - action: The action to be done to each item in the folder.
    func iterated(_ action: ((_ child: FinderItem) -> Void)) {
        
        guard self.isExistence && self.isDirectory else { return }
        guard let children = self.children else { return }
        
        var index = 0
        while index < children.count {
            autoreleasepool {
                let child = children[index]
                if child.isDirectory { child.iterated(action) }
                autoreleasepool {
                    action(child)
                }
            }
            index += 1
        }
    }
    
    /// Opens the current file.
    func open() {
        NSWorkspace.shared.open(self.url)
    }
    
    /// Returns the relative path to other item.
    ///
    /// - Attention: The return value is `nil` if current item is not in the folder of `item`.
    ///
    /// - Parameters:
    ///    - item: A folder that hoped to contain current item.
    ///
    /// - Returns: The relative path to other item; `nil` otherwise.
    func relativePath(to item: FinderItem) -> String? {
        guard self.path.contains(item.path) else { return nil }
        var path = self.path.replacingOccurrences(of: item.path, with: "")
        if path.first == "/" { path.removeFirst() }
        return path
    }
    
    /// Remove the file.
    func removeFile() throws {
        try FileManager.default.removeItem(atPath: self.path)
    }
    
    /// Renames the file.
    ///
    /// This method changes the `path`.
    ///
    /// - Parameters:
    ///     - newName: The name for the file.
    mutating func renamed(with newName: String) throws {
        var value = URLResourceValues()
        value.name = newName
        try self.url.setResourceValues(value)
    }
    
    /// Renames the file by replacing occurrence.
    ///
    /// - Parameters:
    ///    - target: The target to be replaced.
    ///    - replacement: The replacement used to replace the target.
    mutating func renamed(byReplacingOccurrenceOf target: String, with replacement: String) throws {
        try self.renamed(with: self.name.replacingOccurrences(of: target, with: replacement))
    }
    
    /// Saves an image as .png.
    ///
    /// This method changes the `path`.
    mutating func saveToPNG(forceSquare: Bool = false) throws {
        guard let image = self.image else { throw NSError(domain: "No image found at path \(self.path)", code: -1, userInfo: ["path": self.path]) }
        if self.extensionName.lowercased() == ".png" {
            if forceSquare {
                try self.removeFile()
                image.embedInSquare()!.write(to: self.path)
            } else {
                return
            }
        }
        let extensionName = self.extensionName
        try self.removeFile()
        let imageData = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
        self.path = self.path.replacingOccurrences(of: extensionName, with: ".png")
        if forceSquare {
            NSImage(data: imageData)!.embedInSquare()!.write(to: self.path)
        } else {
            try imageData.write(to: self.url)
        }
    }
    
    /// Set an image as icon.
    func setIcon(image: NSImage) {
        guard self.isExistence else { return }
        NSWorkspace.shared.setIcon(image, forFile: self.path, options: .init())
    }
    
    /// Reveals the current file in finder.
    func revealInFinder() {
        if self.isDirectory {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    
    
    //MARK: - Comparing two instances
    
    /// Determines whether the `lhs` and `rhs` are equal.
    static func == (lhs: FinderItem, rhs: FinderItem) -> Bool {
        return lhs.path == rhs.path
    }
    
    
    //MARK: - Type Methods
    
    /// Decode a file from `path` to the expected `type`.
    static func loadJSON<T>(from path: String, type: T.Type) throws -> T where T: Decodable {
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try decoder.decode(T.self, from: data)
    }
    
    /// Encode a file with json and save to `path`.
    static func saveJSON<T>(_ file: T, to path: String) throws where T: Encodable {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(file)
        guard let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { throw NSError.init(domain: "String Coding", code: 0, userInfo: nil) }
        try string.write(to: URL(fileURLWithPath: path), atomically: true, encoding: String.Encoding.utf8.rawValue)
    }
    
}


extension Array where Element == FinderItem {
    
    /// Reveals the files in finder.
    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting(self.map({ $0.url }))
    }
    
    /// Append the file or its children to the array which satisfies `condition`.
    mutating func append(from url: URL, condition: (_ item: FinderItem) -> Bool) {
        let item = FinderItem(at: url)
        if item.isDirectory {
            self.append(contentsOf: item.allChildren!.filter({ condition($0) }))
        } else {
            guard condition(item) else { return }
            self.append(item)
        }
    }
    
    /// Append the files or their children to the array which satisfies `condition`.
    mutating func append(from urls: [URL], condition: (_ item: FinderItem) -> Bool) {
        var index = 0
        while index < urls.count {
            self.append(from: urls[index], condition: condition)
            
            index += 1
        }
    }
    
    /// Append the files or their children in the provider to the array which satisfies `condition`.
    mutating func append(from provider: NSItemProvider, condition: (_ item: FinderItem) -> Bool) async {
        guard let result = try? await provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) else { return }
        guard let urlData = result as? Data else { return }
        guard let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
        
        self.append(from: url, condition: condition)
    }
    
    /// Append the files or their children in providers to the array which satisfies `condition`.
    mutating func append(from providers: [NSItemProvider], condition: (_ item: FinderItem) -> Bool) async {
        var index = 0
        while index < providers.count {
            await self.append(from: providers[index], condition: condition)
            
            index += 1
        }
    }
    
}


extension CMTime {
    
    /// Creates an instance with a `Double`.
    ///
    /// - Parameters:
    ///     - content: The content to initialize with.
    init(_ value: Double) {
        let value = value.rounded(toDigit: 3).fraction()
        self = CMTimeMake(value: Int64(value.numerator), timescale: Int32(value.denominator))
    }
    
}


extension AVAsset {
    
    /// The audio track of the video file.
    var audioTrack: AVAssetTrack? {
        return self.tracks(withMediaType: AVMediaType.audio).first
    }
    
    /// Returns the first frame rate of the video.
    ///
    /// - Attention: The return value is `nil` if the file doesn't exist or not a video.
    var firstFrame: NSImage? {
        let asset = self
        let vidLength: CMTime = asset.duration
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        let time: CMTime = CMTimeMake(value: Int64(0), timescale: vidLength.timescale)
        guard let ref = try? imageGenerator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return NSImage(cgImage: ref, size: NSSize(width: ref.width, height: ref.height))
    }
    
    /// Returns all the frames of the video.
    ///
    /// - Attention: The return value is `nil` if the file does not exist, or `avAsset` not found.
    var frames: [NSImage]? {
        let asset = self
        let vidLength: CMTime = asset.duration
        let seconds: Double = CMTimeGetSeconds(vidLength)
        let frameRate = Double(asset.tracks(withMediaType: .video).first!.nominalFrameRate)
        
        var requiredFramesCount = Int(seconds * frameRate)
        
        if requiredFramesCount == 0 {
            requiredFramesCount = 1
        }
        
        let step = Int((vidLength.value / Int64(requiredFramesCount)))
        var value: Int = 0
        
        var counter = 0
        var images: [NSImage] = []
        
        while counter < requiredFramesCount {
            autoreleasepool {
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.requestedTimeToleranceAfter = CMTime.zero
                imageGenerator.requestedTimeToleranceBefore = CMTime.zero
                let time: CMTime = CMTimeMake(value: Int64(value), timescale: vidLength.timescale)
                var imageRef: CGImage?
                do {
                    imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                } catch {
                    print(error)
                }
                guard let ref = imageRef else { return }
                let thumbnail = NSImage(cgImage: ref, size: NSSize(width: ref.width, height: ref.height))
                
                images.append(thumbnail)
                
                value += Int(step)
                counter += 1
            }
        }
        
        return images
    }
    
    var frameRate: Float? {
        guard let value = self.tracks(withMediaType: .video).first else { return nil }
        return value.nominalFrameRate
    }
    
    /// The audio track of the video file
    var videoTrack: AVAssetTrack? {
        return self.tracks(withMediaType: AVMediaType.video).first
    }
}
