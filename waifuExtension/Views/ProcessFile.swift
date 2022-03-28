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
import os

class WorkItem: Equatable, Identifiable, Hashable {
    var finderItem: FinderItem
    var type: ItemType
    
    enum ItemType: String {
        case video, image
    }
    
    enum Status: String {
        case splittingVideo, generatingImages, savingVideos, mergingVideos, mergingAudio
    }
    
    init(at finderItem: FinderItem, type: ItemType) {
        self.finderItem = finderItem
        self.type = type
    }
    
    static func == (lhs: WorkItem, rhs: WorkItem) -> Bool {
        lhs.finderItem == rhs.finderItem
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(finderItem)
        hasher.combine(type)
    }
}

struct orderedImages {
    var image: NSImage
    var index: Int
}

class Counter {
    var concurrentImage: Int = 0
    
    func increaseConcurrentImage() {
        concurrentImage += 1
    }
    
    func decreaseConcurrentImage() {
        concurrentImage -= 1
    }
}

class ArrayContainer<Element> {
    
    var contents: [Element] = []
    
    func append(_ newItem: Element) {
        contents.append(newItem)
    }
    
    var first: Element? {
        contents.first
    }
    
    func removeAll() {
        contents.removeAll()
    }
    
    func append(contentsOf sequence: [Element]) {
        self.contents.append(contentsOf: sequence)
    }
    
    func replace(with newValue: Element, at index: Int) {
        self.contents[index] = newValue
    }
    
}

class ProgressManager {
    
    class Image {
        
        let manager: ProgressManager
        
        /// The progress of the image.
        var progress: Double = 0 {
            didSet {
                manager.onProgressChanged(manager.progress)
                if progress == 1 {
                    manager.didFinishOneItem(manager.videos.filter{ $0.value.progress == 1 }.count + manager.images.filter{ $0.value.progress == 1 }.count, manager.videos.count + manager.images.count)
                }
            }
        }
        
        init(manager: ProgressManager) {
            self.manager = manager
        }
        
    }
    
    class Video {
        
        let manager: ProgressManager
        
        var interpolationProgress: Double = 0 {
            didSet {
                manager.onProgressChanged(manager.progress)
                if progress == 1 {
                    manager.didFinishOneItem(manager.videos.filter{ $0.value.progress == 1 }.count + manager.images.filter{ $0.value.progress == 1 }.count, manager.videos.count + manager.images.count)
                }
            }
        }
        var enlargeProgress: Double = 0 {
            didSet {
                manager.onProgressChanged(manager.progress)
                if progress == 1 {
                    manager.didFinishOneItem(manager.videos.filter{ $0.value.progress == 1 }.count + manager.images.filter{ $0.value.progress == 1 }.count, manager.videos.count + manager.images.count)
                }
            }
        }
        
        var interpolationLevel: Double = 1
        var totalFrames: Double = 0
        
        var progress: Double {
            if interpolationLevel == 1 {
                return enlargeProgress
            } else {
                return interpolationProgress / 2 + enlargeProgress / 2
            }
        }
        
        func updateInterpolation() {
            interpolationProgress += 1 / totalFrames
        }
        
        func updateEnlarge() {
            enlargeProgress += 1 / (totalFrames * interpolationLevel)
        }
        
        init(manager: ProgressManager) {
            self.manager = manager
        }
    }
    
    var videos: [WorkItem: Video] = [:]
    var images: [WorkItem: Image] = [:]
    
    var progress: Double {
        (images.values.reduce(0) {$0 + $1.progress} + videos.values.reduce(0.0) { $0 + $1.progress * $1.totalFrames * $1.interpolationLevel }) / (Double(images.values.count) + videos.values.reduce(0.0) { $0 + $1.totalFrames * $1.interpolationLevel })
    }
    
    var status: ((_ status: String)->()) = { _ in }
    var onStatusProgressChanged: ((_ progress: Int?, _ total: Int?)->()) = { _, _ in }
    var onProgressChanged: ((_ progress: Double) -> ()) = { _ in }
    var didFinishOneItem: ((_ finished: Int, _ total: Int)->()) = { _, _ in }
    
}


//TODO: recalculate estimate size

extension Array where Element == WorkItem {
    
    func contains(_ finderItem: FinderItem) -> Bool {
        return self.contains(WorkItem(at: finderItem, type: .image))
    }
    
    func work(model: ModelCoordinator, task: ShellManager, manager: ProgressManager) async {
        
        let logger = Logger()
        logger.info("Process File started with model: \(model) with \(self.filter{ $0.type == .image }.count) images and \(self.filter{ $0.type == .video }.count) videos")
        
        for i in self {
            if i.type == .image {
                manager.images[i] = .init(manager: manager)
            } else {
                let item = ProgressManager.Video.init(manager: manager)
                item.interpolationLevel = Double(model.frameInterpolation)
                item.totalFrames = Double(i.finderItem.avAsset!.frameRate!) * i.finderItem.avAsset!.duration.seconds
                manager.videos[i] = item
            }
        }
        
        let counter = Counter()
        
        @Sendable func processImage(imageIndex: Int) {
            counter.increaseConcurrentImage()
            manager.status("processing \(counter.concurrentImage) images\(counter.concurrentImage != 1 ? " in parallel" : "")")
            
            let currentImage = images[imageIndex]
            
            let outputFileName: String
            if let name = currentImage.finderItem.relativePath {
                outputFileName = name[..<name.lastIndex(of: ".")!] + ".png"
            } else {
                outputFileName = currentImage.finderItem.fileName + ".png"
            }
            
            let finderItemAtImageOutputPath = FinderItem(at: "\(Configuration.main.saveFolder)/\(outputFileName)")
            
            finderItemAtImageOutputPath.generateDirectory()
            
            if model.isCaffe {
                guard let image = currentImage.finderItem.image else { print("no image"); return }
                var output: NSImage? = nil
                let waifu2x = Waifu2x()
                if model.scaleLevel == 4 {
                    output = waifu2x.run(image, model: model)
                    output = waifu2x.run(output!.reload(), model: model)
                } else if model.scaleLevel == 8 {
                    output = waifu2x.run(image, model: model)
                    output = waifu2x.run(output!.reload(), model: model)
                    output = waifu2x.run(output!.reload(), model: model)
                } else {
                    output = waifu2x.run(image, model: model)
                }
                output?.write(to: finderItemAtImageOutputPath.path)
            } else {
                model.runImageModel(input: currentImage.finderItem, outputItem: finderItemAtImageOutputPath, task: task)
                task.wait()
            }
            
            manager.images[currentImage]!.progress = 1
            counter.decreaseConcurrentImage()
            manager.status("processing \(counter.concurrentImage) images\(counter.concurrentImage != 1 ? " in parallel" : "")")
        }
        
        @Sendable func distributeAssignments(iterations: Int, action: @escaping (Int) -> Void) {
            let odd = iterations % 2 == 1
            let task1 = DispatchQueue(label: "task 1")
            let task2 = DispatchQueue(label: "task 2")
            
            for i in 0..<iterations/2 {
                task1.async {
                    action(i*2)
                }
                task2.async {
                    action(i*2+1)
                }
                
                task1.sync { }
                task2.sync { }
            }
            
            if odd {
                action(iterations - 1)
            }
        }
        
        let images = self.filter({ $0.type == .image })
        let videos = self.filter({ $0.type == .video })
        
        FinderItem(at: Configuration.main.saveFolder).generateDirectory(isFolder: true)
        FinderItem(at: Configuration.main.saveFolder).setIcon(image: NSImage(imageLiteralResourceName: "icon"))
        
        @Sendable func generateFileName(from index: Int) -> String {
            var segmentSequence = String(index)
            while segmentSequence.count <= 5 { segmentSequence.insert("0", at: segmentSequence.startIndex) }
            return segmentSequence
        }
        
        if !images.isEmpty {
            manager.status("Processing Images")
            logger.info("Processing Images")
            
            if model.enableConcurrent && model.isCaffe {
                await Task {
                    DispatchQueue.concurrentPerform(iterations: images.count) { imageIndex in
                        processImage(imageIndex: imageIndex)
                    }
                }.value
            } else {
                distributeAssignments(iterations: images.count) { imageIndex in
                    processImage(imageIndex: imageIndex)
                }
            }
            
            manager.status("Finished Processing Images")
            logger.info("Finished Processing Images")
        }
        
        guard !videos.isEmpty else {
            manager.status("Completed")
            return
        }
        logger.info("Processing Videos")
        
        manager.status("processing videos")
        
        for currentVideo in videos {
            // Use this to prevent memory leak
            await Task {
                
                let filePath = currentVideo.finderItem.relativePath ?? (currentVideo.finderItem.fileName + currentVideo.finderItem.extensionName)
                let destinationFinderItem = FinderItem(at: "\(Configuration.main.saveFolder)/\(filePath)")
                
                if model.enableMemoryOnly {
                    // uses only memory
                    
                    manager.status("generating frames")
                    
                    let output = ArrayContainer<NSImage>()
                    var firstFrame: NSImage?
                    autoreleasepool {
                        guard let frames = currentVideo.finderItem.avAsset?.frames else { return }
                        firstFrame = frames.first
                        output.append(contentsOf: frames)
                    }
                    
                    DispatchQueue.concurrentPerform(iterations: output.contents.count) { index in
                        autoreleasepool {
                            let image = Waifu2x().run(output.contents[index].reload(), model: model)
                            
                            DispatchQueue(label: "adder").async {
                                output.replace(with: image!, at: index)
                            }
                            
                            manager.videos[currentVideo]!.updateEnlarge()
                        }
                    }
                    
                    DispatchQueue(label: "adder").sync { }
                    
                    manager.status("Converting frames to video")
                    
                    FinderItem.convertImageSequenceToVideo(output.contents, videoPath: destinationFinderItem.path, videoSize: output.first!.pixelSize!, videoFPS: currentVideo.finderItem.avAsset!.frameRate!, colorSpace: firstFrame?.cgImage(forProposedRect: nil, context: nil, hints: nil)?.colorSpace) {
                        
                        manager.status("Merging video with audio")
                        Task {
                            await FinderItem.mergeVideoWithAudio(videoUrl: destinationFinderItem.url, audioUrl: currentVideo.finderItem.url)
                        }
                        
                        manager.status("Completed")
                    }
                    return
                }
                
                manager.status("generating audio for \(filePath)")
                FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)").generateDirectory(isFolder: true)
                let audioPath = "\(Configuration.main.saveFolder)/tmp/\(filePath)/audio.m4a"
                do {
                    try await currentVideo.finderItem.saveAudioTrack(to: audioPath)
                } catch {
                    logger.error("failed to save audio track to \(audioPath)")
                }
                
                let duration = currentVideo.finderItem.avAsset!.duration.seconds
                
                // enter what it used to be splitVideo(duration: Double, filePath: String, currentVideo: WorkItem)
                
                manager.status("splitting videos")
                logger.info("splitting videos")
                
                FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo").generateDirectory(isFolder: true)
                
                // enter what it used to be splitVideo(withIndex segmentIndex: Int, duration: Double, filePath: String, currentVideo: WorkItem)
                
                let videoSegmentLength = Double(model.videoSegmentFrames) / Double(currentVideo.finderItem.avAsset!.frameRate!)
                let videoSegmentCount = Int((duration / videoSegmentLength).rounded(.up))
                
                for segmentIndex in 0..<videoSegmentCount {
                    // again, use await task to auto release
                    await Task {
                        
                        var segmentSequence = String(segmentIndex)
                        while segmentSequence.count <= 5 { segmentSequence.insert("0", at: segmentSequence.startIndex) }
                        
                        let path = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo/video \(segmentSequence).m4v"
                        FinderItem(at: path).generateDirectory()
                        guard FinderItem(at: path).avAsset == nil else {
                            
                            manager.onStatusProgressChanged(segmentIndex, videoSegmentCount)
                            return
                        }
                        
                        await FinderItem.trimVideo(sourceURL: currentVideo.finderItem.url, outputURL: URL(fileURLWithPath: path), startTime: (Double(segmentIndex) * Double(videoSegmentLength)), endTime: {()->Double in
                            if Double(segmentIndex) * videoSegmentLength + videoSegmentLength <= duration {
                                return Double(Double(segmentIndex) * videoSegmentLength + videoSegmentLength)
                            } else {
                                return Double(duration)
                            }
                        }())
                        
                        
                        manager.onStatusProgressChanged(segmentIndex, videoSegmentCount)
                        
                    }.value
                }
                
                manager.onStatusProgressChanged(nil, nil)
                logger.info("splitting videos finished")
                
                // enters the completion of split video
                
                for index in 0..<videoSegmentCount {
                    
                    // generate images
                    await Task {
                        
                        let path = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo/video \(generateFileName(from: index)).m4v"
                        
                        manager.status("generating images for \(filePath)")
                        logger.info("generating images for \(filePath), \(index) / \(videoSegmentCount)")
                        
                        manager.onStatusProgressChanged(index, videoSegmentCount)
                        
                        // generateImagesAndMergeToVideoForSegment
                        
                        let segmentsFinderItem = FinderItem(at: path)
                        guard let asset = segmentsFinderItem.avAsset else { return }
                        
                        let vidLength: CMTime = asset.duration
                        let seconds: Double = CMTimeGetSeconds(vidLength)
                        let frameRate = currentVideo.finderItem.avAsset!.frameRate!
                        
                        var requiredFramesCount = Int((seconds * Double(frameRate)).rounded())
                        
                        if requiredFramesCount == 0 { requiredFramesCount = 1 }
                        
                        let indexSequence = generateFileName(from: index)
                        
                        let mergedVideoPath = "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/videos/\(indexSequence).m4v"
                        FinderItem(at: mergedVideoPath).generateDirectory()
                        
                        guard FinderItem(at: mergedVideoPath).avAsset == nil else {
                            if !Configuration.main.isDevEnabled {
                                FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)").removeFile()
                            }
                            manager.videos[currentVideo]!.enlargeProgress = 1
                            manager.videos[currentVideo]!.interpolationLevel = 1
                            // completion after all videos are finished.
                            return
                        }
                        
                        logger.info("frames to process: \(requiredFramesCount)")
                        
                        let rawFramesFolder = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/raw frames")
                        rawFramesFolder.generateDirectory(isFolder: true)
                        var interpolatedFramesFolder = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames")
                        interpolatedFramesFolder.generateDirectory(isFolder: true)
                        let finishedFramesFolder = FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)/finished frames")
                        finishedFramesFolder.generateDirectory(isFolder: true)
                        
                        var colorSpace: CGColorSpace? = nil
                        
                        
                        var framesCounter = 0
                        
                        // write raw images
                        autoreleasepool {
                            let frames = segmentsFinderItem.avAsset!.frames!
                            framesCounter = frames.count
                            
                            for index in 0..<framesCounter {
                                let finderItemAtImageOutputPath = FinderItem(at: rawFramesFolder.path + "/\(generateFileName(from: index)).png")
                                guard !finderItemAtImageOutputPath.isExistence else { continue }
                                frames[index].write(to: finderItemAtImageOutputPath.path)
                            }
                        }
                        
                        // interpolate frames
                        if model.enableFrameInterpolation {
                            manager.onStatusProgressChanged(nil, nil)
                            
                            for frameCounter in 0..<framesCounter {
                                autoreleasepool {
                                    
                                    var sequence = String(frameCounter)
                                    while sequence.count < 6 { sequence.insert("0", at: sequence.startIndex) }
                                    
                                    // Add frames
                                    if frameCounter == 0 {
                                        FinderItem(at: "\(rawFramesFolder.path)/\(sequence).png").copy(to: "\(interpolatedFramesFolder.path)/\(generateFileName(from: 0)).png")
                                        
                                        manager.videos[currentVideo]!.updateInterpolation()
                                        
                                        return
                                    }
                                    
                                    let previousSequence = generateFileName(from: frameCounter - 1)
                                    let processedSequence = generateFileName(from: frameCounter * model.frameInterpolation)
                                    let intermediateSequence = generateFileName(from: frameCounter * model.frameInterpolation - model.frameInterpolation / 2)
                                    
                                    // will not save the previous frame
                                    
                                    FinderItem(at: "\(rawFramesFolder.path)/\(sequence).png").copy(to: "\(interpolatedFramesFolder.path)/\(processedSequence).png")
                                    
                                    if FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence).png").image == nil {
                                        let item1 = FinderItem(at: "\(rawFramesFolder.path)/\(previousSequence).png")
                                        let item2 = FinderItem(at: "\(rawFramesFolder.path)/\(sequence).png")
                                        let output = FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence).png")
                                        
                                        if item1.image?.tiffRepresentation == item2.image?.tiffRepresentation {
                                            item1.copy(to: output.path)
                                        } else {
                                            model.runFrameModel(input1: item1.path, input2: item2.path, outputPath: output.path, task: task)
                                            task.wait()
                                        }
                                    }
                                    
                                    guard model.frameInterpolation == 4 else {
                                        manager.videos[currentVideo]!.updateInterpolation()
                                        return
                                    }
                                    
                                    let intermediateSequence1 = generateFileName(from: frameCounter * model.frameInterpolation - model.frameInterpolation / 2 - 1)
                                    let intermediateSequence3 = generateFileName(from: frameCounter * model.frameInterpolation - model.frameInterpolation / 2 + 1)
                                    
                                    guard (FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence1).png").image == nil || FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence3).png").image == nil) else {
                                        
                                        manager.videos[currentVideo]!.updateInterpolation()
                                        return
                                    }
                                    
                                    let item1 = FinderItem(at: "\(rawFramesFolder.path)/\(previousSequence).png")
                                    let item2 = FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence).png")
                                    let output = FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence1).png")
                                    
                                    if item1.image?.tiffRepresentation == item2.image?.tiffRepresentation {
                                        item1.copy(to: output.path)
                                    } else {
                                        model.runFrameModel(input1: item1.path, input2: item2.path, outputPath: output.path, task: task)
                                        task.wait()
                                    }
                                    
                                    let item3 = FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence).png")
                                    let item4 = FinderItem(at: "\(interpolatedFramesFolder.path)/\(processedSequence).png")
                                    let output2 = FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence3).png")
                                    
                                    if item3.image?.tiffRepresentation == item4.image?.tiffRepresentation {
                                        item3.copy(to: output2.path)
                                    } else {
                                        model.runFrameModel(input1: item3.path, input2: item4.path, outputPath: output2.path, task: task)
                                        task.wait()
                                    }
                                    
                                    manager.videos[currentVideo]!.updateInterpolation()
                                    
                                }
                                
                            }
                        } else {
                            interpolatedFramesFolder = rawFramesFolder
                        }
                        
                        framesCounter = interpolatedFramesFolder.children?.filter{ $0.image != nil }.count ?? framesCounter
                        
                        // now process whatever interpolatedFramesFolder refers to
                        
                        if model.isCaffe {
                            let folder = interpolatedFramesFolder
                            
                            if colorSpace == nil {
                                let path = folder.path + "/\(generateFileName(from: 0)).png"
                                let imageItem = FinderItem(at: path)
                                
                                colorSpace = imageItem.image!.cgImage(forProposedRect: nil, context: nil, hints: nil)?.colorSpace
                            }
                            
                            DispatchQueue.concurrentPerform(iterations: framesCounter) { index in
                                
                                let path = folder.path + "/\(generateFileName(from: index)).png"
                                let imageItem = FinderItem(at: path)
                                
                                let finderItemAtImageOutputPath = FinderItem(at: finishedFramesFolder.path + "/\(generateFileName(from: index)).png")
                                
                                guard finderItemAtImageOutputPath.image == nil else {
                                    manager.videos[currentVideo]!.updateEnlarge()
                                    return
                                }
                                
                                autoreleasepool {
                                    if index >= 1 && imageItem.image?.tiffRepresentation == FinderItem(at: folder.path + "/\(generateFileName(from: index - 1)).png").image?.tiffRepresentation {
                                        FinderItem(at: finishedFramesFolder.path + "/\(generateFileName(from: index - 1)).png").copy(to: finderItemAtImageOutputPath)
                                        manager.videos[currentVideo]!.updateEnlarge()
                                        return
                                    }
                                    
                                    guard let image = imageItem.image else { print("no image"); return }
                                    var output: NSImage? = nil
                                    let waifu2x = Waifu2x()
                                    if model.scaleLevel == 4 {
                                        output = waifu2x.run(image, model: model)
                                        output = waifu2x.run(output!.reload(), model: model)
                                    } else if model.scaleLevel == 8 {
                                        output = waifu2x.run(image, model: model)
                                        output = waifu2x.run(output!.reload(), model: model)
                                        output = waifu2x.run(output!.reload(), model: model)
                                    } else {
                                        output = waifu2x.run(image, model: model)
                                    }
                                    output?.write(to: finderItemAtImageOutputPath.path)
                                }
                                
                                manager.videos[currentVideo]!.updateEnlarge()
                            }
                            
                            
                        } else {
                            distributeAssignments(iterations: framesCounter) { index in
                                let path = interpolatedFramesFolder.path + "/\(generateFileName(from: index)).png"
                                let imageItem = FinderItem(at: path)
                                
                                if colorSpace == nil {
                                    colorSpace = imageItem.image!.cgImage(forProposedRect: nil, context: nil, hints: nil)?.colorSpace
                                }
                                
                                let finderItemAtImageOutputPath = FinderItem(at: finishedFramesFolder.path + "/\(generateFileName(from: index)).png")
                                
                                guard finishedFramesFolder.image == nil else {
                                    manager.videos[currentVideo]!.updateEnlarge()
                                    return
                                }
                                
                                autoreleasepool {
                                    model.runImageModel(input: imageItem, outputItem: finderItemAtImageOutputPath, task: task)
                                    task.wait()
                                }
                                
                                manager.videos[currentVideo]!.updateEnlarge()
                            }
                        }
                        
                        let arbitraryFrame = FinderItem(at: "\(finishedFramesFolder.path)/000000.png")
                        let arbitraryFrameCGImage = arbitraryFrame.image!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
                        
                        if !Configuration.main.isDevEnabled { FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo/video \(indexSequence).m4v").removeFile() }
                        
                        let enlargedFrames: [FinderItem] = finishedFramesFolder.children!
                        print(finishedFramesFolder)
                        
                        logger.info("Start to convert image sequence to video at \(mergedVideoPath)")
                        await FinderItem.convertImageSequenceToVideo(enlargedFrames, videoPath: mergedVideoPath, videoSize: CGSize(width: arbitraryFrameCGImage.width, height: arbitraryFrameCGImage.height), videoFPS: currentVideo.finderItem.avAsset!.frameRate! * Float(model.frameInterpolation), colorSpace: colorSpace)
                        logger.info("Convert image sequence to video at \(mergedVideoPath): finished")
                        
                        if !Configuration.main.isDevEnabled { FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/\(indexSequence)").removeFile() }
                        
                        
                        // delete raw images
                        rawFramesFolder.removeFile()
                        interpolatedFramesFolder.removeFile()
                        
                    }.value
                    
                    // generateImagesAndMergeToVideoForSegment finished
                    
                    let outputPath = "\(Configuration.main.saveFolder)/tmp/\(filePath)/\(currentVideo.finderItem.fileName).m4v"
                    
                    // status: merge videos
                    manager.status("merging video for \(filePath)")
                    logger.info("merging video for \(filePath)")
                    
                    await FinderItem.mergeVideos(from: FinderItem(at: "\(Configuration.main.saveFolder)/tmp/\(filePath)/processed/videos").children!, toPath: outputPath, tempFolder: "\(Configuration.main.saveFolder)/tmp/\(filePath)/merging video", frameRate: currentVideo.finderItem.avAsset!.frameRate! * Float(model.frameInterpolation))
                    
                    print("videos merged with fps: \(String(describing: FinderItem(at: outputPath).avAsset?.frameRate)), duration: \(String(describing: FinderItem(at: outputPath).avAsset?.duration))")
                    manager.status("merging video and audio for \(filePath)")
                    logger.info("merging video and audio for \(filePath)")
                    manager.onStatusProgressChanged(nil, nil)
                    
                    await FinderItem.mergeVideoWithAudio(videoUrl: URL(fileURLWithPath: outputPath), audioUrl: URL(fileURLWithPath: audioPath))
                    
                    manager.status("Completed")
                    logger.info("merging video and audio fnished for \(filePath)")
                    
                    if destinationFinderItem.isExistence { destinationFinderItem.removeFile() }
                    FinderItem(at: outputPath).copy(to: destinationFinderItem.path)
                    if !Configuration.main.isDevEnabled { FinderItem(at: "\(Configuration.main.saveFolder)/tmp").removeFile() }
                    
                    manager.videos[currentVideo]!.enlargeProgress = 1
                    manager.videos[currentVideo]!.interpolationProgress = 1
                    
                    logger.info(">>>>> results: ")
                    Configuration.main.saveLog("Video \(currentVideo.finderItem.fileName) done")
                    Configuration.main.saveLog(printMatrix(matrix: [["", "frames", "duration", "fps"], ["before", "\(currentVideo.finderItem.avAsset!.duration.seconds * Double(currentVideo.finderItem.avAsset!.frameRate!))", "\(currentVideo.finderItem.avAsset!.duration.seconds)", "\(currentVideo.finderItem.avAsset!.frameRate!)"], ["after", "\(destinationFinderItem.avAsset!.duration.seconds * Double(destinationFinderItem.avAsset!.frameRate!))", "\(destinationFinderItem.avAsset!.duration.seconds)", "\(destinationFinderItem.avAsset!.frameRate!)"]]))
                    Configuration.main.saveLog("")
                    logger.info("")
                    
                    if abs((currentVideo.finderItem.avAsset!.duration.seconds * Double(currentVideo.finderItem.avAsset!.frameRate!)) - destinationFinderItem.avAsset!.duration.seconds * Double(destinationFinderItem.avAsset!.frameRate!)) > 5 {
                        Configuration.main.saveError("Sorry, error occurred considering the following files:")
                        Configuration.main.saveError(printMatrix(matrix: [["", "frames", "duration", "fps"], ["before", "\(currentVideo.finderItem.avAsset!.duration.seconds * Double(currentVideo.finderItem.avAsset!.frameRate!))", "\(currentVideo.finderItem.avAsset!.duration.seconds)", "\(currentVideo.finderItem.avAsset!.frameRate!)"], ["after", "\(destinationFinderItem.avAsset!.duration.seconds * Double(destinationFinderItem.avAsset!.frameRate!))", "\(destinationFinderItem.avAsset!.duration.seconds)", "\(destinationFinderItem.avAsset!.frameRate!)"]]))
                        Configuration.main.saveError("")
                    }
                }
                
            }.value
        }
        
    }
    
}


extension FinderItem {
    
    func saveAudioTrack(to path: String) async throws {
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
        await exportSession.export()
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
    static func mergeVideoWithAudio(videoUrl: URL, audioUrl: URL) async {
        
        guard FileManager.default.fileExists(atPath: audioUrl.path) else {
            let logger = Logger()
            logger.error("merge video with audio failed: no audio file found")
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
                    Logger().error("failed to add audio track and video track: \(error.localizedDescription)")
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
            
            await exportSession.export()
        } else {
            let logger = Logger()
            logger.error("failed to merge video and audio: filed by create export session")
        }
        
    }
    
    /// Convert image sequence to video.
    ///
    /// from [stackoverflow](https://stackoverflow.com/questions/3741323/how-do-i-export-uiimage-array-as-a-movie/3742212#36297656)
    static func convertImageSequenceToVideo(_ allImages: [FinderItem], videoPath: String, videoSize: CGSize, videoFPS: Float, colorSpace: CGColorSpace? = nil) async {
        
        let logger = Logger()
        logger.info("Generate Video to \(videoPath) from images at fps of \(videoFPS)")
        FinderItem(at: videoPath).generateDirectory()
        
        // Create AVAssetWriter to write video
        let finderItemAtVideoPath = FinderItem(at: videoPath)
        if finderItemAtVideoPath.isExistence {
            finderItemAtVideoPath.removeFile()
        }
        
        // Convert <path> to NSURL object
        let pathURL = URL(fileURLWithPath: videoPath)
        
        let assetWriter: AVAssetWriter
        
        // Return new asset writer or nil
        do {
            // Create asset writer
            assetWriter = try AVAssetWriter(outputURL: pathURL, fileType: AVFileType.m4v)
            
            // Define settings for video input
            let videoSettings: [String : AnyObject] = [
                AVVideoCodecKey  : AVVideoCodecType.hevc as AnyObject,
                AVVideoWidthKey  : videoSize.width as AnyObject,
                AVVideoHeightKey : videoSize.height as AnyObject,
            ]
            
            // Add video input to writer
            let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
            assetWriter.add(assetWriterVideoInput)
            
            // Return writer
            logger.info("Created asset writer for \(videoSize.width)x\(videoSize.height) video")
        } catch {
            logger.error("Error creating asset writer: \(error.localizedDescription)")
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
                
                autoreleasepool {
                    if  let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                        let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity:1)
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                            kCFAllocatorDefault,
                            pixelBufferPool,
                            pixelBufferPointer
                        )
                        
                        if let pixelBuffer = pixelBufferPointer.pointee , status == 0 {
                            
                            autoreleasepool {
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
                                    space: colorSpace ?? rgbColorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                )!
                                
                                // Draw image into context
                                let drawCGRect = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
                                var drawRect = NSRectFromCGRect(drawCGRect);
                                var cgImage = allImages[frameCount].image!.cgImage(forProposedRect: &drawRect, context: nil, hints: nil)!
                                
                                if colorSpace != nil && colorSpace! != cgImage.colorSpace {
                                    cgImage = cgImage.copy(colorSpace: colorSpace!)!
                                }
                                
                                context.draw(cgImage, in: CGRect(x: 0.0,y: 0.0, width: videoSize.width,height: videoSize.height))
                                
                                CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            }
                            guard pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                                logger.error("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                                return
                            }
                            pixelBufferPointer.deinitialize(count: 1)
                        } else {
                            logger.error("Error: Failed to allocate pixel buffer from pool")
                        }
                        
                        pixelBufferPointer.deallocate()
                    }
                }
                
                frameCount += 1
            }
            
            // No more images to add? End video.
            if (frameCount >= numImages) {
                writerInput.markAsFinished()
            }
        })
        
        mediaQueue.sync {
            logger.info("finished adding frames")
        }
        
        await assetWriter.finishWriting()
        
        if (assetWriter.error != nil) {
            logger.error("Error converting images to video: \(assetWriter.error.debugDescription)")
        } else {
            logger.info("Converted images to movie @ \(videoPath)")
        }
    }
    
    /// Convert image sequence to video.
    ///
    /// from [stackoverflow](https://stackoverflow.com/questions/3741323/how-do-i-export-uiimage-array-as-a-movie/3742212#36297656)
    static func convertImageSequenceToVideo(_ allImages: [NSImage], videoPath: String, videoSize: CGSize, videoFPS: Float, colorSpace: CGColorSpace? = nil, completion: @escaping () -> Void) {
        
        let logger = Logger()
        logger.info("Generate Video to \(videoPath) from images at fps of \(videoFPS)")
        FinderItem(at: videoPath).generateDirectory()
        
        // Create AVAssetWriter to write video
        let finderItemAtVideoPath = FinderItem(at: videoPath)
        if finderItemAtVideoPath.isExistence {
            finderItemAtVideoPath.removeFile()
        }
        
        // Convert <path> to NSURL object
        let pathURL = URL(fileURLWithPath: videoPath)
        
        let assetWriter: AVAssetWriter
        
        // Return new asset writer or nil
        do {
            // Create asset writer
            assetWriter = try AVAssetWriter(outputURL: pathURL, fileType: AVFileType.m4v)
            
            // Define settings for video input
            let videoSettings: [String : AnyObject] = [
                AVVideoCodecKey  : AVVideoCodecType.hevc as AnyObject,
                AVVideoWidthKey  : videoSize.width as AnyObject,
                AVVideoHeightKey : videoSize.height as AnyObject,
            ]
            
            // Add video input to writer
            let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
            assetWriter.add(assetWriterVideoInput)
            
            // Return writer
            logger.info("Created asset writer for \(videoSize.width)x\(videoSize.height) video")
        } catch {
            logger.error("Error creating asset writer: \(error.localizedDescription)")
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
        guard assetWriter.startWriting() else {
            logger.error("assetWriter not started")
            return
        }
        assetWriter.startSession(atSourceTime: CMTime.zero)
        if (pixelBufferAdaptor.pixelBufferPool == nil) {
            Configuration.main.saveLog("Error converting images to video: pixelBufferPool nil after starting session")
            logger.error("Error converting images to video: pixelBufferPool nil after starting session")
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
        writerInput.requestMediaDataWhenReady(on: mediaQueue, using: {
            
            // Append unadded images to video but only while input ready
            while writerInput.isReadyForMoreMediaData && frameCount < numImages {
                let lastFrameTime = CMTimeMake(value: Int64(frameCount) * Int64(fraction.denominator), timescale: Int32(fraction.numerator))
                let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                
                autoreleasepool {
                    print("srtarted: \(frameCount), \(writerInput.isReadyForMoreMediaData)")
                    if  let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                        let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity:1)
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                            kCFAllocatorDefault,
                            pixelBufferPool,
                            pixelBufferPointer
                        )
                        
                        if let pixelBuffer = pixelBufferPointer.pointee , status == 0 {
                            
                            autoreleasepool {
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
                                    space: colorSpace ?? rgbColorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                )!
                                
                                // Draw image into context
                                var cgImage = allImages[frameCount].reload().cgImage(forProposedRect: nil, context: nil, hints: nil)!
                                
                                if colorSpace != nil && colorSpace! != cgImage.colorSpace {
                                    cgImage = cgImage.copy(colorSpace: colorSpace!)!
                                }
                                
                                context.draw(cgImage, in: CGRect(x: 0.0,y: 0.0, width: videoSize.width,height: videoSize.height))
                                
                                CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            }
                            guard pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                                logger.error("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                                return
                            }
                            pixelBufferPointer.deinitialize(count: 1)
                        } else {
                            logger.error("Error: Failed to allocate pixel buffer from pool")
                        }
                        print("endded: \(frameCount), \(writerInput.isReadyForMoreMediaData)")
                        
                        pixelBufferPointer.deallocate()
                    }
                }
                
                frameCount += 1
            }
            
            // No more images to add? End video.
            if (frameCount >= numImages) {
                writerInput.markAsFinished()
                
                assetWriter.finishWriting {
                    if (assetWriter.error != nil) {
                        logger.error("Error converting images to video: \(assetWriter.error.debugDescription)")
                    } else {
                        logger.info("Converted images to movie @ \(videoPath)")
                    }
                    
                    completion()
                }
            }
        })
        
    }
    
    static func trimVideo(sourceURL: URL, outputURL: URL, startTime: Double, endTime: Double) async {
        let asset = AVAsset(url: sourceURL as URL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHEVCHighestQuality) else { return }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4v
        
        let startTime = CMTime(startTime)
        let endTime = CMTime(endTime)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        if FinderItem(at: outputURL).isExistence {
            FinderItem(at: outputURL).removeFile()
        }
        
        exportSession.timeRange = timeRange
        await exportSession.export()
    }
    
    /// merge videos from videos
    ///
    /// from [stackoverflow](https://stackoverflow.com/questions/38972829/swift-merge-avasset-videos-array)
    static func mergeVideos(from arrayVideos: [FinderItem], toPath: String, tempFolder: String, frameRate: Float) async {
        print(">>>>> \(frameRate)")
        
        let logger = Logger()
        logger.info("Merging videos...")
        
        func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
            AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        }
        
        func mergingVideos(from arrayVideos: [FinderItem], toPath: String) async {
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
                        logger.error("error: \(error.localizedDescription)")
                    }
                    
                    let realDuration = { ()-> CMTime in
                        let framesCount = Double(videoAsset.frameRate!) * videoAsset.duration.seconds
                        return CMTime(framesCount / Double(frameRate))
                    }()
                    print(realDuration.seconds)
                    
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
            
            logger.info("add videos finished")
            
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.layerInstructions = layerInstructionsArray
            mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: completeTrackDuration)
            
            let mainComposition = AVMutableVideoComposition()
            mainComposition.instructions = [mainInstruction]
            let fraction = Fraction(frameRate)
            mainComposition.frameDuration = CMTimeMake(value: Int64(fraction.denominator), timescale: Int32(fraction.numerator))
            mainComposition.renderSize = videoSize
            print(">><< \(1 / mainComposition.frameDuration.seconds)")
            
            let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHEVCHighestQuality)!
            exporter.outputURL = URL(fileURLWithPath: toPath)
            exporter.outputFileType = AVFileType.mov
            exporter.shouldOptimizeForNetworkUse = false
            exporter.videoComposition = mainComposition
            await exporter.export()
            
            if let error = exporter.error {
                logger.error("\(error.localizedDescription)")
            }
        }
        
        FinderItem(at: tempFolder).generateDirectory(isFolder: true)
        
        let threshold: Double = 50
        
        if arrayVideos.count >= Int(threshold) {
            var index = 0
            var finishedCounter = 0
            while index < Int((Double(arrayVideos.count) / threshold).rounded(.up)) {
                var sequence = String(index)
                while sequence.count < 6 { sequence.insert("0", at: sequence.startIndex) }
                let upperBound = ((index + 1) * Int(threshold)) > arrayVideos.count ? arrayVideos.count : ((index + 1) * Int(threshold))
                
                await mergingVideos(from: Array(arrayVideos[(index * Int(threshold))..<upperBound]), toPath: tempFolder + "/" + sequence + ".m4v")
                finishedCounter += 1
                guard finishedCounter == Int((Double(arrayVideos.count) / threshold).rounded(.up)) else { return }
                await mergingVideos(from: FinderItem(at: tempFolder).children!, toPath: toPath)
                
                index += 1
            }
        } else {
            await mergingVideos(from: arrayVideos, toPath: toPath)
        }
    }
    
    
}



