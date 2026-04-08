//
//  tiramaosuApp.swift
//  tiramaosu
//
//  Created by vyx on 2026-04-07.
//

import SwiftUI
import AppKit

@main
struct tiramaosuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panel = TimerOverlayPanel(
            contentRect: NSRect(x: 320, y: 320, width: 180, height: 156),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.contentView = NSHostingView(rootView: ContentView())
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.hidesOnDeactivate = false
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()

        self.panel = panel
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        panel?.level = .screenSaver
        panel?.orderFrontRegardless()
    }
}

final class TimerOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
