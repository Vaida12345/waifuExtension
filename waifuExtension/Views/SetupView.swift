//
//  SetupView.swift
//  waifuExtension
//
//  Created by Vaida on 3/28/22.
//

import SwiftUI

struct SetupView: View {
    
    @Binding var isShown: Bool
    
    var isAllInstalled: Bool {
        Model_cain_ncnn_vulkan().programItem.isExistence && Model_dain_ncnn_vulkan().programItem.isExistence && Model_rife_ncnn_vulkan().programItem.isExistence && Model_realsr_ncnn_vulkan().programItem.isExistence && Model_realcugan_ncnn_vulkan().programItem.isExistence && Model_realesrgan_ncnn_vulkan().programItem.isExistence
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome to WaifuExtension!")
                .font(.title)
                .padding()
            Text("Please download the models and drag them here")
                .padding(.horizontal)
            
            GroupBox {
                ModelManager()
            }
            .padding(.horizontal)
            .frame(minHeight: 200)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Please keep your file in your disk, as WaifuExtension do not copy your file.")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    Text("It is not suggested to modify the names of the program, otherwise WaifuExtension may be unable to read.")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button(isAllInstalled ? "Done" : "Skip") {
                    withAnimation {
                        self.isShown = false
                    }
                    var setupManager = StorageManager(path: NSHomeDirectory() + "/setup.plist")
                    setupManager.decode()
                    setupManager["setup"] = true.description
                    setupManager.encode()
                }
                .padding()
            }
            
            .padding()
        }
    }
}
