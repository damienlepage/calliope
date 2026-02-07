//
//  PostSessionReviewTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class PostSessionReviewTests: XCTestCase {
    func testSelectsLongestDurationSummary() {
        let urlA = makeURL("a.wav")
        let urlB = makeURL("b.wav")
        let urlC = makeURL("c.wav")
        let summaries: [URL: AnalysisSummary] = [
            urlA: makeSummary(duration: 120, averageWPM: 110),
            urlB: makeSummary(duration: 300, averageWPM: 150),
            urlC: makeSummary(duration: 60, averageWPM: 90)
        ]
        let session = CompletedRecordingSession(
            sessionID: "session-1",
            recordingURLs: [urlA, urlB, urlC],
            createdAt: Date()
        )

        let review = PostSessionReview(
            session: session,
            summaryProvider: { summaries[$0] },
            durationProvider: { _ in nil }
        )

        XCTAssertEqual(review?.recordingURL, urlB)
        XCTAssertEqual(review?.paceText, "Avg pace: 150 WPM")
    }

    func testUsesDurationProviderWhenSummaryDurationMissing() {
        let urlA = makeURL("a.wav")
        let urlB = makeURL("b.wav")
        let summaries: [URL: AnalysisSummary] = [
            urlA: makeSummary(duration: 0, averageWPM: 100),
            urlB: makeSummary(duration: 0, averageWPM: 120)
        ]
        let durations: [URL: TimeInterval] = [
            urlA: 45,
            urlB: 90
        ]
        let session = CompletedRecordingSession(
            sessionID: "session-2",
            recordingURLs: [urlA, urlB],
            createdAt: Date()
        )

        let review = PostSessionReview(
            session: session,
            summaryProvider: { summaries[$0] },
            durationProvider: { durations[$0] }
        )

        XCTAssertEqual(review?.recordingURL, urlB)
    }

    func testFallbackMessageWhenSummaryMissing() {
        let urlA = makeURL("a.wav")
        let session = CompletedRecordingSession(
            sessionID: "session-3",
            recordingURLs: [urlA],
            createdAt: Date()
        )

        let review = PostSessionReview(
            session: session,
            summaryProvider: { _ in nil },
            durationProvider: { _ in 30 }
        )

        XCTAssertEqual(review?.summaryLines, [PostSessionReview.summaryFallbackText])
        XCTAssertNil(review?.summary)
    }

    private func makeSummary(duration: Double, averageWPM: Double) -> AnalysisSummary {
        AnalysisSummary(
            version: 1,
            createdAt: Date(),
            durationSeconds: duration,
            pace: AnalysisSummary.PaceStats(
                averageWPM: averageWPM,
                minWPM: averageWPM,
                maxWPM: averageWPM,
                totalWords: Int(averageWPM * max(duration / 60, 1))
            ),
            pauses: AnalysisSummary.PauseStats(count: 3, thresholdSeconds: 0.8, averageDurationSeconds: 1.2),
            crutchWords: AnalysisSummary.CrutchWordStats(totalCount: 2, counts: ["um": 2]),
            speaking: AnalysisSummary.SpeakingStats(timeSeconds: duration / 2, turnCount: 4)
        )
    }

    private func makeURL(_ name: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent(name)
    }
}
