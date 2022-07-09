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
    
    @State private var chosenNoiseLevel = "3"
    
    @State private var scaleLevels: [Int] = [1, 2, 4, 8]
    
    @State private var modelClass: [String] = []
    @State private var chosenModelClass: String = ""
    
    @EnvironmentObject private var dataProvider: ModelDataProvider
    @EnvironmentObject private var model: ModelCoordinator
    
    @AppStorage("Waifu2x Model Style") private var modelStyle = "anime"
    
    func findModelClass() {
        self.modelClass = Model_Caffe.allModels.filter{ ($0.style == modelStyle ) && ($0.noise == Int(chosenNoiseLevel)) && ($0.scale == ( model.scaleLevel == 1 ? 1 : 2 )) }.map(\.class).removingRepeatedElements()
        guard let value = modelClass.first else {
            modelStyle = "anime"
            return
        }
        self.chosenModelClass = value
    }
    
    var body: some View {
        VStack {
            DoubleView(label: "Style:", menu: styleNames, selection: $modelStyle)
                .help("anime: for illustrations or 2D images or CG\nphoto: for photos of real world or 3D images")
            DoubleView(label: "Scale Level", menu: scaleLevels, selection: $model.scaleLevel)
                .help("Choose how much you want to scale.")
            DoubleView(label: "Denoise Level:", menu: noiseLevels, selection: $chosenNoiseLevel)
                .help("denoise level 3 recommended.")
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
        .onChange(of: model.scaleLevel) { newValue in
            findModelClass()
            if newValue == 8 {
                model.enableConcurrent = false
            } else {
                model.enableConcurrent = true
            }
            model.scaleLevel = newValue
        }
        .onChange(of: chosenModelClass) { newValue in
            model.caffe = Model_Caffe.allModels.filter({ ($0.style == modelStyle) && ($0.noise == Int(chosenNoiseLevel)) && ($0.scale == ( model.scaleLevel == 1 ? 1 : 2 )) }).first!
        }
        .onChange(of: dataProvider) { _ in
            findModelClass()
        }
    }
}


struct SpecificationsView: View {
    
    let containVideo: Bool
    @Binding var isProcessing: Bool
    
    @ObservedObject var images: MainModel
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataProvider: ModelDataProvider
    @EnvironmentObject private var model: ModelCoordinator
    
    private var imageModelNotInstalled: Bool {
        if let model = model.chosenImageModel {
            return !model.programItem.isExistence
        } else {
            return false
        }
    }
    private var frameModelNotInstalled: Bool {
        if let model = model.chosenFrameModel {
            return !model.programItem.isExistence
        } else {
            return false
        }
    }
    private var anyFrameModelNotInstalled: Bool {
        ModelCoordinator.allInstalledFrameModels.allSatisfy { !$0.programItem.isExistence }
    }
    
    var body: some View {
        
        VStack {
            VStack {
                DoubleView(label: "Image Model:") {
                    Picker("", selection: $model.imageModel) {
                        ForEach(_ModelCoordinator.ImageModel.allCases, id: \.self) { value in
                            Text(value.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.bottom, 10)
                
                VStack {
                    if model.imageModel == .caffe {
                        Waifu2xModelView(containVideo: containVideo)
                    } else if model.imageModel == .realcugan {
                        DoubleView(label: "Model Name:", menu: model.realcugan.modelNameOptions, selection: $model.realcugan.modelName)
                        DoubleView(label: "Scale Level:", menu: model.realcugan.scaleLevelOptions, selection: $model.realcugan.scaleLevel)
                        DoubleView(label: "Denoise Level:", menu: model.realcugan.denoiseLevelOption, selection: $model.realcugan.denoiseLevel)
                        DoubleView(label: "Enable TTA:", menu: [true, false], selection: $model.realcugan.enableTTA)
                            .help("In TTA mode, it takes 8 times of time to improve the image quality that is difficult to be detected by naked eye.")
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
                .disabled(imageModelNotInstalled)
                
                if self.containVideo {
                    Divider()
                        .padding(.top)
                    
                    HStack {
                        DoubleView {
                            Toggle(isOn: $model.enableFrameInterpolation) { }
                        } rhs: {
                            Text("Enable video frame interpolation")
                                .onTapGesture {
                                    model.enableFrameInterpolation.toggle()
                                }
                        }
                        
                        Spacer()
                    }
                    .disabled(anyFrameModelNotInstalled)
                    .foregroundColor(anyFrameModelNotInstalled ? .secondary : .primary)
                    .help {
                        if anyFrameModelNotInstalled {
                            return "Please install models in Preferences"
                        } else {
                            return "Enable video frame interpolation"
                        }
                    }
                    
                    if model.enableFrameInterpolation {
                        DoubleView(label: "Interpolation Model:") {
                            Picker("", selection: $model.frameModel) {
                                ForEach(_ModelCoordinator.FrameModel.allCases, id: \.self) { value in
                                    Text(value.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Group {
                            DoubleView(label: "Frame Interpolation:", menu: [2, 4], selection: $model.frameInterpolation)
                                .help("Choose how many times more frames you want the video be.")
                            
                            if model.frameModel == .rife {
                                VStack {
                                    DoubleView(label: "Model Name:", menu: model.rife.modelNameOptions, selection: $model.rife.modelName)
                                    DoubleView(label: "Enable TTA:", menu: [true, false], selection: $model.rife.enableTTA)
                                        .help("In TTA mode, it takes 8 times of time to improve the image quality that is difficult to be detected by naked eye.")
                                    DoubleView(label: "Enable UHD:", menu: [true, false], selection: $model.rife.enableUHD)
                                }
                            }
                        }
                        .disabled(frameModelNotInstalled)
                        .foregroundColor(frameModelNotInstalled ? .secondary : .primary)
                        .help {
                            if frameModelNotInstalled {
                                return "Please install models in Preferences"
                            } else {
                                return ""
                            }
                        }
                    }
                }
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
                    dismiss()
                } label: {
                    Text("Cancel")
                        .frame(width: 80)
                }
                .padding(.trailing)
                .keyboardShortcut(.cancelAction)
                .help("Return to previous page.")

                Button {
                    isProcessing = true
                    dismiss()
                } label: {
                    Text("Done")
                        .frame(width: 80)
                }
                .keyboardShortcut(.defaultAction)
                .help("Begin processing.")
                .disabled(imageModelNotInstalled || (model.enableFrameInterpolation && frameModelNotInstalled))
            }
            .padding(.horizontal)
        }
        .padding(.all)
        .onChange(of: model.enableFrameInterpolation) { newValue in
            if newValue {
                model.frameInterpolation = 2
            } else {
                model.frameInterpolation = 1
            }
        }
        .frame(height: {() -> CGFloat in
            var height: CGFloat = model.isCaffe ? 200: 230
            
            guard self.containVideo else { return height }
            if !model.enableFrameInterpolation {
                height += 40
            } else {
                if model.frameModel == .rife {
                    height += 200
                } else {
                    height += 110
                }
            }
            
            return height
        }())
    }
    
}
