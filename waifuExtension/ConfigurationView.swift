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
            .padding()
        }
        .onChange(of: isLogEnabled) { newValue in
            Configuration.main.isLogEnabled = newValue
        }
        .onChange(of: saveFolder) { newValue in
            Configuration.main.saveFolder = saveFolder
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
            guard privateSaveFolder != "/Downloads/Waifu Output" else {
                return "\(NSHomeDirectory())/Downloads/Waifu Output"
            }
            let item = FinderItem(at: privateSaveFolder)
            guard item.isExistence else {
                item.generateDirectory()
                return privateSaveFolder
            }
            guard item.children == nil || item.children!.isEmpty else {
                let path = privateSaveFolder + "/Waifu Output"
                FinderItem(at: path).generateDirectory()
                return path
            }
            return privateSaveFolder
        }
        set {
            self.privateSaveFolder = newValue
        }
    }
    
    var saveFolderText: String {
        return privateSaveFolder
    }
    
    private var privateSaveFolder = "/Downloads/Waifu Output"
    
    static var main: Configuration = { () -> Configuration in
        if let configuration = try? FinderItem.loadJSON(from: "\(NSHomeDirectory())/configuration.json", type: Configuration.self) {
            return configuration
        } else {
            return Configuration()
        }
    }() {
        didSet {
            Configuration.main.write()
        }
    }
    
    func write() {
        try! FinderItem.saveJSON(self, to: "\(NSHomeDirectory())/configuration.json")
    }
    
}
