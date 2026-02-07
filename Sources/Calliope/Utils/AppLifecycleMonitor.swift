//
//  AppLifecycleMonitor.swift
//  Calliope
//
//  Created on [Date]
//

import AppKit
import Foundation

final class AppLifecycleMonitor: ObservableObject {
    @Published private(set) var isActive: Bool

    private let notificationCenter: NotificationCenter
    private var observers: [NSObjectProtocol] = []

    init(
        notificationCenter: NotificationCenter = .default,
        initialIsActive: Bool = NSApplication.shared.isActive
    ) {
        self.notificationCenter = notificationCenter
        self.isActive = initialIsActive

        observers = [
            notificationCenter.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.isActive = true
            },
            notificationCenter.addObserver(
                forName: NSApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.isActive = false
            }
        ]
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
    }
}
