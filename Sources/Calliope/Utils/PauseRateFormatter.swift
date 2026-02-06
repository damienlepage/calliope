//
//  PauseRateFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct PauseRateFormatter {
    static func rateText(pauseCount: Int, durationSeconds: Int?) -> String? {
        guard let durationSeconds, durationSeconds > 0 else {
            return nil
        }
        let minutes = Double(durationSeconds) / 60.0
        let safeMinutes = max(minutes, 1.0 / 60.0)
        let rate = Double(pauseCount) / safeMinutes
        return formatRate(rate)
    }

    private static func formatRate(_ rate: Double) -> String {
        let rounded = (rate * 10).rounded() / 10
        if rounded.rounded() == rounded {
            return "\(Int(rounded))/min"
        }
        return String(format: "%.1f/min", rounded)
    }
}
