//
//  CompactFeedbackOverlay.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation
import SwiftUI

struct CompactFeedbackOverlay: View {
    let pace: Double
    let crutchWords: Int
    let pauseCount: Int
    let pauseAverageDuration: TimeInterval
    let inputLevel: Double
    let showSilenceWarning: Bool
    let showWaitingForSpeech: Bool
    let processingLatencyStatus: ProcessingLatencyStatus
    let processingLatencyAverage: TimeInterval
    let processingUtilizationStatus: ProcessingUtilizationStatus
    let processingUtilizationAverage: Double
    let captureStatusText: String
    let paceMin: Double
    let paceMax: Double
    let sessionDurationText: String?
    let sessionDurationSeconds: Int?
    let storageStatus: RecordingStorageStatus

    var body: some View {
        let pauseRateText = PauseRateFormatter.rateText(
            pauseCount: pauseCount,
            durationSeconds: sessionDurationSeconds
        )
        VStack(alignment: .leading, spacing: 6) {
            if let sessionDurationText {
                Text(sessionDurationText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(captureStatusText)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                metric(
                    title: "Pace",
                    value: PaceFeedback.valueText(for: pace),
                    color: paceColor(pace),
                    subtitle: PaceFeedback.label(for: pace, minPace: paceMin, maxPace: paceMax)
                )
                metric(
                    title: "Crutch",
                    value: "\(crutchWords)",
                    color: crutchWords > 5 ? .orange : .green
                )
                metric(
                    title: "Pause",
                    value: "\(pauseCount)",
                    color: .primary,
                    subtitle: pauseSubtitleText(rateText: pauseRateText)
                )
            }
            InputLevelMeterView(level: inputLevel)
                .frame(width: 180)
            HStack(spacing: 6) {
                Text("Processing:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(ProcessingLatencyFormatter.statusText(
                    status: processingLatencyStatus,
                    average: processingLatencyAverage
                ))
                    .font(.caption)
                    .foregroundColor(processingStatusColor(processingLatencyStatus))
            }
            HStack(spacing: 6) {
                Text("Load:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(ProcessingUtilizationFormatter.statusText(
                    status: processingUtilizationStatus,
                    average: processingUtilizationAverage
                ))
                    .font(.caption)
                    .foregroundColor(utilizationStatusColor(processingUtilizationStatus))
            }
            if let warningText = RecordingStorageWarningFormatter.warningText(status: storageStatus) {
                Text(warningText)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            if showSilenceWarning {
                Text("No mic input detected")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            if showWaitingForSpeech {
                Text("Waiting for speech")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2))
        )
        .cornerRadius(12)
        .shadow(radius: 4)
    }

    private func metric(title: String, value: String, color: Color, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 52, alignment: .leading)
    }

    private func paceColor(_ pace: Double) -> Color {
        switch PaceFeedback.level(for: pace, minPace: paceMin, maxPace: paceMax) {
        case .idle:
            return .secondary
        case .slow:
            return .blue
        case .target:
            return .green
        case .fast:
            return .red
        }
    }

    private func pauseSubtitleText(rateText: String?) -> String {
        PauseDetailsFormatter.detailsText(
            pauseCount: pauseCount,
            averageDuration: pauseAverageDuration,
            rateText: rateText
        )
    }

    private func processingStatusColor(_ status: ProcessingLatencyStatus) -> Color {
        switch status {
        case .ok:
            return .green
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }

    private func utilizationStatusColor(_ status: ProcessingUtilizationStatus) -> Color {
        switch status {
        case .ok:
            return .green
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}

#if DEBUG
struct CompactFeedbackOverlay_Previews: PreviewProvider {
    static var previews: some View {
        CompactFeedbackOverlay(
            pace: 165,
            crutchWords: 2,
            pauseCount: 1,
            pauseAverageDuration: 0.9,
            inputLevel: 0.6,
            showSilenceWarning: false,
            showWaitingForSpeech: false,
            processingLatencyStatus: .ok,
            processingLatencyAverage: 0.009,
            processingUtilizationStatus: .ok,
            processingUtilizationAverage: 0.47,
            captureStatusText: "Input: Built-in Microphone · Capture: Standard mic",
            paceMin: Constants.targetPaceMin,
            paceMax: Constants.targetPaceMax,
            sessionDurationText: "00:42",
            sessionDurationSeconds: 42,
            storageStatus: .ok
        )
        .padding()
    }
}
#endif
