//
//  WelcomeView.swift
//  waifuExtension
//
//  Created by Vaida on 3/28/22.
//

import SwiftUI
import Support

struct WelcomeView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var isAllInstalled: Bool {
        ModelCoordinator.allInstalledModels.allSatisfy { $0.programItem.isExistence }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome to WaifuExtension!")
                .font(.title)
                .padding()
            Text("(Optional) Please download the models and link them.")
                .padding(.horizontal)
            
            LazyVGrid(columns: .init(repeating: .init(.flexible()), count: 3)) {
                WelcomeViewGridItem(model: Model_CAIN.self)
                WelcomeViewGridItem(model: Model_DAIN.self)
                WelcomeViewGridItem(model: Model_RIFE.self)
            }
            .padding(.horizontal)
            
            HStack {
                Text("Please keep your file in your disk, as WaifuExtension do not copy your file.")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    withAnimation {
                        dismiss()
                    }
                } label: {
                    Text(isAllInstalled ? "Done" : "Skip")
                        .padding()
                }
            }
            .padding([.horizontal, .bottom])
        }
        .padding()
    }
}
