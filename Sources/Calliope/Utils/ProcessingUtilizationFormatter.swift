//
//  ProcessingUtilizationFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct ProcessingUtilizationFormatter {
    static func statusText(status: ProcessingUtilizationStatus, average: Double) -> String {
        let clampedAverage = max(0, average)
        let percentage = Int((clampedAverage * 100).rounded())
        return "\(status.rawValue) (\(percentage)% avg)"
    }

    static func warningText(status: ProcessingUtilizationStatus) -> String? {
        switch status {
        case .ok:
            return nil
        case .high:
            return "High processing load. Feedback may lag."
        case .critical:
            return "Critical processing load. Feedback may lag."
        }
    }
}
