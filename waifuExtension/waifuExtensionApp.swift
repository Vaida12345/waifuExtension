//
//  waifuExtensionApp.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI

@main
struct waifuExtensionApp: App {
    @State var isShowingComparisonWindow = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("Compare") {
                Button("Compare Models") {
                    ComparisonView().openInWindow(title: "Comparison", sender: self)
                }
            }
        }
    }
}

extension View {
    
    @discardableResult
    func openInWindow(title: String, sender: Any?) -> NSWindow {
        let controller = NSHostingController(rootView: self)
        let win = NSWindow(contentViewController: controller)
        win.contentViewController = controller
        win.title = title
        win.makeKeyAndOrderFront(sender)
        return win
    }
}
