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
        
        Image(systemName: "square.and.arrow.down.fill")
            .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            .frame(width: 100.0, height: 100.0)
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
