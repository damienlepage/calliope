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

    private static func formatDuration(_ duration: TimeInterval) -> String {
        let clamped = max(0, duration)
        let totalSeconds = Int(clamped.rounded())
        if totalSeconds >= 3600 {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
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
