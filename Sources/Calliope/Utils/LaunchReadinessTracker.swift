//
//  LaunchReadinessTracker.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

final class LaunchReadinessTracker {
    static let targetSeconds: TimeInterval = 2.0
    private let launchTimestamp: Date
    private(set) var sessionReadyAt: Date?

    init(now: Date = Date()) {
        launchTimestamp = now
    }

    func markSessionReady(now: Date = Date()) {
        guard sessionReadyAt == nil else { return }
        sessionReadyAt = now
    }

    var appLaunchAt: Date {
        launchTimestamp
    }

    var sessionReadyLatencySeconds: TimeInterval? {
        sessionReadyAt?.timeIntervalSince(launchTimestamp)
    }
}
