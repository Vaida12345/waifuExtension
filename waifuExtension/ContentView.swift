//
//  ContentView.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI
import AVFoundation

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
    
    /// note: remember to add isCancelled into onStatusChanged.
    func work(_ chosenScaleLevel: Int, modelUsed: Model, onStatusChanged status: @escaping ((_ status: String)->()), onProgressChanged: @escaping ((_ progress: Double) -> ()), didFinishOneItem: @escaping ((_ finished: Int, _ total: Int)->()), completion: @escaping (() -> ())) {
        
        let images = self.filter({ $0.type == .image })
        let videos = self.filter({ $0.type == .video })
        let backgroundQueue = DispatchQueue(label: "[WorkItem] background dispatch queue")
        
        let totalItemCounter = self.count
        var finishedItemsCounter = 0
        
        if !images.isEmpty {
            status("processing images")
            var concurrentProcessingImagesCount = 0
            
            DispatchQueue.concurrentPerform(iterations: images.count) { imageIndex in
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
            
        }
        
        status("Completed")
        completion()
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
    
    func work(chosenScaleLevel: Int, modelUsed: Model, onStatusChanged: @escaping ((_ staus: Status)->()), onChangingProgress: @escaping ((_ progress: Double, _ total: Double) -> ()), completion: @escaping (() -> ())) {
        print("work submitted with a \(type.rawValue)")
        
        if type == .image {
            guard var image = self.finderItem.image else { return }
            
            let waifu2x = Waifu2x()
//            waifu2x.didFinishedOneBlock = { finished, total in
//                self.progress += 1 / Double(total)
//                onChangingProgress(self.progress, Double(total))
//            }
            
            if chosenScaleLevel >= 2 {
                for _ in 1...chosenScaleLevel {
                    image = waifu2x.run(image, model: modelUsed)!.reload()
                }
            } else {
                image = waifu2x.run(image, model: modelUsed)!
            }
            
            let path: String
            if let name = self.finderItem.relativePath {
                path = name[..<name.lastIndex(of: ".")!] + ".png"
            } else {
                path = self.finderItem.fileName! + ".png"
            }
            
            let finderItem = FinderItem(at: path)
            
            finderItem.generateDirectory()
            image.write(to: finderItem.path)
            
            completion()
            
        } else {
            print("processing video")
            onStatusChanged(.splittingVideo)
            
            guard self.finderItem.avAsset != nil else { return }
            
            let filePath = self.finderItem.relativePath ?? self.finderItem.fileName!
            
            let tmpPath = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw"
            FinderItem(at: tmpPath).generateDirectory()
            
            try! self.finderItem.saveAudioTrack(to: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/audio.m4a")
            let duration = self.finderItem.avAsset!.duration.seconds
            
            // split videos
            var splitVideos: [WorkItem] = []
            var counter: Double = 0
            var finalCounter = 0
            while counter < duration {
                var sequence = String(Int(counter))
                while sequence.count <= 5 { sequence.insert("0", at: sequence.startIndex) }
                let path = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/splitVideo/video \(sequence).mov"
                FinderItem(at: path).generateDirectory()
                FinderItem.trimVideo(sourceURL: self.finderItem.url, outputURL: URL(fileURLWithPath: path), statTime: Float(counter), endTime: {()->Float in
                    if counter + 1 < duration {
                        return Float(counter + 1)
                    } else {
                        return Float(duration)
                    }
                }()) { asset in
                    // generate frames and enlarge
                    onStatusChanged(.generatingImages)
                    let item = WorkItem(at: FinderItem(at: path), type: .video)
                    splitVideos.append(item)
                    
                    let rawFramePath = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw/frames/video \(sequence).mov"
                    FinderItem(at: rawFramePath + "/frame 1.png").generateDirectory()
                    
                    let rawFrames = item.finderItem.frames!
                    
                    print("frames: \(rawFrames.count)")
                    
                    let frames: [NSImage] = rawFrames
                    
                    var frameCounter = 1
                    
                    var enlargedImages: [orderedImages] = []
                    
                    DispatchQueue.concurrentPerform(iterations: frames.count) { index in
                        var image = frames[index]
                        
                        let waifu2x = Waifu2x()
//                        waifu2x.didFinishedOneBlock = { finished, total in
//                            self.progress += 1 / Double(total) / (duration + 1).rounded(.up) / Double(frames.count)
//                            onChangingProgress(self.progress, Double(total) * (duration + 1).rounded(.up) * Double(frames.count))
//                        }
                        
                        if chosenScaleLevel >= 2 {
                            for _ in 1...chosenScaleLevel {
                                image = waifu2x.run(image.reload(withIndex: index), model: modelUsed)!
                            }
                        } else {
                            image = waifu2x.run(image.reload(withIndex: index), model: modelUsed)!
                        }
                        
                        var frameSequence = String(frameCounter)
                        while frameSequence.count <= 5 { frameSequence.insert("0", at: frameSequence.startIndex) }
                        
                        enlargedImages.append(orderedImages(image: image, index: index))
                        
                        frameCounter += 1
                    }
                    
                    // enlarged, now save as video
                    onStatusChanged(.savingVideos)
                    let path = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/splitVideo/video \(sequence).mov"
                    let enlargedFrames: [NSImage] = enlargedImages.sorted(by: { $0.index < $1.index }).map{ $0.image }
                    
                    print("enlarged frames number: \(enlargedFrames.count)")
                    
//                    try! FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/splitVideo frames/video \(sequence).mov").removeFile()
                    
                    FinderItem.convertImageSequenceToVideo(enlargedFrames, videoPath: path, videoSize: enlargedFrames.first!.size, videoFPS: Int32(item.finderItem.frameRate!)) {
                        
                        // if all videos are ready, merge video and save
                        
                        print(finalCounter)
                        finalCounter += 1
                        guard Int(finalCounter) == Int(duration.rounded(.up)) else { return }
                        onStatusChanged(.mergingVideos)
                        
                        let path = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/\(self.finderItem.fileName!).mov"
                        FinderItem.mergeVideos(from: FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/splitVideo").children!.map({ $0.avAsset! }), toPath: path) { urlGet, errorGet in
                            
                            print("merge video completed.")
                            // video merged, now merge with audio file
                            onStatusChanged(.mergingAudio)
                            FinderItem.mergeVideoWithAudio(videoUrl: URL(fileURLWithPath: path), audioUrl: URL(fileURLWithPath: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/audio.m4a")) { _ in
                                // audio merged. Finished.
                                
                                try! FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/\(self.finderItem.fileName!).mov").copy(to: "\(NSHomeDirectory())/Downloads/Waifu Output/\(self.finderItem.fileName!).mov")
                                try! FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp").removeFile()
                                
                                completion()
                            } failure: { error in
                                print(error.debugDescription)
                            }

                        }
                    }
                }
                
                counter += 1
            }
        }
    }
}

struct ContentView: View {
    @State var finderItems: [WorkItem] = []
    @State var isSheetShown: Bool = false
    @State var isProcessing: Bool = false
    @State var isCreatingPDF: Bool = false
    @State var modelUsed: Model? = nil
    @State var background = DispatchQueue(label: "Background")
    @State var pdfbackground = DispatchQueue(label: "PDF Background")
    @State var chosenScaleLevel: Int = 1
    @State var allowParallelExecution: Bool = true
    
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
                                GridItemView(item: item, geometry: geometry, finderItems: $finderItems)
                                
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
            ConfigurationView(finderItems: finderItems, isShown: $isSheetShown, isProcessing: $isProcessing, modelUsed: $modelUsed, chosenScaleLevel: $chosenScaleLevel, allowParallelExecution: $allowParallelExecution)
        }
        .sheet(isPresented: $isProcessing, onDismiss: nil) {
            ProcessingView(isProcessing: $isProcessing, finderItems: $finderItems, modelUsed: $modelUsed, isSheetShown: $isSheetShown, background: $background, chosenScaleLevel: $chosenScaleLevel, isCreatingPDF: $isCreatingPDF, allowParallelExecution: $allowParallelExecution)
        }
        .sheet(isPresented: $isCreatingPDF, onDismiss: nil) {
            ProcessingPDFView(isCreatingPDF: $isCreatingPDF, background: $pdfbackground)
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
        .onTapGesture {
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
    
    let item: WorkItem
    let geometry: GeometryProxy
    @Binding var finderItems: [WorkItem]
    
    var body: some View {
        if let image = item.finderItem.image ?? item.finderItem.firstFrame {
            VStack(alignment: .center) {
                Image(nsImage: image)
                    .resizable()
                    .cornerRadius(5)
                    .aspectRatio(contentMode: .fit)
                    .padding([.top, .leading, .trailing])
                
                Text(((item.finderItem.relativePath ?? item.finderItem.fileName) ?? item.finderItem.path) + "\n" + "\(image.cgImage(forProposedRect: nil, context: nil, hints: nil)!.width) × \(image.cgImage(forProposedRect: nil, context: nil, hints: nil)!.height)")
                    .multilineTextAlignment(.center)
                    .padding([.leading, .bottom, .trailing])
            }
            .frame(width: geometry.size.width / 5, height: geometry.size.width / 5)
            .contextMenu {
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
    @Binding var modelUsed: Model?
    @Binding var chosenScaleLevel: Int {
        didSet {
            if chosenScaleLevel >= 3 {
                allowParallelExecution = false
            }
        }
    }
    @Binding var allowParallelExecution: Bool
    
    let styleNames: [String] = ["anime", "photo"]
    @State var chosenStyle = "anime"
    
    let noiceLevels: [String] = ["0", "1", "2", "3"]
    @State var chosenNoiceLevel = "3"
    
    let scaleLevels: [Int] = [Int](0...5)
    
    @State var isShowingStyleHint: Bool = false
    @State var isShowingNoiceHint: Bool = false
    @State var isShowingScaleHint: Bool = false
    @State var isShowingParallelHint: Bool = false
    
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
                    HStack {
                        Spacer()
                        Text("Allow Parallel Execution:")
                            .onHover { bool in
                                isShowingParallelHint = bool
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
                    
                    Menu(chosenNoiceLevel.description) {
                        ForEach(noiceLevels, id: \.self) { item in
                            Button(item.description) {
                                chosenNoiceLevel = item
                            }
                        }
                    }
                    .popover(isPresented: $isShowingNoiceHint) {
                        Text("Denoise could counter the effect due to compressions of JPGs. \nThis is not recommended for PNGs.")
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
                    
                    Menu(allowParallelExecution.description) {
                        ForEach([true, false], id: \.self) { item in
                            Button(item.description) {
                                allowParallelExecution = item
                            }
                        }
                    }
                    .popover(isPresented: $isShowingParallelHint) {
                        Text("Parallel execution is recommended to enhance efficiency. \nHowever, the consumption of RAM would increase.")
                            .padding(.all)
                        
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
                    
                    //change here
                    let modelName = (chosenScaleLevel == 0 ? "" : "up_") + "\(chosenStyle)_noise\(chosenNoiceLevel)\(chosenScaleLevel == 0 ? "" : "_scale2x")_model"
                    
                    self.modelUsed = Model(rawValue: modelName)!
                    
                } label: {
                    Text("OK")
                        .frame(width: 80)
                }
            }
                .padding(.all)
        }
            .padding(.all)
            .frame(width: 600, height: 300)
    }
    
}


struct ProcessingView: View {
    
    @Binding var isProcessing: Bool
    @Binding var finderItems: [WorkItem]
    @Binding var modelUsed: Model?
    @Binding var isSheetShown: Bool
    @Binding var background: DispatchQueue
    @Binding var chosenScaleLevel: Int
    @Binding var isCreatingPDF: Bool
    @Binding var allowParallelExecution: Bool
    
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
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(spacing: 10) {
                    HStack {
                        Spacer()
                        Text("Status:")
                    }
                    
                    if !allowParallelExecution {
                        HStack {
                            Spacer()
                            Text("Time Spent:")
                        }
                    }
                    HStack {
                        Spacer()
                        Text("ML Model:")
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text("Processed:")
                    }
                    
                    HStack {
                        Spacer()
                        Text("To be processed:")
                    }
                    
                    HStack {
                        Spacer()
                        Text("Time Spent:")
                    }
                    
                    HStack {
                        Spacer()
                        Text("Time Remainning:")
                    }
                    
                    HStack {
                        Spacer()
                        Text("ETA:")
                    }
                    
                    Spacer()
                }
                
                VStack(spacing: 10) {
                    HStack {
                        Text(status)
                        
                        Spacer()
                    }
                    
                    if !allowParallelExecution {
                        HStack {
                            Text(currentTimeTaken.expressedAsTime())
                            
                            Spacer()
                        }
                    }
                    
                    HStack {
                        Text(modelUsed!.rawValue)
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack {
                        if processedItemsCounter >= 2 {
                            Text("\(processedItemsCounter) items")
                        } else {
                            Text("\(processedItemsCounter) item")
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        if isFinished {
                            Text("0 item")
                        } else if finderItems.count - processedItemsCounter >= 2 {
                            Text("\(finderItems.count - processedItemsCounter) items")
                        } else {
                            Text("\(finderItems.count - processedItemsCounter) item")
                        }
                        
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text((pastTimeTaken).expressedAsTime())
                        
                        Spacer()
                    }
                    
                    HStack { // time remaining
                        Text({ ()-> String in
                            guard !isFinished else { return "finished" }
                            guard !isPaused else { return "paused" }
                            guard processedItemsCounter != 0 && !isMergingVideo else { return "calculating..." }
                            
                            var value = Double(finderItems.count) * (pastTimeTaken / Double(processedItemsCounter))
                            value -= pastTimeTaken + currentTimeTaken
                            
                            guard value >= 0 else { return "calculating..." }
                            
                            return value.expressedAsTime()
                        }())
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text({ ()-> String in
                            guard !isFinished else { return "finished" }
                            guard !isPaused else { return "paused" }
                            guard processedItemsCounter != 0 && !isMergingVideo else { return "calculating..." }
                            
                            var value = Double(finderItems.count) * (pastTimeTaken / Double(processedItemsCounter))
                            value -= pastTimeTaken + currentTimeTaken
                            
                            guard value >= 0 else { return "calculating..." }
                            
                            let date = Date().addingTimeInterval(value)
                            
                            let formatter = DateFormatter()
                            formatter.dateStyle = .none
                            formatter.timeStyle = .medium
                            
                            return formatter.string(from: date)
                        }())
                        
                        Spacer()
                    }
                    
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
                .padding([.bottom])
            
            Spacer()
            
            HStack {
                Spacer()
                
                if !isFinished {
                    Button("Cancel") {
                        isFinished = true
                        isProcessing = false
                        isSheetShown = true
                    }
                    .padding(.trailing)
                    
                    Button(isPaused ? "Resume" : "Pause") {
                        isPaused.toggle()
                    }
                } else {
                    Button("Create PDF") {
                        finderItems = []
                        isProcessing = false
                        isCreatingPDF = true
                    }
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
                func execute(_ i: WorkItem) {
                    DispatchQueue.main.async {
                        currentProcessingItemsCount += 1
                    }
                    
                    i.work(chosenScaleLevel: chosenScaleLevel, modelUsed: modelUsed!) { status in
                        //TODO: change status here, also check why not processed.
                        print(status.rawValue)
                    } onChangingProgress: { progress, total in
                        self.progress += 1 / total
                    } completion: {
//                        processedItemsCounter.append(i)
                        currentTimeTaken = 0
                        
                        DispatchQueue.main.async {
                            currentProcessingItemsCount -= 1
                        }
                        
                        guard processedItemsCounter == finderItems.count else { return }
                        
                        isFinished = true
                    }
                    
                }
                
                background.async {
                    self.finderItems.work(self.chosenScaleLevel, modelUsed: self.modelUsed!) { status in
                        self.status = status
                    } onProgressChanged: { progress in
                        self.progress = progress
                    } didFinishOneItem: { finished,total in
                        self.processedItemsCounter = finished
                    } completion: {
                        print("yeah!")
                        isFinished = true
                    }

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
