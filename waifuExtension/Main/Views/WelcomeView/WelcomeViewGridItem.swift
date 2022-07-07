//
//  WelcomeViewGridItem.swift
//  waifuExtension
//
//  Created by Vaida on 6/16/22.
//

import Foundation
import SwiftUI
import Support

struct WelcomeViewGridItem: View {
    
    let model: any InstalledModel.Type
    
    @EnvironmentObject private var dataProvider: ModelDataProvider
    
    @State private var showImportCatalog = false
    @State private var alertManager = AlertManager()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if model.programItem.isExistence {
                    Image(systemName: "checkmark")
                        .symbolRenderingMode(.multicolor)
                }
                
                Text(model.name)
                    .font(.title2)
                    
            }
            .padding()
            
            Spacer()
            
            HStack {
                Button {
                    NSWorkspace.shared.open(model.source)
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .help("Download from Github")
                
                Button {
                    showImportCatalog = true
                } label: {
                    Image(systemName: "folder")
                }
                .help("Choose Model")
                
                Spacer()
            }
            .padding()
        }
        .background {
            RoundedRectangle(cornerSize: .init(width: 10, height: 10))
                .fill(Color.allColors.randomElement()!.opacity(0.5))
        }
        .onDrop(of: [.folder], isTargeted: nil) { providers in
            Task {
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
            }
            
            return true
        }
        .contextMenu {
            Button("Choose Model") {
                showImportCatalog = true
            }
            
            Button("Download from Github") {
                NSWorkspace.shared.open(model.source)
            }
        }
        .fileImporter(isPresented: $showImportCatalog, allowedContentTypes: [.folder]) { result in
            guard let url = try? result.get() else { alertManager = AlertManager("Cannot read url"); return }
            dataProvider.loadModels(from: [FinderItem(at: url)]) { name in
                alertManager = AlertManager("Cannot read \(name)", message: "Please move the model to somewhere else and retry (for example, your downloads folder)\nOtherwise, please ensure you can open the executable in Finder.", defaultAction:  {
                    self.alertManager.isShown = false
                })
            } onNonAdded: {
                alertManager = AlertManager("None was added", message: "Please drop in the folder containing the executable file.")
            }
            
        }
        .alert(manager: $alertManager)
    }
    
}
