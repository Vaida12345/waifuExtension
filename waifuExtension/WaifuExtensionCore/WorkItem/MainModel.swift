//
//  MainModel.swift
//  waifuExtension
//
//  Created by Vaida on 6/22/22.
//

import AppKit
import CoreMedia
import Foundation
import Support
import os


public final class MainModel: ObservableObject {
    
    @Published public var items: [WorkItem] = []
    
    @MainActor
    public func append(from sources: [FinderItem]) async {
        let sources = [FinderItem](from: sources).concurrentCompactMap { item -> WorkItem? in
            return autoreleasepool {
                guard !items.contains(item) else { return nil }
                if item.image != nil {
                    return WorkItem(at: item, type: .image)
                } else if item.avAsset != nil {
                    return WorkItem(at: item, type: .video)
                } else {
                    return nil
                }
            }
        }
        items.append(contentsOf: sources)
    }
    
    public init(items: [WorkItem] = []) {
        self.items = items
    }
    
    public func work(model: ModelCoordinator, task: ShellManagers, manager: ProgressManager, outputPath: FinderItem) async {
        
        let logger = Logger()
        logger.info("Process File started with model: \(model.description) with \(self.items.filter{ $0.type == .image }.count) images and \(self.items.filter{ $0.type == .video }.count) videos")
        
        // prepare progress
        for i in self.items {
            if i.type == .image {
                manager.images[i] = .init(manager: manager)
            } else {
                let item = ProgressManager.Video.init(manager: manager)
                item.interpolationLevel = Double(model.frameInterpolation)
                item.totalFrames = Double(i.finderItem.avAsset!.frameRate!) * i.finderItem.avAsset!.duration.seconds
                manager.videos[i] = item
            }
        }
        
        let images = self.items.filter({ $0.type == .image })
        let videos = self.items.filter({ $0.type == .video })
        
        outputPath.generateDirectory(isFolder: true)
        
        if let image = FinderItem.bundleItem(forResource: "icon", withExtension: "icns")?.image {
            outputPath.setIcon(image: image)
        }
        
        // process Images
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
        
        // process videos
        guard !videos.isEmpty else {
            manager.status("Completed")
            return
        }
        logger.info("Processing Videos")
        
        manager.status("processing videos")
        
        for currentVideo in videos {
            // Use this to prevent memory leak
            await asyncAutoreleasepool {
                manager.addCurrentItems(currentVideo)
                await processVideo(currentVideo: currentVideo)
                manager.removeFromCurrentItems(currentVideo)
            }
        }
        
        // MARK: - Process Image
        @Sendable func processImage(imageIndex: Int) {
            
            let currentImage = images[imageIndex]
            manager.addCurrentItems(currentImage)
            
            let outputFileName: String
            if let name = currentImage.finderItem.relativePath {
                outputFileName = name[..<name.lastIndex(of: ".")!] + ".png"
            } else {
                outputFileName = currentImage.finderItem.fileName + ".png"
            }
            
            let finderItemAtImageOutputPath = outputPath.with(subPath: outputFileName)
            
            finderItemAtImageOutputPath.generateDirectory()
            
            if model.isCaffe {
                guard let image = currentImage.finderItem.image else { print("no image"); return }
                var output: NSImage? = nil
                let waifu2x = Waifu2x()
                
                if model.scaleLevel == 4 {
                    waifu2x.didFinishedOneBlock = { total in
                        manager.images[currentImage]!.progress += 1 / Double(total) / 2
                    }
                    output = waifu2x.run(image, model: model)
                    output = waifu2x.run(output!.reload(), model: model)
                } else if model.scaleLevel == 8 {
                    waifu2x.didFinishedOneBlock = { total in
                        manager.images[currentImage]!.progress += 1 / Double(total) / 3
                    }
                    output = waifu2x.run(image, model: model)
                    output = waifu2x.run(output!.reload(), model: model)
                    output = waifu2x.run(output!.reload(), model: model)
                } else {
                    waifu2x.didFinishedOneBlock = { total in
                        manager.images[currentImage]!.progress += 1 / Double(total)
                    }
                    output = waifu2x.run(image, model: model)
                }
                try! output?.write(to: finderItemAtImageOutputPath)
            } else {
                let newTask = task.addManager()
                model.content.runImageModel(input: currentImage.finderItem, outputItem: finderItemAtImageOutputPath, task: newTask)
                newTask.onOutputChanged { newLine in
                    logger.info("\(newLine)")
                    guard let value = inferenceProgress(newLine) else { return }
                    guard value <= 1 && value >= 0 else { return }
                    manager.images[currentImage]?.progress = value
                }
                newTask.wait()
                logger.info("\(newTask.output() ?? "")")
            }
            
            manager.images[currentImage]?.progress = 1
            manager.removeFromCurrentItems(currentImage)
        }
        
        // MARK: - Process Video
        func processVideo(currentVideo: WorkItem) async {
            
            let filePath = currentVideo.finderItem.relativePath ?? (currentVideo.finderItem.fileName + currentVideo.finderItem.extensionName)
            let destinationFinderItem = outputPath.with(subPath: filePath)
            
            if model.enableMemoryOnly {
                // uses only memory
                
                manager.status("generating frames")
                
                let output = ArrayContainer<NSImage>()
                var firstFrame: NSImage?
                
                guard let frames = await currentVideo.finderItem.avAsset?.getFrames() else { return }
                firstFrame = frames.first
                output.append(contentsOf: frames)
                
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
                
                await FinderItem.convertImageSequenceToVideo(output.contents, videoPath: destinationFinderItem.path, videoSize: output.first!.pixelSize!, videoFPS: currentVideo.finderItem.avAsset!.frameRate!, colorSpace: firstFrame?.cgImage(forProposedRect: nil, context: nil, hints: nil)?.colorSpace)
                
                manager.status("Merging video with audio")
                await FinderItem.mergeVideoWithAudio(videoUrl: destinationFinderItem.url, audioUrl: currentVideo.finderItem.url)
                
                manager.status("Completed")
                
                return
            }
            
            manager.status("generating audio for \(filePath)")
            outputPath.with(subPath: "tmp/\(filePath)").generateDirectory(isFolder: true)
            let audioPath = outputPath.with(subPath: "tmp/\(filePath)/audio.m4a")
            do {
                try await currentVideo.finderItem.saveAudioTrack(to: audioPath.path)
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
                await asyncAutoreleasepool {
                    
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
                    
                }
            }
            
            manager.onStatusProgressChanged(nil, nil)
            logger.info("splitting videos finished")
            
            // enters the completion of split video
            
            for index in 0..<videoSegmentCount {
                
                // generate images
                await asyncAutoreleasepool {
                    
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
                    
                    let mergedVideoPath = outputPath.with(subPath: "/tmp/\(filePath)/processed/videos/\(indexSequence).m4v")
                    mergedVideoPath.generateDirectory()
                    
                    guard mergedVideoPath.avAsset == nil else {
                        outputPath.with(subPath: "/tmp/\(filePath)/processed/\(indexSequence)").removeFile()
                        manager.videos[currentVideo]!.enlargeProgress = 1
                        manager.videos[currentVideo]!.interpolationLevel = 1
                        // completion after all videos are finished.
                        return
                    }
                    
                    logger.info("frames to process: \(requiredFramesCount)")
                    
                    let rawFramesFolder = outputPath.with(subPath: "/tmp/\(filePath)/processed/\(indexSequence)/raw frames")
                    rawFramesFolder.generateDirectory(isFolder: true)
                    var interpolatedFramesFolder = outputPath.with(subPath: "/tmp/\(filePath)/processed/\(indexSequence)/interpolated frames")
                    interpolatedFramesFolder.generateDirectory(isFolder: true)
                    let finishedFramesFolder = outputPath.with(subPath: "/tmp/\(filePath)/processed/\(indexSequence)/finished frames")
                    finishedFramesFolder.generateDirectory(isFolder: true)
                    
                    var colorSpace: CGColorSpace? = nil
                    
                    
                    var framesCounter = 0
                    
                    // write raw images
                    guard let frames = await segmentsFinderItem.avAsset!.getFrames() else { return }
                    framesCounter = frames.count
                    
                    for index in 0..<framesCounter {
                        autoreleasepool {
                            let finderItemAtImageOutputPath = FinderItem(at: rawFramesFolder.path + "/\(generateFileName(from: index)).png")
                            guard !finderItemAtImageOutputPath.isExistence else { return }
                            try! frames[index].write(to: finderItemAtImageOutputPath)
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
                                    FinderItem(at: "\(rawFramesFolder.path)/\(sequence).png").copy(to: FinderItem(at: "\(interpolatedFramesFolder.path)/\(generateFileName(from: 0)).png"))
                                    
                                    manager.videos[currentVideo]!.updateInterpolation()
                                    
                                    return
                                }
                                
                                let previousSequence = generateFileName(from: frameCounter - 1)
                                let processedSequence = generateFileName(from: frameCounter * model.frameInterpolation)
                                let intermediateSequence = generateFileName(from: frameCounter * model.frameInterpolation - model.frameInterpolation / 2)
                                
                                // will not save the previous frame
                                
                                FinderItem(at: "\(rawFramesFolder.path)/\(sequence).png").copy(to: FinderItem(at: "\(interpolatedFramesFolder.path)/\(processedSequence).png"))
                                
                                if FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence).png").image == nil {
                                    let item1 = FinderItem(at: "\(rawFramesFolder.path)/\(previousSequence).png")
                                    let item2 = FinderItem(at: "\(rawFramesFolder.path)/\(sequence).png")
                                    let output = FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence).png")
                                    
                                    if item1.image?.tiffRepresentation == item2.image?.tiffRepresentation {
                                        item1.copy(to: output)
                                    } else {
                                        let newTask = task.addManager()
                                        model.content.runFrameModel(input1: item1.path, input2: item2.path, outputPath: output.path, task: newTask)
                                        newTask.wait()
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
                                    item1.copy(to: output)
                                } else {
                                    let newTask = task.addManager()
                                    model.content.runFrameModel(input1: item1.path, input2: item2.path, outputPath: output.path, task: newTask)
                                    newTask.wait()
                                }
                                
                                let item3 = FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence).png")
                                let item4 = FinderItem(at: "\(interpolatedFramesFolder.path)/\(processedSequence).png")
                                let output2 = FinderItem(at: "\(interpolatedFramesFolder.path)/\(intermediateSequence3).png")
                                
                                if item3.image?.tiffRepresentation == item4.image?.tiffRepresentation {
                                    item3.copy(to: output2)
                                } else {
                                    let newTask = task.addManager()
                                    model.content.runFrameModel(input1: item3.path, input2: item4.path, outputPath: output2.path, task: newTask)
                                    newTask.wait()
                                }
                                
                                manager.videos[currentVideo]!.updateInterpolation()
                                
                            }
                            
                        }
                    } else {
                        interpolatedFramesFolder = rawFramesFolder
                    }
                    
                    framesCounter = interpolatedFramesFolder.children()?.filter{ $0.image != nil }.count ?? framesCounter
                    
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
                                try! output?.write(to: finderItemAtImageOutputPath)
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
                                let newManager = task.addManager()
                                model.content.runImageModel(input: imageItem, outputItem: finderItemAtImageOutputPath, task: newManager)
                                newManager.wait()
                            }
                            
                            manager.videos[currentVideo]!.updateEnlarge()
                        }
                    }
                    
                    let arbitraryFrame = FinderItem(at: "\(finishedFramesFolder.path)/000000.png")
                    let arbitraryFrameCGImage = arbitraryFrame.image!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
                    
                    outputPath.with(subPath: "tmp/\(filePath)/raw/splitVideo/video \(indexSequence).m4v").removeFile()
                    
                    let enlargedFrames: [FinderItem] = finishedFramesFolder.children()!
                    print(finishedFramesFolder)
                    
                    logger.info("Start to convert image sequence to video at \(mergedVideoPath)")
                    await FinderItem.convertImageSequenceToVideo(enlargedFrames, videoPath: mergedVideoPath.path, videoSize: CGSize(width: arbitraryFrameCGImage.width, height: arbitraryFrameCGImage.height), videoFPS: currentVideo.finderItem.avAsset!.frameRate! * Float(model.frameInterpolation), colorSpace: colorSpace)
                    logger.info("Convert image sequence to video at \(mergedVideoPath): finished")
                    outputPath.with(subPath: "/tmp/\(filePath)/processed/\(indexSequence)").removeFile()
                    
                    
                    // delete raw images
                    rawFramesFolder.removeFile()
                    interpolatedFramesFolder.removeFile()
                    
                }
                
                // generateImagesAndMergeToVideoForSegment finished
                
                let outputPatH = outputPath.with(subPath: "/tmp/\(filePath)/\(currentVideo.finderItem.fileName).m4v")
                
                // status: merge videos
                manager.status("merging video for \(filePath)")
                logger.info("merging video for \(filePath)")
                
                await FinderItem.mergeVideos(from: outputPath.with(subPath: "/tmp/\(filePath)/processed/videos").children()!, toPath: outputPatH.path, tempFolder: outputPath.with(subPath: "tmp/\(filePath)/merging video").path, frameRate: currentVideo.finderItem.avAsset!.frameRate! * Float(model.frameInterpolation))
                
                manager.status("merging video and audio for \(filePath)")
                logger.info("merging video and audio for \(filePath)")
                manager.onStatusProgressChanged(nil, nil)
                
                await FinderItem.mergeVideoWithAudio(videoUrl: outputPatH.url, audioUrl: audioPath.url)
                
                manager.status("Completed")
                logger.info("merging video and audio fnished for \(filePath)")
                
                if destinationFinderItem.isExistence { destinationFinderItem.removeFile() }
                outputPatH.copy(to: destinationFinderItem)
                outputPath.with(subPath: "tmp").removeFile()
                
                manager.videos[currentVideo]!.enlargeProgress = 1
                manager.videos[currentVideo]!.interpolationProgress = 1
                
                logger.info(">>>>> results: ")
                logger.info("Video \(currentVideo.finderItem.fileName) done")
                
                let info = [["", "frames", "duration", "fps"], ["before", "\(currentVideo.finderItem.avAsset!.duration.seconds * Double(currentVideo.finderItem.avAsset!.frameRate!))", "\(currentVideo.finderItem.avAsset!.duration.seconds)", "\(currentVideo.finderItem.avAsset!.frameRate!)"], ["after", "\(destinationFinderItem.avAsset!.duration.seconds * Double(destinationFinderItem.avAsset!.frameRate!))", "\(destinationFinderItem.avAsset!.duration.seconds)", "\(destinationFinderItem.avAsset!.frameRate!)"]].description()
                logger.info("\n\(info)")
            }
            
        }
    }
    
}

// MARK: - Supporting Functions

@Sendable private func generateFileName(from index: Int) -> String {
    var segmentSequence = String(index)
    while segmentSequence.count <= 5 { segmentSequence.insert("0", at: segmentSequence.startIndex) }
    return segmentSequence
}

@Sendable private func distributeAssignments(iterations: Int, action: @escaping (Int) -> Void) {
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
