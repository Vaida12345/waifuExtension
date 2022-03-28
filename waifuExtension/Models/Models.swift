//
//  Models.swift
//  waifuExtension
//
//  Created by Vaida on 3/15/22.
//

import Foundation
import AppKit

protocol InstalledModel: Hashable {
    
    var name: String { get }
    var rawName: String { get }
    var source: URL { get }
    
}

extension InstalledModel {
    
    var rootPath: String {
        var manager = StorageManager(path: NSHomeDirectory() + "/recorderData.json")
        manager.decode()
        return manager[rawName] ?? ""
    }
    
    /// The finderItem which determines where the program is.
    var programFolderItem: FinderItem {
        FinderItem(at: "\(rootPath)")
    }
    
    var programItem: FinderItem {
        return FinderItem(at: "\(rootPath)/\(self.rawName)")
    }
    
}

protocol InstalledImageModel: InstalledModel {
    
    func run(inputItem: FinderItem, outputItem: FinderItem, task: ShellManager)
    
}

protocol InstalledFrameModel: InstalledModel {
    
    func run(input1Item: FinderItem, input2Item: FinderItem, outputItem: FinderItem, task: ShellManager)
    
}

struct Model_cain_ncnn_vulkan: InstalledFrameModel {
    
    var name: String { "CAIN" }
    var rawName: String { "cain-ncnn-vulkan" }
    var source: URL { URL(string: "https://github.com/nihui/cain-ncnn-vulkan")! }
    
    /// Runs the model to achieve an output to `outputItem` from `input1Item` and `input2Item`.
    func run(input1Item: FinderItem, input2Item: FinderItem, outputItem: FinderItem, task: ShellManager) {
        task.run(arguments: "cd \(self.programFolderItem.shellPath); ./\(self.rawName) -0 \(input1Item.shellPath) -1 \(input2Item.shellPath) -o \(outputItem.shellPath)")
        
    }
    
}

struct Model_dain_ncnn_vulkan: InstalledFrameModel {
    
    var name: String { "DAIN" }
    var rawName: String { "dain-ncnn-vulkan" }
    var source: URL { URL(string: "https://github.com/nihui/dain-ncnn-vulkan")! }
    
    /// Runs the model to achieve an output to `outputItem` from `input1Item` and `input2Item`.
    func run(input1Item: FinderItem, input2Item: FinderItem, outputItem: FinderItem, task: ShellManager) {
        task.run(arguments: "cd \(self.programFolderItem.shellPath); ./\(self.rawName) -0 \(input1Item.shellPath) -1 \(input2Item.shellPath) -o \(outputItem.shellPath)")
        
    }
    
}

struct Model_rife_ncnn_vulkan: InstalledFrameModel {
    
    var name: String { "RIFE" }
    var rawName: String { "rife-ncnn-vulkan" }
    var source: URL { URL(string: "https://github.com/nihui/rife-ncnn-vulkan")! }
    
    var modelName: String = "rife-v2.3"
    var modelNameOptions: [String] {
        ["rife", "rife-HD", "rife-UHD", "rife-anime", "rife-v2", "rife-v2.3", "rife-v2.4", "rife-v3.0", "rife-v3.1", "rife-v4"]
    }
    
    var enableTTA: Bool = true
    var enableUHD: Bool = true
    
    /// Runs the model to achieve an output to `outputItem` from `input1Item` and `input2Item`.
    func run(input1Item: FinderItem, input2Item: FinderItem, outputItem: FinderItem, task: ShellManager) {
        task.run(arguments: "cd \(self.programFolderItem.shellPath); ./\(self.rawName)-0 \(input1Item.shellPath) -1 \(input2Item.shellPath) -o \(outputItem.shellPath) \(self.enableTTA ? "-x" : "") \(self.enableUHD ? "-u" : "")")
        
    }
    
}

struct Model_realcugan_ncnn_vulkan: InstalledImageModel {
    
    var name: String { "Real-CUGAN" }
    var rawName: String { "realcugan-ncnn-vulkan" }
    var source: URL { URL(string: "https://github.com/nihui/realcugan-ncnn-vulkan")! }
    
    var scaleLevel: Int = 2
    var scaleLevelOptions: [Int] {
        [1, 2, 3, 4]
    }
    
    var denoiseLevel: Int = -1
    var denoiseLevelOption: [Int] {
        [-1, 0, 1, 2, 3]
    }
    
    var modelName: String = "models-se"
    var modelNameOptions: [String] {
        ["models-se", "models-nose"]
    }
    
    var enableTTA: Bool = true
    
    /// Runs the model to achieve an output to `outputItem` from `inputItem`.
    func run(inputItem: FinderItem, outputItem: FinderItem, task: ShellManager) {
        print(self.programItem.path, inputItem, outputItem)
        task.run(arguments: "cd \(self.programFolderItem.shellPath); ./\(self.rawName) -i \(inputItem.shellPath) -o \(outputItem.shellPath) -n \(self.denoiseLevel) -s \(self.scaleLevel) -m \(self.modelName) \(self.enableTTA ? "-x" : "")")
        
    }
}


struct Model_realesrgan_ncnn_vulkan: InstalledImageModel {
    
    var name: String { "Real-ESRGAN" }
    var rawName: String { "realesrgan-ncnn-vulkan" }
    var source: URL { URL(string: "https://github.com/xinntao/Real-ESRGAN")! }
    
    var scaleLevel: Int = 4
    var denoiseLevel: Int = -1
    
    var scaleLevelOptions: [Int] {
        [4]
    }
    var denoiseLevelOption: [Int] {
        [-1]
    }
    
    var modelName: String = "realesrgan-x4plus"
    var modelNameOptions: [String] {
        ["realesrgan-x4plus", "realesrnet-x4plus", "realesrgan-x4plus-anime", "RealESRGANv2-animevideo-xsx2", "RealESRGANv2-animevideo-xsx4"]
    }
    
    var enableTTA: Bool = true
    
    /// Runs the model to achieve an output to `outputItem` from `inputItem`.
    func run(inputItem: FinderItem, outputItem: FinderItem, task: ShellManager) {
        task.run(arguments: "cd \(self.programFolderItem.shellPath); ./\(self.rawName) -i \(inputItem.shellPath) -o \(outputItem.shellPath) -n \(self.denoiseLevel) -s \(self.scaleLevel) -n \(self.modelName) \(self.enableTTA ? "-x" : "")")
        
    }
}


struct Model_realsr_ncnn_vulkan: InstalledImageModel {
    
    var name: String { "RealSR" }
    var rawName: String { "realsr-ncnn-vulkan" }
    var source: URL { URL(string: "https://github.com/nihui/realsr-ncnn-vulkan")! }
    
    var scaleLevel: Int = 4
    var denoiseLevel: Int = -1 //unable
    var scaleLevelOptions: [Int] {
        [4]
    }
    var denoiseLevelOption: [Int] {
        [-1]
    }
    
    var modelName: String = "models-DF2K_JPEG"
    var modelNameOptions: [String] {
        ["models-DF2K_JPEG", "models-DF2K"]
    }
    
    var enableTTA: Bool = true
    
    /// Runs the model to achieve an output to `outputItem` from `inputItem`.
    func run(inputItem: FinderItem, outputItem: FinderItem, task: ShellManager) {
        task.run(arguments: "cd \(self.programFolderItem.shellPath); ./\(self.rawName) -i \(inputItem.shellPath) -o \(outputItem.shellPath) -s \(self.scaleLevel) -m \(self.modelName) \(self.enableTTA ? "-x" : "")")
        
    }
}
