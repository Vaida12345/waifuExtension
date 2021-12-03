//
//  ConfigurationView.swift
//  waifuExtension
//
//  Created by Vaida on 12/2/21.
//

import SwiftUI

struct ConfigurationView: View {
    
    @State var isLogEnabled = Configuration.main.isLogEnabled
    @State var saveFolder = Configuration.main.saveFolderText
    
    var body: some View {
        
        VStack {
            HStack {
                Toggle(isOn: $isLogEnabled) {
                    Text("Enable Log")
                }
                
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
            .padding([.leading, .bottom, .trailing])
        }
        .onChange(of: isLogEnabled) { newValue in
            Configuration.main.isLogEnabled = newValue
        }
        .onChange(of: saveFolder) { newValue in
            Configuration.main.saveFolder = saveFolder
            Configuration.main.getFolder = {()-> String in
                guard Configuration.main.privateSaveFolder != "/Downloads/Waifu Output" else {
                    return "\(NSHomeDirectory())/Downloads/Waifu Output"
                }
                let item = FinderItem(at: Configuration.main.privateSaveFolder)
                guard item.isExistence else {
                    item.generateDirectory()
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
                    item.generateDirectory()
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
                    item.generateDirectory()
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
        guard self.isLogEnabled else { return }
        let path = self.saveFolder + "/log.txt"
        var content = ""
        if let previousLog = try? String(contentsOfFile: path) {
            content = previousLog
            try! FinderItem(at: path).removeFile()
        }
        content += value + "\n"
        try! content.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    }
    
}
