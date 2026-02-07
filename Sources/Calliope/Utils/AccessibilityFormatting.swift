//
//  AccessibilityFormatting.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum AccessibilityFormatting {
    static func paceValue(pace: Double, minPace: Double, maxPace: Double) -> String {
        let paceText = PaceFeedback.valueText(for: pace)
        let paceLabel = PaceFeedback.label(for: pace, minPace: minPace, maxPace: maxPace)
        let targetRange = PaceFeedback.targetRangeText(minPace: minPace, maxPace: maxPace)
        return [paceText, paceLabel, targetRange]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    static func inputLevelValue(level: Double, statusText: String) -> String {
        let percent = percentText(for: level)
        return [statusText, percent]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    static func metricValue(value: String, subtitle: String?, accessory: String?) -> String {
        [value, subtitle, accessory]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    static func percentText(for level: Double) -> String {
        let clamped = max(0, min(level, 1))
        let percentValue = Int((clamped * 100).rounded())
        return "\(percentValue)%"
    }

    static func warningValue(text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Warning" : trimmed
    }

    static func statusValue(warnings: [String], notes: [String]) -> String {
        let warningText = warnings
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "; ")
        let noteText = notes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "; ")
        var parts: [String] = []
        if !warningText.isEmpty {
            parts.append("Warnings: \(warningText)")
        }
        if !noteText.isEmpty {
            parts.append("Notes: \(noteText)")
        }
        return parts.isEmpty ? "No status updates" : parts.joined(separator: ". ")
    }
}
