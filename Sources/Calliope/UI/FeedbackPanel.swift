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
    let paceMin: Double
    let paceMax: Double
    let sessionDurationText: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Real-time Feedback")
                    .font(.headline)
                Spacer()
                if let sessionDurationText {
                    Text(sessionDurationText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 5)
            
            // Pace indicator
            HStack {
                Text("Pace:")
                    .font(.subheadline)
                Spacer()
                HStack(spacing: 6) {
                    Text("\(Int(pace)) WPM")
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
                    Text("Avg \(pauseAverageDurationText(pauseAverageDuration))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Input Level")
                    .font(.subheadline)
                InputLevelMeterView(level: inputLevel)
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
        case .slow:
            return .blue // Too slow
        case .target:
            return .green // Good pace
        case .fast:
            return .red // Too fast
        }
    }

    private func pauseAverageDurationText(_ duration: TimeInterval) -> String {
        String(format: "%.1fs", duration)
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
            paceMin: Constants.targetPaceMin,
            paceMax: Constants.targetPaceMax,
            sessionDurationText: "02:15"
        )
            .padding()
    }
}
#endif
