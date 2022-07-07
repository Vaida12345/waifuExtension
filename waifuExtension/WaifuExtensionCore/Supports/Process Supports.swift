//
//  ProcessFile.swift
//  waifuExtension
//
//  Created by Vaida on 3/15/22.
//

import Foundation
import AVFoundation
import AppKit
import os
import Support

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

func inferenceProgress(_ text: String) -> Double? {
    if let index = text.lastIndex(of: "%") {
        var startIndex = index
        var forced = false
        
        var lastCharacter = text[text.index(before: startIndex)]
        while Int(String(lastCharacter)) != nil || lastCharacter == "." {
            text.formIndex(before: &startIndex)
            guard startIndex != text.startIndex else { forced = true; break }
            lastCharacter = text[text.index(before: startIndex)]
        }
        if !forced {
            text.formIndex(after: &startIndex)
        }
        
        guard startIndex < index else { return nil }
        guard let value = Double(text[startIndex..<index]) else { return nil }
        return value / 100
    } else {
        //        guard let lastIndex = text.lastIndex(where:  { $0.isNumber }) else { return nil }
        //        var startIndex = lastIndex
        //
        //        var lastCharacter = text[text.index(before: startIndex)]
        //        while Int(String(lastCharacter)) != nil || lastCharacter == "." {
        //            text.formIndex(before: &startIndex)
        //            guard startIndex != text.startIndex else { break }
        //            lastCharacter = text[text.index(before: startIndex)]
        //        }
        //
        //        guard startIndex < lastIndex else { return nil }
        //        return Double(text[text.index(after: startIndex)..<lastIndex])
        return nil
    }
}

public class ProgressManager {
    
    class Image {
        
        unowned let manager: ProgressManager
        
        /// The progress of the image.
        var progress: Double = 0 {
            didSet {
                print("changed")
                manager.onProgressChanged(manager.progress)
            }
        }
        
        init(manager: ProgressManager) {
            self.manager = manager
        }
        
    }
    
    class Video {
        
        unowned let manager: ProgressManager
        
        var interpolationProgress: Double = 0 {
            didSet {
                manager.onProgressChanged(manager.progress)
            }
        }
        var enlargeProgress: Double = 0 {
            didSet {
                manager.onProgressChanged(manager.progress)
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
    
    public var status: (_ status: String) -> Void = { _ in }
    public var onStatusProgressChanged: (_ progress: Int?, _ total: Int?) -> Void = { _, _ in }
    public var onProgressChanged: (_ progress: Double) -> Void = { _ in }
    public var addCurrentItems: (_ item: WorkItem) -> Void = { _ in }
    public var removeFromCurrentItems: (_ item: WorkItem) -> Void = { _ in }
    
    public init() { }
}


//TODO: recalculate estimate size

extension Array where Element == WorkItem {
    
    func contains(_ finderItem: FinderItem) -> Bool {
        return self.contains(WorkItem(at: finderItem, type: .image))
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
    static func convertImageSequenceToVideo<T>(_ allImages: [T], videoPath: String, videoSize: CGSize, videoFPS: Float, colorSpace: CGColorSpace? = nil) async where T: FinderItemOrImage {
        
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
        let _: Void = await withCheckedContinuation({ continuation in
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
                                    var cgImage = allImages[frameCount].imagE.cgImage(forProposedRect: &drawRect, context: nil, hints: nil)!
                                    
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
                    continuation.resume()
                }
            })
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
                await mergingVideos(from: FinderItem(at: tempFolder).children()!, toPath: toPath)
                
                index += 1
            }
        } else {
            await mergingVideos(from: arrayVideos, toPath: toPath)
        }
    }
}


protocol FinderItemOrImage {
    var imagE: NSImage { get }
}

extension NSImage: FinderItemOrImage {
    var imagE: NSImage {
        self
    }
}

extension FinderItem: FinderItemOrImage {
    var imagE: NSImage {
        self.image!
    }
}
