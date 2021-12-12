//
//  FinderItem.swift
//  
//
//  Created by Vaida on 9/18/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation
import PDFKit
import AppKit
import AVFoundation
import AVKit

class FinderItem: Codable, CustomStringConvertible, Equatable, Hashable, Identifiable {
    
    
    //MARK: - Basic Properties
    
    /// The absolute path.
    var path: String
    
    /// The context’s direct ancestor in the context hierarchy.
    var parent: FinderItem? = nil
    
    /// The path relative.
    var relativePath: String? = nil
    
    
    //MARK: - Instance Properties
    
    /// Returns the audio / video asset at the path, if exists.
    var avAsset: AVAsset? {
        guard AVAsset(url: self.url).isReadable else { return nil }
        return AVAsset(url: self.url)
    }
    
    /// Returns the audio track of the video file, if exists.
    var audioTrack: AVAssetTrack? {
        return self.avAsset?.tracks(withMediaType: AVMediaType.audio).first
    }
    
    /// Returns the files that are **strictly** instead this folder.
    ///
    /// The files that are only inside this folder, not its subfolders.
    ///
    /// - Note: `children` are sorted by name.
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
    
    /// Returns the description of the `FinderItem`.
    ///
    /// In the form of `FinderItem<\(self.path)>`.
    var description: String {
        return "FinderItem<\(self.path)>"
    }
    
    /// Returns the extension name of the file.
    ///
    /// calculus.pdf -> .pdf
    var extensionName: String {
        let value = (try? url.resourceValues(forKeys: [.nameKey]).name) ?? self.rawPath
        guard value.contains(".") else { return "" }
        return String(value[value.lastIndex(of: ".")!..<value.endIndex])
    }
    
    /// Returns the file name of the file.
    ///
    /// calculus.pdf -> calculus
    var fileName: String {
        let value = (try? url.resourceValues(forKeys: [.nameKey]).name) ?? self.rawPath
        if value.contains(".") {
            return String(value[..<value.lastIndex(of: ".")!])
        } else {
            return value
        }
    }
    
    /// Returns the total displayable size of the file in bytes (this may include space used by metadata).
    ///
    /// Use `.expressAsFileSize()` to express as file size.
    ///
    /// - Attention: The return value is `nil` if the file does not exist.
    var fileSize: Int? {
        guard let value = try? url.resourceValues(forKeys: [.totalFileSizeKey]).totalFileSize else { return nil }
        return value
    }
    
    /// Returns all the frames of the video.
    ///
    /// - Attention: The return value is `nil` if the file does not exist, or `avAsset` not found.
    var frames: [NSImage]? {
        guard let asset = self.avAsset else { return nil }
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
    
    /// Returns the frame rate of the video.
    ///
    /// - Attention: The return value is `nil` if the file doesn't exist or not a video.
    var frameRate: Float? {
        guard let value = self.avAsset?.tracks(withMediaType: .video).first else { return nil }
        return value.nominalFrameRate
    }
    
    /// Returns the first frame rate of the video.
    ///
    /// - Attention: The return value is `nil` if the file doesn't exist or not a video.
    var firstFrame: NSImage? {
        guard let asset = self.avAsset else { return nil }
        let vidLength: CMTime = asset.duration
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        let time: CMTime = CMTimeMake(value: Int64(0), timescale: vidLength.timescale)
        var imageRef: CGImage?
        do {
            imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        } catch {
            print(error)
        }
        guard let ref = imageRef else { return nil }
        return NSImage(cgImage: ref, size: NSSize(width: ref.width, height: ref.height))
    }
    
    /// Determines whether there are files in this folder.
    ///
    /// The return value is `nil` if the files doesn't exist.
    var hasChildren: Bool {
        guard let rawChildren = self.rawChildren else { return false }
        return !rawChildren.isEmpty
    }
    
    /// Determines whether this folder has subfolder.
    ///
    /// The return value is `nil` if the files doesn't exist.
    var hasSubfolder: Bool {
        guard let rawChildren = self.rawChildren else { return false }
        for i in rawChildren {
            if i.isDirectory { return true }
        }
        return false
    }
    
    /// Returns the icon of the file.
    ///
    /// The return value is `nil` if the files doesn't exist, or, there is no tiff representation behind.
    var icon: NSImage? {
        guard self.isExistence else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: self.path)
        guard icon.tiffRepresentation != nil else { return nil }
        return icon
    }
    
    /// Returns the image at the path, if exists.
    var image: NSImage? {
        guard self.isExistence else { return nil }
        return NSImage(contentsOfFile: self.path)
    }
    
    /// Determines whether the file exists at the required position.
    var isExistence: Bool {
        return FileManager.default.fileExists(atPath: self.path)
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
    
    /// Returns the absolute path, separated into `String` array.
    var pathArray: [String] {
        return path.split(separator: "/").map({ String($0) })
    }
    
    /// Returns the individual path.
    ///
    /// /Study/Calculus/Materials -> Materials
    var rawPath: String {
        return self.pathArray.last!
    }
    
    /// Returns the files that are **strictly** instead this file.
    ///
    /// This property does not sort the children, however, please use this to save time.
    var rawChildren: [FinderItem]? {
        guard let paths = self.findFiles() else { return nil }
        return paths.map({
            let item = FinderItem(at: self.path + "/" + $0)
            item.parent = self
            return item
        })
    }
    
    /// Returns the path to run in shell.
    var shellPath: String {
        return self.path.replacingOccurrences(of: "\\", with: "\\\\")
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
    
    /// Returns the url of the path.
    var url: URL {
        get { return URL(fileURLWithPath: self.path) }
        set { self.path = newValue.path }
    }
    
    /// Returns the audio track of the video file.
    ///
    /// - Attention: The return value is `nil` if the file doesn't exist or not a video.
    var videoTrack: AVAssetTrack? {
        return self.avAsset?.tracks(withMediaType: AVMediaType.video).first
    }
    
    
    //MARK: - Initializers
    
    /// Creates an instance with an absolute path.
    ///
    /// - Parameters:
    ///    - path: The absolute path.
    init(at path: String) {
        self.path = path
    }
    
    /// Creates an instance with an absolute path.
    ///
    /// - Parameters:
    ///    - path: The absolute path.
    init(at path: Substring) {
        self.path = String(path)
    }
    
    /// Creates an instance with a url.
    ///
    /// - Parameters:
    ///    - url: The file url.
    init(at url: URL) {
        self.path = url.path
    }
    
    //MARK: - Instance Methods
    
    /// Copies the current item to the `path`.
    ///
    /// - Note: It creates the folder at the copied item path.
    ///
    /// - Parameters:
    ///    - path: The absolute path of the copied item.
    func copy(to path: String) throws {
        FinderItem(at: path).generateDirectory()
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
        guard var allFiles = FileManager.default.enumerator(atPath: self.path)?.allObjects as? [String] else { return nil }
        allFiles = allFiles.filter({ !$0.contains(".DS_Store") })
        allFiles = allFiles.filter({ !$0.contains("Icon\r") })
        allFiles = allFiles.filter({ !$0.contains("/") })
        return allFiles
    }
    
    /// Hashes the essential components of this value by feeding them into the given hasher.
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.path)
        hasher.combine(self.parent)
        hasher.combine(self.relativePath)
    }
    
    /// Generates the desired folders at the path.
    ///
    /// - Note: This function also generates all the folders containing the final folder.
    ///
    /// - Parameters:
    ///    - isFolder: Determines whether the `FinderItem` path is a folder. Required only if the folder name contains ".".
    func generateDirectory(isFolder: Bool = false) {
        var folders = self.pathArray
        if !isFolder && folders.last!.contains(".") { folders.removeLast() }
        
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
            let fileExtension = self.extensionName
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
        var index = 0
        while index < children.count {
            autoreleasepool {
                let child = children[index]
                if child.isDirectory { child.iteratedOver(action) }
                action(child)
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
        path.removeFirst()
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
    func renamed(with newName: String) throws {
        var value = URLResourceValues()
        value.name = newName
        try self.url.setResourceValues(value)
    }
    
    /// Renames the file by replacing occurrence.
    ///
    /// - Parameters:
    ///    - target: The target to be replaced.
    ///    - replacement: The replacement used to replace the target.
    func renamed(byReplacingOccurrenceOf target: String, with replacement: String) throws {
        var fileName = fileName
        fileName = fileName.replacingOccurrences(of: target, with: replacement)
        try self.renamed(with: fileName)
    }
    
    /// Saves an image as .png.
    ///
    /// This method changes the `path`.
    func saveToPNG() throws {
        if self.extensionName.lowercased() == ".png" { return }
        guard let image = self.image else { throw NSError(domain: "No image found at path \(self.path)", code: -1, userInfo: ["path": self.path]) }
        
        try self.removeFile()
        let imageData = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
        if extensionName != "" {
            self.path = self.path.replacingOccurrences(of: extensionName, with: ".png")
        } else {
            self.path = self.path + ".png"
        }
        try imageData.write(to: self.url)
    }
    
    /// Saves the audio track to `path`.
    ///
    /// - Important: The export thread differences from current thread.
    ///
    /// - Note: The preset used is `AVAssetExportPresetAppleM4A`.
    ///
    /// - Parameters:
    ///    - path: The path where to save the audio track. The path should end with .m4v or .mov.
    ///    - completion: The closure run after the function is finished.
    func saveAudioTrack(to path: String, completion: (()->Void)? = nil) throws {
        // Create a composition
        let composition = AVMutableComposition()
        guard let asset = avAsset else {
            throw NSError(domain: "no avAsset found", code: 1, userInfo: nil)
        }
        guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { print("eror: 1"); return }
        guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { print("eror: 1"); return }
        try! audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
        print(audioAssetTrack.trackID, audioAssetTrack.timeRange)
        
        // Get url for output
        let outputUrl = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: outputUrl.path) {
            try? FileManager.default.removeItem(atPath: outputUrl.path)
        }
        
        // Create an export session
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)!
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputUrl
        
        // Export file
        exportSession.exportAsynchronously {
            guard case exportSession.status = AVAssetExportSession.Status.completed else { return }
            if let completion = completion {
                completion()
            }
        }
    }
    
    /// Set an image as icon.
    ///
    /// - precondition: The file exists.
    func setIcon(image: NSImage) {
        precondition(self.isExistence)
        NSWorkspace.shared.setIcon(image, forFile: self.path, options: .init())
    }
    
    
    //MARK: - Comparing two instances
    
    static func == (lhs: FinderItem, rhs: FinderItem) -> Bool {
        return lhs.path == rhs.path
    }
    
    
    //MARK: - Type Methods
    
    /// Creates icon at the `folderPath`.
    static func createIcon(at file: FinderItem) {
        file.iteratedOver { child in
            guard child.isFile else { return }
            let child = child
            guard (try? child.saveToPNG()) != nil else { return }
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
    static func createPDF(fromFolder folder: FinderItem, outputPath: String = "\(NSHomeDirectory())/Downloads/PDF Output", onChangingItem: ((_ item: FinderItem)->())? = nil) {
        
        precondition(folder.isExistence)
        precondition(folder.hasChildren)
        
        if folder.hasSubfolder {
            for i in folder.children! {
                if i.isDirectory && i.hasChildren {
                    createPDF(fromFolder: i, outputPath: outputPath)
                }
            }
        }
        
        if let onChangingItem = onChangingItem {
            onChangingItem(folder)
        }
        
        // create PDF
        let document = PDFDocument()
        print("create PDF:", folder.fileName)
        for child in folder.children! {
            guard child.isFile else { return }
            
            guard let image = child.image else { return }
            let imageWidth = 1080.0
            let imageRef = image.representations.first!
            let frame = NSSize(width: imageWidth, height: imageWidth/Double(imageRef.pixelsWide)*Double(imageRef.pixelsHigh))
            image.size = CGSize(width: imageWidth, height: imageWidth / Double(imageRef.pixelsWide)*Double(imageRef.pixelsHigh))
            
            let page = PDFPage(image: image)!
            page.setBounds(NSRect(origin: CGPoint.zero, size: frame), for: .mediaBox)
            document.insert(page, at: document.pageCount)
        }
        
        guard document.pageCount != 0  else { return }
        
        let pastePath = outputPath + "/" + folder.fileName + ".pdf"
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
            let value = String(i.fileName.split(whereSeparator: separator).first!)
            if !folders.keys.contains(value) {
                folders[value] = 1
            } else {
                folders[value]! += 1
            }
        }
        
        let keys = folders.filter({ $0.value >= organizeThreshold }).keys
        for i in children {
            let value = String(i.fileName.split(whereSeparator: separator).first!)
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
                try! item.renamed(byReplacingOccurrenceOf: i, with: "")
                try! item.renamed(byReplacingOccurrenceOf: "  ", with: " ")
            }
        }
    }
    
    /// Merges video and sound while keeping sound of the video too
    ///
    /// - Parameters:
    ///   - videoUrl: URL to video file
    ///   - audioUrl: URL to audio file
    ///   - completion: completion of saving: error or url with final video
    ///
    /// from [stackoverflow](https://stackoverflow.com/questions/31984474/swift-merge-audio-and-video-files-into-one-video)
    static func mergeVideoWithAudio(videoUrl: URL, audioUrl: URL, success: @escaping ((URL) -> Void), failure: @escaping ((Error?) -> Void)) {
        
        guard FileManager.default.fileExists(atPath: audioUrl.path) else {
            print("no audio file found")
            success(videoUrl)
            return
        }
        
        let mixComposition: AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack: [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack: [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        let aVideoAsset: AVAsset = AVAsset(url: videoUrl)
        let aAudioAsset: AVAsset = AVAsset(url: audioUrl)
        
        if let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            mutableCompositionVideoTrack.append(videoTrack)
            mutableCompositionAudioTrack.append(audioTrack)
            
            if let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: .video).first, let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: .audio).first {
                do {
                    try mutableCompositionVideoTrack.first?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: CMTime.zero)
                    try mutableCompositionAudioTrack.first?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
                    videoTrack.preferredTransform = aVideoAssetTrack.preferredTransform
                    
                } catch{
                    print(error)
                }
                
                
                totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero,duration: aVideoAssetTrack.timeRange.duration)
            }
        }
        
        let mutableVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
        let frame = Fraction(aVideoAsset.tracks(withMediaType: .video).first!.nominalFrameRate)
        mutableVideoComposition.frameDuration = CMTimeMake(value: Int64(frame.denominator), timescale: Int32(frame.numerator))
        mutableVideoComposition.renderSize = aVideoAsset.tracks(withMediaType: .video).first!.naturalSize
        
        let outputURL = videoUrl
        
        do {
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
        } catch { }
        
        if let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHEVCHighestQuality) {
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.m4v
            exportSession.shouldOptimizeForNetworkUse = true
            
            /// try to export the file and handle the status cases
            exportSession.exportAsynchronously(completionHandler: {
                switch exportSession.status {
                case .failed:
                    if let _error = exportSession.error {
                        failure(_error)
                    }
                    
                case .cancelled:
                    if let _error = exportSession.error {
                        failure(_error)
                    }
                    
                default:
                    print("finished")
                    success(outputURL)
                }
            })
        } else {
            failure(nil)
        }

    }
    
    /// Convert image sequence to video.
    ///
    /// from [stackoverflow](https://stackoverflow.com/questions/3741323/how-do-i-export-uiimage-array-as-a-movie/3742212#36297656)
    static func convertImageSequenceToVideo(_ allImages: [FinderItem], videoPath: String, videoSize: CGSize, videoFPS: Float, colorSpace: CGColorSpace? = nil, completion: (()->Void)? = nil) {
        
        print("Generate Video to \(videoPath) from images at fps of \(videoFPS)")
        FinderItem(at: videoPath).generateDirectory()
        
        func writeImagesAsMovie(_ allImages: [FinderItem], videoPath: String, videoSize: CGSize, videoFPS: Float) {
            // Create AVAssetWriter to write video
            let finderItemAtVideoPath = FinderItem(at: videoPath)
            if finderItemAtVideoPath.isExistence {
                try! finderItemAtVideoPath.removeFile()
            }
            
            guard let assetWriter = createAssetWriter(videoPath, size: videoSize) else {
                print("Error converting images to video: AVAssetWriter not created")
                Configuration.main.saveLog("Error converting images to video: AVAssetWriter not created")
                return
            }
            
            // If here, AVAssetWriter exists so create AVAssetWriterInputPixelBufferAdaptor
            let writerInput = assetWriter.inputs.filter{ $0.mediaType == AVMediaType.video }.first!
            let sourceBufferAttributes : [String : AnyObject] = [
                kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32ARGB) as AnyObject,
                kCVPixelBufferWidthKey as String : videoSize.width as AnyObject,
                kCVPixelBufferHeightKey as String : videoSize.height as AnyObject,
            ]
            let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourceBufferAttributes)
            
            // Start writing session
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMTime.zero)
            if (pixelBufferAdaptor.pixelBufferPool == nil) {
                print("Error converting images to video: pixelBufferPool nil after starting session")
                Configuration.main.saveLog("Error converting images to video: pixelBufferPool nil after starting session")
                return
            }
            
            // -- Create queue for <requestMediaDataWhenReadyOnQueue>
            let mediaQueue = DispatchQueue(label: "mediaInputQueue", attributes: [])
            
            // -- Set video parameters
            let fraction = Fraction(videoFPS)
            let frameDuration = CMTimeMake(value: Int64(fraction.denominator), timescale: Int32(fraction.numerator))
            var frameCount = 0
            
            // -- Add images to video
            let numImages = allImages.count
            writerInput.requestMediaDataWhenReady(on: mediaQueue, using: { () -> Void in
                // Append unadded images to video but only while input ready
                while (writerInput.isReadyForMoreMediaData && frameCount < numImages) {
                    let lastFrameTime = CMTimeMake(value: Int64(frameCount) * Int64(fraction.denominator), timescale: Int32(fraction.numerator))
                    let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                    
                    if !appendPixelBufferForImageAtURL(allImages[frameCount], size: videoSize, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                        print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                        return
                    }
                    
                    frameCount += 1
                }
                
                // No more images to add? End video.
                if (frameCount >= numImages) {
                    writerInput.markAsFinished()
                    assetWriter.finishWriting {
                        if (assetWriter.error != nil) {
                            print("Error converting images to video: \(assetWriter.error.debugDescription)")
                        } else {
                            print("Converted images to movie @ \(videoPath)")
                            print("The fps is \(FinderItem(at: videoPath).frameRate!)")
                        }
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                }
            })
        }
        
        
        func createAssetWriter(_ path: String, size: CGSize) -> AVAssetWriter? {
            // Convert <path> to NSURL object
            let pathURL = URL(fileURLWithPath: path)
            
            // Return new asset writer or nil
            do {
                // Create asset writer
                let newWriter = try AVAssetWriter(outputURL: pathURL, fileType: AVFileType.m4v)
                
                // Define settings for video input
                let videoSettings: [String : AnyObject] = [
                    AVVideoCodecKey  : AVVideoCodecType.hevc as AnyObject,
                    AVVideoWidthKey  : size.width as AnyObject,
                    AVVideoHeightKey : size.height as AnyObject,
                ]
                
                // Add video input to writer
                let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
                newWriter.add(assetWriterVideoInput)
                
                // Return writer
                print("Created asset writer for \(size.width)x\(size.height) video")
                return newWriter
            } catch {
                print("Error creating asset writer: \(error)")
                return nil
            }
        }
        
        
        func appendPixelBufferForImageAtURL(_ image: FinderItem, size: CGSize, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
            var appendSucceeded = false
            
            autoreleasepool {
                if  let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                    let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity:1)
                    let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                        kCFAllocatorDefault,
                        pixelBufferPool,
                        pixelBufferPointer
                    )
                    
                    if let pixelBuffer = pixelBufferPointer.pointee , status == 0 {
                        fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer, size: size)
                        appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                        pixelBufferPointer.deinitialize(count: 1)
                    } else {
                        NSLog("Error: Failed to allocate pixel buffer from pool")
                    }
                    
                    pixelBufferPointer.deallocate()
                }
            }
            
            return appendSucceeded
        }
        
        
        func fillPixelBufferFromImage(_ image: FinderItem, pixelBuffer: CVPixelBuffer, size: CGSize) {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            
            // Create CGBitmapContext
            let context = CGContext(
                data: pixelData,
                width: Int(videoSize.width),
                height: Int(videoSize.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: rgbColorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            )!
            
            // Draw image into context
            let drawCGRect = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
            var drawRect = NSRectFromCGRect(drawCGRect);
            var cgImage = image.image!.cgImage(forProposedRect: &drawRect, context: nil, hints: nil)!
            
            if colorSpace != nil && colorSpace! != cgImage.colorSpace {
                cgImage = cgImage.copy(colorSpace: colorSpace!)!
            }
            
            context.draw(cgImage, in: CGRect(x: 0.0,y: 0.0, width: size.width,height: size.height))
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        }
        
        writeImagesAsMovie(allImages, videoPath: videoPath, videoSize: videoSize, videoFPS: videoFPS)
    }
    
    static func trimVideo(sourceURL: URL, outputURL: URL, startTime: Double, endTime: Double, completion: @escaping ((_ asset: AVAsset)->())) {
        let asset = AVAsset(url: sourceURL as URL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHEVCHighestQuality) else { return }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4v
        
        let startTime = CMTime(startTime)
        let endTime = CMTime(endTime)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        if FinderItem(at: outputURL).isExistence {
            try! FinderItem(at: outputURL).removeFile()
        }
        
        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("exported at \(outputURL)")
                completion(FinderItem(at: outputURL).avAsset!)
            case .failed:
                print("failed \(exportSession.error.debugDescription)")
                
            case .cancelled:
                print("cancelled \(exportSession.error.debugDescription)")
                
            default: break
            }
        }
    }
    
    /// merge videos from videos
    ///
    /// from [stackoverflow](https://stackoverflow.com/questions/38972829/swift-merge-avasset-videos-array)
    static func mergeVideos(from arrayVideos: [FinderItem], toPath: String, tempFolder: String, frameRate: Float, completion: @escaping (_ urlGet:URL?,_ errorGet:Error?) -> Void) {
        
        print("Merging videos...")
        
        func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset)
        -> AVMutableVideoCompositionLayerInstruction {
            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            
            return instruction
        }
        
        func mergingVideos(from arrayVideos: [FinderItem], toPath: String, completion: @escaping (_ urlGet:URL?,_ errorGet:Error?) -> Void) {
            var atTimeM = CMTime.zero
            var layerInstructionsArray = [AVVideoCompositionLayerInstruction]()
            var completeTrackDuration = CMTime.zero
            var videoSize: CGSize = CGSize(width: 0.0, height: 0.0)
            
            let mixComposition = AVMutableComposition()
            var index = 0
            while index < arrayVideos.count {
                autoreleasepool {
                    let videoAsset = arrayVideos[index].avAsset!
                    
                    let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
                    do {
                        try videoTrack!.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration),
                                                        of: videoAsset.tracks(withMediaType: AVMediaType.video).first!,
                                                        at: atTimeM)
                        videoSize = (videoTrack!.naturalSize)
                        
                    } catch let error as NSError {
                        print("error: \(error)")
                    }
                    
                    let realDuration = { ()-> CMTime in
                        let framesCount = Double(videoAsset.frameRate!) * videoAsset.duration.seconds
                        return CMTime(framesCount / Double(frameRate))
                    }()
                    
                    videoTrack!.scaleTimeRange(CMTimeRangeMake(start: atTimeM, duration: videoAsset.duration), toDuration: realDuration)
                    
                    atTimeM = CMTimeAdd(atTimeM, realDuration)
                    print(atTimeM.seconds.expressedAsTime(), realDuration.seconds.expressedAsTime())
                    completeTrackDuration = CMTimeAdd(completeTrackDuration, realDuration)
                    
                    let firstInstruction = videoCompositionInstruction(videoTrack!, asset: videoAsset)
                    firstInstruction.setOpacity(0.0, at: atTimeM) // hide the video after its duration.
                    
                    layerInstructionsArray.append(firstInstruction)
                    
                    index += 1
                }
            }
            
            print("add videos finished")
            
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.layerInstructions = layerInstructionsArray
            mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: completeTrackDuration)
            
            let mainComposition = AVMutableVideoComposition()
            mainComposition.instructions = [mainInstruction]
            let fraction = Fraction(frameRate)
            mainComposition.frameDuration = CMTimeMake(value: Int64(fraction.denominator), timescale: Int32(fraction.numerator))
            mainComposition.renderSize = videoSize
            
            let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHEVCHighestQuality)
            exporter!.outputURL = URL(fileURLWithPath: toPath)
            exporter!.outputFileType = AVFileType.mov
            exporter!.shouldOptimizeForNetworkUse = false
            exporter!.videoComposition = mainComposition
            exporter!.exportAsynchronously {
                print("merge videos: \(exporter!.status.rawValue)", exporter!.error ?? "")
                completion(exporter?.outputURL, nil)
            }
        }
        
        FinderItem(at: tempFolder).generateDirectory(isFolder: true)
        
        let threshold: Double = 50
        
        if arrayVideos.count >= Int(threshold) {
            var index = 0
            var finishedCounter = 0
            while index < Int((Double(arrayVideos.count) / threshold).rounded(.up)) {
                autoreleasepool {
                    
                    var sequence = String(index)
                    while sequence.count < 6 { sequence.insert("0", at: sequence.startIndex) }
                    let upperBound = ((index + 1) * Int(threshold)) > arrayVideos.count ? arrayVideos.count : ((index + 1) * Int(threshold))
                    
                    mergingVideos(from: Array(arrayVideos[(index * Int(threshold))..<upperBound]), toPath: tempFolder + "/" + sequence + ".m4v") { urlGet, errorGet in
                        finishedCounter += 1
                        guard finishedCounter == Int((Double(arrayVideos.count) / threshold).rounded(.up)) else { return }
                        mergingVideos(from: FinderItem(at: tempFolder).children!, toPath: toPath, completion: completion)
                    }
                    
                    index += 1
                    
                }
            }
        } else {
            mergingVideos(from: arrayVideos, toPath: toPath, completion: completion)
        }
    }
    
    static func addFrame(fromFrame1: String, fromFrame2: String, to: String) {
        let fromFrame1 = FinderItem(at: fromFrame1)
        let fromFrame2 = FinderItem(at: fromFrame2)
        let to = FinderItem(at: to)
        let path = FinderItem(at: Bundle.main.bundlePath + "/Contents/Resources/dain-ncnn-vulkan-20210210-macos")
        print(shell(["cd \(path.shellPath)", "./dain-ncnn-vulkan  -0 \(fromFrame1.shellPath) -1 \(fromFrame2.shellPath) -o \(to.shellPath)"])!)
    }
}

