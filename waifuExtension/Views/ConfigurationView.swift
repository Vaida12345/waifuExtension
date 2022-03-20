//
//  ConfigurationView.swift
//  waifuExtension
//
//  Created by Vaida on 12/2/21.
//

import SwiftUI

struct DoubleText: View {
    
    let lhs: String
    let rhs: String
    
    var body: some View {
        HStack {
            Text(lhs)
                .padding(.horizontal)
            
            Text(rhs)
            
            Spacer()
        }
    }
}

struct ModelView<T>: View where T: InstalledModel {
    
    @State var showImportCatalog = false
    let model: T
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(model.name)
                .font(.title)
                .padding()
            
            HStack {
                DoubleText(lhs: "Installed: ", rhs: model.programFolderItem.isExistence.description)
                    .padding(.trailing)
                
                if model.programItem.isExistence {
                    DoubleText(lhs: "Size: ", rhs: model.programFolderItem.fileSize?.expressAsFileSize() ?? "unkown")
                }
                
                Spacer()
            }
            
            if model.programItem.isExistence {
                HStack {
//                    Button("Remove Model") {
//                        do {
//                            try model.programItem.removeFile()
//                        } catch { print(error) }
//                    }
//                    Button("Update Model") {
//                        showImportCatalog = true
//                    }
                    Button("Show in Finder") {
                        model.programItem.revealInFinder()
                    }
                    
                    Button("Show on Github") {
                        NSWorkspace.shared.open(model.source)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            } else {
                HStack {
                    Button("Choose Model") {
                        showImportCatalog = true
                    }
                    .padding(.horizontal)
                    
                    Button("Download from Github") {
                        NSWorkspace.shared.open(model.source)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            
            Divider()
                .padding(.vertical)
        }
        .fileImporter(isPresented: $showImportCatalog, allowedContentTypes: [.folder]) { result in
            guard let result = try? result.get() else { return }
            let item = FinderItem(at: result)
            guard item.isDirectory else { return }
            guard item.name.contains(model.name) else { return }
            
            do {
                try model.programItem.removeFile()
                try item.copy(to: model.programItem.path)
            } catch { print(error) }
        }
    }
}

struct ConfigurationView: View {
    
    @State var isLogEnabled = Configuration.main.isLogEnabled
    @State var saveFolder = Configuration.main.saveFolderText
    @State var isDevEnabled = Configuration.main.isDevEnabled
    @State var isVideoLogEnabled = Configuration.main.isVideoLogEnabled
    
    var body: some View {
        
        ScrollView {
            VStack {
                HStack {
                    Toggle(isOn: $isLogEnabled) {
                        Text("Enable Log")
                            .help("Debug use")
                    }
                    .padding(.trailing)
                    
                    Toggle(isOn: $isDevEnabled) {
                        Text("Enable Dev")
                            .help("Debug use")
                    }
                    .padding(.trailing)
                    
                    Toggle(isOn: $isVideoLogEnabled) {
                        Text("Enable Video Log")
                            .help("Debug use")
                    }
                    .padding(.trailing)
                    
                    Spacer()
                }
                .padding()
                
                HStack {
                    Text("Save Folder")
                    
                    Menu(saveFolder) {
                        Button("/Downloads/Waifu Output") {
                            saveFolder = "/Downloads/Waifu Output"
                        }
                        Button("Other...") {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            panel.canCreateDirectories = true
                            if panel.runModal() == .OK {
                                for i in panel.urls {
                                    let item = FinderItem(at: i)
                                    saveFolder = item.path
                                }
                            }
                        }
                    }
                }
                .padding()
                
                HStack {
                    Spacer()
                    
                    Button("Delete Cache") {
                        do {
                            try FinderItem(at: "\(NSHomeDirectory())/tmp").removeFile()
                        } catch {  }
                    }
                    
                    Text("Cache: \(FinderItem(at: "\(NSHomeDirectory())/tmp").fileSize?.expressAsFileSize() ?? "Empty")")
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Divider()
                
                ModelView(model: Model_realsr_ncnn_vulkan())
                ModelView(model: Model_realcugan_ncnn_vulkan())
                ModelView(model: Model_realesrgan_ncnn_vulkan())
                ModelView(model: Model_cain_ncnn_vulkan())
                ModelView(model: Model_dain_ncnn_vulkan())
                ModelView(model: Model_rife_ncnn_vulkan())
                
            }
        }
        .onChange(of: isLogEnabled) { newValue in
            Configuration.main.isLogEnabled = newValue
        }
        .onChange(of: isDevEnabled, perform: { newValue in
            Configuration.main.isDevEnabled = newValue
        })
        .onChange(of: isVideoLogEnabled, perform: { newValue in
            Configuration.main.isVideoLogEnabled = newValue
        })
        .onChange(of: saveFolder) { newValue in
            Configuration.main.saveFolder = saveFolder
            Configuration.main.getFolder = {()-> String in
                guard Configuration.main.privateSaveFolder != "/Downloads/Waifu Output" else {
                    return "\(NSHomeDirectory())/Downloads/Waifu Output"
                }
                let item = FinderItem(at: Configuration.main.privateSaveFolder)
                guard item.isExistence else {
                    try! item.generateDirectory()
                    return Configuration.main.privateSaveFolder
                }
                return Configuration.main.privateSaveFolder
            }()
        }
    }
    
}

struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView()
    }
}

struct Configuration: Codable {
    
    var isLogEnabled = false
    var isDevEnabled = false
    var isVideoLogEnabled = false
    
    var gridNumber = 1.6
    var aspectRatio = true
    
    var saveFolder: String {
        get {
            return getFolder
        }
        set {
            self.privateSaveFolder = newValue
        }
    }
    
    var saveFolderText: String {
        return privateSaveFolder
    }
    
    var modelStyle: String = "anime"
    
    var privateSaveFolder = "/Downloads/Waifu Output"
    var getFolder = ""
    
    static var main: Configuration = { () -> Configuration in
        if var configuration = try? FinderItem.loadJSON(from: "\(NSHomeDirectory())/configuration.json", type: Configuration.self) {
            configuration.getFolder = {()-> String in
                guard configuration.privateSaveFolder != "/Downloads/Waifu Output" else {
                    return "\(NSHomeDirectory())/Downloads/Waifu Output"
                }
                let item = FinderItem(at: configuration.privateSaveFolder)
                guard item.isExistence else {
                    try! item.generateDirectory()
                    return configuration.privateSaveFolder
                }
                return configuration.privateSaveFolder
            }()
            return configuration
        } else {
            var configuration = Configuration()
            
            configuration.getFolder = {()-> String in
                guard configuration.privateSaveFolder != "/Downloads/Waifu Output" else {
                    return "\(NSHomeDirectory())/Downloads/Waifu Output"
                }
                let item = FinderItem(at: configuration.privateSaveFolder)
                guard item.isExistence else {
                    try! item.generateDirectory()
                    return configuration.privateSaveFolder
                }
                return configuration.privateSaveFolder
            }()
            return configuration
        }
    }() {
        didSet {
            Configuration.main.write()
        }
    }
    
    func write() {
        try! FinderItem.saveJSON(self, to: "\(NSHomeDirectory())/configuration.json")
    }
    
    func saveLog(_ value: String) {
        guard self.isVideoLogEnabled else { return }
        let path = self.saveFolder + "/log.txt"
        var content = ""
        if let previousLog = try? String(contentsOfFile: path) {
            content = previousLog
            try! FinderItem(at: path).removeFile()
        }
        content += value + "\n"
        try! content.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    }
    
    func saveError(_ value: String) {
        let path = self.saveFolder + "/error.txt"
        var content = ""
        if let previousLog = try? String(contentsOfFile: path) {
            content = previousLog
            try! FinderItem(at: path).removeFile()
        }
        content += value + "\n"
        try! content.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    }
    
}
