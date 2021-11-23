//
//  ContentView.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State var finderItems: [FinderItem] = []
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
                            
                            guard !finderItems.contains(item) else { return }
                            
                            if item.isFile {
                                guard item.image != nil || item.avAsset != nil else { return }
                                finderItems.append(item)
                            } else {
                                item.iteratedOver { child in
                                    guard !finderItems.contains(child) else { return }
                                    guard child.image != nil || child.avAsset != nil else { return }
                                    child.relativePath = item.fileName! + "/" + child.relativePath(to: item)!
                                    finderItems.append(child)
                                }
                            }
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
                                guard !finderItems.contains(item) else { return }
                                
                                if item.isFile {
                                    guard item.image != nil || item.avAsset != nil else { return }
                                    finderItems.append(item)
                                } else {
                                    item.iteratedOver { child in
                                        guard !finderItems.contains(child) else { return }
                                        guard child.image != nil || child.avAsset != nil else { return }
                                        child.relativePath = item.fileName! + "/" + child.relativePath(to: item)!
                                        finderItems.append(child)
                                    }
                                }
                                
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
    
    @Binding var finderItems: [FinderItem]
    
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
                    
                    if item.isFile {
                        guard item.image != nil || item.avAsset != nil else { return }
                        finderItems.append(item)
                    } else {
                        item.iteratedOver { child in
                            guard child.image != nil || child.avAsset != nil else { return }
                            child.relativePath = item.fileName! + "/" + child.relativePath(to: item)!
                            finderItems.append(child)
                        }
                    }
                    
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
                    
                    if item.isFile {
                        guard item.image != nil || item.avAsset != nil else { return }
                        finderItems.append(item)
                    } else {
                        item.iteratedOver { child in
                            guard child.image != nil || child.avAsset != nil else { return }
                            child.relativePath = item.fileName! + "/" + child.relativePath(to: item)!
                            finderItems.append(child)
                        }
                    }
                }
            }
        }
    }
}


struct GridItemView: View {
    
    let item: FinderItem
    let geometry: GeometryProxy
    @Binding var finderItems: [FinderItem]
    
    var body: some View {
        if let image = item.image ?? item.firstFrame {
            VStack(alignment: .center) {
                Image(nsImage: image)
                    .resizable()
                    .cornerRadius(5)
                    .aspectRatio(contentMode: .fit)
                    .padding([.top, .leading, .trailing])
                
                Text(((item.relativePath ?? item.fileName) ?? item.path) + "\n" + "\(image.cgImage(forProposedRect: nil, context: nil, hints: nil)!.width) × \(image.cgImage(forProposedRect: nil, context: nil, hints: nil)!.height)")
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
    
    var finderItems: [FinderItem]
    
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
    @Binding var finderItems: [FinderItem]
    @Binding var modelUsed: Model?
    @Binding var isSheetShown: Bool
    @Binding var background: DispatchQueue
    @Binding var chosenScaleLevel: Int
    @Binding var isCreatingPDF: Bool
    @Binding var allowParallelExecution: Bool
    
    @State var processedItems: [FinderItem] = []
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
    @State var isFinished: Bool = false
    @State var progress: Double = 0.0
    @State var isCreatingImageSequence: Bool = false
    @State var isMergingVideo: Bool = false
    @State var videos: [FinderItem] = []
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(spacing: 10) {
                    HStack {
                        Spacer()
                        Text("Processing:")
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
                        if isMergingVideo {
                            Text("Merging frames to video...")
                        } else if isCreatingImageSequence {
                            Text("Extracting frames from video...")
                        } else if currentProcessingItemsCount >= 2 {
                            Text("\(currentProcessingItemsCount) items in parallel")
                        } else {
                            Text("\(currentProcessingItemsCount) item")
                        }
                        
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
                        if processedItems.count >= 2 {
                            Text("\(processedItems.count) items")
                        } else {
                            Text("\(processedItems.count) item")
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        if isFinished {
                            Text("0 item")
                        } else if finderItems.count - processedItems.count >= 2 {
                            Text("\(finderItems.count - processedItems.count) items")
                        } else {
                            Text("\(finderItems.count - processedItems.count) item")
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
                            guard !processedItems.isEmpty && !isMergingVideo else { return "calculating..." }
                            
                            var value = Double(finderItems.count) * (pastTimeTaken / Double(processedItems.count))
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
                            guard !processedItems.isEmpty && !isMergingVideo else { return "calculating..." }
                            
                            var value = Double(finderItems.count) * (pastTimeTaken / Double(processedItems.count))
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
                
                return progress / Double(finderItems.count * factor)
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
                func execute(_ i: FinderItem) {
                    DispatchQueue.main.async {
                        currentProcessingItemsCount += 1
                    }
                    
                    guard var image = i.image else { return }
                    
                    let waifu2x = Waifu2x()
                    waifu2x.didFinishedOneBlock = { finished, total in
                        progress += 1 / Double(total)
                    }
                    if chosenScaleLevel >= 2 {
                        for _ in 1...chosenScaleLevel {
                            image = waifu2x.run(image, model: modelUsed!)!.reload()
                        }
                    } else {
                        image = waifu2x.run(image, model: modelUsed!)!
                    }
                    
                    let path: String
                    if let name = i.relativePath {
                        path = name[..<name.lastIndex(of: ".")!] + ".png"
                    } else {
                        path = i.fileName! + ".png"
                    }
                    
                    let finderItem: FinderItem
                    if i.fileName!.contains("{sequence}") {
                        let name = i.fileName![i.fileName!.index(after: i.fileName!.startIndex)..<i.fileName!.firstIndex(of: "}")!]
                        let item = videos.filter({ $0.fileName! == name }).first!
                        
                        let filePath = item.relativePath ?? item.fileName!
                        
                        finderItem = FinderItem(at: NSHomeDirectory() + "/Downloads/Waifu Output/tmp/\(filePath)/processed/\(path)")
                    } else {
                        finderItem = FinderItem(at: NSHomeDirectory() + "/Downloads/Waifu Output/\(path)")
                    }
                    
                    finderItem.generateDirectory()
                    image.write(to: finderItem.path)
                    
                    processedItems.append(i)
                    currentTimeTaken = 0
                    
                    DispatchQueue.main.async {
                        currentProcessingItemsCount -= 1
                    }
                    
                    if processedItems.count == finderItems.count {
                        
                        background.async {
                            timer.upstream.connect().cancel()
                            
                            if !videos.isEmpty {
                                isMergingVideo = true
                                
                                for item in videos {
                                    var images: [NSImage] = []
                                    
                                    let filePath = item.relativePath ?? item.fileName!
                                    
                                    FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed").iteratedOver { child in
                                        images.append(child.image!)
                                    }
                                    
                                    let cgImage = images.first!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
                                    let videoPath = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/processed/video.mov"
                                    FinderItem.convertImageSequenceToVideo(images, videoPath: videoPath, videoSize: CGSize(width: cgImage.width, height: cgImage.height), videoFPS: Int32(item.avAsset!.tracks(withMediaType: .video).first!.nominalFrameRate)) {
                                        
                                        FinderItem.mergeVideoWithAudio(videoUrl: URL(fileURLWithPath: videoPath), audioUrl: URL(fileURLWithPath: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/audio.m4a")) { _ in
                                            
                                            let outputPath: String
                                            if filePath.contains(".") {
                                                outputPath = String(filePath[..<filePath.lastIndex(of: ".")!])
                                            } else {
                                                outputPath = filePath
                                            }
                                            
                                            try! FinderItem(at: videoPath).copy(to: "\(NSHomeDirectory())/Downloads/Waifu Output/\(outputPath).mov")
                                            
                                            videos.remove(at: videos.firstIndex(of: item)!)
                                            
                                            if videos.isEmpty {
                                                finderItems = []
                                                try! FinderItem(at: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp").removeFile()
                                                isMergingVideo = false
                                                isFinished = true
                                            }
                                            
                                        } failure: { _ in
                                            
                                        }
                                    }
                                }
                            } else {
                                isFinished = true
                            }
                        }
                        
                    }
                }
                
                background.async {
                    if !finderItems.allSatisfy({ $0.image != nil }) {
                        isCreatingImageSequence = true
                        
                        for i in finderItems {
                            guard i.avAsset != nil else { continue }
                            finderItems.remove(at: finderItems.firstIndex(of: i)!)
                            videos.append(i)
                            
                            let filePath = i.relativePath ?? i.fileName!
                            
                            let tmpPath = "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/raw"
                            FinderItem(at: tmpPath).generateDirectory()
                            
                            try! i.saveAudioTrack(to: "\(NSHomeDirectory())/Downloads/Waifu Output/tmp/\(filePath)/audio.m4a")
                            
                            var counter = 1
                            
                            for ii in i.frames! {
                                var sequence = String(counter)
                                while sequence.count <= 5 { sequence.insert("0", at: sequence.startIndex) }
                                
                                let path = tmpPath + "/" + "{\(i.fileName!)}{sequence} \(sequence).png"
                                ii.write(to: path)
                                finderItems.append(FinderItem(at: path))
                                
                                counter += 1
                            }
                        }
                        
                        currentTimeTaken = 0
                        isCreatingImageSequence = false
                    }
                    
                    if allowParallelExecution {
                        DispatchQueue.concurrentPerform(iterations: finderItems.count) { i in
                            guard !isFinished else { return }
                            execute(finderItems[i])
                        }
                    } else {
                        for i in finderItems {
                            guard !isFinished else { return }
                            execute(i)
                        }
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
