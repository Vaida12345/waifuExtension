//
//  waifuExtensionApp.swift
//  waifuExtension
//
//  Created by Vaida on 11/22/21.
//

import SwiftUI
import Support

@main
struct waifuExtensionApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    @StateObject private var modelDataProvider = ModelDataProvider.main
    @StateObject private var model = ModelCoordinator.main
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 620, idealWidth: 900, maxWidth: .infinity, minHeight: 360, idealHeight: 450, maxHeight: .infinity)
                .navigationTitle("")
                .environmentObject(modelDataProvider)
                .environmentObject(model)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        
        Settings {
            ConfigurationContainerView()
                .frame(width: 400)
                .environmentObject(modelDataProvider)
                .environmentObject(model)
        }
    }
    
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if FinderItem.temporaryDirectory.isExistence {
            FinderItem.temporaryDirectory.clear()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if FinderItem.temporaryDirectory.isExistence {
            FinderItem.temporaryDirectory.clear()
        }
        
        ModelDataProvider.main.save()
        ModelCoordinator.main.save()
    }
    
}
