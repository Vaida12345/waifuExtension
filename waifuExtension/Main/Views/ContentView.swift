//
//  ContentView.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI
import Support

struct ContentView: View {
    
    @State private var isSheetShown: Bool = false
    @State private var isProcessing: Bool = false
    
    @StateObject private var images = MainModel()
    
    @EnvironmentObject private var modelDataProvider: ModelDataProvider
    
    @AppStorage("ContentView.gridNumber") private var gridNumber = 1.6
    @AppStorage("ContentView.aspectRatio") private var aspectRatio = true
    
    var body: some View {
        VStack {
            if images.items.isEmpty {
                DropView("Drag files or folder.") { resultItems in
                    Task {
                        await self.images.append(from: resultItems)
                    }
                }
            } else {
                GeometryReader { geometry in
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: Int(8 / gridNumber))) {
                            ForEach(images.items) { item in
                                GridItemView(item: item, geometry: geometry, images: images)
                            }
                        }
                        .padding()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            Task {
                let items = await [FinderItem](from: providers)
                await self.images.append(from: items)
            }

            return true
        }
        .sheet(isPresented: $isSheetShown) {
            SpecificationsView(containVideo: self.images.items.contains{ $0.type == .video }, isProcessing: $isProcessing, images: images)
                .frame(width: 600)
        }
        .sheet(isPresented: $isProcessing) {
            ProcessingView(images: images)
                .padding()
                .frame(width: 600, height: 250)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Remove All") {
                    images.items = []
                }
                .disabled(images.items.isEmpty)
                .help("Remove all files.")
            }

            ToolbarItemGroup {
                Button {
                    withAnimation {
                        aspectRatio.toggle()
                    }
                } label: {
                    Image(systemName: aspectRatio ? "rectangle.arrowtriangle.2.outward" : "rectangle.arrowtriangle.2.inward")
                }
                .help("Show thumbnails as square or in full aspect ratio.")
                
                Slider(value: $gridNumber, in: 1...8) {
                    Text("Grid Item Count.")
                } minimumValueLabel: {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12)
                } maximumValueLabel: {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                }
                .onTapGesture {
                    withAnimation {
                        gridNumber = 1.6
                    }
                }
                .frame(width: 150)
                .help("Set the size of each thumbnail.")

                Button("Add Item") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = true
                    if panel.runModal() == .OK {
                        Task {
                            await self.images.append(from: panel.urls.map{ FinderItem(at: $0) })
                        }
                    }
                }
                .help("Add another item.")
                
                Button("Done") {
                    isSheetShown = true
                }
                .disabled(images.items.isEmpty || isSheetShown)
                .help("Begin processing.")
            }
        }
    }
}
