//
//  FeedbackPanel.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation
import SwiftUI

struct FeedbackPanel: View {
    let pace: Double // words per minute
    let crutchWords: Int
    let pauseCount: Int
    let pauseAverageDuration: TimeInterval
    let speakingTimeSeconds: TimeInterval
    let inputLevel: Double
    let showSilenceWarning: Bool
    let showWaitingForSpeech: Bool
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
        let speakingTimeText = SessionDurationFormatter.format(
            seconds: max(0, Int(speakingTimeSeconds.rounded()))
        )
        let cardSpacing: CGFloat = 12
        let metricColumns = [
            GridItem(.flexible(), spacing: cardSpacing),
            GridItem(.flexible(), spacing: cardSpacing)
        ]
        let crutchLevel = CrutchWordFeedback.level(for: crutchWords)
        let statusMessages = FeedbackStatusMessages.build(
            storageStatus: storageStatus,
            interruptionMessage: nil,
            showSilenceWarning: showSilenceWarning,
            showWaitingForSpeech: showWaitingForSpeech
        )
        let crutchStatusText = CrutchWordFeedback.statusText(for: crutchWords)
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Real-time Feedback")
                    .font(.headline)
                Spacer()
            }

            FeedbackCard(title: "Pace") {
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
                PaceRangeBar(
                    pace: pace,
                    paceMin: paceMin,
                    paceMax: paceMax,
                    indicatorColor: paceColor(pace)
                )
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
                FeedbackStatCard(
                    title: "Crutch Words",
                    value: "\(crutchWords)",
                    valueColor: crutchColor(crutchLevel),
                    subtitle: "Status: \(crutchStatusText) · Target: \u{2264} 5"
                )
                FeedbackStatCard(
                    title: "Pauses",
                    value: "\(pauseCount)",
                    valueColor: .primary,
                    subtitle: pauseDetailsText(rateText: pauseRateText),
                    accessibilitySupplement: pauseRateText
                ) {
                    if let pauseRateText {
                        PauseRateBadge(text: pauseRateText)
                            .padding(.top, 2)
                    }
                }
                FeedbackStatCard(
                    title: "Speaking",
                    value: speakingTimeText,
                    valueColor: .primary,
                    subtitle: "Talk time"
                )
                FeedbackCard(title: "Input Level") {
                    VStack(alignment: .leading, spacing: 6) {
                        InputLevelMeterView(level: inputLevel)
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
                FeedbackStatCard(
                    title: "Elapsed",
                    value: sessionDurationText ?? "—",
                    valueColor: .primary,
                    subtitle: "Session time"
                )
            }

            if !statusMessages.isEmpty {
                FeedbackCard(title: "Session Status") {
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
                .accessibilityValue(
                    AccessibilityFormatting.statusValue(
                        warnings: statusMessages.warnings,
                        notes: statusMessages.notes
                    )
                )
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.15))
        )
        .cornerRadius(12)
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

    private func pauseDetailsText(rateText: String?) -> String {
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Warning")
        .accessibilityValue(AccessibilityFormatting.warningValue(text: text))
    }

    private func inputLevelStatusText() -> String {
        inputLevel < InputLevelMeter.meaningfulThreshold ? "Low signal" : "Active"
    }
}

private struct PaceRangeBar: View {
    let pace: Double
    let paceMin: Double
    let paceMax: Double
    let indicatorColor: Color

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let layout = PaceRangeBarLayout.compute(
                pace: pace,
                minPace: paceMin,
                maxPace: paceMax
            )
            let indicatorSize: CGFloat = 8
            let indicatorOffset = max(
                0,
                min(
                    barWidth - indicatorSize,
                    barWidth * CGFloat(layout.pacePosition) - indicatorSize / 2
                )
            )

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                Capsule()
                    .fill(Color.green.opacity(0.24))
                    .frame(width: barWidth * CGFloat(layout.targetWidth))
                    .offset(x: barWidth * CGFloat(layout.targetStart))
                Circle()
                    .fill(indicatorColor)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .offset(x: indicatorOffset, y: -1)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

}

private struct FeedbackCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            content
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.12))
        )
        .cornerRadius(10)
    }
}

private struct FeedbackStatCard<Accessory: View>: View {
    let title: String
    let value: String
    let valueColor: Color
    let subtitle: String?
    let accessibilitySupplement: String?
    let accessory: Accessory

    init(
        title: String,
        value: String,
        valueColor: Color,
        subtitle: String? = nil,
        accessibilitySupplement: String? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
        self.subtitle = subtitle
        self.accessibilitySupplement = accessibilitySupplement
        self.accessory = accessory()
    }

    var body: some View {
        FeedbackCard(title: title) {
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
                accessory
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

private extension FeedbackStatCard where Accessory == EmptyView {
    init(
        title: String,
        value: String,
        valueColor: Color,
        subtitle: String? = nil,
        accessibilitySupplement: String? = nil
    ) {
        self.init(
            title: title,
            value: value,
            valueColor: valueColor,
            subtitle: subtitle,
            accessibilitySupplement: accessibilitySupplement,
            accessory: { EmptyView() }
        )
    }
}

private struct PauseRateBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
            )
            .accessibilityLabel("Pause rate \(text)")
    }
}

#if DEBUG
struct FeedbackPanel_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackPanel(
            pace: 150,
            crutchWords: 3,
            pauseCount: 2,
            pauseAverageDuration: 1.4,
            speakingTimeSeconds: 72,
            inputLevel: 0.4,
            showSilenceWarning: false,
            showWaitingForSpeech: false,
            paceMin: Constants.targetPaceMin,
            paceMax: Constants.targetPaceMax,
            sessionDurationText: "02:15",
            sessionDurationSeconds: 135,
            storageStatus: .ok
        )
            .padding()
    }
}
#endif
