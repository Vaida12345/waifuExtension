//
//  ContentView.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI

struct ContentView: View {
    @State var finderItems: [FinderItem] = []
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button("Add Item") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = true
                    if panel.runModal() == .OK {
                        for i in panel.urls {
                            let item = FinderItem(at: i)
                            
                            guard !finderItems.contains(item) else { return }
                            
                            if item.isFile {
                                guard item.image != nil else { return }
                                finderItems.append(item)
                            } else {
                                item.iteratedOver { child in
                                    guard !finderItems.contains(child) else { return }
                                    guard child.image != nil else { return }
                                    finderItems.append(child)
                                }
                            }
                        }
                    }
                }
                    .padding(.all)
                
                Button("Done") {
                    
                }
                    .disabled(finderItems.isEmpty)
                    .padding([.top, .bottom, .trailing])
            }
            
            if finderItems.isEmpty {
                welcomeView(finderItems: $finderItems)
            } else {
                GeometryReader { geometry in
                    
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5)) {
                            ForEach(finderItems) { item in
                                
                                GridItemView(item: item, geometry: geometry, finderItems: $finderItems)
                                
                            }
                        }
                        
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        for i in providers {
                            i.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, error in
                                guard error == nil else { return }
                                guard let urlData = urlData as? Data else { return }
                                guard let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                                
                                let item = FinderItem(at: url)
                                guard !finderItems.contains(item) else { return }
                                
                                if item.isFile {
                                    guard item.image != nil else { return }
                                    finderItems.append(item)
                                } else {
                                    item.iteratedOver { child in
                                        guard !finderItems.contains(child) else { return }
                                        guard child.image != nil else { return }
                                        finderItems.append(child)
                                    }
                                }
                                
                            }
                        }
                        
                        return true
                    }
                }
            }
        }
    }
    
}

struct welcomeView: View {
    
    @Binding var finderItems: [FinderItem]
    
    var body: some View {
        VStack {
            Image(systemName: "square.and.arrow.down.fill")
                .padding(.all)
            Text("Drag files or folder \n or \n click to add files.")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.all)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.all, 0.0)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for i in providers {
                i.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, error in
                    guard error == nil else { return }
                    guard let urlData = urlData as? Data else { return }
                    guard let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                    
                    let item = FinderItem(at: url)
                    
                    if item.isFile {
                        guard item.image != nil else { return }
                        finderItems.append(item)
                    } else {
                        item.iteratedOver { child in
                            guard child.image != nil else { return }
                            finderItems.append(child)
                        }
                    }
                    
                }
            }
            
            return true
        }
        .onTapGesture {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = true
            if panel.runModal() == .OK {
                for i in panel.urls {
                    let item = FinderItem(at: i)
                    
                    if item.isFile {
                        guard item.image != nil else { return }
                        finderItems.append(item)
                    } else {
                        item.iteratedOver { child in
                            guard child.image != nil else { return }
                            finderItems.append(child)
                        }
                    }
                }
            }
        }
    }
}


struct GridItemView: View {
    
    let item: FinderItem
    let geometry: GeometryProxy
    @Binding var finderItems: [FinderItem]
    
    var body: some View {
        let image = item.image!
        
        VStack {
            Image(nsImage: image)
                .resizable()
                .cornerRadius(5)
                .aspectRatio(contentMode: .fit)
                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            
            
            Text(item.fileName ?? item.path)
                .padding(.all)
        }
        .frame(width: geometry.size.width / 5, height: geometry.size.width / 5)
        .contextMenu {
            Button("Delete") {
                finderItems.remove(at: finderItems.firstIndex(of: item)!)
            }
        }
    }
}

struct ConfigurationView: View {
    
    var finderItems: [FinderItem] = []
    
    let modelNames: [String] = ["srcnn_mps", "srcnn_coreml", "cunet"]
    @State var chosenModel = "srcnn_mps"
    
    let styleNames: [String] = ["anime", "photo"]
    @State var chosenStyle = "anime"
    
    let noiceLevels: [Int] = [Int](0...3)
    @State var chosenNoiceLevel = 3
    
    let scaleLevels: [Int] = [2, 4]
    @State var chosenScaleLevel = 2
    
    var body: some View {
        VStack {
            
            Spacer()
            
            HStack(spacing: 10) {
                VStack(spacing: 19) {
                    Text("        Model:")
                    Text("         Style:")
                        .padding(.bottom)
                    Text("Noice Level:")
                    Text("Scale Level:")
                }
                
                VStack(spacing: 15) {
                    Menu(chosenModel) {
                        ForEach(modelNames, id: \.self) { item in
                            Button(item) {
                                chosenModel = item
                            }
                        }
                    }
                    
                    Menu(chosenStyle) {
                        ForEach(styleNames, id: \.self) { item in
                            Button(item) {
                                chosenStyle = item
                            }
                        }
                    }
                    .padding(.bottom)
                    
                    Menu(chosenNoiceLevel.description) {
                        ForEach(noiceLevels, id: \.self) { item in
                            Button(item.description) {
                                chosenNoiceLevel = item
                            }
                        }
                    }
                    
                    Menu(chosenScaleLevel.description) {
                        ForEach(scaleLevels, id: \.self) { item in
                            Button(item.description) {
                                chosenScaleLevel = item
                            }
                        }
                    }
                }
                
            }
                .padding(.horizontal, 50.0)
            
            Spacer()
            
            HStack {
                Button {
                    
                } label: {
                    Text("Save as default")
                        .frame(width: 120)
                }
                .padding(.trailing)
                
                Spacer()
                
                Button {
                    
                } label: {
                    Text("Cancel")
                        .frame(width: 80)
                }
                .padding(.trailing)
                
                Button {
                    
                } label: {
                    Text("OK")
                        .frame(width: 80)
                }
            }
                .padding(.all)
        }
            .padding(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView()
    }
}
