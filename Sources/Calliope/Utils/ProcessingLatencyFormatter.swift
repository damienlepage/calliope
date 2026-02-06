//
//  ProcessingLatencyFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct ProcessingLatencyFormatter {
    static func statusText(status: ProcessingLatencyStatus, average: TimeInterval) -> String {
        let clampedAverage = max(0, average)
        let milliseconds = Int((clampedAverage * 1000).rounded())
        return "\(status.rawValue) (\(milliseconds) ms avg)"
    }

    static func warningText(status: ProcessingLatencyStatus) -> String? {
        guard status == .high else { return nil }
        return "High processing latency. Feedback may lag."
    }
}
