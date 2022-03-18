//
//  ContentView.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI

struct ContentView: View {
    @State var finderItems: [WorkItem] = []
    @State var isSheetShown: Bool = false
    @State var isProcessing: Bool = false
    @State var isCreatingPDF: Bool = false
    
    @State var model: ModelCoordinator = ModelCoordinator(imageModel: .caffe, frameModel: .dain_ncnn_vulkan)
    
    @State var gridNumber = Configuration.main.gridNumber
    @State var aspectRatio = Configuration.main.aspectRatio
    
    @State var isShowingLoadingView = false
    @State var isShowingCannotReadFile = false
    
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
                                        .popover(isPresented: .constant(isShowingCannotReadFile && item.finderItem.avAsset == nil && item.finderItem.image == nil)) {
                                            Text("Cannot read this file")
                                                .padding()
                                        }
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
            SpecificationsView(finderItems: finderItems, isShown: $isSheetShown, isProcessing: $isProcessing, model: $model)
        }
        .sheet(isPresented: $isProcessing, onDismiss: nil) {
            ProcessingView(isProcessing: $isProcessing, finderItems: $finderItems, model: $model, isSheetShown: $isSheetShown, isCreatingPDF: $isCreatingPDF)
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
                .disabled(!finderItems.allSatisfy({ $0.finderItem.avAsset != nil || $0.finderItem.image != nil }))
                .help("Begin processing.")
                .onHover { bool in
                    guard finderItems.allSatisfy({ $0.finderItem.avAsset != nil || $0.finderItem.image != nil }) else { return }
                    isShowingCannotReadFile = bool
                }
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
                image = (item.finderItem.image ?? item.finderItem.avAsset?.firstFrame) ?? NSImage(named: "placeholder")!
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


struct MenuView<T>: View where T: CustomStringConvertible, T: Hashable {
    
    let title: String
    
    @Binding var chosenItem: T
    let itemOptions: [T]
    
    let unit: String
    
    let lhsIndent: CGFloat = 150
    
    var body: some View {
        HStack {
            HStack {
                Spacer()
                Text(title.description)
            }
            .frame(width: lhsIndent)
            
            HStack {
                Menu {
                    ForEach(itemOptions, id: \.self) { option in
                        Button(option.description + unit) {
                            chosenItem = option
                        }
                    }
                } label: {
                    Text(chosenItem.description + unit)
                }

                Spacer()
            }
        }
    }
    
}

struct Waifu2xModelView: View {
    
    var finderItems: [WorkItem]
    @Binding var model: ModelCoordinator
    
    let styleNames: [String] = ["anime", "photo"]
    @State var chosenStyle = Configuration.main.modelStyle {
        didSet {
            findModelClass()
        }
    }
    @State var chosenScaleLevel: Int = 2 {
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
    
    @State var scaleLevels: [Int] = [1, 2, 4, 8]
    
    @State var modelClass: [String] = []
    @State var chosenModelClass: String = ""

    
    func findModelClass() {
        self.modelClass = Array(Set(Model_Caffe.allModels.filter({ ($0.style == chosenStyle) && ($0.noise == Int(chosenNoiseLevel)) && ($0.scale == ( chosenScaleLevel == 1 ? 1 : 2 )) }).map({ $0.class })))
        self.chosenModelClass = modelClass[0]
    }
    
    var body: some View {
        VStack {
            
            MenuView(title: "Style:", chosenItem: $chosenStyle, itemOptions: styleNames, unit: "")
                .help("anime: for illustrations or 2D images or CG\nphoto: for photos of real world or 3D images")
            MenuView(title: "Scale Level:", chosenItem: $chosenScaleLevel, itemOptions: scaleLevels, unit: "x")
                .help("Choose how much you want to scale.")
            MenuView(title: "Denoise Level:", chosenItem: $chosenNoiseLevel, itemOptions: noiseLevels, unit: "")
                .help("denoise level 3 recommended.\nHint: Don't know which to choose? go to Compare > Compare Denoise Levels and try by yourself!")
            
        }
        
        .onAppear {
            DispatchQueue(label: "background").async {
                findModelClass()
                
                self.scaleLevels = finderItems.allSatisfy({ $0.type == .image }) ? [1, 2, 4, 8] : [1, 2]
            }
        }
        .onChange(of: chosenStyle) { newValue in
            Configuration.main.modelStyle = newValue
        }
        .onChange(of: chosenScaleLevel) { newValue in
            if newValue == 8 {
                model.enableConcurrent = false
            } else {
                model.enableConcurrent = true
            }
            model.scaleLevel = newValue
        }
        .onChange(of: chosenModelClass) { newValue in
            model.caffe = Model_Caffe.allModels.filter({ ($0.style == chosenStyle) && ($0.noise == Int(chosenNoiseLevel)) && ($0.scale == ( chosenScaleLevel == 1 ? 1 : 2 )) }).first!
        }
    }
}


struct SpecificationsView: View {
    
    var finderItems: [WorkItem]
    
    @Binding var isShown: Bool
    @Binding var isProcessing: Bool
    
    @Binding var model: ModelCoordinator
    
    @State var frameHeight: CGFloat = 400
    @State var storageRequired: String? = nil
    
    let lhsIndent: CGFloat = 150
    let pickerOffset: CGFloat = -7
    
    
    var body: some View {
        
        VStack {
            
            HStack {
                HStack {
                    Spacer()
                    
                    Text("Image Model:")
                }
                .frame(width: lhsIndent)
                
                Picker("", selection: $model.imageModel.animation()) {
                    ForEach(ModelCoordinator.ImageModel.allCases, id: \.self) { value in
                        Text(value.rawValue)
                    }
                }
                .offset(x: pickerOffset)
            }
            .pickerStyle(.segmented)
            
            VStack {
                if model.imageModel == .caffe {
                    Waifu2xModelView(finderItems: finderItems, model: $model)
                } else if model.imageModel == .realcugan_ncnn_vulkan {
                    MenuView(title: "Model Name:", chosenItem: $model.realcugan_ncnn_vulkan.modelName, itemOptions: model.realcugan_ncnn_vulkan.modelNameOptions, unit: "")
                    MenuView(title: "Scale Level:", chosenItem: $model.realcugan_ncnn_vulkan.scaleLevel, itemOptions: model.realcugan_ncnn_vulkan.scaleLevelOptions, unit: "x")
                    MenuView(title: "Denoise Level:", chosenItem: $model.realcugan_ncnn_vulkan.denoiseLevel, itemOptions: model.realcugan_ncnn_vulkan.denoiseLevelOption, unit: "")
                } else if model.imageModel == .realesrgan_ncnn_vulkan {
                    MenuView(title: "Model Name:", chosenItem: $model.realesrgan_ncnn_vulkan.modelName, itemOptions: model.realesrgan_ncnn_vulkan.modelNameOptions, unit: "")
                    MenuView(title: "Scale Level:", chosenItem: $model.realesrgan_ncnn_vulkan.scaleLevel, itemOptions: model.realesrgan_ncnn_vulkan.scaleLevelOptions, unit: "x")
                    MenuView(title: "Denoise Level:", chosenItem: $model.realesrgan_ncnn_vulkan.denoiseLevel, itemOptions: model.realesrgan_ncnn_vulkan.denoiseLevelOption, unit: "")
                } else if model.imageModel == .realsr_ncnn_vulkan {
                    MenuView(title: "Model Name:", chosenItem: $model.realsr_ncnn_vulkan.modelName, itemOptions: model.realsr_ncnn_vulkan.modelNameOptions, unit: "")
                    MenuView(title: "Scale Level:", chosenItem: $model.realsr_ncnn_vulkan.scaleLevel, itemOptions: model.realsr_ncnn_vulkan.scaleLevelOptions, unit: "x")
                    MenuView(title: "Denoise Level:", chosenItem: $model.realsr_ncnn_vulkan.denoiseLevel, itemOptions: model.realsr_ncnn_vulkan.denoiseLevelOption, unit: "")
                }
            }
            
            
            if finderItems.contains(where: { $0.type == .video }) {
                Divider()
                    .padding(.top)
                
                HStack {
                    Toggle(isOn: $model.enableFrameInterpolation) {
                        Text("Enable video frame interpolation")
                    }
                    .padding(.leading)
                    
                    Spacer()
                }
                
                HStack {
                    HStack {
                        Spacer()
                        Text("Interpolation Model:")
                            .foregroundColor(model.enableFrameInterpolation ? .primary : .secondary)
                    }
                    .frame(width: lhsIndent)
                    
                    Picker("", selection: $model.frameModel.animation()) {
                        ForEach(ModelCoordinator.FrameModel.allCases, id: \.self) { value in
                            Text(value.rawValue)
                        }
                    }
                    .offset(x: pickerOffset)
                }
                .pickerStyle(.segmented)
                .disabled(!model.enableFrameInterpolation)
                
                if model.frameModel == .rife_dain_ncnn_vulkan {
                    MenuView(title: "Model Name:", chosenItem: $model.rife_dain_ncnn_vulkan.modelName, itemOptions: model.rife_dain_ncnn_vulkan.modelNameOptions, unit: "")
                        .disabled(!model.enableFrameInterpolation)
                        .foregroundColor(model.enableFrameInterpolation ? .primary : .secondary)
                }
                
                MenuView(title: "Frame Interpolation:", chosenItem: $model.frameInterpolation, itemOptions: [2, 4], unit: "x")
                    .help("Choose how many times more frames you want the video be.")
                    .disabled(!model.enableFrameInterpolation)
                    .foregroundColor(model.enableFrameInterpolation ? .primary : .secondary)
            }
            
            Divider()
                .padding(.top)
            
            if finderItems.contains(where: { $0.type == .video }) {
                MenuView(title: "Video segmentation:", chosenItem: $model.videoSegmentFrames, itemOptions: [100, 500, 1000, 2000, 5000], unit: " frames")
                    .help("During processing, videos will be split into smaller ones, choose how long you want each smaller video be, in frames.")
            } else {
                MenuView(title: "Enable Parallel:", chosenItem: $model.enableConcurrent, itemOptions: [true, false], unit: "")
                    .help("Enable this to reduce processing speed in return for better memory performance.")
            }
            
            
            Spacer()
            
            
            HStack {
                
                Spacer()
                
                if let storageRequired = storageRequired, !finderItems.allSatisfy({ $0.type == .image }) {
                    Text("Estimated Storage required: \(storageRequired)")
                        .foregroundColor(.secondary)
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
                    
                    
                    
                } label: {
                    Text("OK")
                        .frame(width: 80)
                }
                .help("Begin processing.")
            }
            .padding(.all)
        }
        .padding(.all)
        .frame(width: 600, height: frameHeight)
        .onChange(of: model.videoSegmentFrames) { newValue in
            DispatchQueue(label: "background").async {
                self.storageRequired = estimateSize(finderItems: finderItems.map({ $0.finderItem }), frames: model.videoSegmentFrames, scale: model.scaleLevel)
            }
        }
        .onAppear {
            DispatchQueue(label: "background").async {
                self.storageRequired = estimateSize(finderItems: finderItems.map({ $0.finderItem }), frames: model.videoSegmentFrames, scale: model.scaleLevel)
            }
            frameHeight = finderItems.contains(where: { $0.type == .video }) ? 400 : 250
        }
        
    }
    
}


struct ProcessingView: View {
    
    @Binding var isProcessing: Bool
    @Binding var finderItems: [WorkItem]
    @Binding var model: ModelCoordinator
    @Binding var isSheetShown: Bool
    @Binding var isCreatingPDF: Bool
    
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
                            .lineLimit(1)
                        
                        if let statusProgress = statusProgress, !isFinished {
                            Text("\(statusProgress.progress) / \(statusProgress.total)")
                        }
                        
                        Text(model.imageModel.rawValue)
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
                guard !isFinished else { return 1}
                
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
                    
                    finderItems.work(model: model) { status in
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
                                    finderItems.work(model: model) { status in
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
                                    finderItems.work(model: model) { status in
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
