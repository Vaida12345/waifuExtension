//
//  ContentView.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI
import AVFoundation

var isProcessingCancelled = false

struct orderedImages {
    var image: NSImage
    var index: Int
}

func addItems(of items: [FinderItem], to finderItems: [WorkItem]) -> [WorkItem] {
    var finderItems = finderItems
    var counter = 0
    while counter < items.count {
        autoreleasepool {
            finderItems = addItemIfPossible(of: items[counter], to: finderItems)
            
            counter += 1
        }
    }
    return finderItems
}

func addItemIfPossible(of item: FinderItem, to finderItems: [WorkItem]) -> [WorkItem] {
    guard !finderItems.contains(item) else { return finderItems }
    var finderItems = finderItems
    if item.isFile {
        guard item.image != nil || item.avAsset != nil else { return finderItems }
        finderItems.append(WorkItem(at: item, type: item.image != nil ? .image : .video))
    } else {
        item.iteratedOver { child in
            autoreleasepool {
                guard !finderItems.contains(child) else { return }
                guard child.image != nil || child.avAsset != nil else { return }
                child.relativePath = item.fileName + "/" + child.relativePath(to: item)!
                finderItems.append(WorkItem(at: child, type: child.image != nil ? .image : .video))
            }
        }
    }
    return finderItems
}

extension Array where Element == WorkItem {
    
    func contains(_ finderItem: FinderItem) -> Bool {
        return self.contains(WorkItem(at: finderItem, type: .image))
    }
    
    func work(_ chosenScaleLevel: Int?, modelUsed: Waifu2xModel?, videoSegmentFrames: Int = 10, frameInterpolation: Int?, enableConcurrent: Bool, onStatusChanged status: @escaping ((_ status: String)->()), onStatusProgressChanged: @escaping ((_ progress: Int?, _ total: Int?)->()), onProgressChanged: @escaping ((_ progress: Double) -> ()), didFinishOneItem: @escaping ((_ finished: Int, _ total: Int)->()), completion: @escaping (() -> ())) {
        
        let images = self.filter({ $0.type == .image })
        let videos = self.filter({ $0.type == .video })
        let backgroundQueue = DispatchQueue(label: "[WorkItem] background dispatch queue")
        
        let totalItemCounter = self.count
        let totalFrames = videos.map({ Double($0.finderItem.frameRate!) * $0.finderItem.avAsset!.duration.seconds }).reduce(0.0, +) + Double(images.count)
        var finishedItemsCounter = 0
        let scaleFactor = {()-> Double in
            if let chosenScaleLevel = chosenScaleLevel {
                if chosenScaleLevel > 1 {
                    return Double(chosenScaleLevel)
                }
            }
            return 1
        }()
        
        FinderItem(at: Configuration.main.saveFolder).generateDirectory(isFolder: true)
        FinderItem(at: Configuration.main.saveFolder).setIcon(image: NSImage(imageLiteralResourceName: "icon"))
        
        if !images.isEmpty {
            status("processing images")
            var concurrentProcessingImagesCount = 0
            
            if enableConcurrent {
                DispatchQueue.concurrentPerform(iterations: images.count) { imageIndex in
                    autoreleasepool {
                        
                        guard !isProcessingCancelled else { return }
                        
                        backgroundQueue.async {
                            concurrentProcessingImagesCount += 1
                            
                            status("processing \(concurrentProcessingImagesCount) images in parallel")
                        }
                        
                        let currentImage = images[imageIndex]
                        var image = currentImage.finderItem.image!
                        
                        let waifu2x = Waifu2x()
                        waifu2x.didFinishedOneBlock = { total in
                            currentImage.progress += 1 / Double(total) / scaleFactor
                            onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / totalFrames)
                        }
                        
                        if chosenScaleLevel! >= 2 {
                            for _ in 1...chosenScaleLevel! {
                                image = waifu2x.run(image, model: modelUsed!, concurrentCount: concurrentProcessingImagesCount)!.reload()
                            }
                        } else {
                            image = waifu2x.run(image, model: modelUsed!, concurrentCount: concurrentProcessingImagesCount)!
                        }
                        
                        let outputFileName: String
                        if let name = currentImage.finderItem.relativePath {
                            outputFileName = name[..<name.lastIndex(of: ".")!] + ".png"
                        } else {
                            outputFileName = currentImage.finderItem.fileName + ".png"
                        }
                        
                        let finderItemAtImageOutputPath = FinderItem(at: "\(Configuration.main.saveFolder)/\(outputFileName)")
                        
                        finderItemAtImageOutputPath.generateDirectory()
                        image.write(to: finderItemAtImageOutputPath.path)
                        
                        backgroundQueue.async {
                            concurrentProcessingImagesCount -= 1
                            status("processing \(concurrentProcessingImagesCount) images in parallel")
                            finishedItemsCounter += 1
                            didFinishOneItem(finishedItemsCounter, totalItemCounter)
                        }
                        
                    }
                }
            } else {
                var imageIndex = 0
                while imageIndex < images.count {
                    autoreleasepool {
                        
                        guard !isProcessingCancelled else { return }
                        
                        backgroundQueue.async {
                            concurrentProcessingImagesCount += 1
                            
                            status("processing \(concurrentProcessingImagesCount) images in parallel")
                        }
                        
                        let currentImage = images[imageIndex]
                        var image = currentImage.finderItem.image!
                        
                        let waifu2x = Waifu2x()
                        waifu2x.didFinishedOneBlock = { total in
                            currentImage.progress += 1 / Double(total) / scaleFactor
                            onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / totalFrames)
                        }
                        
                        if chosenScaleLevel! >= 2 {
                            for _ in 1...chosenScaleLevel! {
                                image = waifu2x.run(image, model: modelUsed!)!.reload()
                            }
                        } else {
                            image = waifu2x.run(image, model: modelUsed!)!
                        }
                        
                        let outputFileName: String
                        if let name = currentImage.finderItem.relativePath {
                            outputFileName = name[..<name.lastIndex(of: ".")!] + ".png"
                        } else {
                            outputFileName = currentImage.finderItem.fileName + ".png"
                        }
                        
                        let finderItemAtImageOutputPath = FinderItem(at: "\(Configuration.main.saveFolder)/\(outputFileName)")
                        
                        finderItemAtImageOutputPath.generateDirectory()
                        image.write(to: finderItemAtImageOutputPath.path)
                        
                        backgroundQueue.async {
                            concurrentProcessingImagesCount -= 1
                            status("processing \(concurrentProcessingImagesCount) images in parallel")
                            finishedItemsCounter += 1
                            didFinishOneItem(finishedItemsCounter, totalItemCounter)
                        }
                        
                        imageIndex += 1
                    }
                }
            }
            
            status("finished processing images")
        }
        
        if !videos.isEmpty {
            //helper functions
            
            func splitVideo(duration: Double, filePath: String, currentVideo: WorkItem, completion: @escaping ((_ paths: [String])->())) {
                
                guard !isProcessingCancelled else { return }
                
                status("splitting videos")
                
                FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo").generateDirectory(isFolder: true)
                var finishedCounter = 0
                var paths: [String] = []
                
                func splitVideo(withIndex segmentIndex: Int, duration: Double, filePath: String, currentVideo: WorkItem, completion: @escaping (()->())) {
                    
                    guard !isProcessingCancelled else { return }
                    let videoSegmentLength = Double(videoSegmentFrames) / Double(currentVideo.finderItem.frameRate!)
                    guard Double(segmentIndex) < (duration / videoSegmentLength).rounded(.up) else { return }
                    
                    var segmentSequence = String(segmentIndex)
                    while segmentSequence.count <= 5 { segmentSequence.insert("0", at: segmentSequence.startIndex) }
                    
                    let path = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo/video \(segmentSequence).m4v"
                    FinderItem(at: path).generateDirectory()
                    paths.append(path)
                    guard FinderItem(at: path).avAsset == nil else {
                        finishedCounter += 1
                        onStatusProgressChanged(finishedCounter, Int((duration / videoSegmentLength).rounded(.up)))
                        
                        splitVideo(withIndex: segmentIndex + 1, duration: duration, filePath: filePath, currentVideo: currentVideo, completion: completion)
                        guard finishedCounter == Int((duration / videoSegmentLength).rounded(.up)) else { return }
                        onStatusProgressChanged(nil, nil)
                        completion()
                        
                        return
                    }
                    
                    FinderItem.trimVideo(sourceURL: currentVideo.finderItem.url, outputURL: URL(fileURLWithPath: path), startTime: (Double(segmentIndex) * Double(videoSegmentLength)), endTime: {()->Double in
                        if Double(segmentIndex) * videoSegmentLength + videoSegmentLength <= duration {
                            return Double(Double(segmentIndex) * videoSegmentLength + videoSegmentLength)
                        } else {
                            return Double(duration)
                        }
                    }()) { _ in
                        finishedCounter += 1
                        onStatusProgressChanged(finishedCounter, Int((duration / videoSegmentLength).rounded(.up)))
                        
                        splitVideo(withIndex: segmentIndex + 1, duration: duration, filePath: filePath, currentVideo: currentVideo, completion: completion)
                        guard finishedCounter == Int((duration / videoSegmentLength).rounded(.up)) else { return }
                        onStatusProgressChanged(nil, nil)
                        completion()
                    }
                }
                
                splitVideo(withIndex: 0, duration: duration, filePath: filePath, currentVideo: currentVideo) {
                    completion(paths)
                }
            }
            
            
            func generateImagesAndMergeToVideoForSegment(segmentsFinderItem: FinderItem, index: Int, currentVideo: WorkItem, filePath: String, totalSegmentsCount: Double, completion: @escaping (()->())) {
                autoreleasepool {
                    
                    guard !isProcessingCancelled else { return }
                    guard let asset = segmentsFinderItem.avAsset else { return }
                    
                    let vidLength: CMTime = asset.duration
                    let seconds: Double = CMTimeGetSeconds(vidLength)
                    let frameRate = currentVideo.finderItem.frameRate!
                    
                    var requiredFramesCount = Int((seconds * Double(frameRate)).rounded())
                    
                    if requiredFramesCount == 0 {
                        requiredFramesCount = 1
                    }
                    
                    let step = Int((vidLength.value / Int64(requiredFramesCount)))
                    
                    var indexSequence = String(index)
                    while indexSequence.count < 6 { indexSequence.insert("0", at: indexSequence.startIndex) }
                    
                    let mergedVideoPath = "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/videos/\(indexSequence).m4v"
                    guard FinderItem(at: mergedVideoPath).avAsset == nil else {
                        if !Configuration.main.isDevEnabled {
                            do {
                                try FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)").removeFile()
                            } catch {  }
                        }
                        currentVideo.progress += Double(requiredFramesCount)
                        onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / totalFrames)
                        // completion after all videos are finished.
                        completion()
                        return
                    }
                    
                    print("frames to process: \(requiredFramesCount)")
                    FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames").generateDirectory(isFolder: true)
                    FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames").generateDirectory(isFolder: true)
                    let factor: Double = chosenScaleLevel != nil && frameInterpolation != nil ? 2 : 1
                    var colorSpace: CGColorSpace? = nil
                    
                    DispatchQueue.concurrentPerform(iterations: requiredFramesCount) { frameCounter in
                        autoreleasepool {
                            
                            var sequence = String(frameCounter)
                            while sequence.count < 6 { sequence.insert("0", at: sequence.startIndex) }
                            
                            // generate frames
                            guard FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(sequence).png").image == nil else {
                                currentVideo.progress += 1
                                onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / totalFrames)
                                return
                            }
                            
                            let imageGenerator = AVAssetImageGenerator(asset: asset)
                            imageGenerator.requestedTimeToleranceAfter = CMTime.zero
                            imageGenerator.requestedTimeToleranceBefore = CMTime.zero
                            
                            let time: CMTime = CMTimeMake(value: Int64(step * frameCounter), timescale: vidLength.timescale)
                            var imageRef: CGImage?
                            do {
                                imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                            } catch {
                                Configuration.main.saveError("Image could be found at \(time.seconds)s in \(currentVideo.finderItem.fileName). Skipped.")
                                print(error)
                                return
                            }
                            if colorSpace == nil {
                                colorSpace = imageRef?.colorSpace
                            }
                            var thumbnail = NSImage(cgImage: imageRef!, size: NSSize(width: imageRef!.width, height: imageRef!.height))
                            
                            // enlarge image
                            if chosenScaleLevel != nil {
                                
                                let waifu2x = Waifu2x()
                                
                                if chosenScaleLevel! >= 2 {
                                    for _ in 1...chosenScaleLevel! {
                                        thumbnail = waifu2x.run(thumbnail.reload(withIndex: "\(frameCounter)"), model: modelUsed!)!
                                    }
                                } else {
                                    thumbnail = waifu2x.run(thumbnail.reload(withIndex: "\(frameCounter)"), model: modelUsed!)!
                                }
                                
                                currentVideo.progress += 1 / factor
                                onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / totalFrames)
                            }
                            
                            thumbnail.write(to: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(sequence).png")
                        }
                    }
                    
                    if frameInterpolation != nil {
                        onStatusProgressChanged(nil, nil)
                        var frameCounter = 0
                        
                        while frameCounter < requiredFramesCount {
                            autoreleasepool {
                                
                                var sequence = String(frameCounter)
                                while sequence.count < 6 { sequence.insert("0", at: sequence.startIndex) }
                                
                                // add frames
                                
                                if frameCounter == 0 {
                                    var previousSequence = String(0)
                                    while previousSequence.count < 6 { previousSequence.insert("0", at: previousSequence.startIndex) }
                                    try! FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(sequence).png").copy(to: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(previousSequence).png")
                                    frameCounter += 1
                                    
                                    currentVideo.progress += 1 / factor
                                    onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / totalFrames)
                                    
                                    return
                                }
                                
                                var previousSequence = String(frameCounter - 1)
                                while previousSequence.count < 6 { previousSequence.insert("0", at: previousSequence.startIndex) }
                                
                                var processedSequence = String(frameCounter * frameInterpolation!)
                                while processedSequence.count < 6 { processedSequence.insert("0", at: processedSequence.startIndex) }
                                
                                var intermediateSequence = String(frameCounter * frameInterpolation! - frameInterpolation! / 2)
                                while intermediateSequence.count < 6 { intermediateSequence.insert("0", at: intermediateSequence.startIndex) }
                                
                                // will not save the previous frame
                                
                                try! FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(sequence).png").copy(to: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(processedSequence).png")
                                
                                if FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence).png").image == nil {
                                    FinderItem.addFrame(fromFrame1: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(previousSequence).png", fromFrame2: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(sequence).png", to: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence).png")
                                }
                                
                                var intermediateSequence1 = String(frameCounter * frameInterpolation! - frameInterpolation! / 2 - 1)
                                while intermediateSequence1.count < 6 { intermediateSequence1.insert("0", at: intermediateSequence1.startIndex) }
                                
                                var intermediateSequence3 = String(frameCounter * frameInterpolation! - frameInterpolation! / 2 + 1)
                                while intermediateSequence3.count < 6 { intermediateSequence3.insert("0", at: intermediateSequence3.startIndex) }
                                
                                if frameInterpolation! == 4 && (FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence1).png").image == nil || FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence3).png").image == nil) {
                                    
                                    FinderItem.addFrame(fromFrame1: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(previousSequence).png", fromFrame2: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence).png", to: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence1).png")
                                    
                                    FinderItem.addFrame(fromFrame1: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence).png", fromFrame2: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(processedSequence).png", to: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence3).png")
                                }
                                
                                currentVideo.progress += 1 / Double(requiredFramesCount) / factor / totalSegmentsCount
                                onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / Double(totalItemCounter))
                                
                                
                                frameCounter += 1
                            }
                        }
                    }
                    
                    FinderItem(at: mergedVideoPath).generateDirectory()
                    
                    let arbitraryFrame = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/000000.png")
                    let arbitraryFrameCGImage = arbitraryFrame.image!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
                    
                    if !Configuration.main.isDevEnabled { try! FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo/video \(indexSequence).m4v").removeFile() }
                    
                    if frameInterpolation == nil {
                        let enlargedFrames: [FinderItem] = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames").children!
                        FinderItem.convertImageSequenceToVideo(enlargedFrames, videoPath: mergedVideoPath, videoSize: CGSize(width: arbitraryFrameCGImage.width, height: arbitraryFrameCGImage.height), videoFPS: currentVideo.finderItem.frameRate!, colorSpace: colorSpace) {
                            if !Configuration.main.isDevEnabled { try! FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)").removeFile() }
                            // completion after all videos are finished.
                            completion()
                        }
                    } else {
                        let enlargedFrames: [FinderItem] = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames").children!
                        FinderItem.convertImageSequenceToVideo(enlargedFrames, videoPath: mergedVideoPath, videoSize: CGSize(width: arbitraryFrameCGImage.width, height: arbitraryFrameCGImage.height), videoFPS: currentVideo.finderItem.frameRate! * Float(frameInterpolation!), colorSpace: colorSpace) {
                            if !Configuration.main.isDevEnabled { try! FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)").removeFile() }
                            // completion after all videos are finished.
                            completion()
                        }
                    }
                }
            }
            
            func processSingleVideo(withIndex videoIndex: Int, completion: @escaping (()->())) {
                
                guard !isProcessingCancelled else { return }
                
                let currentVideo = videos[videoIndex]
                let filePath = currentVideo.finderItem.relativePath ?? (currentVideo.finderItem.fileName + currentVideo.finderItem.extensionName)
                
                status("generating audio for \(filePath)")
                
                FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)").generateDirectory(isFolder: true)
                let audioPath = "\(Configuration.main.saveFolder)/tmp/\(filePath)/audio.m4a"
                try! currentVideo.finderItem.saveAudioTrack(to: audioPath)
                
                let duration = currentVideo.finderItem.avAsset!.duration.seconds
                
                //status: generating video segment frames
                
                splitVideo(duration: duration, filePath: filePath, currentVideo: currentVideo) { paths in
                    status("generating images for \(filePath)")
                    onStatusProgressChanged(nil, nil)
                    
                    var index = 0
                    var finished = 0
                    while index < paths.count {
                        
                        onStatusProgressChanged(index, paths.count)
                        generateImagesAndMergeToVideoForSegment(segmentsFinderItem: FinderItem(at: paths[index]), index: index, currentVideo: currentVideo, filePath: filePath, totalSegmentsCount: Double(paths.count)) {
                            finished += 1
                            
                            print(finished, paths.count)
                            guard finished == paths.count else { return }
                            guard !isProcessingCancelled else { return }
                            
                            let outputPath = "\(Configuration.main.saveFolder)/tmp/\(filePath)/\(currentVideo.finderItem.fileName).m4v"
                            
                            // status: merge videos
                            status("merging video for \(filePath)")
                            
                            FinderItem.mergeVideos(from: FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/videos").children!, toPath: outputPath, tempFolder: "\(Configuration.main.saveFolder)/tmp/\(filePath)/merging video", frameRate: currentVideo.finderItem.frameRate! * Float((frameInterpolation == nil ? 1 : frameInterpolation!))) { urlGet, errorGet in
                                
                                print("videos merged")
                                status("merging video and audio for \(filePath)")
                                onStatusProgressChanged(nil, nil)
                                
                                FinderItem.mergeVideoWithAudio(videoUrl: URL(fileURLWithPath: outputPath), audioUrl: URL(fileURLWithPath: audioPath)) { _ in
                                    status("Completed")
                                    
                                    let destinationFinderItem = FinderItem(at: "\(Configuration.main.saveFolder)/\(filePath)")
                                    if destinationFinderItem.isExistence { try! destinationFinderItem.removeFile() }
                                    try! FinderItem(at: outputPath).copy(to: destinationFinderItem.path)
                                    if !Configuration.main.isDevEnabled { try! FinderItem(at: "\(Configuration.main.saveFolder)/tmp").removeFile() }
                                    
                                    finishedItemsCounter += 1
                                    didFinishOneItem(finishedItemsCounter, totalItemCounter)
                                    
                                    print(">>>>> results: ")
                                    print("Video \(currentVideo.finderItem.fileName) done")
                                    Configuration.main.saveLog("Video \(currentVideo.finderItem.fileName) done")
                                    Configuration.main.saveLog(printMatrix(matrix: [["", "frames", "duration", "fps"], ["before", "\(currentVideo.finderItem.avAsset!.duration.seconds * Double(currentVideo.finderItem.frameRate!))", "\(currentVideo.finderItem.avAsset!.duration.seconds)", "\(currentVideo.finderItem.frameRate!)"], ["after", "\(destinationFinderItem.avAsset!.duration.seconds * Double(destinationFinderItem.frameRate!))", "\(destinationFinderItem.avAsset!.duration.seconds)", "\(destinationFinderItem.frameRate!)"]]))
                                    Configuration.main.saveLog("")
                                    print("")
                                    
                                    if abs((currentVideo.finderItem.avAsset!.duration.seconds * Double(currentVideo.finderItem.frameRate!)) - destinationFinderItem.avAsset!.duration.seconds * Double(destinationFinderItem.frameRate!)) > 5 {
                                        Configuration.main.saveError("Sorry, error occurred considering the following files:")
                                        Configuration.main.saveError(printMatrix(matrix: [["", "frames", "duration", "fps"], ["before", "\(currentVideo.finderItem.avAsset!.duration.seconds * Double(currentVideo.finderItem.frameRate!))", "\(currentVideo.finderItem.avAsset!.duration.seconds)", "\(currentVideo.finderItem.frameRate!)"], ["after", "\(destinationFinderItem.avAsset!.duration.seconds * Double(destinationFinderItem.frameRate!))", "\(destinationFinderItem.avAsset!.duration.seconds)", "\(destinationFinderItem.frameRate!)"]]))
                                        Configuration.main.saveError("")
                                    }
                                    
                                    if videos.count - 1 == videoIndex {
                                        completion()
                                    } else {
                                        processSingleVideo(withIndex: videoIndex + 1, completion: completion)
                                    }
                                    
                                } failure: { error in
                                    print(error.debugDescription)
                                }
                            }
                            
                        }
                        
                        index += 1
                    }
                }
            }
            
            status("processing videos")
            processSingleVideo(withIndex: 0) {
                completion()
            }
            
        } else {
            status("Completed")
            completion()
        }
        
    }
    
}

class WorkItem: Equatable, Identifiable {
    var finderItem: FinderItem
    var progress: Double
    var type: ItemType
    
    enum ItemType: String {
        case video, image
    }
    
    enum Status: String {
        case splittingVideo, generatingImages, savingVideos, mergingVideos, mergingAudio
    }
    
    init(at finderItem: FinderItem, type: ItemType) {
        self.finderItem = finderItem
        self.progress = 0
        self.type = type
    }
    
    static func == (lhs: WorkItem, rhs: WorkItem) -> Bool {
        lhs.finderItem == rhs.finderItem
    }
}

struct ContentView: View {
    @State var finderItems: [WorkItem] = []
    @State var isSheetShown: Bool = false
    @State var isProcessing: Bool = false
    @State var isCreatingPDF: Bool = false
    @State var modelUsed: Waifu2xModel? = nil
    @State var chosenScaleLevel: String = "1"
    @State var videoSegmentLength = 2000
    @State var frameInterpolation = "none"
    @State var enableConcurrent = true
    @State var gridNumber = Configuration.main.gridNumber
    @State var aspectRatio = Configuration.main.aspectRatio
    
    @State var isShowingLoadingView = false
    
    var body: some View {
        VStack {
            if finderItems.isEmpty {
                welcomeView(finderItems: $finderItems, isShowingLoadingView: $isShowingLoadingView)
            } else {
                GeometryReader { geometry in
                    
                    withAnimation {
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: Int(8 / gridNumber))) {
                                ForEach(finderItems) { item in
                                    GridItemView(finderItems: $finderItems, gridNumber: $gridNumber, aspectRatio: $aspectRatio, isLoading: $isShowingLoadingView, item: item, geometry: geometry)
                                }
                            }
                            .padding()
                            
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            isShowingLoadingView = true
            DispatchQueue(label: "background", qos: .userInitiated).async {
                for i in providers {
                    i.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, error in
                        guard error == nil else { return }
                        guard let urlData = urlData as? Data else { return }
                        guard let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                        
                        let item = FinderItem(at: url)
                        finderItems = addItemIfPossible(of: item, to: finderItems)
                        
                        if i == providers.last {
                            isShowingLoadingView = false
                        }
                    }
                }
            }
            return true
        }
        .onChange(of: gridNumber, perform: { newValue in
            Configuration.main.gridNumber = newValue
            Configuration.main.write()
        })
        .sheet(isPresented: $isSheetShown, onDismiss: nil) {
            SpecificationsView(finderItems: finderItems, isShown: $isSheetShown, isProcessing: $isProcessing, modelUsed: $modelUsed, chosenScaleLevel: $chosenScaleLevel, videoSegmentLength: $videoSegmentLength, frameInterpolation: $frameInterpolation, enableConcurrentPerform: $enableConcurrent, frameHeight: !finderItems.allSatisfy({ $0.finderItem.avAsset == nil }) ? 400 : 350)
        }
        .sheet(isPresented: $isProcessing, onDismiss: nil) {
            ProcessingView(isProcessing: $isProcessing, finderItems: $finderItems, modelUsed: $modelUsed, isSheetShown: $isSheetShown, chosenScaleLevel: $chosenScaleLevel, isCreatingPDF: $isCreatingPDF, videoSegmentLength: $videoSegmentLength, frameInterpolation: $frameInterpolation, enableConcurrent: $enableConcurrent)
        }
        .sheet(isPresented: $isCreatingPDF, onDismiss: nil) {
            ProcessingPDFView(isCreatingPDF: $isCreatingPDF)
        }
        .sheet(isPresented: $isShowingLoadingView, onDismiss: nil, content: {
            LoadingView(text: "Loading files...")
                .frame(width: 400, height: 75)
        })
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Remove All") {
                    finderItems = []
                }
                .disabled(finderItems.isEmpty)
                .help("Remove all files.")
            }
            
            ToolbarItemGroup {
                Button(action: {
                    withAnimation {
                        aspectRatio.toggle()
                        Configuration.main.aspectRatio = aspectRatio
                        Configuration.main.write()
                    }
                }, label: {
                    Label("", systemImage: aspectRatio ? "rectangle.arrowtriangle.2.outward" : "rectangle.arrowtriangle.2.inward")
                        .labelStyle(.iconOnly)
                })
                .help("Show thumbnails as square or in full aspect ratio.")
                
                Slider(
                    value: $gridNumber,
                    in: 1...8,
                    minimumValueLabel:
                        Text("􀏅")
                        .font(.system(size: 8))
                        .onTapGesture(perform: {
                            withAnimation {
                                gridNumber = 1.6
                            }
                        }),
                    maximumValueLabel:
                        Text("􀏅")
                        .font(.system(size: 16))
                        .onTapGesture(perform: {
                            withAnimation {
                                gridNumber = 1.6
                            }
                        })
                ) {
                    Text("Grid Item Count\nTap to restore default.")
                }
                .frame(width: 150)
                .help("Set the size of each thumbnail.")
                
                Button("Add Item") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = true
                    if panel.runModal() == .OK {
                        isShowingLoadingView = true
                        DispatchQueue(label: "background", qos: .userInitiated).async {
                            for i in panel.urls {
                                finderItems = addItemIfPossible(of: FinderItem(at: i), to: finderItems)
                            }
                            isShowingLoadingView = false
                        }
                    }
                }
                .help("Add another item.")
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    isSheetShown = true
                }
                .disabled(finderItems.isEmpty || isSheetShown)
                .help("Begin processing.")
            }
        }
    }
}

struct welcomeView: View {
    
    @Binding var finderItems: [WorkItem]
    @Binding var isShowingLoadingView: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "square.and.arrow.down.fill")
                .resizable()
                .scaledToFit()
                .padding(.all)
                .frame(width: 100, height: 100, alignment: .center)
            Text("Drag files or folder.")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.all)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.all, 0.0)
        .onTapGesture(count: 2) {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = true
            if panel.runModal() == .OK {
                isShowingLoadingView = true
                DispatchQueue(label: "background", qos: .userInitiated).async {
                    for i in panel.urls {
                        finderItems = addItemIfPossible(of: FinderItem(at: i), to: finderItems)
                    }
                    isShowingLoadingView = false
                }
            }
        }
    }
}


struct GridItemView: View {
    
    @Binding var finderItems: [WorkItem]
    @Binding var gridNumber: Double
    @Binding var aspectRatio: Bool
    @Binding var isLoading: Bool
    
    @State var image: NSImage? = nil
    
    let item: WorkItem
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .center) {
            
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .cornerRadius(5)
                    .aspectRatio(contentMode: aspectRatio ? .fit : .fill)
                    .frame(width: geometry.size.width * gridNumber / 8.5, height: geometry.size.width * gridNumber / 8.5)
                    .clipped()
                    .cornerRadius(5)
                    .padding([.top, .leading, .trailing])
            } else {
                Rectangle()
                    .padding([.top, .leading, .trailing])
                    .opacity(0)
                    .frame(width: geometry.size.width * gridNumber / 8.5, height: geometry.size.width * gridNumber / 8.5)
            }
            Text(((item.finderItem.relativePath ?? item.finderItem.fileName)))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding([.leading, .bottom, .trailing])
        }
        .contextMenu {
            Button("Open") {
                item.finderItem.open()
            }
            Button("Show in Finder") {
                shell(["open \(item.finderItem.shellPath) -R"])
            }
            Button("Delete") {
                withAnimation {
                    _ = finderItems.remove(at: finderItems.firstIndex(of: item)!)
                }
            }
        }
        .onTapGesture(count: 2, perform: {
            item.finderItem.open()
        })
        .onAppear {
            DispatchQueue(label: "img", qos: .utility).async {
                image = (item.finderItem.image ?? item.finderItem.firstFrame) ?? NSImage(named: "placeholder")!
                isLoading = false
            }
        }
        .help({() -> String in
            if let image = image {
                var value = """
                            name: \(item.finderItem.fileName)
                            path: \(item.finderItem.path)
                            size: \(image.cgImage(forProposedRect: nil, context: nil, hints: nil)!.width) × \(image.cgImage(forProposedRect: nil, context: nil, hints: nil)!.height)
                            """
                if item.type == .video {
                    value += "\nlength: \(item.finderItem.avAsset?.duration.seconds.expressedAsTime() ?? "0s")"
                }
                return value
            } else {
                return """
                        Loading...
                        name: \(item.finderItem.fileName)
                        path: \(item.finderItem.path)
                        (If this continuous, please transcode your video into HEVC and retry)
                        """
            }
        }())
    }
}

struct SpecificationsView: View {
    
    var finderItems: [WorkItem]
    
    @Binding var isShown: Bool
    @Binding var isProcessing: Bool
    @Binding var modelUsed: Waifu2xModel?
    @Binding var chosenScaleLevel: String {
        didSet {
            findModelClass()
        }
    }
    @Binding var videoSegmentLength: Int
    @Binding var frameInterpolation: String
    @Binding var enableConcurrentPerform: Bool
    
    let styleNames: [String] = ["anime", "photo"]
    @State var chosenStyle = Configuration.main.modelStyle {
        didSet {
            findModelClass()
        }
    }
    
    let noiseLevels: [String] = ["none", "0", "1", "2", "3"]
    @State var chosenNoiseLevel = "3" {
        didSet {
            findModelClass()
        }
    }
    
    @State var scaleLevels: [String] = []
    
    @State var modelClass: [String] = []
    @State var chosenModelClass: String = ""
    
    let videoSegmentOptions = [100, 500, 1000, 2000, 5000, 10000, 20000]
    let frameInterpolationOptions = ["none", "2", "4"]
    
    @State var frameHeight: CGFloat
    @State var storageRequired: String? = nil
    
    func findModelClass() {
        guard let chosenScaleLevel = Int(chosenScaleLevel) else {
            self.modelClass = []
            self.chosenModelClass = ""
            return
        }
        self.modelClass = Array(Set(Waifu2xModel.allModels.filter({ ($0.style == chosenStyle || $0.style == nil) && $0.noise == Int(chosenNoiseLevel) && $0.scale == ( chosenScaleLevel == 0 ? 1 : 2 ) }).map({ $0.class })))
        self.chosenModelClass = modelClass[0]
    }
    
    var body: some View {
        VStack {
            
            Spacer()
            
            HStack(spacing: 10) {
                VStack(spacing: 19) {
                    if Int(chosenScaleLevel) != nil {
                        HStack {
                            Spacer()
                            Text("Style:")
                                .padding(.bottom)
                                .help("anime: for illustrations or 2D images or CG\nphoto: for photos of real world or 3D images")
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Text("Scale Level:")
                            .help("Choose how much you want to scale.")
                    }
                    
                    if Int(chosenScaleLevel) != nil {
                        HStack {
                            Spacer()
                            Text("Denoise Level:")
                                .help("denoise level 3 recommended.\nHint: Don't know which to choose? go to Compare > Compare Models and try by yourself!")
                        }
                    }
                    
//                    if !modelClass.isEmpty {
//                        HStack {
//                            Spacer()
//                            Text("Model Class:")
//                                .onHover { bool in
//                                    isShowingModelClassHint = bool
//                                }
//                                .padding(.bottom)
//                        }
//                    }
                    
                    if !finderItems.allSatisfy({ $0.type == .image }) {
                        HStack {
                            Spacer()
                            Text("Video segmentation:")
                                .help("Lager the value, less the storage used. But the process would be slower.")
                        }
                        .padding(.top)
                        
                        HStack {
                            Spacer()
                            Text("Frame Interpolation:")
                                .help("Enable frame interpolation will make video smoother")
                        }
                    } else if finderItems.allSatisfy({ $0.type == .image }) {
                        HStack {
                            Spacer()
                            Text("Enable Concurrent Perform:")
                                .help("Please enable this unless the images are large.")
                        }
                    }
                }
                
                VStack(spacing: 15) {
                    
                    if Int(chosenScaleLevel) != nil {
                        Menu(chosenStyle) {
                            ForEach(styleNames, id: \.self) { item in
                                Button(item) {
                                    chosenStyle = item
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                    
                    Menu(Int(chosenScaleLevel) != nil ? pow(2, Int(chosenScaleLevel)!).description : chosenScaleLevel) {
                        ForEach(scaleLevels, id: \.self) { item in
                            Button(Int(item) != nil ? pow(2, Int(item)!).description : item) {
                                chosenScaleLevel = item
                            }
                        }
                    }
                    
                    if Int(chosenScaleLevel) != nil {
                        Menu(chosenNoiseLevel.description) {
                            ForEach(noiseLevels, id: \.self) { item in
                                Button(item.description) {
                                    chosenNoiseLevel = item
                                    self.storageRequired = nil
                                }
                            }
                        }
                    }
                    
//                    if !modelClass.isEmpty {
//                        Menu(chosenModelClass) {
//                            ForEach(modelClass, id: \.self) { item in
//                                Button(item) {
//                                    chosenModelClass = item
//                                }
//                            }
//                        }
//                        .padding(.bottom)
//                        .popover(isPresented: $isShowingModelClassHint) {
//                            Text("The model to use.")
//                                .padding(.all)
//
//                        }
//                    }
                    
                    if !finderItems.allSatisfy({ $0.type == .image }) {
                        Menu(videoSegmentLength.description + " frames") {
                            ForEach(videoSegmentOptions, id: \.self) { item in
                                Button(item.description + " frames") {
                                    videoSegmentLength = item
                                    self.storageRequired = nil
                                }
                            }
                        }
                        .padding(.top)
                        
                        Menu(Int(frameInterpolation) != nil ? frameInterpolation + "x" : frameInterpolation) {
                            ForEach(frameInterpolationOptions, id: \.self) { item in
                                Button(Int(item) != nil ? item + "x" : item) {
                                    frameInterpolation = item
                                }
                            }
                        }
                    } else if finderItems.allSatisfy({ $0.type == .image }) {
                        Menu(enableConcurrentPerform.description) {
                            ForEach([true, false], id: \.self) { item in
                                Button(item.description) {
                                    enableConcurrentPerform = item
                                }
                            }
                        }
                    }
                }
                
            }
                .padding(.horizontal, 50.0)
            
            Spacer()
            
            HStack {
                
                Spacer()
                
                if let storageRequired = storageRequired, !finderItems.allSatisfy({ $0.type == .image }) {
                    Text("Estimated Storage required: \(storageRequired)")
                        .padding(.trailing)
                        .help("Storage required when processing the videos.\nIf you can not afford, lower the video segment length.")
                }
                
                Button {
                    isShown = false
                } label: {
                    Text("Cancel")
                        .frame(width: 80)
                }
                .padding(.trailing)
                .help("Return to previous page.")
                
                Button {
                    isProcessing = true
                    isShown = false
                    
                    if chosenScaleLevel == "none" {
                        self.modelUsed = nil
                    } else {
                        self.modelUsed = Waifu2xModel.allModels.filter({ ($0.style == chosenStyle || $0.style == nil) && $0.noise == Int(chosenNoiseLevel) && $0.scale == ( Int(chosenScaleLevel)! == 0 ? 1 : 2 ) && $0.class == self.chosenModelClass }).first!
                    }
                    
                } label: {
                    Text("OK")
                        .frame(width: 80)
                }
                .disabled(frameInterpolation == "none" && chosenScaleLevel == "none")
                .help("Begin processing.")
            }
                .padding(.all)
        }
            .padding(.all)
            .frame(width: 600, height: frameHeight)
            .onAppear {
                DispatchQueue(label: "background").async {
                    findModelClass()
                    self.storageRequired = estimateSize(finderItems: finderItems.map({ $0.finderItem }), frames: videoSegmentLength, scale: self.chosenScaleLevel)
                    
                    self.scaleLevels = { ()-> [String] in
                        if finderItems.allSatisfy({ $0.type == .image }) {
                            return  ["0", "1", "2", "3", "4", "5"]
                        } else {
                            return ["none", "0", "1", "2", "3"]
                        }
                    }()
                }
            }
            .onChange(of: chosenStyle) { newValue in
                Configuration.main.modelStyle = newValue
            }
            .onChange(of: chosenScaleLevel) { newValue in
                if newValue == "4" || newValue == "5" {
                    enableConcurrentPerform = false
                }
                if newValue == "none" || finderItems.allSatisfy({ $0.type == .image }) {
                    withAnimation {
                        frameHeight = 350
                    }
                } else {
                    withAnimation {
                        frameHeight = 400
                    }
                }
                DispatchQueue(label: "background").async {
                    self.storageRequired = estimateSize(finderItems: finderItems.map({ $0.finderItem }), frames: videoSegmentLength, scale: self.chosenScaleLevel)
                }
            }
            .onChange(of: videoSegmentLength) { newValue in
                DispatchQueue(label: "background").async {
                    self.storageRequired = estimateSize(finderItems: finderItems.map({ $0.finderItem }), frames: videoSegmentLength, scale: self.chosenScaleLevel)
                }
            }
    }
    
}


struct ProcessingView: View {
    
    @Binding var isProcessing: Bool
    @Binding var finderItems: [WorkItem]
    @Binding var modelUsed: Waifu2xModel?
    @Binding var isSheetShown: Bool
    @Binding var chosenScaleLevel: String
    @Binding var isCreatingPDF: Bool
    @Binding var videoSegmentLength: Int
    @Binding var frameInterpolation: String
    @Binding var enableConcurrent: Bool
    
    @State var processedItemsCounter: Int = 0
    @State var currentTimeTaken: Double = 0 // up to 1s
    @State var pastTimeTaken: Double = 0 // up to 1s
    @State var isPaused: Bool = false
    @State var timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    @State var isFinished: Bool = false
    @State var progress: Double = 0.0
    @State var status: String = "Loading..."
    @State var statusProgress: (progress: Int, total: Int)? = nil
    @State var workItem: DispatchWorkItem? = nil
    @State var isShowingQuitConfirmation = false
    @State var isShowingReplace = false
    
    var background: DispatchQueue = DispatchQueue(label: "background", qos: .utility)
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .trailing, spacing: 10) {
                    VStack(alignment: .trailing, spacing: 10) {
                        Text("Status:")
                        
                        if statusProgress != nil, !isFinished {
                            Text("progress:")
                        }
                        
                        if modelUsed != nil {
                            Text("ML Model:")
                        }
                    }
                    
                    Spacer()
                    
                    Text("Processed:")
                    Text("To be processed:")
                    Text("Time Spent:")
                    Text("Time Remaining:")
                    Text("ETA:")
                    
                    Spacer()
                }
                .padding(.leading)
                
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(status)
                            .lineLimit(1)
                        
                        if let statusProgress = statusProgress, !isFinished {
                            Text("\(statusProgress.progress) / \(statusProgress.total)")
                        }
                        
                        if modelUsed != nil {
                            Text(modelUsed!.name)
                        }
                    }
                    
                    Spacer()
                    
                    if processedItemsCounter >= 2 {
                        Text("\(processedItemsCounter) items")
                    } else {
                        Text("\(processedItemsCounter) item")
                    }
                    
                    if isFinished {
                        Text("0 item")
                    } else if finderItems.count - processedItemsCounter >= 2 {
                        Text("\(finderItems.count - processedItemsCounter) items")
                    } else {
                        Text("\(finderItems.count - processedItemsCounter) item")
                    }
                    
                    Text((pastTimeTaken).expressedAsTime())
                    
                    Text({ ()-> String in
                        guard !isFinished else { return "finished" }
                        guard !isPaused else { return "paused" }
                        guard progress != 0 else { return "calculating..." }
                        
                        var value = (pastTimeTaken) / progress
                        value -= pastTimeTaken
                        
                        guard value > 0 else { return "calculating..." }
                        
                        return value.expressedAsTime()
                    }())
                    
                    Text({ ()-> String in
                        guard !isFinished else { return "finished" }
                        guard !isPaused else { return "paused" }
                        guard progress != 0 else { return "calculating..." }
                        
                        var value = (pastTimeTaken) / progress
                        value -= pastTimeTaken
                        
                        guard value > 0 else { return "calculating..." }
                        
                        let date = Date().addingTimeInterval(value)
                        
                        let formatter = DateFormatter()
                        if value < 10 * 60 * 60 {
                            formatter.dateStyle = .none
                        } else {
                            formatter.dateStyle = .medium
                        }
                        formatter.timeStyle = .medium
                        
                        return formatter.string(from: date)
                    }())
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            ProgressView(value: {()->Double in
                guard !finderItems.isEmpty else { return 1 }
                
                return progress <= 1 ? progress : 1
            }(), total: 1.0)
                .help("\(String(format: "%.2f", progress * 100))%")
            .padding([.bottom])
            
            Spacer()
            
            HStack {
                Spacer()
                
                if !isFinished {
                    Button() {
                        isShowingQuitConfirmation = true
                    } label: {
                        Text("Cancel")
                            .frame(width: 80)
                    }
                    .padding(.trailing)
                    .help("Cancel and quit.")
                    
                    Button() {
                        isPaused.toggle()
                    } label: {
                        Text(isPaused ? "Resume" : "Pause")
                            .frame(width: 80)
                    }
                    .disabled(true)
                } else {
                    Button() {
                        finderItems = []
                        isProcessing = false
                        isCreatingPDF = true
                    } label: {
                        Text("Create PDF")
                            .frame(width: 80)
                    }
                    .disabled((FinderItem(at: "\(Configuration.main.saveFolder)").children?.filter({ $0.isDirectory }).isEmpty ?? false))
                    .padding(.trailing)
                    
                    Button("Show in Finder") {
                        shell(["open \(FinderItem(at: Configuration.main.saveFolder).shellPath)"])
                    }
                    .padding(.trailing)
                    
                    Button() {
                        finderItems = []
                        isProcessing = false
                    } label: {
                        Text("Done")
                            .frame(width: 80)
                    }
                }
            }
        }
            .padding(.all)
            .frame(width: 600, height: 350)
            .onAppear {
                
                background.async {
                    for i in self.finderItems {
                        if FinderItem(at: Configuration.main.saveFolder).hasChildren, FinderItem(at: Configuration.main.saveFolder).allChildren!.contains(where: { $0.relativePath == i.finderItem.relativePath || $0.relativePath == i.finderItem.name }) {
                            isShowingReplace = true
                            return
                        }
                    }
                    
                    finderItems.work(Int(chosenScaleLevel), modelUsed: modelUsed, videoSegmentFrames: videoSegmentLength, frameInterpolation: Int(frameInterpolation), enableConcurrent: enableConcurrent) { status in
                        self.status = status
                    } onStatusProgressChanged: { progress,total in
                        if progress != nil {
                            self.statusProgress = (progress!, total!)
                        } else {
                            self.statusProgress = nil
                        }
                    } onProgressChanged: { progress in
                        self.progress = progress
                    } didFinishOneItem: { finished,total in
                        processedItemsCounter = finished
                    } completion: {
                        isFinished = true
                    }
                }
                
            }
            .onReceive(timer) { timer in
                currentTimeTaken += 1
                pastTimeTaken += 1
            }
            .onChange(of: isPaused) { newValue in
                if newValue {
                    timer.upstream.connect().cancel()
                    background.suspend()
                } else {
                    timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
                    background.resume()
                }
            }
            .onChange(of: isFinished) { newValue in
                if newValue {
                    timer.upstream.connect().cancel()
                }
            }
            .confirmationDialog("Quit the app?", isPresented: $isShowingQuitConfirmation) {
                Button("Quit", role: .destructive) {
                    exit(0)
                }
                
                Button("Cancel", role: .cancel) {
                    isShowingQuitConfirmation = false
                }
            }
            .sheet(isPresented: $isShowingReplace, onDismiss: nil) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .padding(.horizontal)
                        .font(.system(size: 30))
                    
                    VStack {
                        HStack {
                            Text("Items of the same name already exists in output location.\nDo you want to replace them?")
                                .padding(.top)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            Button() {
                                for i in self.finderItems {
                                    if FinderItem(at: Configuration.main.saveFolder).hasChildren, FinderItem(at: Configuration.main.saveFolder).allChildren!.contains(where: { $0.relativePath == i.finderItem.relativePath || $0.relativePath == i.finderItem.name }) {
                                        finderItems.remove(at: finderItems.firstIndex(of: i)!)
                                    }
                                }
                                isShowingReplace = false
                                
                                background.async {
                                    finderItems.work(Int(chosenScaleLevel), modelUsed: modelUsed, videoSegmentFrames: videoSegmentLength, frameInterpolation: Int(frameInterpolation), enableConcurrent: enableConcurrent) { status in
                                        self.status = status
                                    } onStatusProgressChanged: { progress,total in
                                        if progress != nil {
                                            self.statusProgress = (progress!, total!)
                                        } else {
                                            self.statusProgress = nil
                                        }
                                    } onProgressChanged: { progress in
                                        self.progress = progress
                                    } didFinishOneItem: { finished,total in
                                        processedItemsCounter = finished
                                    } completion: {
                                        isFinished = true
                                    }
                                }
                            } label: {
                                Text("Skip")
                                    .frame(width: 80)
                            }
                            .padding(.trailing)
                            Button() {
                                isShowingReplace = false
                                
                                background.async {
                                    finderItems.work(Int(chosenScaleLevel), modelUsed: modelUsed, videoSegmentFrames: videoSegmentLength, frameInterpolation: Int(frameInterpolation), enableConcurrent: enableConcurrent) { status in
                                        self.status = status
                                    } onStatusProgressChanged: { progress,total in
                                        if progress != nil {
                                            self.statusProgress = (progress!, total!)
                                        } else {
                                            self.statusProgress = nil
                                        }
                                    } onProgressChanged: { progress in
                                        self.progress = progress
                                    } didFinishOneItem: { finished,total in
                                        processedItemsCounter = finished
                                    } completion: {
                                        isFinished = true
                                    }
                                }
                            } label: {
                                Text("Replace")
                                    .frame(width: 80)
                            }
                        }
                        .padding([.horizontal, .bottom])
                    }
                }
                .frame(width: 500, height: 100)
            }
    }
}


struct ProcessingPDFView: View {
    
    @Binding var isCreatingPDF: Bool
    
    @State var finderItemsCount: Int = 0
    @State var processedItemsCount: Int = 0
    @State var currentProcessingItem: FinderItem? = nil
    @State var isFinished: Bool = false
    
    var body: some View {
        VStack {
            
            Spacer()
            
            HStack {
                VStack(spacing: 10) {
                    Text("Processing:")
                    Text("Processed:")
                }
                
                VStack(spacing: 10) {
                    HStack {
                        if let currentProcessingItem = currentProcessingItem {
                            Text(isFinished ? "Finished" : currentProcessingItem.relativePath ?? currentProcessingItem.fileName)
                        } else {
                            Text("Loading")
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(processedItemsCount) items")
                        
                        Spacer()
                    }
                }
            }
            .padding([.horizontal, .bottom])
            
            if !isFinished {
                ProgressView()
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
            } else {
                ProgressView(value: 1)
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
            }
            
            HStack {
                Spacer()
                
                Button("Show in Finder") {
                    shell(["open \(FinderItem(at: "\(NSHomeDirectory())/Downloads/PDF output").shellPath)"])
                }
                .padding(.trailing)
                
                Button() {
                    isCreatingPDF = false
                } label: {
                    Text("Done")
                        .frame(width: 80)
                }
                .disabled(!isFinished)
            }
            .padding()
        }
        .padding(.all)
        .frame(width: 600, height: 170)
        .onAppear {
            
            DispatchQueue(label: "background").async {
                isProcessingCancelled = false
                
                FinderItem.createPDF(fromFolder: FinderItem(at: "\(Configuration.main.saveFolder)")) { item in
                    currentProcessingItem = item
                    processedItemsCount += 1
                }
                
                isFinished = true
            }
            
        }
        
    }
}

struct LoadingView: View {
    
    @State var text: String
    
    var body: some View {
        
        VStack {
            HStack {
                Text(text)
                    .multilineTextAlignment(.leading)
                    .padding([.horizontal, .top])
                
                Spacer()
            }
            
            ProgressView()
                .progressViewStyle(.linear)
                .padding([.horizontal, .bottom])
        }
        
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingPDFView(isCreatingPDF: .constant(true))
    }
}
