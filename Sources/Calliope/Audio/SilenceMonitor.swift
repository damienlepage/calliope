//
//  SilenceMonitor.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

final class SilenceMonitor {
    private let timeout: TimeInterval
    private let threshold: Double
    private let now: () -> Date
    private var lastMeaningfulInputAt: Date

    init(
        timeout: TimeInterval = 5.0,
        threshold: Double = InputLevelMeter.meaningfulThreshold,
        now: @escaping () -> Date = Date.init
    ) {
        self.timeout = timeout
        self.threshold = threshold
        self.now = now
        self.lastMeaningfulInputAt = now()
    }

    func reset() {
        lastMeaningfulInputAt = now()
    }

    func registerLevel(_ level: Double) {
        if level >= threshold {
            lastMeaningfulInputAt = now()
        }
    }

    func isSilenceWarningActive() -> Bool {
        now().timeIntervalSince(lastMeaningfulInputAt) >= timeout
    }
}
