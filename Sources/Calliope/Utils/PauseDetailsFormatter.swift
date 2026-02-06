//
//  PauseDetailsFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct PauseDetailsFormatter {
    static func detailsText(averageDuration: TimeInterval, rateText: String?) -> String {
        var details = ["Avg \(formatSeconds(averageDuration))"]
        if let rateText {
            details.append(rateText)
        }
        return details.joined(separator: " • ")
    }

    private static func formatSeconds(_ seconds: TimeInterval) -> String {
        String(format: "%.1fs", seconds)
    }
}
