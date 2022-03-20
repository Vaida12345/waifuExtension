//
//  ProcessFile.swift
//  waifuExtension
//
//  Created by Vaida on 3/15/22.
//

import Foundation
import AVFoundation
import AppKit
import PDFKit

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
        item.iterated { child in
            autoreleasepool {
                var child = child
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
    
    func work(model: ModelCoordinator, task: ShellManager, status: @escaping ((_ status: String)->()), onStatusProgressChanged: @escaping ((_ progress: Int?, _ total: Int?)->()), onProgressChanged: @escaping ((_ progress: Double) -> ()), didFinishOneItem: @escaping ((_ finished: Int, _ total: Int)->()), completion: @escaping (() -> ())) {
        
        func runImageModel(inputItem: FinderItem, outputItem: FinderItem) {
            
            if model.isCaffe {
                if model.scaleLevel == 4 {
                    model.runImageModel(input: .path(inputItem), outputItem: inputItem, task: task)
                    model.runImageModel(input: .path(inputItem), outputItem: outputItem, task: task)
                } else if model.scaleLevel == 8 {
                    model.runImageModel(input: .path(inputItem), outputItem: inputItem, task: task)
                    model.runImageModel(input: .path(inputItem), outputItem: inputItem, task: task)
                    model.runImageModel(input: .path(inputItem), outputItem: outputItem, task: task)
                } else {
                    model.runImageModel(input: .path(inputItem), outputItem: outputItem, task: task)
                }
            } else {
                model.runImageModel(input: .path(inputItem), outputItem: outputItem, task: task)
            }
        }
        
        var concurrentProcessingImagesCount = 0
        func processImage(imageIndex: Int) {
            autoreleasepool {
                
                guard !isProcessingCancelled else { return }
                
                backgroundQueue.async {
                    concurrentProcessingImagesCount += 1
                    
                    status("processing \(concurrentProcessingImagesCount) images\(concurrentProcessingImagesCount != 1 ? " in parallel" : "")")
                }
                
                let currentImage = images[imageIndex]
                
                let outputFileName: String
                if let name = currentImage.finderItem.relativePath {
                    outputFileName = name[..<name.lastIndex(of: ".")!] + ".png"
                } else {
                    outputFileName = currentImage.finderItem.fileName + ".png"
                }
                
                let finderItemAtImageOutputPath = FinderItem(at: "\(Configuration.main.saveFolder)/\(outputFileName)")
                
                try! finderItemAtImageOutputPath.generateDirectory()
                
                runImageModel(inputItem: currentImage.finderItem, outputItem: finderItemAtImageOutputPath)
                task.wait()
                
                backgroundQueue.async {
                    currentImage.progress = 1
                    concurrentProcessingImagesCount -= 1
                    status("processing \(concurrentProcessingImagesCount) images\(concurrentProcessingImagesCount != 1 ? " in parallel" : "")")
                    finishedItemsCounter += 1
                    didFinishOneItem(finishedItemsCounter, totalItemCounter)
                }
                
            }
        }
        
        let images = self.filter({ $0.type == .image })
        let videos = self.filter({ $0.type == .video })
        let backgroundQueue = DispatchQueue(label: "[WorkItem] background dispatch queue")
        
        let totalItemCounter = self.count
        let totalFrames = videos.map({ Double(($0.finderItem.avAsset?.frameRate!)!) * $0.finderItem.avAsset!.duration.seconds }).reduce(0.0, +) + Double(images.count)
        var finishedItemsCounter = 0
        
        try! FinderItem(at: Configuration.main.saveFolder).generateDirectory(isFolder: true)
        FinderItem(at: Configuration.main.saveFolder).setIcon(image: NSImage(imageLiteralResourceName: "icon"))
        
        if !images.isEmpty {
            status("processing images")
            
            if model.enableConcurrent && model.isCaffe {
                DispatchQueue.concurrentPerform(iterations: images.count) { imageIndex in
                    processImage(imageIndex: imageIndex)
                }
            } else {
                var imageIndex = 0
                while imageIndex < images.count {
                    processImage(imageIndex: imageIndex)
                    imageIndex += 1
                    onProgressChanged(Double(imageIndex) / Double(images.count))
                }
            }
            
            backgroundQueue.sync {
                status("finished processing images")
            }
        }
        
        if !videos.isEmpty {
            //helper functions
            
            func splitVideo(duration: Double, filePath: String, currentVideo: WorkItem, completion: @escaping ((_ paths: [String])->())) {
                
                guard !isProcessingCancelled else { return }
                
                status("splitting videos")
                
                try! FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo").generateDirectory(isFolder: true)
                var finishedCounter = 0
                var paths: [String] = []
                
                func splitVideo(withIndex segmentIndex: Int, duration: Double, filePath: String, currentVideo: WorkItem, completion: @escaping (()->())) {
                    
                    guard !isProcessingCancelled else { return }
                    let videoSegmentLength = Double(model.videoSegmentFrames) / Double(currentVideo.finderItem.avAsset!.frameRate!)
                    guard Double(segmentIndex) < (duration / videoSegmentLength).rounded(.up) else { return }
                    
                    var segmentSequence = String(segmentIndex)
                    while segmentSequence.count <= 5 { segmentSequence.insert("0", at: segmentSequence.startIndex) }
                    
                    let path = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo/video \(segmentSequence).m4v"
                    try! FinderItem(at: path).generateDirectory()
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
                    let frameRate = currentVideo.finderItem.avAsset!.frameRate!
                    
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
                    try! FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames").generateDirectory(isFolder: true)
                    try! FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames").generateDirectory(isFolder: true)
                    let factor: Double = model.enableFrameInterpolation ? 2 : 1
                    var colorSpace: CGColorSpace? = nil
                    
                    for frameCounter in 0..<requiredFramesCount {
                        autoreleasepool {
                            
                            var sequence = String(frameCounter)
                            while sequence.count < 6 { sequence.insert("0", at: sequence.startIndex) }
                            
                            // generate frames
                            guard FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(sequence).png").image == nil else {
                                currentVideo.progress += 1 / factor
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
                            let thumbnail = NSImage(cgImage: imageRef!, size: NSSize(width: imageRef!.width, height: imageRef!.height))
                            model.runImageModel(input: .image(thumbnail), outputItem: FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(sequence).png"), task: task)
                            task.wait()
                            print("waited")
                            
                            do { try FinderItem(at: "\(NSHomeDirectory())/tmp/vulkan/input").removeFile() } catch { print(error) }
                            currentVideo.progress += 1 / factor
                            onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / totalFrames)
                        }
                    }
                    
                    if model.enableFrameInterpolation {
                        onStatusProgressChanged(nil, nil)
                        var frameCounter = 0
                        
                        while frameCounter < FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames").children!.count {
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
                                
                                var processedSequence = String(frameCounter * model.frameInterpolation)
                                while processedSequence.count < 6 { processedSequence.insert("0", at: processedSequence.startIndex) }
                                
                                var intermediateSequence = String(frameCounter * model.frameInterpolation - model.frameInterpolation / 2)
                                while intermediateSequence.count < 6 { intermediateSequence.insert("0", at: intermediateSequence.startIndex) }
                                
                                // will not save the previous frame
                                
                                try! FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(sequence).png").copy(to: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(processedSequence).png")
                                
                                if FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence).png").image == nil {
                                    let item1 = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(previousSequence).png")
                                    let item2 = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(sequence).png")
                                    let output = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence).png")
                                    
                                    if item1.image?.tiffRepresentation == item2.image?.tiffRepresentation {
                                        try! item1.copy(to: output.path)
                                    } else {
                                        model.runFrameModel(input1: item1.path, input2: item2.path, outputPath: output.path, task: task)
                                        task.wait()
                                    }
                                }
                                
                                var intermediateSequence1 = String(frameCounter * model.frameInterpolation - model.frameInterpolation / 2 - 1)
                                while intermediateSequence1.count < 6 { intermediateSequence1.insert("0", at: intermediateSequence1.startIndex) }
                                
                                var intermediateSequence3 = String(frameCounter * model.frameInterpolation - model.frameInterpolation / 2 + 1)
                                while intermediateSequence3.count < 6 { intermediateSequence3.insert("0", at: intermediateSequence3.startIndex) }
                                
                                if model.frameInterpolation == 4 && (FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence1).png").image == nil || FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence3).png").image == nil) {
                                    let item1 = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/\(previousSequence).png")
                                    let item2 = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence).png")
                                    let output = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence1).png")
                                    
                                    if item1.image?.tiffRepresentation == item2.image?.tiffRepresentation {
                                        try! item1.copy(to: output.path)
                                    } else {
                                        model.runFrameModel(input1: item1.path, input2: item2.path, outputPath: output.path, task: task)
                                        task.wait()
                                    }
                                    
                                    let item3 = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence).png")
                                    let item4 = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(processedSequence).png")
                                    let output2 = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames/\(intermediateSequence3).png")
                                    
                                    if item3.image?.tiffRepresentation == item4.image?.tiffRepresentation {
                                        try! item3.copy(to: output2.path)
                                    } else {
                                        model.runFrameModel(input1: item3.path, input2: item4.path, outputPath: output2.path, task: task)
                                        task.wait()
                                    }
                                    
                                    
                                }
                                
                                currentVideo.progress += 1 / Double(requiredFramesCount) / factor / totalSegmentsCount
                                onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / Double(totalItemCounter))
                                
                                frameCounter += 1
                            }
                        }
                    }
                    
                    try! FinderItem(at: mergedVideoPath).generateDirectory()
                    
                    let arbitraryFrame = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames/000000.png")
                    let arbitraryFrameCGImage = arbitraryFrame.image!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
                    
                    if !Configuration.main.isDevEnabled { try! FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo/video \(indexSequence).m4v").removeFile() }
                    
                    if !model.enableFrameInterpolation {
                        let enlargedFrames: [FinderItem] = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/splitVideo frames").children!
                        FinderItem.convertImageSequenceToVideo(enlargedFrames, videoPath: mergedVideoPath, videoSize: CGSize(width: arbitraryFrameCGImage.width, height: arbitraryFrameCGImage.height), videoFPS: currentVideo.finderItem.avAsset!.frameRate!, colorSpace: colorSpace) {
                            if !Configuration.main.isDevEnabled { try! FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)").removeFile() }
                            // completion after all videos are finished.
                            completion()
                        }
                    } else {
                        let enlargedFrames: [FinderItem] = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames").children!
                        FinderItem.convertImageSequenceToVideo(enlargedFrames, videoPath: mergedVideoPath, videoSize: CGSize(width: arbitraryFrameCGImage.width, height: arbitraryFrameCGImage.height), videoFPS: currentVideo.finderItem.avAsset!.frameRate! * Float(model.frameInterpolation), colorSpace: colorSpace) {
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
                
                try! FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)").generateDirectory(isFolder: true)
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
                            
                            FinderItem.mergeVideos(from: FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/videos").children!, toPath: outputPath, tempFolder: "\(Configuration.main.saveFolder)/tmp/\(filePath)/merging video", frameRate: currentVideo.finderItem.avAsset!.frameRate! * Float((model.enableFrameInterpolation ? 1 : model.frameInterpolation))) { urlGet, errorGet in
                                
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
                                    Configuration.main.saveLog(printMatrix(matrix: [["", "frames", "duration", "fps"], ["before", "\(currentVideo.finderItem.avAsset!.duration.seconds * Double(currentVideo.finderItem.avAsset!.frameRate!))", "\(currentVideo.finderItem.avAsset!.duration.seconds)", "\(currentVideo.finderItem.avAsset!.frameRate!)"], ["after", "\(destinationFinderItem.avAsset!.duration.seconds * Double(destinationFinderItem.avAsset!.frameRate!))", "\(destinationFinderItem.avAsset!.duration.seconds)", "\(destinationFinderItem.avAsset!.frameRate!)"]]))
                                    Configuration.main.saveLog("")
                                    print("")
                                    
                                    if abs((currentVideo.finderItem.avAsset!.duration.seconds * Double(currentVideo.finderItem.avAsset!.frameRate!)) - destinationFinderItem.avAsset!.duration.seconds * Double(destinationFinderItem.avAsset!.frameRate!)) > 5 {
                                        Configuration.main.saveError("Sorry, error occurred considering the following files:")
                                        Configuration.main.saveError(printMatrix(matrix: [["", "frames", "duration", "fps"], ["before", "\(currentVideo.finderItem.avAsset!.duration.seconds * Double(currentVideo.finderItem.avAsset!.frameRate!))", "\(currentVideo.finderItem.avAsset!.duration.seconds)", "\(currentVideo.finderItem.avAsset!.frameRate!)"], ["after", "\(destinationFinderItem.avAsset!.duration.seconds * Double(destinationFinderItem.avAsset!.frameRate!))", "\(destinationFinderItem.avAsset!.duration.seconds)", "\(destinationFinderItem.avAsset!.frameRate!)"]]))
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


extension FinderItem {
    
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
    
    /// Creates PDF from images in folders.
    static func createPDF(fromFolder folder: FinderItem, outputPath: String = "\(NSHomeDirectory())/Downloads/PDF Output", onChangingItem: ((_ item: FinderItem)->())? = nil) {
        
        precondition(folder.isExistence)
        precondition(folder.hasChildren)
        
        if let onChangingItem = onChangingItem {
            onChangingItem(folder)
        }
        
        if folder.hasSubfolder {
            for i in folder.children! {
                if i.isDirectory && i.hasChildren {
                    createPDF(fromFolder: i, outputPath: outputPath, onChangingItem: onChangingItem)
                }
            }
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
        
        var item = FinderItem(at: pastePath)
        item.generateOutputPath()
        
        document.write(toFile: item.path)
        
//        FinderItem(at: outputPath).setIcon(image: NSImage(named: "pdf icon")!)
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
        try! FinderItem(at: videoPath).generateDirectory()
        
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
                            print("The fps is \(FinderItem(at: videoPath).avAsset!.frameRate!)")
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
        
        try! FinderItem(at: tempFolder).generateDirectory(isFolder: true)
        
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
    
    
}



