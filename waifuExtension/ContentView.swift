//
//  ContentView.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI
import CoreML

struct ContentView: View {
    @State var finderItems: [FinderItem] = []
    @State var isSheetShown: Bool = false
    @State var isProcessing: Bool = false
    @State var isCreatingPDF: Bool = false
    @State var modelUsed: Model? = nil
    @State var background = DispatchQueue(label: "Background")
    @State var pdfbackground = DispatchQueue(label: "PDF Background")
    @State var chosenScaleLevel: Int = 2
    
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
                                guard item.image != nil else { return }
                                finderItems.append(item)
                            } else {
                                item.iteratedOver { child in
                                    guard !finderItems.contains(child) else { return }
                                    guard child.image != nil else { return }
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
                                guard error == nil else { return }
                                guard let urlData = urlData as? Data else { return }
                                guard let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                                
                                let item = FinderItem(at: url)
                                guard !finderItems.contains(item) else { return }
                                
                                if item.isFile {
                                    guard item.image != nil else { return }
                                    finderItems.append(item)
                                } else {
                                    item.iteratedOver { child in
                                        guard !finderItems.contains(child) else { return }
                                        guard child.image != nil else { return }
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
            ConfigurationView(finderItems: finderItems, isShown: $isSheetShown, isProcessing: $isProcessing, modelUsed: $modelUsed, chosenScaleLevel: $chosenScaleLevel)
        }
        .sheet(isPresented: $isProcessing, onDismiss: nil) {
            ProcessingView(isProcessing: $isProcessing, finderItems: $finderItems, modelUsed: $modelUsed, isSheetShown: $isSheetShown, background: $background, chosenScaleLevel: $chosenScaleLevel, isCreatingPDF: $isCreatingPDF)
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
            Text("Drag files or folder \n or \n click to add files.")
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
                        guard item.image != nil else { return }
                        finderItems.append(item)
                    } else {
                        item.iteratedOver { child in
                            guard child.image != nil else { return }
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
                        guard item.image != nil else { return }
                        finderItems.append(item)
                    } else {
                        item.iteratedOver { child in
                            guard child.image != nil else { return }
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
        let image = item.image!
        
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
    }
}

struct ConfigurationView: View {
    
    var finderItems: [FinderItem]
    
    @Binding var isShown: Bool
    @Binding var isProcessing: Bool
    @Binding var modelUsed: Model?
    @Binding var chosenScaleLevel: Int
    
    //TODO: edit models
    
    let styleNames: [String] = ["anime", "photo"]
    @State var chosenStyle = "anime"
    
    let noiceLevels: [String] = ["none", "0", "1", "2", "3"]
    @State var chosenNoiceLevel = "3"
    
    let scaleLevels: [Int] = [Int](0...5).map({ pow(2, $0) })
    
    var body: some View {
        VStack {
            
            Spacer()
            
            HStack(spacing: 10) {
                VStack(spacing: 19) {
                    Text("         Style:")
                        .padding(.bottom)
                    Text("Noice Level:")
                    Text("Scale Level:")
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
                    
                    Menu(chosenNoiceLevel.description) {
                        ForEach(noiceLevels, id: \.self) { item in
                            Button(item.description) {
                                chosenNoiceLevel = item
                            }
                        }
                    }
                    
                    Menu(chosenScaleLevel.description) {
                        ForEach(scaleLevels, id: \.self) { item in
                            Button(item.description) {
                                chosenScaleLevel = item
                            }
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
                    
                    //change here
                    let modelName = (chosenScaleLevel == 1 ? "" : "up_") + "\(chosenStyle)_noise\(chosenNoiceLevel)\(chosenScaleLevel == 1 ? "" : "_scale2x")_model"
                    
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
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(spacing: 10) {
                    HStack {
                        Spacer()
                        Text("Processing:")
                    }
                    
                    HStack {
                        Spacer()
                        Text("Time Spent:")
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
                        if currentProcessingItemsCount >= 2 {
                            Text("\(currentProcessingItemsCount) items in parallel")
                        } else {
                            Text("\(currentProcessingItemsCount) item")
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(currentTimeTaken.expressedAsTime())
                        
                        Spacer()
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
                        if finderItems.count - processedItems.count >= 2 {
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
                            guard !processedItems.isEmpty else { return "calculating..." }
                            
                            var value = Double(finderItems.count) * (pastTimeTaken / Double(processedItems.count))
                            value -= pastTimeTaken
                            
                            guard value >= 0 else { return "calculating..." }
                            
                            return value.expressedAsTime()
                        }())
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text({ ()-> String in
                            guard !isFinished else { return "finished" }
                            guard !isPaused else { return "paused" }
                            guard !processedItems.isEmpty else { return "calculating..." }
                            
                            var value = Double(finderItems.count) * (pastTimeTaken / Double(processedItems.count))
                            value -= pastTimeTaken
                            
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
                guard !finderItems.isEmpty else { return 1 }
                return Double(processedItems.count) / Double(finderItems.count)
            }())
                .padding([.bottom])
            
            Spacer()
            
            HStack {
                Spacer()
                
                if !isFinished {
                    Button("Cancel") {
                        isPaused = true
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
                        _ = shell(["open /Users/vaida/Downloads/Waifu\\ Output"])
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
                background = DispatchQueue(label: "Background")
                
                background.async {
                    DispatchQueue.concurrentPerform(iterations: finderItems.count) { i in
                        let i = finderItems[i]
                        
                        DispatchQueue.main.async {
                            currentProcessingItemsCount += 1
                        }
                        
                        guard var image = i.image else { return }
                        
                        if chosenScaleLevel > 2 {
                            for _ in 1...(chosenScaleLevel / 2) {
                                image = Waifu2x().run(image, model: modelUsed!)!.reload()
                            }
                        } else {
                            image = Waifu2x().run(image, model: modelUsed!)!
                        }
                        
                        let finderItem = FinderItem(at: "/Users/vaida/Downloads/Waifu Output/\(i.relativePath ?? i.fileName! + ".png")")
                        finderItem.generateDirectory()
                        image.write(to: "/Users/vaida/Downloads/Waifu Output/\(i.relativePath ?? i.fileName! + ".png")")
                        
                        processedItems.append(i)
                        currentTimeTaken = 0
                        
                        DispatchQueue.main.async {
                            currentProcessingItemsCount -= 1
                        }
                        
                        if processedItems.count == finderItems.count {
                            background.suspend()
                            isPaused = true
                            isFinished = true
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
                    _ = shell(["open /Users/vaida/Downloads/PDF\\ output"])
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
            FinderItem(at: "/Users/vaida/Downloads/Waifu Output").iteratedOver { child in
                guard child.image != nil else { return }
                counter += 1
            }
            
            finderItemsCount = counter
            
            background.async {
                FinderItem(at: "/Users/vaida/Downloads/Waifu Output").iteratedOver { child in
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
