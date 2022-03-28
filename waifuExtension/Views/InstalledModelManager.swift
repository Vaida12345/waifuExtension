//
//  ModelManager.swift
//  waifuExtension
//
//  Created by Vaida on 3/26/22.
//

import SwiftUI

struct DoubleText: View {
    
    let lhs: String
    let rhs: String
    
    @State var isLoading: Bool = false
    
    var body: some View {
        HStack {
            Text(lhs)
                .padding(.horizontal)
            
            Text(rhs)
            
            if isLoading {
                ProgressView()
            }
            
            Spacer()
        }
    }
}

struct ModelView<T>: View where T: InstalledModel {
    
    @State var isLoading = false
    let model: T
    
    @State var showImportCatalog = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(model.name)
                .font(.title)
                .padding()
            
            HStack {
                DoubleText(lhs: "Installed: ", rhs: model.programFolderItem.isExistence.description, isLoading: isLoading)
                    .padding(.trailing)
                
                if model.programItem.isExistence {
                    DoubleText(lhs: "Size: ", rhs: model.programFolderItem.fileSize?.expressAsFileSize() ?? "unkown")
                }
                
                Spacer()
            }
            
            if model.programItem.isExistence {
                HStack {
                    Button("Remove Model") {
                        model.programItem.removeFile()
                    }
                    Button("Update Model") {
                        showImportCatalog = true
                    }
                    Button("Show in Finder") {
                        model.programFolderItem.revealInFinder()
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
            guard item.isDirectory && item.name.contains(model.rawName) && item.children!.contains(where: { $0.name == model.rawName }) else { return }
            
            var manager = StorageManager(path: NSHomeDirectory() + "/recorderData.json")
            manager.decode()
            manager[model.rawName] = item.path
            manager.encode()
        }
    }
}



struct ModelManager: View {
    
    @State var isLoading = false
    @State var updater = Updater()
    
    @State var showAlert = false
    @State var alertModel: String = ""
    
    var body: some View {
        List {
            ModelView(isLoading: isLoading, model: Model_realsr_ncnn_vulkan())
                .environmentObject(updater)
            ModelView(isLoading: isLoading, model: Model_realcugan_ncnn_vulkan())
                .environmentObject(updater)
            ModelView(isLoading: isLoading, model: Model_realesrgan_ncnn_vulkan())
                .environmentObject(updater)
            ModelView(isLoading: isLoading, model: Model_cain_ncnn_vulkan())
                .environmentObject(updater)
            ModelView(isLoading: isLoading, model: Model_dain_ncnn_vulkan())
                .environmentObject(updater)
            ModelView(isLoading: isLoading, model: Model_rife_ncnn_vulkan())
                .environmentObject(updater)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            Task {
                isLoading = true
                
                var items: [FinderItem] = []
                await items.append(from: providers)
                
                func checkModel<T>(model: T, item: FinderItem) where T: InstalledModel {
                    print(item)
                    if item.name.contains(model.rawName) && item.children != nil && item.children!.contains(where: { $0.name == model.rawName }) {
                        let task = ShellManager()
                        guard task.run(path: "\(item.path + "/\(model.rawName)")", arguments: "") else {
                            print("123")
                            showAlert = true
                            alertModel = model.rawName
                            return
                        }
                        
                        
                        var manager = StorageManager(path: NSHomeDirectory() + "/recorderData.json")
                        manager.decode()
                        manager[model.rawName] = item.path
                        manager.encode()
                    }
                }
                
                for i in items {
                    i.enclosingFolder.iteratedFolder { item in
                        guard item.isDirectory else { return }
                        checkModel(model: Model_realsr_ncnn_vulkan(), item: item)
                        checkModel(model: Model_realcugan_ncnn_vulkan(), item: item)
                        checkModel(model: Model_realesrgan_ncnn_vulkan(), item: item)
                        checkModel(model: Model_cain_ncnn_vulkan(), item: item)
                        checkModel(model: Model_dain_ncnn_vulkan(), item: item)
                        checkModel(model: Model_rife_ncnn_vulkan(), item: item)
                    }
                }
                
                isLoading = false
                updater.update.toggle()
            }
            
            return true
        }
        .alert("Error Importing Model: \(alertModel)", isPresented: $showAlert) {
            Button("OK") {
                showAlert = false
            }
        } message: {
            Text("Unable to read \(alertModel)\n" + "Please move the model to somewhere else and retry (for example, your downloads folder)")
        }
    }
}

extension FinderItem {
    
    func iteratedFolder(_ action: ((_ item: FinderItem) -> Void)) {
        
        guard self.isExistence && self.isDirectory else { return }
        guard let children = self.children else { return }
        
        autoreleasepool {
            action(self)
        }
        
        var index = 0
        while index < children.count {
            autoreleasepool {
                let child = children[index]
                autoreleasepool {
                    action(child)
                }
                if child.isDirectory { child.iterated(action) }
            }
            index += 1
        }
    }
    
}

class Updater: ObservableObject {
    
    @Published var update: Bool = false
    
}
