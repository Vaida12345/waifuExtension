//
//  ConfigurationContainerView.swift
//  waifuExtension
//
//  Created by Vaida on 6/13/22.
//

import SwiftUI

struct ConfigurationContainerView: View {
    
    @State private var height: CGFloat = 100
    
    var body: some View {
        TabView {
            ConfigurationView()
                .onAppear {
                    height = 100
                }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Config")
                        .frame(width: 80)
                }
            
            ProcessingConfigurationView()
                .onAppear {
                    height = 200
                }
                .tabItem {
                    Image(systemName: "photo.fill")
                    Text("Inference")
                        .frame(width: 80)
                }
            
            ModelManager()
                .onAppear {
                    height = 390
                }
                .tabItem {
                    Image(systemName: "doc.on.doc")
                    Text("Models")
                        .frame(width: 80)
                }
        }
        .frame(height: height)
    }
    
}
