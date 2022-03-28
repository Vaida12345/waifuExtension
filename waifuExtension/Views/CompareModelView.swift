//
//  CompareModelView.swift
//  waifuExtension
//
//  Created by Vaida on 3/18/22.
//

import Foundation
import SwiftUI

struct CompareModelView: View {
    
    @State var coordinators: [ModelCoordinator] = []
    @State var item: FinderItem? = nil
    
    @State var isShowingImportingDialog = false
    @State var next = ModelCoordinator(imageModel: .caffe, frameModel: .dain_ncnn_vulkan)
    
    var body: some View {
        VStack {
            GroupBox(content: {
                HStack {
                    if item != nil && item?.image != nil {
                        CompareModelImageView(item: item!, model: nil, label: "Original")
                    } else {
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
                    }
                    Spacer()
                }
            }, label: {
                Text("original")
                    .font(.title)
            })
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                Task {
                    var finderItems: [FinderItem] = []
                    await finderItems.append(from: providers, condition: { item in
                        item.image != nil
                    })
                    self.item = finderItems.first
                }
                return true
            }
            .padding()
            .frame(height: 300)
            
            if let item = item {
                GroupBox {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: Int(4))) {
                            ForEach(coordinators) { coordinator in
                                CompareModelImageView(item: item, model: coordinator)
//                                    .frame(height: 300)
                            }
                            
                            CompareModelImageView(item: item, model: nil, label: "New")
//                                .frame(height: 300)
                                .onTapGesture {
                                    isShowingImportingDialog = true
                                }
                        }
                        .padding()
                        
                    }
                } label: {
                    Text("Processed")
                        .font(.title)
                }
                .padding()
            }
        }
        .sheet(isPresented: $isShowingImportingDialog) {
            SpecificationsView(finderItems: [WorkItem(at: item!, type: .image)], isShown: $isShowingImportingDialog, isProcessing: .constant(false), model: $next)
                .onDisappear {
                    coordinators.append(next)
                    next = ModelCoordinator(imageModel: .caffe, frameModel: .dain_ncnn_vulkan)
                }
        }
    }
}

struct CompareModelImageView: View {
    
    let item: FinderItem
    let model: ModelCoordinator?
    @State var label: String? = nil
    
    @State var image: NSImage? = nil
    @State var timeTaken: Double? = nil
    var outputItem: FinderItem? {
        guard let model = model else {
            return nil
        }

        return FinderItem(at: "\(NSHomeDirectory())/tmp/\(model.imageModel.rawValue)-\(model.id).png")
    }
    
    @State var task = ShellManager()
    
    var body: some View {
        VStack(alignment: .center) {
            if label != "New" {
                Image(nsImage: image ?? item.image!)
                    .resizable()
                    .renderingMode(image == nil ? .template : .original )
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(5)
                    .help("Double click to show detail")
            } else {
                VStack {
                    Image(nsImage: item.image!)
                        .resizable()
                        .renderingMode(image == nil ? .template : .original )
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(5)
                }
                .blur(radius: 10)
                .foregroundColor(.secondary)
                .overlay(alignment: .center) {
                    Image(systemName: "plus")
                }
                .help("Click to run in a new model")
            }
            
            if let label = label {
                Text(label)
                Text("")
                Text("")
            } else if let model = model {
                Text(model.imageModel.rawValue)
                Text({()->String in
                    switch model.imageModel {
                    case .caffe:
                        return "scale level: \(model.scaleLevel), denoise level: \(model.caffe.noise ?? 0)"
                    case .realcugan_ncnn_vulkan:
                        return "scale level: \(model.realcugan_ncnn_vulkan.scaleLevel), denoise level: \(model.realcugan_ncnn_vulkan.denoiseLevel), tta: \(model.realcugan_ncnn_vulkan.enableTTA)"
                    case .realesrgan_ncnn_vulkan:
                        return "scale level: \(model.realesrgan_ncnn_vulkan.scaleLevel), denoise level: \(model.realesrgan_ncnn_vulkan.denoiseLevel), tta: \(model.realesrgan_ncnn_vulkan.enableTTA)"
                    case .realsr_ncnn_vulkan:
                        return "scale level: \(model.realsr_ncnn_vulkan.scaleLevel), denoise level: \(model.realsr_ncnn_vulkan.denoiseLevel), tta: \(model.realsr_ncnn_vulkan.enableTTA)"
                    }
                }())
                .foregroundColor(.secondary)
                if let timeTaken = timeTaken {
                    Text("Time: \(timeTaken.expressedAsTime())")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .onTapGesture(count: 2, perform: {
            if label == "Original" {
                item.open()
            } else {
                outputItem?.open()
            }
        })
        .onAppear {
            if model != nil {
                outputItem!.generateDirectory(isFolder: false)
                runImageModel(inputItem: item, outputItem: outputItem!)
            } else {
                image = item.image!
            }
        }
    }
    
    func runImageModel(inputItem: FinderItem, outputItem: FinderItem) {
        guard let model = model else {
            return
        }
        DispatchQueue(label: "CompareModel").async {
            let date = Date()
            var output: NSImage? = nil
            if model.isCaffe {
                guard let image = inputItem.image else { return }
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
            } else {
                model.runImageModel(input: inputItem, outputItem: outputItem, task: task)
                task.wait()
            }
            
            if let image = outputItem.image {
                self.image = image
            } else if let image = output {
                self.image = image
            }
            self.timeTaken = date.distance(to: Date())
        }
    }
}
