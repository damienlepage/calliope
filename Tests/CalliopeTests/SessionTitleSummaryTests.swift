import XCTest
@testable import Calliope

final class SessionTitleSummaryTests: XCTestCase {
    func testSummaryFormattingIncludesKeyStats() {
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(),
            durationSeconds: 300,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 145.6,
                minWPM: 120,
                maxWPM: 170,
                totalWords: 728
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 4,
                thresholdSeconds: 0.8,
                averageDurationSeconds: 1.3
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 7,
                counts: ["um": 3, "like": 4]
            ),
            speaking: AnalysisSummary.SpeakingStats(timeSeconds: 95, turnCount: 3)
        )

        let summaryText = SessionTitleSummary(summary: summary)

        XCTAssertEqual(summaryText.paceText, "Avg pace: 146 WPM")
        XCTAssertEqual(summaryText.crutchText, "Crutch words: 7")
        XCTAssertEqual(summaryText.pauseText, "Pauses: 4")
        XCTAssertEqual(summaryText.speakingText, "Speaking time: 1:35 (32%)")
    }

    func testSummaryFormattingHandlesZeroDuration() {
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(),
            durationSeconds: 0,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 0,
                minWPM: 0,
                maxWPM: 0,
                totalWords: 0
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 0,
                thresholdSeconds: 0.8,
                averageDurationSeconds: 0
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 0,
                counts: [:]
            ),
            speaking: AnalysisSummary.SpeakingStats(timeSeconds: 0, turnCount: 0)
        )

        let summaryText = SessionTitleSummary(summary: summary)

        XCTAssertEqual(summaryText.speakingText, "Speaking time: 0:00")
    }
}
