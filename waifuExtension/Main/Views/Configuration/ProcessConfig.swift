//
//  ProcessingConfigurationView.swift
//  waifuExtension
//
//  Created by Vaida on 7/10/22.
//

import SwiftUI
import Support


struct ProcessingConfigurationView: View {
    
    @EnvironmentObject private var model: ModelCoordinator
    
    @State private var selectedSegmentation: CGFloat = 3
    
    @ViewBuilder private var dividingSpacer: some View {
        Divider()
        Spacer()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $model.disableTTA) {
                Text("Disable TTA")
            }
            Text("In TTA mode, it takes 8 times of time to improve the image quality that is difficult to be detected by naked eye.")
                .font(.callout)
                .foregroundColor(.secondary)
            
            dividingSpacer
            
            Toggle(isOn: $model.enableConcurrent) {
                Text("Enable Parallel")
            }
            Text("Disable this to reduce processing speed in return for better memory performance.")
                .font(.callout)
                .foregroundColor(.secondary)
            
            dividingSpacer
            
            Text("Video segmentation: \(model.videoSegmentFrames.description) frames")
            
            Slider(value: $selectedSegmentation, in: 0...4, step: 1) {
                
            }
            .onChange(of: selectedSegmentation) { _ in
                model.videoSegmentFrames = [100, 500, 1000, 2000, 5000][Int(selectedSegmentation)]
            }
            Text("During processing, videos will be split into smaller ones, choose how long you want each smaller video be, in frames.")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
}
