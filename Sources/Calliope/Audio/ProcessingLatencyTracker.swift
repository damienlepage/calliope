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
}

struct ProcessingLatencyTracker {
    private var samples: [TimeInterval]
    private var index: Int = 0
    private var count: Int = 0
    private var total: TimeInterval = 0

    let windowSize: Int
    let threshold: TimeInterval

    init(
        windowSize: Int = Constants.processingLatencyWindowSize,
        threshold: TimeInterval = Constants.processingLatencyHighThreshold
    ) {
        let safeWindow = max(1, windowSize)
        self.windowSize = safeWindow
        self.threshold = threshold
        self.samples = Array(repeating: 0, count: safeWindow)
    }

    var average: TimeInterval {
        guard count > 0 else { return 0 }
        return total / Double(count)
    }

    var status: ProcessingLatencyStatus {
        average >= threshold ? .high : .ok
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
