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
                        let url = URL(dataRepresentation: urlData, relativeTo: nil)
                        
                        print(url)
                        
                    }
                }
                
                return true
            }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
