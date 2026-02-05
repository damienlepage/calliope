//
//  WindowLevelController.swift
//  Calliope
//
//  Created on [Date]
//

import AppKit

enum WindowLevelController {
    static func apply(alwaysOnTop: Bool) {
        DispatchQueue.main.async {
            let level: NSWindow.Level = alwaysOnTop ? .floating : .normal
            for window in NSApp.windows {
                window.level = level
            }
        }
    }
}
