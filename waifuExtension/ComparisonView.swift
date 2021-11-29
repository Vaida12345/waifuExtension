//
//  ComparisonView.swift
//  waifuExtension
//
//  Created by Vaida on 11/29/21.
//

import SwiftUI

struct ComparisonView: View {
    @State var finderItem: FinderItem? = FinderItem(at: "/Users/vaida/Downloads/Kamui-0001.png")
    
    var body: some View {
        if finderItem == nil {
            VStack {
                Image(systemName: "square.and.arrow.down.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(.all)
                    .frame(width: 100, height: 100, alignment: .center)
                Text("Drag a file here")
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
                        guard FinderItem(at: url).image != nil else { return }
                        
                        self.finderItem = FinderItem(at: url)
                        return
                    }
                }
                
                return true
            }
        } else {
            Image(nsImage: finderItem!.image!)
        }
        
        
    }
}

struct ComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        ComparisonView()
    }
}
