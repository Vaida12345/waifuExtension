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
    @State private var isShowingCannotReadFile = false
    
    @StateObject private var images = MainModel()
    
    @EnvironmentObject private var modelDataProvider: ModelDataProvider
    
    @AppStorage("ContentView.gridNumber") private var gridNumber = 1.6
    @AppStorage("ContentView.aspectRatio") private var aspectRatio = true
    
    var body: some View {
        VStack {
            if images.items.isEmpty {
                DropView { resultItems in
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
                                    .popover(isPresented: .constant(isShowingCannotReadFile && item.finderItem.avAsset == nil && item.finderItem.image == nil)) {
                                        Text("Cannot read this file")
                                            .padding()
                                    }
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
            SpecificationsView(containVideo: self.images.items.contains{ $0.type == .video }, isShown: $isSheetShown, isProcessing: $isProcessing, images: images)
        }
        .sheet(isPresented: $isProcessing) {
            ProcessingView(isProcessing: $isProcessing, isSheetShown: $isSheetShown, images: images)
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
                Button(action: {
                    withAnimation(.spring()) {
                        aspectRatio.toggle()
                    }
                }, label: {
                    Label("", systemImage: aspectRatio ? "rectangle.arrowtriangle.2.outward" : "rectangle.arrowtriangle.2.inward")
                        .labelStyle(.iconOnly)
                })
                .help("Show thumbnails as square or in full aspect ratio.")

                Slider(
                    value: $gridNumber,
                    in: 1...8,
                    minimumValueLabel:
                        Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12)
                        .onTapGesture(perform: {
                            withAnimation {
                                gridNumber = 1.6
                            }
                        }),
                    maximumValueLabel:
                        Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                        .onTapGesture(perform: {
                            withAnimation {
                                gridNumber = 1.6
                            }
                        })
                ) {
                    Text("Grid Item Count\nTap to restore default.")
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
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    isSheetShown = true
                }
                .disabled(images.items.isEmpty || isSheetShown)
                .disabled(!(images.items.allSatisfy{ $0.finderItem.avAsset != nil || $0.finderItem.image != nil }))
                .help("Begin processing.")
                .onHover { bool in
                    guard images.items.allSatisfy({ $0.finderItem.avAsset != nil || $0.finderItem.image != nil }) else { return }
                    isShowingCannotReadFile = bool
                }
            }
        }
    }
}
