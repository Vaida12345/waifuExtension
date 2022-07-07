//
//  ConfigurationView.swift
//  waifuExtension
//
//  Created by Vaida on 12/2/21.
//

import SwiftUI
import os
import Support

struct ConfigurationView: View {
    
    @State private var isShowingImportDialog = false
    @State private var alterManager = AlertManager()
    
    @AppStorage("defaultOutputPath") private var outputPath: FinderItem = .downloadsDirectory.with(subPath: "waifu Output")
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                Text("Save Folder")
                
                Menu(outputPath.relativePath(to: .homeDirectory) ?? outputPath.path) {
                    Button("Downloads/Waifu Output") {
                        outputPath = .downloadsDirectory.with(subPath: "waifu Output")
                    }
                    
                    Button("Other...") {
                        isShowingImportDialog = true
                    }
                }
            }
            .padding()
            .fileImporter(isPresented: $isShowingImportDialog, allowedContentTypes: [.directory]) { result in
                guard let resultItem = FinderItem(at: try? result.get()), resultItem.isDirectory else {
                    alterManager = AlertManager("Please choose a folder.")
                    return
                }
                outputPath = resultItem
            }
            
            Spacer()
            
            HStack {
                Button {
                    FinderItem.homeDirectory.revealInFinder()
                } label: {
                    Image(systemName: "folder")
                }
                .help("Show Container")
                
                Spacer()
                
                Text("Cache: \(FinderItem.temporaryDirectory.hasChildren ? FinderItem.temporaryDirectory.fileSize?.expressAsFileSize() ?? "Empty" : "Empty")")
                    .foregroundColor(.secondary)
                
                Button("Delete Cache") {
                    FinderItem.temporaryDirectory.clear()
                }
            }
            .padding()
        }
    }
    
}
