//
//  PerformanceDiagnosticsFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct PerformanceDiagnosticsFormatter {
    static func utilizationSummary(average: Double, peak: Double) -> String {
        let averageText = percentText(average)
        let peakText = percentText(peak)
        return "Utilization avg/peak: \(averageText) / \(peakText)"
    }

    private static func percentText(_ value: Double) -> String {
        guard value.isFinite else { return "--" }
        let percent = max(0, value) * 100
        return String(format: "%.0f%%", percent.rounded())
    }
}
