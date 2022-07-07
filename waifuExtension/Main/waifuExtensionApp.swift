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
    
    @AppStorage("hasSetup") private var isShowingSetup = true
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 620, idealWidth: 900, maxWidth: .infinity, minHeight: 360, idealHeight: 450, maxHeight: .infinity)
                .navigationTitle("")
                .sheet(isPresented: $isShowingSetup) {
                    WelcomeView()
                }
                .environmentObject(modelDataProvider)
                .environmentObject(model)
        }
        
        Settings {
            ConfigurationContainerView()
                .frame(width: 400)
                .environmentObject(modelDataProvider)
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
        
        ModelDataProvider.main.encode(to: .preferencesDirectory.with(subPath: "model.json"))
        ModelCoordinator.main.encode(to: .preferencesDirectory.with(subPath: "model coordinator.json"))
    }
    
}
