//
//  ProcessingView.swift
//  waifuExtension
//
//  Created by Vaida on 5/4/22.
//

import SwiftUI
import Support

struct StatusObserver {
    
    var processedItemsCounter: Int = 0
    var pastTimeTaken: Double = 0 // up to 1s
    
    var isPaused: Bool = false
    
    var isFinished: Bool = false {
        didSet {
            self.progress = 1
            self.status = updateProgress(from: .finished)
        }
    }
    var progress: Double = 0
    
    var status: String = "Loading..."
    var statusProgress: (progress: Int, total: Int)? = nil
    
    var currentItems: [WorkItem] = [] {
        didSet {
            self.status = updateProgress(from: .currentItems)
        }
    }
    var coordinator: ModelCoordinator?
    
    func updateProgress(from source: ProgressProvider) -> String {
        guard let coordinator else { return "Loading." }
        
        switch source {
        case .currentItems:
            guard !currentItems.isEmpty else { return "Loading..." }
            if coordinator.enableConcurrent {
                guard currentItems.count != 1 else { break }
                var subfix: String {
                    let folder = currentItems.map({ $0.relativePath?.components(separatedBy: "/").last })
                    if folder.allEqual(), let firstElement = folder.first, let firstElement {
                        return " in " + firstElement
                    }
                    return ""
                }
                
                return "Processing \(currentItems.count) images" + subfix
            }
            let firstItem = currentItems.first!
            return "Processing \(firstItem.fileName)"
        case .finished:
            return "Finished"
        }
        
        return "Loading.."
    }
    
    enum ProgressProvider {
        case currentItems
        case finished
    }
}

struct ProcessingView: View {
    
    //TODO: - FIX HERE.
    private let progressManager: ProgressManager = .init()
    private let background: DispatchQueue = DispatchQueue(label: "background", qos: .utility)
    
    @State private var timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    @State private var isShowingQuitConfirmation = false
    @State private var task = ShellManagers()
    @State private var status = StatusObserver()
    
    @Binding var isProcessing: Bool
    @Binding var isSheetShown: Bool
    
    @ObservedObject var images: MainModel
    
    @EnvironmentObject private var model: ModelCoordinator
    
    @AppStorage("defaultOutputPath") var outputPath: FinderItem = .downloadsDirectory.with(subPath: "waifu Output")
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 10) {
                
                DoubleView(label: "Status:", text: status.status)
                    .lineLimit(1)
                
                if let statusProgress = status.statusProgress, !status.isFinished {
                    DoubleView(label: "Progress:", text: "\(statusProgress.progress) / \(statusProgress.total)")
                }
                
                DoubleView(label: "ML Model:", text: model.imageModel.rawValue)
                    .padding(.bottom)
                
                DoubleView(label: "Processed:") {
                    if status.processedItemsCounter >= 2 {
                        Text("\(status.processedItemsCounter) items")
                    } else {
                        Text("\(status.processedItemsCounter) item")
                    }
                }
                
                DoubleView(label: "To be processed:") {
                    if status.isFinished {
                        Text("0 item")
                    } else if images.items.count - status.processedItemsCounter >= 2 {
                        Text("\(images.items.count - status.processedItemsCounter) items")
                    } else {
                        Text("\(images.items.count - status.processedItemsCounter) item")
                    }
                }
                
                DoubleView(label: "Time Spent:", text: (status.pastTimeTaken).expressedAsTime())
                
                DoubleView(label: "Time Remaining:") {
                    Text {
                        guard !status.isFinished else { return "finished" }
                        guard !status.isPaused else { return "paused" }
                        guard status.progress != 0 else { return "calculating..." }
                        
                        var value = status.pastTimeTaken / status.progress
                        value -= status.pastTimeTaken
                        
                        guard value > 0 else { return "calculating..." }
                        
                        return value.expressedAsTime()
                    }
                }
                
                DoubleView(label: "ETA:") {
                    Text {
                        guard !status.isFinished else { return "finished" }
                        guard !status.isPaused else { return "paused" }
                        guard status.progress != 0 else { return "calculating..." }
                        
                        var value = (status.pastTimeTaken) / status.progress
                        value -= status.pastTimeTaken
                        
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
                    }
                }
            }
            
            Spacer()
            
            ProgressView(value: {()->Double in
                guard !images.items.isEmpty else { return 1 }
                guard !status.isFinished else { return 1 }
                
                return status.progress <= 1 ? status.progress : 1
            }(), total: 1.0)
            .help("\(String(format: "%.2f", status.progress * 100))%")
            .padding([.bottom])
            
            Spacer()
            
            HStack {
                Spacer()
                
                if !status.isFinished {
                    Button() {
                        isShowingQuitConfirmation = true
                    } label: {
                        Text("Cancel")
                            .frame(width: 80)
                    }
                    .padding(.trailing)
                    .help("Cancel and quit.")
                    
                    Button() {
                        if !status.isPaused {
                            task.pause()
                        } else {
                            task.resume()
                        }
                        
                        status.isPaused.toggle()
                    } label: {
                        Text(status.isPaused ? "Resume" : "Pause")
                            .frame(width: 80)
                    }
                    .disabled(true)
                } else {
                    Button("Show in Finder") {
                        outputPath.open()
                    }
                    .padding(.trailing)
                    
                    Button() {
                        images.items = []
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
        .task {
            
            progressManager.status = { status in
                Task { @MainActor in
                    self.status.status = status
                }
            }
            
            progressManager.onStatusProgressChanged = { progress,total in
                Task { @MainActor in
                    if let progress, let total, total > 1 {
                        self.status.statusProgress = (progress, total)
                    } else {
                        self.status.statusProgress = nil
                    }
                }
            }
            
            progressManager.onProgressChanged = { progress in
                Task { @MainActor in
                    self.status.progress = progress
                }
            }
            
            progressManager.addCurrentItems = { item in
                Task { @MainActor in
                    self.status.currentItems.append(item)
                }
            }
            
            progressManager.removeFromCurrentItems = { item in
                Task { @MainActor in
                    self.status.currentItems.removeAll { $0 == item }
                    self.status.processedItemsCounter += 1
                }
            }
            
            Task.detached {
                await images.work(model: model, task: task, manager: progressManager, outputPath: outputPath)
                Task { @MainActor in
                    status.isFinished = true
                }
            }
            
        }
        .onReceive(timer) { timer in
            status.pastTimeTaken += 1
        }
        .onChange(of: status.isPaused) { newValue in
            if newValue {
                timer.upstream.connect().cancel()
                background.suspend()
            } else {
                timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
                background.resume()
            }
        }
        .onChange(of: status.isFinished) { newValue in
            if newValue {
                timer.upstream.connect().cancel()
            }
        }
        .confirmationDialog("Quit the app?", isPresented: $isShowingQuitConfirmation) {
            Button("Quit", role: .destructive) {
                task.terminateIfPosible()
                exit(0)
            }
            
            Button("Cancel", role: .cancel) {
                isShowingQuitConfirmation = false
            }
        }
        .onAppear {
            self.status.coordinator = model
        }
    }
}

