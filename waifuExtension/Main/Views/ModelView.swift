//
//  ModelView.swift
//  waifuExtension
//
//  Created by Vaida on 5/4/22.
//

import SwiftUI
import Support


struct Waifu2xModelView: View {
    
    let containVideo: Bool
    
    private let styleNames: [String] = ["anime", "photo"]
    private let noiseLevels: [String] = ["none", "0", "1", "2", "3"]
    
    @State private var chosenScaleLevel: Int = 2
    @State private var chosenNoiseLevel = "3"
    
    @State private var scaleLevels: [Int] = [1, 2, 4, 8]
    
    @State private var modelClass: [String] = []
    @State private var chosenModelClass: String = ""
    
    @EnvironmentObject private var dataProvider: ModelDataProvider
    @EnvironmentObject private var model: ModelCoordinator
    
    @AppStorage("Waifu2x Model Style") private var modelStyle = "anime"
    
    func findModelClass() {
        self.modelClass = Model_Caffe.allModels.filter{ ($0.style == modelStyle ) && ($0.noise == Int(chosenNoiseLevel)) && ($0.scale == ( chosenScaleLevel == 1 ? 1 : 2 )) }.map(\.class).removingRepeatedElements()
        self.chosenModelClass = modelClass[0]
    }
    
    var body: some View {
        VStack {
            
            DoubleView(label: "Style:", menu: styleNames, selection: $modelStyle)
                .help("anime: for illustrations or 2D images or CG\nphoto: for photos of real world or 3D images")
            DoubleView(label: "Scale Level", menu: scaleLevels, selection: $chosenScaleLevel)
                .help("Choose how much you want to scale.")
            DoubleView(label: "Denoise Level:", menu: noiseLevels, selection: $chosenNoiseLevel)
                .help("denoise level 3 recommended.\nHint: Don't know which to choose? go to Compare > Compare Denoise Levels and try by yourself!")
            
        }

        .onAppear {
            DispatchQueue(label: "background").async {
                findModelClass()
                
                self.scaleLevels = !containVideo ? [1, 2, 4, 8] : [1, 2]
            }
        }
        .onChange(of: chosenNoiseLevel) { _ in
            findModelClass()
        }
        .onChange(of: chosenScaleLevel) { newValue in
            findModelClass()
            if newValue == 8 {
                model.enableConcurrent = false
            } else {
                model.enableConcurrent = true
            }
            model.scaleLevel = newValue
        }
        .onChange(of: chosenModelClass) { newValue in
            model.caffe = Model_Caffe.allModels.filter({ ($0.style == modelStyle) && ($0.noise == Int(chosenNoiseLevel)) && ($0.scale == ( chosenScaleLevel == 1 ? 1 : 2 )) }).first!
        }
        .onChange(of: dataProvider) { _ in
            findModelClass()
        }
    }
}


struct SpecificationsView: View {
    
    private let pickerOffset: CGFloat = -7
    let containVideo: Bool
    
    @Binding var isShown: Bool
    @Binding var isProcessing: Bool
    
    @ObservedObject var images: MainModel
    
    @EnvironmentObject private var dataProvider: ModelDataProvider
    @EnvironmentObject private var model: ModelCoordinator
    
    var modelIsInstalled: Bool {
        if let model = model.chosenImageModel {
            return !model.programItem.isExistence
        } else {
            return false
        }
    }
    
    var body: some View {
        
        VStack {
            
            DoubleView(label: "Image Model:") {
                Picker("", selection: $model.imageModel.animation()) {
                    ForEach(_ModelCoordinator.ImageModel.allCases, id: \.self) { value in
                        Text(value.rawValue)
                    }
                }
                .offset(x: pickerOffset)
                .pickerStyle(.segmented)
            }
            
            VStack {
                if model.imageModel == .caffe {
                    Waifu2xModelView(containVideo: containVideo)
                } else if model.imageModel == .realcugan {
                    DoubleView(label: "Model Name:", menu: model.realcugan.modelNameOptions, selection: $model.realcugan.modelName)
                    DoubleView(label: "Scale Level:", menu: model.realcugan.scaleLevelOptions, selection: $model.realcugan.scaleLevel)
                    DoubleView(label: "Denoise Level:", menu: model.realcugan.denoiseLevelOption, selection: $model.realcugan.denoiseLevel)
                    DoubleView(label: "Enable TTA:", menu: [true, false], selection: $model.realcugan.enableTTA)
                } else if model.imageModel == .realesrgan {
                    DoubleView(label: "Model Name:", menu: model.realesrgan.modelNameOptions, selection: $model.realesrgan.modelName)
                    DoubleView(label: "Scale Level:", menu: model.realesrgan.scaleLevelOptions, selection: $model.realesrgan.scaleLevel)
                    DoubleView(label: "Denoise Level:", menu: model.realesrgan.denoiseLevelOption, selection: $model.realesrgan.denoiseLevel)
                    DoubleView(label: "Enable TTA:", menu: [true, false], selection: $model.realesrgan.enableTTA)
                } else if model.imageModel == .realsr {
                    DoubleView(label: "Model Name:", menu: model.realsr.modelNameOptions, selection: $model.realsr.modelName)
                    DoubleView(label: "Scale Level:", menu: model.realsr.scaleLevelOptions, selection: $model.realsr.scaleLevel)
                    DoubleView(label: "Denoise Level:", menu: model.realsr.denoiseLevelOption, selection: $model.realsr.denoiseLevel)
                    DoubleView(label: "Enable TTA:", menu: [true, false], selection: $model.realsr.enableTTA)
                }
            }
            .disabled(modelIsInstalled)
            
            if self.containVideo {
                Divider()
                    .padding(.top)

                HStack {
                    Toggle(isOn: $model.enableFrameInterpolation) {
                        Text("Enable video frame interpolation")
                    }
                    .padding(.leading)

                    Spacer()
                }

                DoubleView(label: "Interpolation Model:") {
                    Picker("", selection: $model.frameModel.animation()) {
                        ForEach(_ModelCoordinator.FrameModel.allCases, id: \.self) { value in
                            Text(value.rawValue)
                        }
                    }
                    .offset(x: pickerOffset)
                    .pickerStyle(.segmented)
                }
                .disabled(!model.enableFrameInterpolation)

                if model.frameModel == .rife {
                    VStack {
                        DoubleView(label: "Model Name:", menu: model.rife.modelNameOptions, selection: $model.rife.modelName)
                        DoubleView(label: "Enable TTA", menu: [true, false], selection: $model.rife.enableTTA)
                        DoubleView(label: "Enable UHD", menu: [true, false], selection: $model.rife.enableUHD)
                    }
                    .disabled(!model.enableFrameInterpolation)
                    .foregroundColor(model.enableFrameInterpolation ? .primary : .secondary)
                }

                DoubleView(label: "Frame Interpolation:", menu: [2, 4], selection: $model.frameInterpolation)
                    .help("Choose how many times more frames you want the video be.")
                    .disabled(!model.enableFrameInterpolation)
                    .foregroundColor(model.enableFrameInterpolation ? .primary : .secondary)
            }

            Divider()
                .padding(.top)

            if self.containVideo {
                DoubleView(label: "Video segmentation:", menu: [100, 500, 1000, 2000, 5000], selection: $model.videoSegmentFrames)
                    .help("During processing, videos will be split into smaller ones, choose how long you want each smaller video be, in frames.")
            } else {
                DoubleView(label: "Enable Parallel:", menu: [true, false], selection: $model.enableConcurrent)
                    .help("Enable this to reduce processing speed in return for better memory performance.")
            }

            Spacer()

            HStack {

                Spacer()

                if model.imageModel == .caffe && model.scaleLevel == 2 && !model.enableFrameInterpolation && self.containVideo {
                    Toggle(isOn: $model.enableMemoryOnly) {
                        Text("Memory Only")
                            .help("Use this option only if you are certain it is safe to keep all the intermediate images in the memory.")
                    }
                }

                Button {
                    isShown = false
                } label: {
                    Text("Cancel")
                        .frame(width: 80)
                }
                .padding(.trailing)
                .keyboardShortcut(.cancelAction)
                .help("Return to previous page.")

                Button {
                    isProcessing = true
                    isShown = false
                } label: {
                    Text("OK")
                        .frame(width: 80)
                }
                .keyboardShortcut(.defaultAction)
                .help("Begin processing.")
                .disabled(modelIsInstalled)
            }
            .padding([.horizontal, .top])
        }
        .padding(.all)
        .onChange(of: model.enableFrameInterpolation) { newValue in
            if newValue {
                model.frameInterpolation = 2
            } else {
                model.frameInterpolation = 1
            }
        }
        
    }
    
}
