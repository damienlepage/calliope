//
//  ProcessingLatencyTracker.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum ProcessingLatencyStatus: String, Equatable {
    case ok = "OK"
    case high = "High"
    case critical = "Critical"
}

struct ProcessingLatencyTracker {
    private var samples: [TimeInterval]
    private var index: Int = 0
    private var count: Int = 0
    private var total: TimeInterval = 0

    let windowSize: Int
    let highThreshold: TimeInterval
    let criticalThreshold: TimeInterval

    init(
        windowSize: Int = Constants.processingLatencyWindowSize,
        highThreshold: TimeInterval = Constants.processingLatencyHighThreshold,
        criticalThreshold: TimeInterval = Constants.processingLatencyCriticalThreshold
    ) {
        let safeWindow = max(1, windowSize)
        let safeHigh = max(0, highThreshold)
        let safeCritical = max(safeHigh, criticalThreshold)
        self.windowSize = safeWindow
        self.highThreshold = safeHigh
        self.criticalThreshold = safeCritical
        self.samples = Array(repeating: 0, count: safeWindow)
    }

    init(windowSize: Int, threshold: TimeInterval) {
        self.init(
            windowSize: windowSize,
            highThreshold: threshold,
            criticalThreshold: TimeInterval.greatestFiniteMagnitude
        )
    }

    var average: TimeInterval {
        guard count > 0 else { return 0 }
        return total / Double(count)
    }

    var status: ProcessingLatencyStatus {
        if average >= criticalThreshold {
            return .critical
        }
        if average >= highThreshold {
            return .high
        }
        return .ok
    }

    mutating func record(duration: TimeInterval) -> ProcessingLatencyStatus {
        guard duration >= 0 else { return status }

        if count < windowSize {
            samples[count] = duration
            total += duration
            count += 1
        } else {
            total -= samples[index]
            samples[index] = duration
            total += duration
            index = (index + 1) % windowSize
        }

        return status
    }

    mutating func reset() {
        samples = Array(repeating: 0, count: windowSize)
        index = 0
        count = 0
        total = 0
    }
}
