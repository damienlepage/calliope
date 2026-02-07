import XCTest
@testable import Calliope

@MainActor
final class RecordingDetailViewTests: XCTestCase {
    func testRecordingDetailViewBuilds() {
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(),
            durationSeconds: 120,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 135,
                minWPM: 110,
                maxWPM: 160,
                totalWords: 270
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 4,
                thresholdSeconds: 1.0,
                averageDurationSeconds: 1.2
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 2,
                counts: ["um": 2]
            ),
            processing: AnalysisSummary.ProcessingStats(
                latencyAverageMs: 12,
                latencyPeakMs: 20,
                utilizationAverage: 0.22,
                utilizationPeak: 0.4
            )
        )
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/recording.m4a"),
            modifiedAt: Date(),
            duration: 120,
            fileSizeBytes: 1024,
            summary: summary,
            integrityReport: nil
        )

        let view = RecordingDetailView(item: item, onEditTitle: nil)

        _ = view.body
    }

    func testRecordingDetailViewBuildsWithoutSummary() {
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/recording.m4a"),
            modifiedAt: Date(),
            duration: 65,
            fileSizeBytes: 512,
            summary: nil,
            integrityReport: RecordingIntegrityReport(
                createdAt: Date(),
                issues: [.missingSummary]
            )
        )

        let view = RecordingDetailView(item: item, onEditTitle: nil)

        _ = view.body
    }
}
