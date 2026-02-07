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
    let inputLevel: Double
    let showSilenceWarning: Bool
    let showWaitingForSpeech: Bool
    let processingLatencyStatus: ProcessingLatencyStatus
    let processingLatencyAverage: TimeInterval
    let processingUtilizationStatus: ProcessingUtilizationStatus
    let processingUtilizationAverage: Double
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
        let metricColumns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        let crutchLevel = CrutchWordFeedback.level(for: crutchWords)
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Real-time Feedback")
                    .font(.headline)
                Spacer()
                if let elapsedText = ElapsedTimeFormatter.labelText(sessionDurationText) {
                    Text(elapsedText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            FeedbackCard(title: "Pace") {
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
                PaceRangeBar(
                    pace: pace,
                    paceMin: paceMin,
                    paceMax: paceMax,
                    indicatorColor: paceColor(pace)
                )
            }

            LazyVGrid(columns: metricColumns, spacing: 12) {
                FeedbackStatCard(
                    title: "Crutch Words",
                    value: "\(crutchWords)",
                    valueColor: crutchColor(crutchLevel),
                    subtitle: "Target: \u{2264} 5"
                )
                FeedbackStatCard(
                    title: "Pauses",
                    value: "\(pauseCount)",
                    valueColor: .primary,
                    subtitle: pauseDetailsText(rateText: pauseRateText)
                ) {
                    if let pauseRateText {
                        PauseRateBadge(text: pauseRateText)
                            .padding(.top, 2)
                    }
                }
            }

            FeedbackCard(title: "Input & Processing") {
                VStack(alignment: .leading, spacing: 8) {
                    InputLevelMeterView(level: inputLevel)
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
            return .blue // Too slow
        case .target:
            return .green // Good pace
        case .fast:
            return .red // Too fast
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
    let accessory: Accessory?

    init(
        title: String,
        value: String,
        valueColor: Color,
        subtitle: String? = nil,
        @ViewBuilder accessory: () -> Accessory? = { nil }
    ) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
        self.subtitle = subtitle
        self.accessory = accessory()
    }

    var body: some View {
        FeedbackCard(title: title) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .foregroundColor(valueColor)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let accessory {
                    accessory
                }
            }
        }
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
            inputLevel: 0.4,
            showSilenceWarning: false,
            showWaitingForSpeech: false,
            processingLatencyStatus: .ok,
            processingLatencyAverage: 0.012,
            processingUtilizationStatus: .ok,
            processingUtilizationAverage: 0.52,
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
