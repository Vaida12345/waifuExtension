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
        if finderItems.isEmpty {
            welcomeView(finderItems: $finderItems)
        } else {
            GeometryReader { geometry in
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5)) {
                        ForEach(finderItems) { item in
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
    
//    var body: some View {
//        GeometryReader { geometry in
//            VStack {
//                Text("\(geometry.size.width) x \(geometry.size.height)")
//            }
//        }
//    }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
