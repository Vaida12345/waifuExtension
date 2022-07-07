//
//  ConfigurationContainerView.swift
//  waifuExtension
//
//  Created by Vaida on 6/13/22.
//

import SwiftUI

struct ConfigurationContainerView: View {
    
    @State private var height: CGFloat = 500
    
    var body: some View {
        TabView {
            ConfigurationView()
                .onAppear {
                    height = 100
                }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Configuration")
                }
            
            ModelManager()
                .onAppear {
                    height = 360
                }
                .tabItem {
                    Image(systemName: "doc.on.doc")
                    Text("Models")
                }
        }
        .frame(height: height)
    }
    
}
