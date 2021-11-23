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

class FinderItem: CustomStringConvertible, Identifiable, Equatable {
    
    
    //MARK: - Basic Properties
    
    /// The absolute path.
    var path: String
    
    var parent: FinderItem? = nil
    
    var relativePath: String? = nil
    
    
    //MARK: - Instance Properties
    
    /// The audio / video asset at the path, if exists.
    var avAsset: AVAsset? {
        guard AVAsset(url: self.url).isReadable else { return nil }
        return AVAsset(url: self.url)
    }
    
    /// The audio track of the video file
    var audioTrack: AVAssetTrack? {
        return self.avAsset?.tracks(withMediaType: AVMediaType.audio).first
    }
    
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
    
    /// All the frames of the video.
    var frames: [NSImage]? {
        guard let asset = self.avAsset else { return nil }
        let vidLength: CMTime = asset.duration
        let seconds: Double = CMTimeGetSeconds(vidLength)
        let frameRate = Double(asset.tracks(withMediaType: .video).first!.nominalFrameRate)
        
        let requiredFramesCount = Int(seconds * frameRate)
        
        let step = Int((vidLength.value / Int64(requiredFramesCount)))
        var value: Int = 0
        
        var counter = 0
        var images: [NSImage] = []
        
        print(requiredFramesCount)
        
        while counter < requiredFramesCount {
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
            guard let ref = imageRef else { continue }
            let thumbnail = NSImage(cgImage: ref, size: NSSize(width: ref.width, height: ref.height))
            
            images.append(thumbnail)
            
            value += Int(step)
            counter += 1
        }
        
        return images
    }
    
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
    
    /// The audio track of the video file
    var videoTrack: AVAssetTrack? {
        return self.avAsset?.tracks(withMediaType: AVMediaType.video).first
    }
    
    
    //MARK: - Initializers
    
    init(at path: String) {
        self.path = path
    }
    
    init(at url: URL) {
        self.path = url.path
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
    /// - Note: This function also generates all the folders containing the final folder.
    func generateDirectory() {
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
    
    func saveAudioTrack(to path: String) throws {
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
        }
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
    static func createPDF(fromFolder folder: FinderItem, outputPath: String = "\(NSHomeDirectory())/Downloads/PDF Output", onChangingItem: ((_ item: FinderItem)->())? = nil, onFinish: (()->())? = nil) {
        
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
            
            if let onChangingItem = onChangingItem {
                onChangingItem(child)
            }
            
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
        
        if let onFinish = onFinish {
            onFinish()
        }
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
    
    /// Merges video and sound while keeping sound of the video too
    ///
    /// - Parameters:
    ///   - videoUrl: URL to video file
    ///   - audioUrl: URL to audio file
    ///   - shouldFlipHorizontally: pass True if video was recorded using frontal camera otherwise pass False
    ///   - completion: completion of saving: error or url with final video
    ///
    /// from https://stackoverflow.com/questions/31984474/swift-merge-audio-and-video-files-into-one-video
    static func mergeVideoAndAudio(videoUrl: URL,
                            audioUrl: URL,
                            shouldFlipHorizontally: Bool = false,
                            completion: @escaping (_ error: Error?, _ url: URL?) -> Void) {
        
        let mixComposition = AVMutableComposition()
        var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioOfVideoTrack = [AVMutableCompositionTrack]()
        
        //start merge
        
        let aVideoAsset = AVAsset(url: videoUrl)
        let aAudioAsset = AVAsset(url: audioUrl)
        
        let compositionAddVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                 preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let compositionAddAudio = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                 preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        let compositionAddAudioOfVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                        preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioOfVideoAssetTrack: AVAssetTrack? = aVideoAsset.tracks(withMediaType: AVMediaType.audio).first
        let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        // Default must have tranformation
        compositionAddVideo?.preferredTransform = aVideoAssetTrack.preferredTransform
        
        if shouldFlipHorizontally {
            // Flip video horizontally
            var frontalTransform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            frontalTransform = frontalTransform.translatedBy(x: -aVideoAssetTrack.naturalSize.width, y: 0.0)
            frontalTransform = frontalTransform.translatedBy(x: 0.0, y: -aVideoAssetTrack.naturalSize.width)
            compositionAddVideo?.preferredTransform = frontalTransform
        }
        
        mutableCompositionVideoTrack.append(compositionAddVideo!)
        mutableCompositionAudioTrack.append(compositionAddAudio)
        mutableCompositionAudioOfVideoTrack.append(compositionAddAudioOfVideo)
        
        do {
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero,
                                                                                duration: aVideoAssetTrack.timeRange.duration),
                                                                of: aVideoAssetTrack,
                                                                at: CMTime.zero)
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero,
                                                                                duration: aVideoAssetTrack.timeRange.duration),
                                                                of: aAudioAssetTrack,
                                                                at: CMTime.zero)
            
            // adding audio (of the video if exists) asset to the final composition
            if let aAudioOfVideoAssetTrack = aAudioOfVideoAssetTrack {
                try mutableCompositionAudioOfVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero,
                                                                                           duration: aVideoAssetTrack.timeRange.duration),
                                                                           of: aAudioOfVideoAssetTrack,
                                                                           at: CMTime.zero)
            }
        } catch {
            print(error.localizedDescription)
        }
        
        // Exporting
        let savePathUrl: URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")
        do { // delete old video
            try FileManager.default.removeItem(at: savePathUrl)
        } catch { print(error.localizedDescription) }
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mov
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
            case AVAssetExportSession.Status.completed:
                print("success")
                completion(nil, savePathUrl)
            case AVAssetExportSession.Status.failed:
                print("failed \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(assetExport.error, nil)
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(assetExport.error, nil)
            default:
                print("complete")
                completion(assetExport.error, nil)
            }
        }
        
    }
    
    /// Convert image sequence to video.
    ///
    /// from https://stackoverflow.com/questions/3741323/how-do-i-export-uiimage-array-as-a-movie/3742212#36297656
    static func convertImageSequenceToVideo(_ allImages: [NSImage], videoPath: String, videoSize: CGSize, videoFPS: Int32, didFinish: (()->Void)? = nil) {
        
        func writeImagesAsMovie(_ allImages: [NSImage], videoPath: String, videoSize: CGSize, videoFPS: Int32) {
            // Create AVAssetWriter to write video
            guard let assetWriter = createAssetWriter(videoPath, size: videoSize) else {
                print("Error converting images to video: AVAssetWriter not created")
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
                return
            }
            
            // -- Create queue for <requestMediaDataWhenReadyOnQueue>
            let mediaQueue = DispatchQueue(label: "mediaInputQueue", attributes: [])
            
            // -- Set video parameters
            let frameDuration = CMTimeMake(value: 1, timescale: videoFPS)
            var frameCount = 0
            
            // -- Add images to video
            let numImages = allImages.count
            writerInput.requestMediaDataWhenReady(on: mediaQueue, using: { () -> Void in
                // Append unadded images to video but only while input ready
                while (writerInput.isReadyForMoreMediaData && frameCount < numImages) {
                    let lastFrameTime = CMTimeMake(value: Int64(frameCount), timescale: videoFPS)
                    let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                    
                    if !appendPixelBufferForImageAtURL(allImages[frameCount], pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
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
                        }
                        
                        if let didFinish = didFinish {
                            didFinish()
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
                let newWriter = try AVAssetWriter(outputURL: pathURL, fileType: AVFileType.mov)
                
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
        
        
        func appendPixelBufferForImageAtURL(_ image: NSImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
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
                        fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
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
        
        
        func fillPixelBufferFromImage(_ image: NSImage, pixelBuffer: CVPixelBuffer) {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            
            // Create CGBitmapContext
            let context = CGContext(
                data: pixelData,
                width: Int(image.size.width),
                height: Int(image.size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: rgbColorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            )!
            
            // Draw image into context
            let drawCGRect = CGRect(x:0, y:0, width:image.size.width, height:image.size.height)
            var drawRect = NSRectFromCGRect(drawCGRect);
            let cgImage = image.cgImage(forProposedRect: &drawRect, context: nil, hints: nil)!
            context.draw(cgImage, in: CGRect(x: 0.0,y: 0.0,width: image.size.width,height: image.size.height))
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        }
        
        writeImagesAsMovie(allImages, videoPath: videoPath, videoSize: videoSize, videoFPS: videoFPS)
    }
}

