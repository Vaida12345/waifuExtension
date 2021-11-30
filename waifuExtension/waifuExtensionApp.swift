//
//  waifuExtensionApp.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI

@main
struct waifuExtensionApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                .onAppear {
                    let finderItem = FinderItem(at: "\(NSHomeDirectory())/tmp")
                    if finderItem.isExistence {
                        try! finderItem.removeFile()
                    }
                }
                .onExitCommand {
                    let finderItem = FinderItem(at: "\(NSHomeDirectory())/tmp")
                    if finderItem.isExistence {
                        try! finderItem.removeFile()
                    }
                }
        }
        .commands {
            CommandMenu("Compare") {
                Button("Compare Models") {
                    ComparisonView()
                        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                        .openInWindow(title: "Comparison", sender: self)
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
