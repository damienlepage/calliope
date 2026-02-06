//
//  PauseDetailsFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct PauseDetailsFormatter {
    static func detailsText(pauseCount: Int, averageDuration: TimeInterval, rateText: String?) -> String {
        let averageText = pauseCount > 0 ? "Avg \(formatSeconds(averageDuration))" : "Avg --"
        var details = [averageText]
        if let rateText {
            details.append(rateText)
        }
        return details.joined(separator: " • ")
    }

    private static func formatSeconds(_ seconds: TimeInterval) -> String {
        String(format: "%.1fs", seconds)
    }
}
