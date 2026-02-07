//
//  CalliopeApp.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI
import AppKit

@main
struct CalliopeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var navigationState = AppNavigationState()
    @StateObject private var appState = CalliopeAppState()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .environmentObject(navigationState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            AppNavigationCommands(navigationState: navigationState)
            RecordingCommands()
            RecordingsCommands()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app is treated as a regular GUI app when launched via `swift run`.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
