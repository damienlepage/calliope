//
//  ProcessingUtilizationTracker.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum ProcessingUtilizationStatus: String, Equatable {
    case ok = "OK"
    case high = "High"
    case critical = "Critical"
}

struct ProcessingUtilizationTracker {
    private var samples: [Double]
    private var index: Int = 0
    private var count: Int = 0
    private var total: Double = 0

    let windowSize: Int
    let highThreshold: Double
    let criticalThreshold: Double

    init(
        windowSize: Int = Constants.processingUtilizationWindowSize,
        highThreshold: Double = Constants.processingUtilizationHighThreshold,
        criticalThreshold: Double = Constants.processingUtilizationCriticalThreshold
    ) {
        let safeWindow = max(1, windowSize)
        let safeHigh = max(0, highThreshold)
        let safeCritical = max(safeHigh, criticalThreshold)
        self.windowSize = safeWindow
        self.highThreshold = safeHigh
        self.criticalThreshold = safeCritical
        self.samples = Array(repeating: 0, count: safeWindow)
    }

    var average: Double {
        guard count > 0 else { return 0 }
        return total / Double(count)
    }

    var status: ProcessingUtilizationStatus {
        if average >= criticalThreshold {
            return .critical
        }
        if average >= highThreshold {
            return .high
        }
        return .ok
    }

    mutating func record(utilization: Double) -> ProcessingUtilizationStatus {
        guard utilization >= 0 else { return status }

        if count < windowSize {
            samples[count] = utilization
            total += utilization
            count += 1
        } else {
            total -= samples[index]
            samples[index] = utilization
            total += utilization
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
