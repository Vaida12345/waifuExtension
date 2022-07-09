//
//  GridView.swift
//  waifuExtension
//
//  Created by Vaida on 5/4/22.
//

import SwiftUI
import Support

struct GridItemView: View {
    
    let item: WorkItem
    let geometry: GeometryProxy
    
    @ObservedObject var images: MainModel
    
    @AppStorage("ContentView.gridNumber") private var gridNumber = 1.6
    @AppStorage("ContentView.aspectRatio") private var aspectRatio = true
    
    var body: some View {
        VStack(alignment: .center) {
            
            AsyncView {
                return (item.finderItem.image ?? item.finderItem.avAsset?.firstFrame) ?? NSImage(named: "placeholder")!
            } content: { result in
                Image(nsImage: result)
                    .resizable()
                    .cornerRadius(5)
                    .aspectRatio(contentMode: aspectRatio ? .fit : .fill)
                    .frame(width: geometry.size.width * gridNumber / 8.5, height: geometry.size.width * gridNumber / 8.5)
                    .clipped()
                    .cornerRadius(5)
                    .padding([.top, .leading, .trailing])
                    .help {
                        if let size = result.pixelSize {
                            var value = """
                            name: \(item.finderItem.fileName)
                            path: \(item.finderItem.path)
                            size: \(size.width) × \(size.height)
                            """
                            if item.type == .video {
                                value += "\nlength: \(item.finderItem.avAsset?.duration.seconds.expressedAsTime() ?? "0s")"
                            }
                            return .init(value)
                        } else {
                            return """
                        Loading...
                        name: \(item.finderItem.fileName)
                        path: \(item.finderItem.path)
                        (If this continuous, please transcode your video into HEVC and retry)
                        """
                        }
                    }
            } placeHolderValue: {
                NSImage(named: "placeholder")!
            }
            
            Text(item.finderItem.relativePath ?? item.finderItem.fileName)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding([.leading, .bottom, .trailing])
        }
        .contextMenu {
            Button("Open") {
                item.finderItem.open()
            }
            Button("Show in Finder") {
                item.finderItem.revealInFinder()
            }
            Button("Delete") {
                withAnimation {
                    images.items.removeAll { $0 == item }
                }
            }
        }
        .onTapGesture(count: 2) {
            item.finderItem.open()
        }
    }
}
