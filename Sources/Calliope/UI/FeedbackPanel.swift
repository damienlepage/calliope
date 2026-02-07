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
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Real-time Feedback")
                    .font(.headline)
                Spacer()
                if let elapsedText = ElapsedTimeFormatter.labelText(sessionDurationText) {
                    Text(elapsedText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 5)
            
            // Pace indicator
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 6) {
                        Text("Pace:")
                            .font(.subheadline)
                        Text(PaceFeedback.targetRangeText(minPace: paceMin, maxPace: paceMax))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Text(PaceFeedback.valueText(for: pace))
                            .font(.subheadline)
                            .foregroundColor(paceColor(pace))
                        Text(PaceFeedback.label(for: pace, minPace: paceMin, maxPace: paceMax))
                            .font(.subheadline)
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
            
            // Crutch words indicator
            HStack {
                Text("Crutch Words:")
                    .font(.subheadline)
                Spacer()
                Text("\(crutchWords)")
                    .font(.subheadline)
                    .foregroundColor(crutchWords > 5 ? .orange : .green)
            }
            
            // Pauses indicator
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Pauses:")
                        .font(.subheadline)
                    Spacer()
                    HStack(spacing: 6) {
                        Text("\(pauseCount)")
                            .font(.subheadline)
                        Text(pauseDetailsText(rateText: pauseRateText))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                if let pauseRateText {
                    PauseRateBadge(text: pauseRateText)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Input Level")
                    .font(.subheadline)
                InputLevelMeterView(level: inputLevel)
                HStack(spacing: 6) {
                    Text("Processing:")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text(ProcessingLatencyFormatter.statusText(
                        status: processingLatencyStatus,
                        average: processingLatencyAverage
                    ))
                        .font(.footnote)
                        .foregroundColor(processingStatusColor(processingLatencyStatus))
                }
                HStack(spacing: 6) {
                    Text("Load:")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text(ProcessingUtilizationFormatter.statusText(
                        status: processingUtilizationStatus,
                        average: processingUtilizationAverage
                    ))
                        .font(.footnote)
                        .foregroundColor(utilizationStatusColor(processingUtilizationStatus))
                }
                if let warningText = ProcessingLatencyFormatter.warningText(status: processingLatencyStatus) {
                    Text(warningText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if let warningText = ProcessingUtilizationFormatter.warningText(status: processingUtilizationStatus) {
                    Text(warningText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if let warningText = RecordingStorageWarningFormatter.warningText(status: storageStatus) {
                    Text(warningText)
                        .font(.footnote)
                        .foregroundColor(.orange)
                }
                if showSilenceWarning {
                    Text("No mic input detected")
                        .font(.footnote)
                        .foregroundColor(.orange)
                    Text("Check your microphone or input selection in Settings.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if showWaitingForSpeech {
                    Text("Waiting for speech")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
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
                    .fill(Color.secondary.opacity(0.15))
                Capsule()
                    .fill(Color.green.opacity(0.28))
                    .frame(width: barWidth * CGFloat(layout.targetWidth))
                    .offset(x: barWidth * CGFloat(layout.targetStart))
                Circle()
                    .fill(indicatorColor)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .offset(x: indicatorOffset, y: -1)
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
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
