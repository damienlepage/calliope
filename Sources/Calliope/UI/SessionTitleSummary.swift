//
//  SessionTitleSummary.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct SessionTitleSummary: Equatable {
    let durationText: String
    let paceText: String
    let crutchText: String
    let pauseText: String
    let pauseRateText: String
    let speakingText: String
    let turnsText: String

    init(summary: AnalysisSummary) {
        let pace = Int(summary.pace.averageWPM.rounded())
        let crutchCount = summary.crutchWords.totalCount
        let pauseCount = summary.pauses.count
        let durationText = SessionTitleSummary.formatDuration(summary.durationSeconds)
        let pauseRateText = SessionTitleSummary.formatPausesPerMinute(
            count: pauseCount,
            durationSeconds: summary.durationSeconds
        ) ?? "n/a"
        let speakingText = SessionTitleSummary.formatSpeaking(
            speakingSeconds: summary.speaking.timeSeconds,
            durationSeconds: summary.durationSeconds
        )

        self.durationText = "Duration: \(durationText)"
        self.paceText = "Avg pace: \(pace) WPM"
        self.crutchText = "Crutch words: \(crutchCount)"
        self.pauseText = "Pauses: \(pauseCount)"
        self.pauseRateText = "Pauses/min: \(pauseRateText)"
        self.speakingText = "Speaking time: \(speakingText)"
        self.turnsText = "Turns: \(summary.speaking.turnCount)"
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

    private static func formatPausesPerMinute(count: Int, durationSeconds: Double) -> String? {
        guard durationSeconds > 0 else { return nil }
        let safeDuration = max(durationSeconds, 1)
        let minutes = safeDuration / 60
        let rate = Double(count) / minutes
        return String(format: "%.1f", rate)
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
