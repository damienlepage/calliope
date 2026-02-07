//
//  RecordingDetailView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct RecordingDetailView: View {
    let item: RecordingItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.title2)
                    Text(item.detailMetadataText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let profileText = item.coachingProfileText {
                        Text(profileText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)

                if let warningText = item.integrityWarningText {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(warningText)
                            .font(.subheadline)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Recording issue")
                    .accessibilityValue(warningText)
                }

                if item.summary == nil {
                    Text("No analysis summary available for this recording.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    DetailSection(title: "Pace", lines: item.paceDetailLines)
                    DetailSection(title: "Pauses", lines: item.pauseDetailLines)
                    if !item.speakingDetailLines.isEmpty {
                        DetailSection(title: "Speaking Activity", lines: item.speakingDetailLines)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Crutch Words")
                            .font(.headline)
                        if item.crutchBreakdown.isEmpty {
                            Text("No crutch words detected.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(item.crutchBreakdown, id: \.word) { entry in
                                HStack {
                                    Text(entry.word)
                                    Spacer()
                                    Text("\(entry.count)")
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                                .accessibilityLabel(entry.word)
                                .accessibilityValue("\(entry.count) occurrences")
                            }
                        }
                    }

                    if !item.processingDetailLines.isEmpty {
                        DetailSection(title: "Processing", lines: item.processingDetailLines)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(minWidth: 420, minHeight: 320)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Recording Details")
                    .font(.headline)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}

private struct DetailSection: View {
    let title: String
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let summary = AnalysisSummary(
        version: 1,
        createdAt: Date(),
        durationSeconds: 180,
        pace: AnalysisSummary.PaceStats(
            averageWPM: 140,
            minWPM: 100,
            maxWPM: 180,
            totalWords: 420
        ),
        pauses: AnalysisSummary.PauseStats(
            count: 6,
            thresholdSeconds: 0.8,
            averageDurationSeconds: 1.4
        ),
        crutchWords: AnalysisSummary.CrutchWordStats(
            totalCount: 5,
            counts: ["um": 3, "you know": 2]
        ),
        processing: AnalysisSummary.ProcessingStats(
            latencyAverageMs: 14,
            latencyPeakMs: 28,
            utilizationAverage: 0.32,
            utilizationPeak: 0.74
        )
    )
    let item = RecordingItem(
        url: URL(fileURLWithPath: "/tmp/recording.m4a"),
        modifiedAt: Date(),
        duration: 180,
        fileSizeBytes: 2048,
        summary: summary,
        integrityReport: RecordingIntegrityReport(
            createdAt: Date(),
            issues: [.missingSummary]
        )
    )
    RecordingDetailView(item: item)
}
