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
    let speakingTimeSeconds: TimeInterval
    let inputLevel: Double
    let showSilenceWarning: Bool
    let showWaitingForSpeech: Bool
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
        let speakingTimeText = SessionDurationFormatter.format(
            seconds: max(0, Int(speakingTimeSeconds.rounded()))
        )
        let crutchLevel = CrutchWordFeedback.level(for: crutchWords)
        let cardSpacing: CGFloat = 10
        let metricColumns = [
            GridItem(.flexible(), spacing: cardSpacing),
            GridItem(.flexible(), spacing: cardSpacing)
        ]
        let statusMessages = FeedbackStatusMessages.build(
            storageStatus: storageStatus,
            interruptionMessage: interruptionMessage,
            showSilenceWarning: showSilenceWarning,
            showWaitingForSpeech: showWaitingForSpeech
        )
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Live Feedback")
                    .font(.headline)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(captureStatusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Capture status")
                    .accessibilityValue(captureStatusText)
                    .fixedSize(horizontal: false, vertical: true)
                if let activeProfileLabel {
                    Text(activeProfileLabel)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Active profile")
                        .accessibilityValue(activeProfileLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            OverlayCard(title: "Pace") {
                ViewThatFits(in: .horizontal) {
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(PaceFeedback.valueText(for: pace))
                            .font(.title3)
                            .foregroundColor(paceColor(pace))
                        Text(PaceFeedback.label(for: pace, minPace: paceMin, maxPace: paceMax))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(PaceFeedback.targetRangeText(minPace: paceMin, maxPace: paceMax))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pace")
            .accessibilityValue(
                AccessibilityFormatting.paceValue(
                    pace: pace,
                    minPace: paceMin,
                    maxPace: paceMax
                )
            )

            LazyVGrid(columns: metricColumns, spacing: cardSpacing) {
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
                    subtitle: pauseSubtitleText(rateText: pauseRateText),
                    accessibilitySupplement: pauseRateText
                )
                OverlayStatCard(
                    title: "Speaking",
                    value: speakingTimeText,
                    valueColor: .primary,
                    subtitle: "Talk time"
                )
                OverlayCard(title: "Input Level") {
                    VStack(alignment: .leading, spacing: 6) {
                        InputLevelMeterView(level: inputLevel)
                            .frame(maxWidth: .infinity)
                        Text(inputLevelStatusText())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Input level")
                .accessibilityValue(
                    AccessibilityFormatting.inputLevelValue(
                        level: inputLevel,
                        statusText: inputLevelStatusText()
                    )
                )
                OverlayStatCard(
                    title: "Elapsed",
                    value: sessionDurationText ?? "—",
                    valueColor: .primary,
                    subtitle: "Session time"
                )
            }

            if !statusMessages.isEmpty {
                OverlayCard(title: "Session Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(statusMessages.warnings, id: \.self) { message in
                            feedbackWarning(message)
                        }
                        ForEach(statusMessages.notes, id: \.self) { message in
                            feedbackNote(message)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Session status")
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
            return Color(NSColor.systemBlue)
        case .target:
            return Color(NSColor.systemGreen)
        case .fast:
            return Color(NSColor.systemOrange)
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
            return Color(NSColor.systemGreen)
        case .caution:
            return Color(NSColor.systemOrange)
        }
    }

    private func feedbackNote(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func feedbackWarning(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.footnote)
            Text(text)
                .font(.footnote)
        }
        .foregroundColor(Color(NSColor.systemOrange))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.systemOrange).opacity(0.12))
        )
    }

    private func inputLevelStatusText() -> String {
        inputLevel < InputLevelMeter.meaningfulThreshold ? "Low signal" : "Active"
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
    let accessibilitySupplement: String?

    init(
        title: String,
        value: String,
        valueColor: Color,
        subtitle: String? = nil,
        accessibilitySupplement: String? = nil
    ) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
        self.subtitle = subtitle
        self.accessibilitySupplement = accessibilitySupplement
    }

    var body: some View {
        OverlayCard(title: title) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .foregroundColor(valueColor)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(
            AccessibilityFormatting.metricValue(
                value: value,
                subtitle: subtitle,
                accessory: accessibilitySupplement
            )
        )
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
            speakingTimeSeconds: 18,
            inputLevel: 0.6,
            showSilenceWarning: false,
            showWaitingForSpeech: false,
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
