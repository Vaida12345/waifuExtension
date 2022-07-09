//
//  ModelManager.swift
//  waifuExtension
//
//  Created by Vaida on 3/26/22.
//

import SwiftUI
import Support

struct ModelView: View {
    
    let model: any InstalledModel.Type
    
    @State private var showImportCatalog = false
    
    @EnvironmentObject private var dataProvider: ModelDataProvider
    
    var contextMenu: some View {
        VStack {
            if model.programItem.isExistence {
                if model is InstalledFrameModel {
                    Button("Remove Model") {
                        dataProvider.location[model.rawName] = nil
                    }
                    
                    Button("Update Model") {
                        showImportCatalog = true
                    }
                }
                
                Divider()
                
                Button("Show in Finder") {
                    model.programFolderItem.revealInFinder()
                }
                
                Button("Show on Github") {
                    NSWorkspace.shared.open(model.source)
                }
            } else {
                Button("Choose Model") {
                    showImportCatalog = true
                }
                
                Button("Download from Github") {
                    NSWorkspace.shared.open(model.source)
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label {
                    Text(model.name)
                        .font(.title2)
                } icon: {
                    model.programItem.isExistence ? Image(systemName: "checkmark") : Image(systemName: "xmark")
                        .symbolRenderingMode(.multicolor)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Menu {
                    contextMenu
                } label: {
                    
                }
                .menuStyle(.borderlessButton)
                .frame(width: 10)
            }

            
            if model.programItem.isExistence {
                Text("Size: \(model.programFolderItem.fileSize?.expressAsFileSize() ?? "unknown")")
                    .padding(.horizontal)
            } else {
                Text("Not Installed")
                    .padding(.horizontal)
            }
            
            Divider()
        }
        .fileImporter(isPresented: $showImportCatalog, allowedContentTypes: [.folder]) { result in
            guard let result = try? result.get() else { return }
            let item = FinderItem(at: result)
            guard item.isDirectory && item.name.contains(model.rawName) && item.children()!.contains(where: { $0.name == model.rawName }) else { return }
            
            dataProvider.location[model.rawName] = item.path
        }
        .contextMenu {
            contextMenu
        }
    }
}



struct ModelManager: View {
    
    @State private var isLoading = false
    @State private var alertManager = AlertManager()
    
    @EnvironmentObject private var dataProvider: ModelDataProvider
    
    var baseView: some View {
        List {
            ModelView(model: Model_RealSR.self)
            ModelView(model: Model_RealCUGAN.self)
            ModelView(model: Model_RealESRGAN.self)
            ModelView(model: Model_CAIN.self)
            ModelView(model: Model_DAIN.self)
            ModelView(model: Model_RIFE.self)
            Text("Drop additional models here\nPlease keep your file in your disk, as executables are not copied.")
                .foregroundColor(.secondary)
                .font(.callout)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            Task {
                isLoading = true
                
                let items = await [FinderItem](from: providers, option: .directory)
                guard !items.isEmpty else {
                    alertManager = AlertManager("None was added", message: "Please drop in the folder containing the executable file.")
                    return
                }
                
                dataProvider.loadModels(from: items) { name in
                    alertManager = AlertManager("Cannot read \(name)", message: "Please move the model to somewhere else and retry (for example, your downloads folder)\nOtherwise, please ensure you can open the executable in Finder.")
                } onNonAdded: {
                    alertManager = AlertManager("None was added", message: "Please drop in the folder containing the executable file.")
                }
                
                isLoading = false
            }
            
            return true
        }
        .alert(manager: $alertManager)
    }
    
    var body: some View {
        if #available(macOS 13.0, *) {
            baseView
                .scrollDisabled(true)
        } else {
            baseView
        }
    }
}
