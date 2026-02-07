//
//  SessionTitleSummary.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct SessionTitleSummary: Equatable {
    let paceText: String
    let crutchText: String
    let pauseText: String
    let speakingText: String

    init(summary: AnalysisSummary) {
        let pace = Int(summary.pace.averageWPM.rounded())
        let crutchCount = summary.crutchWords.totalCount
        let pauseCount = summary.pauses.count
        let speakingText = SessionTitleSummary.formatSpeaking(
            speakingSeconds: summary.speaking.timeSeconds,
            durationSeconds: summary.durationSeconds
        )

        self.paceText = "Avg pace: \(pace) WPM"
        self.crutchText = "Crutch words: \(crutchCount)"
        self.pauseText = "Pauses: \(pauseCount)"
        self.speakingText = "Speaking time: \(speakingText)"
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private static let durationWithHoursFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad, .dropLeading]
        return formatter
    }()

    private static func formatDuration(_ duration: TimeInterval) -> String {
        let clamped = max(0, duration)
        if clamped >= 3600 {
            let formatted = durationWithHoursFormatter.string(from: clamped) ?? "0:00"
            if formatted.hasPrefix("0") && formatted.count > 1 {
                return String(formatted.dropFirst())
            }
            return formatted
        }
        return durationFormatter.string(from: clamped) ?? "0:00"
    }

    private static func formatSpeaking(speakingSeconds: Double, durationSeconds: Double) -> String {
        let timeText = formatDuration(speakingSeconds)
        guard durationSeconds > 0 else {
            return timeText
        }
        let rawRatio = speakingSeconds / durationSeconds
        let clampedRatio = min(max(rawRatio, 0), 1)
        let percentText = String(format: "%.0f%%", clampedRatio * 100)
        return "\(timeText) (\(percentText))"
    }
}
