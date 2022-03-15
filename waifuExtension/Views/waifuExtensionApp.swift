//
//  waifuExtensionApp.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI

@main
struct waifuExtensionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 620, idealWidth: 900, maxWidth: .infinity, minHeight: 360, idealHeight: 450, maxHeight: .infinity)
                .navigationTitle("")
        }
        .commands {
            CommandMenu("Compare") {
                Button("Compare Waifu2x") {
                    ComparisonView()
                        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                        .openInWindow(title: "Comparison", sender: self)
                }
            }
        }
        
        Settings {
            ConfigurationView()
                .frame(width: 600, height: 200)
        }
    }
    
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let finderItem = FinderItem(at: "\(NSHomeDirectory())/tmp")
        if finderItem.isExistence {
            try! finderItem.removeFile()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        let finderItem = FinderItem(at: "\(NSHomeDirectory())/tmp")
        if finderItem.isExistence {
            try! finderItem.removeFile()
        }
    }
    
}
