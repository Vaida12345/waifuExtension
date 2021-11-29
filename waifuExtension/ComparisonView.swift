//
//  ComparisonView.swift
//  waifuExtension
//
//  Created by Vaida on 11/29/21.
//

import SwiftUI

struct ComparisonView: View {
    @State var finderItem: FinderItem? = nil {
        didSet {
            self.finderItemImage = finderItem!.image!
            
            //render anime
            DispatchQueue(label: "background").async {
                let waifu2x = Waifu2x()
                self.animeScale2DenoiseNone = waifu2x.run(self.finderItemImage, model: .waifu2x_upconv_7_anime_style_art_rgb_scale2)
                self.animeScale2Denoise0 = waifu2x.run(self.finderItemImage, model: .waifu2x_upconv_7_anime_style_art_rgb_noise0_scale2)
                self.animeScale2Denoise1 = waifu2x.run(self.finderItemImage, model: .waifu2x_upconv_7_anime_style_art_rgb_noise1_scale2)
                self.animeScale2Denoise2 = waifu2x.run(self.finderItemImage, model: .waifu2x_upconv_7_anime_style_art_rgb_noise2_scale2)
                self.animeScale2Denoise3 = waifu2x.run(self.finderItemImage, model: .waifu2x_upconv_7_anime_style_art_rgb_noise3_scale2)
                
                self.photoScale2DenoiseNone = waifu2x.run(self.finderItemImage, model: .waifu2x_upconv_7_photo_scale2)
                self.photoScale2Denoise0 = waifu2x.run(self.finderItemImage, model: .waifu2x_upconv_7_photo_noise0_scale2)
                self.photoScale2Denoise1 = waifu2x.run(self.finderItemImage, model: .waifu2x_upconv_7_photo_noise1_scale2)
                self.photoScale2Denoise2 = waifu2x.run(self.finderItemImage, model: .waifu2x_upconv_7_photo_noise2_scale2)
                self.photoScale2Denoise3 = waifu2x.run(self.finderItemImage, model: .waifu2x_upconv_7_photo_noise3_scale2)
            }
        }
    }
    @State var finderItemImage: NSImage? = nil
    
    @State var animeScale2DenoiseNone: NSImage? = nil
    @State var animeScale2Denoise0: NSImage? = nil
    @State var animeScale2Denoise1: NSImage? = nil
    @State var animeScale2Denoise2: NSImage? = nil
    @State var animeScale2Denoise3: NSImage? = nil
    
    @State var photoScale2DenoiseNone: NSImage? = nil
    @State var photoScale2Denoise0: NSImage? = nil
    @State var photoScale2Denoise1: NSImage? = nil
    @State var photoScale2Denoise2: NSImage? = nil
    @State var photoScale2Denoise3: NSImage? = nil
    
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
            .padding(.all, 0.0)
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                for i in providers {
                    i.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, error in
                        guard error == nil else { return }
                        guard let urlData = urlData as? Data else { return }
                        guard let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                        guard FinderItem(at: url).image != nil else { return }
                        
                        self.finderItem = FinderItem(at: url)
                        self.finderItemImage = finderItem!.image!
                        return
                    }
                }
                
                return true
            }
        } else {
            ScrollView {
                VStack(spacing: 5) {
                    
                    GroupBox(content: {
                        HStack {
                            ImageView(defaultImage: $finderItemImage, image: $finderItemImage, name: "Original")
                            Spacer()
                        }
                    }, label: {
                        Text("original")
                            .font(.title)
                    })
                        .padding()
                        .frame(height: 300)
                    
                    GroupBox(content: {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ImageView(defaultImage: $finderItemImage, image: $animeScale2DenoiseNone, name: "Denoise None")
                                
                                ImageView(defaultImage: $finderItemImage, image: $animeScale2Denoise0, name: "Denoise 0")
                                
                                ImageView(defaultImage: $finderItemImage, image: $animeScale2Denoise1, name: "Denoise 1")
                                
                                ImageView(defaultImage: $finderItemImage, image: $animeScale2Denoise2, name: "Denoise 2")
                                
                                ImageView(defaultImage: $finderItemImage, image: $animeScale2Denoise3, name: "Denoise 3")
                            }
                        }
                    }, label: {
                        Text("Anime scale 2x")
                            .font(.title)
                    })
                        .padding()
                        .frame(height: 300)
                    
                    GroupBox(content: {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ImageView(defaultImage: $finderItemImage, image: $photoScale2DenoiseNone, name: "Denoise None")
                                
                                ImageView(defaultImage: $finderItemImage, image: $photoScale2Denoise0, name: "Denoise 0")
                                
                                ImageView(defaultImage: $finderItemImage, image: $photoScale2Denoise1, name: "Denoise 1")
                                
                                ImageView(defaultImage: $finderItemImage, image: $photoScale2Denoise2, name: "Denoise 2")
                                
                                ImageView(defaultImage: $finderItemImage, image: $photoScale2Denoise3, name: "Denoise 3")
                            }
                        }
                    }, label: {
                        Text("Photo scale 2x")
                            .font(.title)
                    })
                        .padding()
                        .frame(height: 300)
                    
                }
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                for i in providers {
                    i.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, error in
                        guard error == nil else { return }
                        guard let urlData = urlData as? Data else { return }
                        guard let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                        guard FinderItem(at: url).image != nil else { return }
                        
                        self.finderItem = FinderItem(at: url)
                        self.finderItemImage = finderItem!.image!
                        return
                    }
                }
                
                return true
            }
        }
    }
}

struct ImageView: View {
    
    @Binding var defaultImage: NSImage?
    @Binding var image: NSImage?
    @State var name: String
    @State var showHint = false
    
    func openFile() {
        guard let image = image else {
            return
        }
        
        let path = "\(NSHomeDirectory())/\(name).png"
        image.write(to: path)
        _ = shell(["open \(path.replacingOccurrences(of: " ", with: "\\ "))"])
    }
    
    var body: some View {
        VStack {
            Image(nsImage: image ?? defaultImage!)
                .resizable()
                .renderingMode(image == nil ? .template : .original )
                .aspectRatio(contentMode: .fit)
                .cornerRadius(5)
                .popover(isPresented: $showHint) {
                    Text("Click to show detail")
                        .padding()
                }
            
            Text(name)
                .onHover { bool in
                    self.showHint = bool
                }
        }
        .onTapGesture(count: 1) {
            openFile()
        }
        .onTapGesture(count: 2) {
            openFile()
        }
        .contextMenu {
            Button("Open") {
               openFile()
            }
        }
    }
    
}

struct ComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        ComparisonView()
            
    }
}
