//
//  WindowLevelController.swift
//  Calliope
//
//  Created on [Date]
//

import AppKit

protocol WindowLevelTarget: AnyObject {
    var level: NSWindow.Level { get set }
}

extension NSWindow: WindowLevelTarget {}

enum WindowLevelController {
    static func apply(alwaysOnTop: Bool) {
        apply(
            alwaysOnTop: alwaysOnTop,
            windowsProvider: { NSApp.windows },
            scheduler: { DispatchQueue.main.async(execute: $0) }
        )
    }

    static func apply(
        alwaysOnTop: Bool,
        windowsProvider: @escaping () -> [WindowLevelTarget],
        scheduler: (@escaping () -> Void) -> Void
    ) {
        scheduler {
            let level: NSWindow.Level = alwaysOnTop ? .floating : .normal
            for window in windowsProvider() {
                window.level = level
            }
        }
    }
}
