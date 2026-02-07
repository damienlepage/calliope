import XCTest
@testable import Calliope

final class PostSessionReviewCoordinatorTests: XCTestCase {
    func testCompletedSessionSetsReviewAndPendingTitle() {
        let session = CompletedRecordingSession(
            sessionID: "session-1",
            recordingURLs: [URL(fileURLWithPath: "/tmp/test-1.wav")],
            createdAt: Date()
        )
        let review = PostSessionReview(
            session: session,
            summaryProvider: { _ in Self.makeSummary(duration: 120) },
            durationProvider: { _ in 120 }
        )
        var coordinator = PostSessionReviewCoordinator()

        coordinator.handleCompletedSession(session) { _ in review }

        XCTAssertEqual(coordinator.pendingSessionForTitle, session)
        XCTAssertEqual(coordinator.lastCompletedSession, session)
        XCTAssertEqual(coordinator.postSessionReview, review)
        XCTAssertEqual(coordinator.sessionTitleDraft, "")
    }

    func testTitleSkippedKeepsReviewAndClearsPending() {
        let session = CompletedRecordingSession(
            sessionID: "session-2",
            recordingURLs: [URL(fileURLWithPath: "/tmp/test-2.wav")],
            createdAt: Date()
        )
        var coordinator = PostSessionReviewCoordinator(
            pendingSessionForTitle: session,
            lastCompletedSession: session,
            postSessionReview: PostSessionReview(
                session: session,
                summaryProvider: { _ in Self.makeSummary(duration: 90) },
                durationProvider: { _ in 90 }
            ),
            sessionTitleDraft: "Draft"
        )

        coordinator.handleTitleSkipped()

        XCTAssertNil(coordinator.pendingSessionForTitle)
        XCTAssertEqual(coordinator.lastCompletedSession, session)
        XCTAssertNotNil(coordinator.postSessionReview)
        XCTAssertEqual(coordinator.sessionTitleDraft, "")
    }

    func testRecordingStartResetsPostSessionState() {
        let session = CompletedRecordingSession(
            sessionID: "session-3",
            recordingURLs: [URL(fileURLWithPath: "/tmp/test-3.wav")],
            createdAt: Date()
        )
        var coordinator = PostSessionReviewCoordinator(
            pendingSessionForTitle: session,
            lastCompletedSession: session,
            postSessionReview: PostSessionReview(
                session: session,
                summaryProvider: { _ in Self.makeSummary(duration: 60) },
                durationProvider: { _ in 60 }
            ),
            sessionTitleDraft: "Draft"
        )

        coordinator.handleRecordingStarted()

        XCTAssertNil(coordinator.pendingSessionForTitle)
        XCTAssertNil(coordinator.lastCompletedSession)
        XCTAssertNil(coordinator.postSessionReview)
        XCTAssertEqual(coordinator.sessionTitleDraft, "")
    }

    func testEditTitleRestoresPendingSession() {
        let session = CompletedRecordingSession(
            sessionID: "session-4",
            recordingURLs: [URL(fileURLWithPath: "/tmp/test-4.wav")],
            createdAt: Date()
        )
        var coordinator = PostSessionReviewCoordinator(
            pendingSessionForTitle: nil,
            lastCompletedSession: session,
            postSessionReview: nil,
            sessionTitleDraft: ""
        )

        coordinator.handleEditTitle()

        XCTAssertEqual(coordinator.pendingSessionForTitle, session)
    }

    private static func makeSummary(duration: Double) -> AnalysisSummary {
        AnalysisSummary(
            version: 1,
            createdAt: Date(),
            durationSeconds: duration,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 120,
                minWPM: 100,
                maxWPM: 140,
                totalWords: 300
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 2,
                thresholdSeconds: 0.8,
                averageDurationSeconds: 1.1
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 1,
                counts: ["um": 1]
            ),
            speaking: AnalysisSummary.SpeakingStats(timeSeconds: duration / 2, turnCount: 3)
        )
    }
}
