//
//  TaskFlowApp.swift
//  TaskFlow
//
//  Created by stone on 2025/7/11.
//

import SwiftUI
import SwiftData

@main
struct TaskFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Plan.self,
            Task.self,
            Pomodoro.self,
            Review.self,
            AppSettings.self,
            RootData.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.action = #selector(menuBarIconClicked)
            button.target = self
        }
    }

    @objc func menuBarIconClicked() {
        NSApp.activate(ignoringOtherApps: true) // Bring the app to front
    }
}
