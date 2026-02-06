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
    let paceMin: Double
    let paceMax: Double
    let sessionDurationText: String?
    let sessionDurationSeconds: Int?
    
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

            VStack(alignment: .leading, spacing: 4) {
                Text("Input Level")
                    .font(.subheadline)
                InputLevelMeterView(level: inputLevel)
                HStack(spacing: 6) {
                    Text("Processing:")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text(processingLatencyStatus.rawValue)
                        .font(.footnote)
                        .foregroundColor(processingStatusColor(processingLatencyStatus))
                }
                if showSilenceWarning {
                    Text("No mic input detected")
                        .font(.footnote)
                        .foregroundColor(.orange)
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
        }
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
            paceMin: Constants.targetPaceMin,
            paceMax: Constants.targetPaceMax,
            sessionDurationText: "02:15",
            sessionDurationSeconds: 135
        )
            .padding()
    }
}
#endif
