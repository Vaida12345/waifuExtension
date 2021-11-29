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

func addItemIfPossible(of item: FinderItem, to finderItems: inout [WorkItem]) {
    guard !finderItems.contains(item) else { return }
    
    if item.isFile {
        guard item.image != nil || item.avAsset != nil else { return }
        finderItems.append(WorkItem(at: item, type: item.image != nil ? .image : .video))
    } else {
        item.iteratedOver { child in
            guard !finderItems.contains(child) else { return }
            guard child.image != nil || child.avAsset != nil else { return }
            child.relativePath = item.fileName! + "/" + child.relativePath(to: item)!
            finderItems.append(WorkItem(at: child, type: child.image != nil ? .image : .video))
        }
    }
}

extension Array where Element == WorkItem {
    
    func contains(_ finderItem: FinderItem) -> Bool {
        return self.contains(WorkItem(at: finderItem, type: .image))
    }
    
    func work(_ chosenScaleLevel: Int, modelUsed: Waifu2xModel, videoSegmentLength: Int, isUsingGPU: Bool, onStatusChanged status: @escaping ((_ status: String)->()), onStatusProgressChanged: @escaping ((_ progress: Int?, _ total: Int?)->()), onProgressChanged: @escaping ((_ progress: Double) -> ()), didFinishOneItem: @escaping ((_ finished: Int, _ total: Int)->()), completion: @escaping (() -> ())) {
        
        let images = self.filter({ $0.type == .image })
        let videos = self.filter({ $0.type == .video })
        let backgroundQueue = DispatchQueue(label: "[WorkItem] background dispatch queue")
        
        let totalItemCounter = self.count
        var finishedItemsCounter = 0
        
        if !images.isEmpty {
            status("processing images")
            var concurrentProcessingImagesCount = 0
            
            DispatchQueue.concurrentPerform(iterations: images.count) { imageIndex in
                
                guard !isProcessingCancelled else { return }
                
                backgroundQueue.async {
                    concurrentProcessingImagesCount += 1
                    
                    status("processing \(concurrentProcessingImagesCount) images in parallel")
                }
                
                let currentImage = images[imageIndex]
                var image = currentImage.finderItem.image!
                
                let waifu2x = Waifu2x()
                waifu2x.didFinishedOneBlock = { total in
                    currentImage.progress += 1 / Double(total)
                    onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / Double(totalItemCounter))
                }
                waifu2x.isGPUEnabled = isUsingGPU
                
                if chosenScaleLevel >= 2 {
                    for _ in 1...chosenScaleLevel {
                        image = waifu2x.run(image, model: modelUsed)!.reload()
                    }
                } else {
                    image = waifu2x.run(image, model: modelUsed)!
                }
                
                let outputFileName: String
                if let name = currentImage.finderItem.relativePath {
                    outputFileName = name[..<name.lastIndex(of: ".")!] + ".png"
                } else {
                    outputFileName = currentImage.finderItem.fileName! + ".png"
                }
                
                let finderItemAtImageOutputPath = FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/\(outputFileName)")
                
                finderItemAtImageOutputPath.generateDirectory()
                image.write(to: finderItemAtImageOutputPath.path)
                
                backgroundQueue.async {
                    concurrentProcessingImagesCount -= 1
                    status("processing \(concurrentProcessingImagesCount) images in parallel")
                    finishedItemsCounter += 1
                    didFinishOneItem(finishedItemsCounter, totalItemCounter)
                }
            }
            
            status("finished processing images")
        }
        
        if !videos.isEmpty {
            //helper functions
            
            var segmentCompletedCounter = 0
            
            func splitVideo(withIndex segmentIndex: Int, duration: Double, filePath: String, currentVideo: WorkItem, completion: @escaping (()->())) {
                
                guard !isProcessingCancelled else { return }
                guard segmentIndex <= Int(duration) / videoSegmentLength else { return }
                
                var segmentSequence = String(segmentIndex)
                while segmentSequence.count <= 5 { segmentSequence.insert("0", at: segmentSequence.startIndex) }
                
                let path = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo/video \(segmentSequence).mov"
                FinderItem(at: path).generateDirectory()
                
                FinderItem.trimVideo(sourceURL: currentVideo.finderItem.url, outputURL: URL(fileURLWithPath: path), statTime: Float(segmentIndex * videoSegmentLength), endTime: {()->Float in
                    if Double(segmentIndex * videoSegmentLength + videoSegmentLength) < duration {
                        return Float(segmentIndex * videoSegmentLength + videoSegmentLength)
                    } else {
                        return Float(duration)
                    }
                }()) { _ in
                    
                    onStatusProgressChanged(segmentIndex, Int(duration) / videoSegmentLength)
                    
                    splitVideo(withIndex: segmentIndex + 1, duration: duration, filePath: filePath, currentVideo: currentVideo, completion: completion)
                    guard segmentIndex == Int(duration) / videoSegmentLength else { return }
                    completion()
                }
            }
            
            func generateImagesAndMergeToVideo(segmentsFinderItems: [FinderItem], currentVideo: WorkItem, filePath: String, totalSegmentsCount: Double, duration: Double, completion: @escaping (()->())) {
                
                var segmentCounter = 0
                while segmentCounter < Int((duration / Double(videoSegmentLength)).rounded(.up)) {
                    
                    guard !isProcessingCancelled else { return }
                    guard !segmentsFinderItems.isEmpty else { return }
                    
                    let segmentsFinderItem = segmentsFinderItems[segmentCounter]
                    var asset = segmentsFinderItem.avAsset
                    let segmentSequence = segmentsFinderItem.fileName!
                    
                    var framesToBeProcessed = asset?.frames
                    
                    print("frames to process: \(framesToBeProcessed!.count)")
                    
                    FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/splitVideo frames/\(segmentSequence)").generateDirectory()
                    DispatchQueue.concurrentPerform(iterations: framesToBeProcessed!.count) { frameIndex in
                        
                        autoreleasepool {
                            var currentFrame: NSImage? = framesToBeProcessed![frameIndex]
                            
                            let waifu2x = Waifu2x()
                            
                            if chosenScaleLevel >= 2 {
                                for _ in 1...chosenScaleLevel {
                                    currentFrame = waifu2x.run(currentFrame!.reload(withIndex: "\(segmentSequence)\(frameIndex)"), model: modelUsed)!
                                }
                            } else {
                                currentFrame = waifu2x.run(currentFrame!.reload(withIndex: "\(segmentSequence)\(frameIndex)"), model: modelUsed)!
                            }
                            
                            currentVideo.progress += 1 / Double(framesToBeProcessed!.count) / totalSegmentsCount
                            onProgressChanged(self.reduce(0.0, { $0 + $1.progress }) / Double(totalItemCounter))
                            
                            var sequence = String(frameIndex)
                            while sequence.count < 5 { sequence.insert("0", at: sequence.startIndex) }
                            
                            currentFrame!.write(to: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/splitVideo frames/\(segmentSequence)/\(sequence).png")
                            
                            currentFrame = nil
                        }
                    }
                    
                    framesToBeProcessed = nil
                    asset = nil
                    
                    // status: merge videos
                    
                    let mergedVideoSegmentPath = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/splitVideo/\(segmentSequence).mov"
                    FinderItem(at: mergedVideoSegmentPath).generateDirectory()
                    
                    let arbitraryFrame = FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/splitVideo frames/\(segmentSequence)/00000.png")
                    let arbitraryFrameCGImage = arbitraryFrame.image!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
                    var enlargedFrames: [NSImage]? = FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/splitVideo frames/\(segmentSequence)").children!.map({ $0.image! })
                    
                    FinderItem.convertImageSequenceToVideo(enlargedFrames!, videoPath: mergedVideoSegmentPath, videoSize: CGSize(width: arbitraryFrameCGImage.width, height: arbitraryFrameCGImage.height), videoFPS: Int32(currentVideo.finderItem.frameRate!)) {
                        segmentCompletedCounter += 1
                        enlargedFrames = nil
                        
                        try! FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/splitVideo frames/\(segmentSequence)").removeFile()
                        onStatusProgressChanged(segmentCompletedCounter,  Int((duration / Double(videoSegmentLength)).rounded(.up)))
                        
                        guard segmentCompletedCounter == Int((duration / Double(videoSegmentLength)).rounded(.up)) else {
                            return
                        }
                        // completion after all videos are finished.
                        completion()
                    }
                    
                    segmentCounter += 1
                }
            }
            
            func processSingleVideo(withIndex videoIndex: Int, completion: @escaping (()->())) {
                
                guard !isProcessingCancelled else { return }
                
                let currentVideo = videos[videoIndex]
                
                let filePath = currentVideo.finderItem.relativePath ?? currentVideo.finderItem.fileName!
                let tmpPath = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw"
                FinderItem(at: tmpPath).generateDirectory()
                
                status("splitting audio for \(filePath)")
                
                let audioPath = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/audio.m4a"
                try! currentVideo.finderItem.saveAudioTrack(to: audioPath)
                
                status("generating video segments for \(filePath)")
                
                let duration = currentVideo.finderItem.avAsset!.duration.seconds
                let totalSegmentsCount = Double(Int(duration) / videoSegmentLength + 1)
                
                splitVideo(withIndex: 0, duration: duration, filePath: filePath, currentVideo: currentVideo) {
                    
                    guard !isProcessingCancelled else { return }
                    onStatusProgressChanged(nil, nil)
                    
                    status("generating images for \(filePath)")
                    
                    //status: generating video segment frames
                    onStatusProgressChanged(0, Int((duration / Double(videoSegmentLength)).rounded(.up)))
                    
                    generateImagesAndMergeToVideo(segmentsFinderItems: FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo").children!, currentVideo: currentVideo, filePath: filePath, totalSegmentsCount: totalSegmentsCount, duration: duration) {
                        guard !isProcessingCancelled else { return }
                        status("merging videos for \(filePath)")
                        
                        let outputPath = "\(NSHomeDirectory())/Downloads/Waifu Output/\(currentVideo.finderItem.fileName!).mov"
                        
                        FinderItem.mergeVideos(from: FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/splitVideo").children!.map({ $0.avAsset! }), toPath: outputPath) { urlGet, errorGet in
                            
                            onStatusProgressChanged(nil, nil)
                            
                            status("merging video and audio for \(filePath)")
                            
                            FinderItem.mergeVideoWithAudio(videoUrl: URL(fileURLWithPath: outputPath), audioUrl: URL(fileURLWithPath: audioPath)) { _ in
                                status("Completed")
                                try! FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp").removeFile()
                                
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
    @State var pdfbackground = DispatchQueue(label: "PDF Background")
    @State var chosenScaleLevel: Int = 1
    @State var chosenComputeOption = "GPU"
    @State var videoSegmentLength = 10
    
    var body: some View {
        VStack {
            HStack {
                if !finderItems.isEmpty {
                    Button("Remove All") {
                        finderItems = []
                    }
                    .padding(.all)
                }
                
                Spacer()
                
                Button("Add Item") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = true
                    if panel.runModal() == .OK {
                        for i in panel.urls {
                            let item = FinderItem(at: i)
                            
                            addItemIfPossible(of: item, to: &finderItems)
                        }
                    }
                }
                    .padding(.all)
                
                Button("Done") {
                    isSheetShown = true
                }
                    .disabled(finderItems.isEmpty || isSheetShown)
                    .padding([.top, .bottom, .trailing])
            }
            
            if finderItems.isEmpty {
                welcomeView(finderItems: $finderItems)
            } else {
                GeometryReader { geometry in
                    
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5)) {
                            ForEach(finderItems) { item in
                                GridItemView(finderItems: $finderItems, item: item, geometry: geometry)
                                
                            }
                        }
                        
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        for i in providers {
                            i.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, error in
                                print(finderItems)
                                
                                guard error == nil else { return }
                                guard let urlData = urlData as? Data else { return }
                                guard let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                                
                                let item = FinderItem(at: url)
                                
                                addItemIfPossible(of: item, to: &finderItems)
                            }
                        }
                        
                        return true
                    }
                }
            }
        }
        .sheet(isPresented: $isSheetShown, onDismiss: nil) {
            ConfigurationView(finderItems: finderItems, isShown: $isSheetShown, isProcessing: $isProcessing, modelUsed: $modelUsed, chosenScaleLevel: $chosenScaleLevel, chosenComputeOption: $chosenComputeOption, videoSegmentLength: $videoSegmentLength)
        }
        .sheet(isPresented: $isProcessing, onDismiss: nil) {
            ProcessingView(isProcessing: $isProcessing, finderItems: $finderItems, modelUsed: $modelUsed, isSheetShown: $isSheetShown, chosenScaleLevel: $chosenScaleLevel, isCreatingPDF: $isCreatingPDF, chosenComputeOption: $chosenComputeOption, videoSegmentLength: $videoSegmentLength)
        }
        .sheet(isPresented: $isCreatingPDF, onDismiss: nil) {
            ProcessingPDFView(isCreatingPDF: $isCreatingPDF, background: $pdfbackground)
        }
        .onAppear {
            DispatchQueue(label: "background").async {
                let finderItem = FinderItem(at: "\(NSHomeDirectory())/temp")
                if finderItem.isExistence {
                    try! finderItem.removeFile()
                }
            }
        }
    }
}

struct welcomeView: View {
    
    @Binding var finderItems: [WorkItem]
    
    var body: some View {
        VStack {
            Image(systemName: "square.and.arrow.down.fill")
                .resizable()
                .scaledToFit()
                .padding(.all)
                .frame(width: 100, height: 100, alignment: .center)
            Text("Drag files or folder \n or \n Click to add files.")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.all)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.all, 0.0)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for i in providers {
                i.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, error in
                    guard error == nil else { return }
                    guard let urlData = urlData as? Data else { return }
                    guard let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                    
                    let item = FinderItem(at: url)
                    
                    addItemIfPossible(of: item, to: &finderItems)
                }
            }
            
            return true
        }
        .onTapGesture(count: 2) {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = true
            if panel.runModal() == .OK {
                for i in panel.urls {
                    let item = FinderItem(at: i)
                    addItemIfPossible(of: item, to: &finderItems)
                }
            }
        }
    }
}


struct GridItemView: View {
    
    @Binding var finderItems: [WorkItem]
    
    @State var isShowingHint: Bool = false
    
    let item: WorkItem
    let geometry: GeometryProxy
    
    var body: some View {
        if let image = item.finderItem.image ?? item.finderItem.firstFrame {
            VStack(alignment: .center) {
                Image(nsImage: image)
                    .resizable()
                    .cornerRadius(5)
                    .aspectRatio(contentMode: .fit)
                    .padding([.top, .leading, .trailing])
                    .popover(isPresented: $isShowingHint) {
                        Text("""
                        name: \(item.finderItem.fileName ?? "???")
                        path: \(item.finderItem.path)
                        """)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                
                Text(((item.finderItem.relativePath ?? item.finderItem.fileName) ?? item.finderItem.path) + "\n" + "\(image.cgImage(forProposedRect: nil, context: nil, hints: nil)!.width) × \(image.cgImage(forProposedRect: nil, context: nil, hints: nil)!.height)")
                    .multilineTextAlignment(.center)
                    .padding([.leading, .bottom, .trailing])
                    .onHover { bool in
                        self.isShowingHint = bool
                    }
            }
            .frame(width: geometry.size.width / 5, height: geometry.size.width / 5)
            .contextMenu {
                Button("Open") {
                    _ = shell(["open \(item.finderItem.path.replacingOccurrences(of: " ", with: "\\ "))"])
                }
                Button("Show in Finder") {
                    _ = shell(["open \(item.finderItem.path.replacingOccurrences(of: " ", with: "\\ ")) -R"])
                }
                Button("Delete") {
                    finderItems.remove(at: finderItems.firstIndex(of: item)!)
                }
            }
        } else {
            Rectangle()
        }
    }
}

struct ConfigurationView: View {
    
    var finderItems: [WorkItem]
    
    @Binding var isShown: Bool
    @Binding var isProcessing: Bool
    @Binding var modelUsed: Waifu2xModel?
    @Binding var chosenScaleLevel: Int {
        didSet {
            findModelClass()
        }
    }
    @Binding var chosenComputeOption: String
    @Binding var videoSegmentLength: Int
    
    let styleNames: [String] = ["anime", "photo"]
    @State var chosenStyle = "anime" {
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
    
    let scaleLevels: [Int] = [Int](0...5)
    
    @State var modelClass: [String] = []
    @State var chosenModelClass: String = ""
    
    let computeOptions = ["CPU", "GPU"]
    let videoSegmentOptions = [1, 5, 10, 15, 30, 60]
    
    @State var isShowingStyleHint: Bool = false
    @State var isShowingNoiceHint: Bool = false
    @State var isShowingScaleHint: Bool = false
    @State var isShowingModelClassHint: Bool = false
    @State var isShowingGPUHint: Bool = false
    @State var isShowingVideoSegmentHint: Bool = false
    
    func findModelClass() {
        self.modelClass = Array(Set(Waifu2xModel.allModels.filter({ ($0.style == chosenStyle || $0.style == nil) && $0.noise == Int(chosenNoiseLevel) && $0.scale == ( chosenScaleLevel == 0 ? 1 : 2 ) }).map({ $0.class })))
        self.chosenModelClass = modelClass[0]
    }
    
    var body: some View {
        VStack {
            
            Spacer()
            
            HStack(spacing: 10) {
                VStack(spacing: 19) {
                    HStack {
                        Spacer()
                        Text("Style:")
                            .padding(.bottom)
                            .onHover { bool in
                                isShowingStyleHint = bool
                            }
                    }
                    
                    HStack {
                        Spacer()
                        Text("Denoise Level:")
                            .onHover { bool in
                                isShowingNoiceHint = bool
                            }
                    }
                    
                    HStack {
                        Spacer()
                        Text("Scale Level:")
                            .onHover { bool in
                                isShowingScaleHint = bool
                            }
                    }
                    
                    if !modelClass.isEmpty {
                        HStack {
                            Spacer()
                            Text("Model Class:")
                                .onHover { bool in
                                    isShowingModelClassHint = bool
                                }
                                .padding(.bottom)
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Text("Compute With:")
                            .onHover { bool in
                                isShowingGPUHint = bool
                            }
                    }
                    
                    if !finderItems.filter({ $0.type == .video }).isEmpty {
                        HStack {
                            Spacer()
                            Text("Video Segment Length:")
                                .onHover { bool in
                                    isShowingVideoSegmentHint = bool
                                }
                        }
                    }
                }
                
                VStack(spacing: 15) {
                    
                    Menu(chosenStyle) {
                        ForEach(styleNames, id: \.self) { item in
                            Button(item) {
                                chosenStyle = item
                            }
                        }
                    }
                    .padding(.bottom)
                    .popover(isPresented: $isShowingStyleHint) {
                        Text("anime: for illustrations or 2D images or CG")
                            .padding([.top, .leading, .trailing])
                            .padding(.bottom, 3)
                            
                        Text("photo: for photos of real world or 3D images")
                            .padding([.leading, .bottom, .trailing])
                        
                    }
                    
                    Menu(chosenNoiseLevel.description) {
                        ForEach(noiseLevels, id: \.self) { item in
                            Button(item.description) {
                                chosenNoiseLevel = item
                            }
                        }
                    }
                    .popover(isPresented: $isShowingNoiceHint) {
                        Text("denoise level 3 recommended.\nHint: Don't know which to choose? go to Compare > Compare Models and try by yourself!")
                            .padding(.all)
                        
                    }
                    
                    Menu(pow(2, chosenScaleLevel).description) {
                        ForEach(scaleLevels, id: \.self) { item in
                            Button(pow(2, item).description) {
                                chosenScaleLevel = item
                            }
                        }
                    }
                    .popover(isPresented: $isShowingScaleHint) {
                        Text("Choose how much you want to scale.")
                            .padding(.all)
                        
                    }
                    
                    if !modelClass.isEmpty {
                        Menu(chosenModelClass) {
                            ForEach(modelClass, id: \.self) { item in
                                Button(item) {
                                    chosenModelClass = item
                                }
                            }
                        }
                        .padding(.bottom)
                        .popover(isPresented: $isShowingModelClassHint) {
                            Text("The model to use.")
                                .padding(.all)
                            
                        }
                    }
                    
                    Menu(chosenComputeOption) {
                        ForEach(computeOptions, id: \.self) { item in
                            Button(item) {
                                chosenComputeOption = item
                            }
                        }
                    }
                    .popover(isPresented: $isShowingGPUHint) {
                        Text("GPU recommended")
                            .padding(.all)
                        
                    }
                    
                    if !finderItems.filter({ $0.type == .video }).isEmpty {
                        Menu(videoSegmentLength.description + "s") {
                            ForEach(videoSegmentOptions, id: \.self) { item in
                                Button(item.description + "s") {
                                     videoSegmentLength = item
                                }
                            }
                        }
                        .popover(isPresented: $isShowingVideoSegmentHint) {
                            Text("Larger the value, more storage required, but faster (maybe)")
                                .padding(.all)
                            
                        }
                    }
                }
                
            }
                .padding(.horizontal, 50.0)
            
            Spacer()
            
            HStack {
                
                Spacer()
                
                Button {
                    isShown = false
                } label: {
                    Text("Cancel")
                        .frame(width: 80)
                }
                .padding(.trailing)
                
                Button {
                    isProcessing = true
                    isShown = false
                    
                    self.modelUsed = Waifu2xModel.allModels.filter({ ($0.style == chosenStyle || $0.style == nil) && $0.noise == Int(chosenNoiseLevel) && $0.scale == ( chosenScaleLevel == 0 ? 1 : 2 ) && $0.class == self.chosenModelClass }).first!
                    
                } label: {
                    Text("OK")
                        .frame(width: 80)
                }.disabled(modelClass.isEmpty)
            }
                .padding(.all)
        }
            .padding(.all)
            .frame(width: 600, height: 350)
            .onAppear {
                findModelClass()
            }
    }
    
}


struct ProcessingView: View {
    
    @Binding var isProcessing: Bool
    @Binding var finderItems: [WorkItem]
    @Binding var modelUsed: Waifu2xModel?
    @Binding var isSheetShown: Bool
    @Binding var chosenScaleLevel: Int
    @Binding var isCreatingPDF: Bool
    @Binding var chosenComputeOption: String
    @Binding var videoSegmentLength: Int
    
    @State var processedItemsCounter: Int = 0
    @State var currentTimeTaken: Double = 0 // up to 1s
    @State var pastTimeTaken: Double = 0 // up to 1s
    @State var isPaused: Bool = false {
        didSet {
            if isPaused {
                timer.upstream.connect().cancel()
                
                background.suspend()
            } else {
                timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
                
                background.resume()
            }
        }
    }
    @State var currentProcessingItemsCount: Int = 0
    @State var timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    @State var isFinished: Bool = false {
        didSet {
            if isFinished {
                timer.upstream.connect().cancel()
            }
        }
    }
    @State var progress: Double = 0.0
    @State var isCreatingImageSequence: Bool = false
    @State var isMergingVideo: Bool = false
    @State var videos: [FinderItem] = []
    @State var status: String = "Loading..."
    @State var statusProgress: (progress: Int, total: Int)? = nil
    @State var isShowProgressDetail = false
    @State var workItem: DispatchWorkItem? = nil
    var background: DispatchQueue = DispatchQueue(label: "background")
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .trailing, spacing: 10) {
                    VStack(alignment: .trailing, spacing: 10) {
                        Text("Status:")
                        
                        if statusProgress != nil {
                            Text("progress:")
                        }
                        
                        Text("ML Model:")
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
                        
                        if let statusProgress = statusProgress {
                            Text("\(statusProgress.progress) / \(statusProgress.total)")
                        }
                        
                        Text(modelUsed!.class)
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
                guard !isCreatingImageSequence else { return 0 }
                guard !finderItems.isEmpty else { return 1 }
                let factor: Int
                if chosenScaleLevel > 1 {
                    factor = chosenScaleLevel
                } else {
                    factor = 1
                }
                
                return progress / Double(factor)
            }())
            .popover(isPresented: $isShowProgressDetail) {
                Text("\(String(format: "%.2f", progress * 100))%")
                    .padding(.all, 3)
                    .frame(width: 100)
            }
            .onHover { bool in
                isShowProgressDetail = bool
            }
            .padding([.bottom])
            
            Spacer()
            
            HStack {
                Spacer()
                
                if !isFinished {
                    Button("Cancel") {
                        isFinished = true
                        isProcessing = false
                        isSheetShown = true
                        isProcessingCancelled = true
                        workItem!.cancel()
                    }
                    .padding(.trailing)
                    
                    Button(isPaused ? "Resume" : "Pause") {
                        isPaused.toggle()
                    }
                    .disabled(true)
                } else {
                    Button("Create PDF") {
                        finderItems = []
                        isProcessing = false
                        isCreatingPDF = true
                    }
                    .disabled(!(FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu\\ Output").children?.filter({ $0.isDirectory }).isEmpty ?? false))
                    .padding(.trailing)
                    
                    Button("Show in Finder") {
                        _ = shell(["open \(NSHomeDirectory())/Downloads/Waifu\\ Output"])
                    }
                    .padding(.trailing)
                    
                    Button("Done") {
                        finderItems = []
                        isProcessing = false
                    }
                }
            }
        }
            .padding(.all)
            .frame(width: 600, height: 350)
            .onAppear {
                
                self.workItem = DispatchWorkItem(qos: .background, flags: .inheritQoS) {
                    finderItems.work(chosenScaleLevel, modelUsed: modelUsed!, videoSegmentLength: videoSegmentLength, isUsingGPU: chosenComputeOption == "GPU") { status in
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
                
                background.async {
                    workItem!.perform()
                }
            }
            .onReceive(timer) { timer in
                currentTimeTaken += 1
                pastTimeTaken += 1
            }
    }
}


struct ProcessingPDFView: View {
    
    @Binding var isCreatingPDF: Bool
    @Binding var background: DispatchQueue
    
    @State var finderItemsCount: Int = 0
    @State var processedItemsCount: Int = 0
    @State var currentProcessingItem: FinderItem? = nil
    @State var isFinished: Bool = false
    
    var body: some View {
        VStack {
            
            HStack {
                VStack(spacing: 10) {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text("Processing:")
                    }
                    .padding(.bottom)
                    
                    HStack {
                        Spacer()
                        Text("Processed:")
                    }
                    
                    HStack {
                        Spacer()
                        Text("To be processed:")
                    }
                    
                    Spacer()
                }
                
                VStack(spacing: 10) {
                    Spacer()
                    
                    HStack {
                        if let currentProcessingItem = currentProcessingItem {
                            Text(currentProcessingItem.relativePath ?? currentProcessingItem.fileName ?? "error")
                        } else {
                            Text("Error: \(currentProcessingItem.debugDescription)")
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom)
                    
                    HStack {
                        Text("\(processedItemsCount) items")
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(finderItemsCount - processedItemsCount) items")
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            ProgressView(value: {()->Double in
                guard finderItemsCount != 0 else { return 1 }
                return Double(processedItemsCount) / Double(finderItemsCount)
            }())
                .padding(.all)
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Show in Finder") {
                    _ = shell(["open \(NSHomeDirectory())/Downloads/PDF\\ output"])
                }
                .padding(.trailing)
                
                Button("Done") {
                    isCreatingPDF = false
                }
                .disabled(!isFinished)
            }
            .padding(.all)
        }
        .padding(.all)
        .frame(width: 600, height: 300)
        .onAppear {
            
            isProcessingCancelled = false
            
            var counter = 0
            FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output").iteratedOver { child in
                guard child.image != nil else { return }
                counter += 1
            }
            
            finderItemsCount = counter
            
            background.async {
                FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output").iteratedOver { child in
                    guard child.isDirectory else { return }
                    
                    FinderItem.createPDF(fromFolder: child) { item in
                        currentProcessingItem = item
                        processedItemsCount += 1
                    } onFinish: {
                        isFinished = true
                    }
                }
                
            }
            
        }
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
