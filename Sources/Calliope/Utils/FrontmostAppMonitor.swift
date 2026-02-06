//
//  FrontmostAppMonitor.swift
//  Calliope
//
//  Created on [Date]
//

import AppKit
import Combine

protocol FrontmostWorkspaceProviding {
    var frontmostApplication: NSRunningApplication? { get }
}

extension NSWorkspace: FrontmostWorkspaceProviding {}

final class FrontmostAppMonitor: ObservableObject {
    @Published private(set) var frontmostAppIdentifier: String?

    private let workspace: FrontmostWorkspaceProviding
    private let notificationCenter: NotificationCenter
    private var activationObserver: Any?

    init(
        workspace: FrontmostWorkspaceProviding = NSWorkspace.shared,
        notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter
    ) {
        self.workspace = workspace
        self.notificationCenter = notificationCenter
        frontmostAppIdentifier = workspace.frontmostApplication?.bundleIdentifier

        activationObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.frontmostAppIdentifier = app?.bundleIdentifier
                ?? workspace.frontmostApplication?.bundleIdentifier
        }
    }

    deinit {
        if let activationObserver {
            notificationCenter.removeObserver(activationObserver)
        }
    }

    func refresh() {
        frontmostAppIdentifier = workspace.frontmostApplication?.bundleIdentifier
    }
}
