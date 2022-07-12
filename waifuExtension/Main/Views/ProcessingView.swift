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
    
    var isFinished: Bool = false {
        didSet {
            self.progress = 1
            self.status = updateProgress()
        }
    }
    var progress: Double = 0
    
    var status: LocalizedStringKey = "Loading..."
    var statusProgress: (progress: Int, total: Int)? = nil
    
    var currentItems: [WorkItem] = [] {
        didSet {
            self.status = updateProgress()
        }
    }
    var coordinator: ModelCoordinator?
    
    private func updateProgress() -> LocalizedStringKey {
        guard let coordinator else { return "Loading.." }
        
        if !self.isFinished {
            guard !currentItems.isEmpty else { return "Loading..." }
            if coordinator.enableConcurrent && currentItems.count != 1 {
                var subfix: String {
                    let folder = currentItems.map({ $0.relativePath?.components(separatedBy: "/").last })
                    if folder.allEqual(), let firstElement = folder.first, let firstElement {
                        return "Processing \(currentItems.count) images in \(firstElement)"
                    }
                    return "Processing \(currentItems.count) images"
                }
            }
            let firstItem = currentItems.first!
            return "Processing \(firstItem.fileName)"
        } else {
            return "Finished"
        }
    }
}

struct ProcessingView: View {
    
    private let background: DispatchQueue = DispatchQueue(label: "background", qos: .utility)
    
    @State private var timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    @State private var isShowingQuitConfirmation = false
    @State private var task = ShellManagers()
    @State private var status = StatusObserver()
    
    @State private var isShowingTimeRemaining = true
    
    @ObservedObject var images: MainModel
    
    @StateObject private var progressManager = ProgressManager()
    
    @EnvironmentObject private var model: ModelCoordinator
    @Environment(\.locale) private var local
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("defaultOutputPath") var outputPath: FinderItem = .downloadsDirectory.with(subPath: "waifu Output")
    
    
    private var pendingCount: Int {
        images.items.count - status.processedItemsCounter - status.currentItems.count
    }
    
    var body: some View {
        VStack {
            
            VStack(spacing: 10) {
                Spacer()
                
                DoubleView("Status:", text: status.status)
                    .lineLimit(1)
                
                if let statusProgress = status.statusProgress, !status.isFinished {
                    DoubleView("Progress:", text: "\(statusProgress.progress) / \(statusProgress.total)")
                }
                
                DoubleView("Processed:") {
                    if status.processedItemsCounter >= 2 {
                        if pendingCount >= 2 {
                            Text("\(status.processedItemsCounter.description) items, \(pendingCount.description) items pending")
                        } else if pendingCount == 1 {
                            Text("\(status.processedItemsCounter.description) items, \(pendingCount.description) item pending")
                        } else {
                            Text("\(status.processedItemsCounter.description) items")
                        }
                    } else {
                        if pendingCount >= 2 {
                            Text("\(status.processedItemsCounter.description) item, \(pendingCount.description) items pending")
                        } else if pendingCount == 1 {
                            Text("\(status.processedItemsCounter.description) item, \(pendingCount.description) item pending")
                        } else {
                            Text("\(status.processedItemsCounter.description) item")
                        }
                    }
                    Spacer()
                }
                .padding(.bottom)
                
                DoubleView("Time Spent:", text: .init(status.pastTimeTaken.expressedAsTime()))
                
                Group {
                    if isShowingTimeRemaining {
                        DoubleView("Time Remaining:") {
                            Text {
                                guard !status.isFinished else { return "Finished" }
                                guard status.progress != 0 else { return "Calculating..." }
                                
                                var value = status.pastTimeTaken / status.progress
                                value -= status.pastTimeTaken
                                
                                guard value > 0 else { return "Calculating..." }
                                
                                return .init(value.expressedAsTime())
                            }
                            Spacer()
                        }
                    } else {
                        DoubleView("ETA:") {
                            Text {
                                guard !status.isFinished else { return "Finished" }
                                guard status.progress != 0 else { return "Calculating..." }
                                
                                var value = (status.pastTimeTaken) / status.progress
                                value -= status.pastTimeTaken
                                
                                guard value > 0 else { return "Calculating..." }
                                
                                let date = Date().addingTimeInterval(value)
                                
                                let formatter = DateFormatter()
                                if value < 10 * 60 * 60 {
                                    formatter.dateStyle = .none
                                } else {
                                    formatter.dateStyle = .medium
                                }
                                formatter.timeStyle = .medium
                                formatter.locale = self.local
                                
                                return .init(formatter.string(from: date))
                            }
                            Spacer()
                        }
                    }
                }
                .onTapGesture {
                    isShowingTimeRemaining.toggle()
                }
                
                Spacer()
            }
            
            ProgressView(value: {()->Double in
                guard !images.items.isEmpty else { return 1 }
                guard !status.isFinished else { return 1 }
                
                return status.progress <= 1 ? status.progress : 1
            }(), total: 1.0)
            .help("\(String(format: "%.2f", status.progress * 100))%")
            .padding(.bottom)
            
            Spacer()
            
            HStack {
                if !status.isFinished {
                    Button() {
                        isShowingQuitConfirmation = true
                    } label: {
                        Text("Cancel")
                            .frame(width: 80)
                    }
                    .padding(.trailing)
                }
                
                Spacer()
                
                if status.isFinished {
                    Button("Show in Finder") {
                        outputPath.open()
                    }
                    .padding(.trailing)
                    
                    Button() {
                        images.items = []
                        dismiss()
                    } label: {
                        Text("Done")
                            .frame(width: 80)
                    }
                }
            }
        }
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
