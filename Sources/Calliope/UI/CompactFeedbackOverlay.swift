//
//  CompactFeedbackOverlay.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct CompactFeedbackOverlay: View {
    let pace: Double
    let crutchWords: Int
    let pauseCount: Int
    let paceMin: Double
    let paceMax: Double

    var body: some View {
        HStack(spacing: 12) {
            metric(
                title: "Pace",
                value: "\(Int(pace))",
                color: paceColor(pace)
            )
            metric(
                title: "Crutch",
                value: "\(crutchWords)",
                color: crutchWords > 5 ? .orange : .green
            )
            metric(
                title: "Pause",
                value: "\(pauseCount)",
                color: .primary
            )
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

    private func metric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(minWidth: 52, alignment: .leading)
    }

    private func paceColor(_ pace: Double) -> Color {
        switch PaceFeedback.level(for: pace, minPace: paceMin, maxPace: paceMax) {
        case .slow:
            return .blue
        case .target:
            return .green
        case .fast:
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
            paceMin: Constants.targetPaceMin,
            paceMax: Constants.targetPaceMax
        )
        .padding()
    }
}
#endif
