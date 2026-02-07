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
    let interruptionMessage: String?
    let activeProfileLabel: String?

    var body: some View {
        let pauseRateText = PauseRateFormatter.rateText(
            pauseCount: pauseCount,
            durationSeconds: sessionDurationSeconds
        )
        let crutchLevel = CrutchWordFeedback.level(for: crutchWords)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Live Feedback")
                    .font(.headline)
                Spacer()
                if let elapsedText = ElapsedTimeFormatter.labelText(sessionDurationText) {
                    Text(elapsedText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(captureStatusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                if let activeProfileLabel {
                    Text(activeProfileLabel)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            OverlayCard(title: "Pace") {
                HStack(alignment: .firstTextBaseline) {
                    Text(PaceFeedback.valueText(for: pace))
                        .font(.title3)
                        .foregroundColor(paceColor(pace))
                    Text(PaceFeedback.label(for: pace, minPace: paceMin, maxPace: paceMax))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(PaceFeedback.targetRangeText(minPace: paceMin, maxPace: paceMax))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 10) {
                OverlayStatCard(
                    title: "Crutch Words",
                    value: "\(crutchWords)",
                    valueColor: crutchColor(crutchLevel),
                    subtitle: "Target: \u{2264} 5"
                )
                OverlayStatCard(
                    title: "Pauses",
                    value: "\(pauseCount)",
                    valueColor: .primary,
                    subtitle: pauseSubtitleText(rateText: pauseRateText)
                )
            }

            OverlayCard(title: "Input & Processing") {
                VStack(alignment: .leading, spacing: 8) {
                    InputLevelMeterView(level: inputLevel)
                        .frame(width: 180)
                    statusLine(
                        label: "Processing",
                        value: ProcessingLatencyFormatter.statusText(
                            status: processingLatencyStatus,
                            average: processingLatencyAverage
                        ),
                        color: processingStatusColor(processingLatencyStatus)
                    )
                    statusLine(
                        label: "Load",
                        value: ProcessingUtilizationFormatter.statusText(
                            status: processingUtilizationStatus,
                            average: processingUtilizationAverage
                        ),
                        color: utilizationStatusColor(processingUtilizationStatus)
                    )
                    if let warningText = ProcessingLatencyFormatter.warningText(status: processingLatencyStatus) {
                        feedbackNote(warningText)
                    }
                    if let warningText = ProcessingUtilizationFormatter.warningText(status: processingUtilizationStatus) {
                        feedbackNote(warningText)
                    }
                    if let warningText = RecordingStorageWarningFormatter.warningText(status: storageStatus) {
                        feedbackWarning(warningText)
                    }
                    if let interruptionMessage {
                        feedbackWarning(interruptionMessage)
                    }
                    if showSilenceWarning {
                        feedbackWarning("No mic input detected")
                        feedbackNote("Check your microphone or input selection in Settings.")
                    }
                    if showWaitingForSpeech {
                        feedbackNote("Waiting for speech")
                    }
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.15))
        )
        .cornerRadius(12)
        .shadow(radius: 4)
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

    private func crutchColor(_ level: CrutchWordFeedbackLevel) -> Color {
        switch level {
        case .calm:
            return .green
        case .caution:
            return .orange
        }
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

    private func statusLine(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(label):")
                .font(.footnote)
                .foregroundColor(.secondary)
            Text(value)
                .font(.footnote)
                .foregroundColor(color)
        }
    }

    private func feedbackNote(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func feedbackWarning(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.orange)
    }
}

private struct OverlayCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            content
        }
        .padding(10)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.12))
        )
        .cornerRadius(10)
    }
}

private struct OverlayStatCard: View {
    let title: String
    let value: String
    let valueColor: Color
    let subtitle: String?

    init(
        title: String,
        value: String,
        valueColor: Color,
        subtitle: String? = nil
    ) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
        self.subtitle = subtitle
    }

    var body: some View {
        OverlayCard(title: title) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .foregroundColor(valueColor)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
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
            storageStatus: .ok,
            interruptionMessage: "Audio input changed. Recording continues with the new device.",
            activeProfileLabel: "Profile: Default (App: Default)"
        )
        .padding()
    }
}
#endif
