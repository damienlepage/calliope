//
//  RecordingListViewModelTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import Combine
import Foundation
import XCTest
@testable import Calliope

@MainActor
final class RecordingListViewModelTests: XCTestCase {
    private final class MockRecordingManager: RecordingManaging {
        var recordings: [URL]
        var deleted: [URL] = []
        var deleteAllCount = 0
        var loadCount = 0
        var backfillCount = 0
        var backfillTargets: [[URL]] = []
        var deleteOlderCount = 0
        var deleteOlderCutoff: Date?
        var cleanupCount = 0
        var cleanupTargets: [[URL]] = []
        var recordingsDirectory = URL(fileURLWithPath: "/tmp/CalliopeRecordings")
        var deleteError: Error?
        var deleteAllError: Error?

        init(recordings: [URL]) {
            self.recordings = recordings
        }

        func getAllRecordings() -> [URL] {
            loadCount += 1
            return recordings
        }

        func backfillMetadataIfNeeded(for recordings: [URL]) {
            backfillCount += 1
            backfillTargets.append(recordings)
        }

        func cleanupOrphanedMetadata(for recordings: [URL]) {
            cleanupCount += 1
            cleanupTargets.append(recordings)
        }

        func deleteRecording(at url: URL) throws {
            if let deleteError {
                throw deleteError
            }
            deleted.append(url)
            recordings.removeAll { $0 == url }
        }

        func deleteAllRecordings() throws {
            if let deleteAllError {
                throw deleteAllError
            }
            deleteAllCount += 1
            recordings.removeAll()
        }

        func deleteRecordings(olderThan cutoff: Date) -> Int {
            deleteOlderCount += 1
            deleteOlderCutoff = cutoff
            return 0
        }

        func recordingsDirectoryURL() -> URL {
            recordingsDirectory
        }
    }

    private final class SpyWorkspace: WorkspaceOpening {
        private(set) var selections: [[URL]] = []

        func activateFileViewerSelecting(_ fileURLs: [URL]) {
            selections.append(fileURLs)
        }
    }

    private final class MockAudioPlayer: AudioPlaying {
        let url: URL
        var isPlaying: Bool { isPlayingFlag }
        var onPlaybackEnded: (() -> Void)?
        private(set) var playCount = 0
        private(set) var pauseCount = 0
        private(set) var stopCount = 0
        private var isPlayingFlag = false

        init(url: URL) {
            self.url = url
        }

        func play() -> Bool {
            playCount += 1
            isPlayingFlag = true
            return true
        }

        func pause() {
            pauseCount += 1
            isPlayingFlag = false
        }

        func stop() {
            stopCount += 1
            isPlayingFlag = false
        }
    }

    private final class PlayerStore {
        var players: [URL: MockAudioPlayer] = [:]
    }

    private func makeViewModelWithPlayback(
        recordings: [URL]
    ) -> (RecordingListViewModel, MockRecordingManager, PlayerStore) {
        let manager = MockRecordingManager(recordings: recordings)
        let store = PlayerStore()
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            audioPlayerFactory: { url in
                let player = MockAudioPlayer(url: url)
                store.players[url] = player
                return player
            }
        )
        return (viewModel, manager, store)
    }

    func testLoadRecordingsSortsNewestFirst() {
        let urlA = URL(fileURLWithPath: "/tmp/a.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/b.wav")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let dates: [URL: Date] = [
            urlA: Date(timeIntervalSince1970: 10),
            urlB: Date(timeIntervalSince1970: 20)
        ]
        let durations: [URL: TimeInterval] = [
            urlA: 12.5,
            urlB: 42.0
        ]
        let sizes: [URL: Int] = [
            urlA: 1024,
            urlB: 2048
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { dates[$0] ?? .distantPast },
            durationProvider: { durations[$0] },
            fileSizeProvider: { sizes[$0] }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(viewModel.recordings.map(\.url), [urlB, urlA])
        XCTAssertEqual(viewModel.recordings.map(\.modifiedAt), [dates[urlB]!, dates[urlA]!])
        XCTAssertEqual(viewModel.recordings.map(\.duration), [durations[urlB]!, durations[urlA]!])
        XCTAssertEqual(viewModel.recordings.map(\.fileSizeBytes), [sizes[urlB]!, sizes[urlA]!])
    }

    func testItemForURLUsesProviders() {
        let url = URL(fileURLWithPath: "/tmp/review.m4a")
        let expectedDate = Date(timeIntervalSince1970: 42)
        let expectedDuration: TimeInterval = 180
        let expectedSize = 2048
        let expectedSummary = AnalysisSummary(
            version: 1,
            createdAt: Date(timeIntervalSince1970: 10),
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
            speaking: AnalysisSummary.SpeakingStats(timeSeconds: 72, turnCount: 6)
        )
        let expectedReport = RecordingIntegrityReport(
            createdAt: Date(timeIntervalSince1970: 11),
            issues: [.missingSummary]
        )
        let expectedMetadata = RecordingMetadata(
            title: "Session Review",
            createdAt: Date(timeIntervalSince1970: 12),
            coachingProfileID: UUID(),
            coachingProfileName: "Focused"
        )
        let viewModel = RecordingListViewModel(
            manager: MockRecordingManager(recordings: []),
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in expectedDate },
            durationProvider: { _ in expectedDuration },
            fileSizeProvider: { _ in expectedSize },
            summaryProvider: { _ in expectedSummary },
            integrityReportProvider: { _ in expectedReport },
            metadataProvider: { _ in expectedMetadata }
        )

        let item = viewModel.item(for: url)

        XCTAssertEqual(item.url, url)
        XCTAssertEqual(item.modifiedAt, expectedDate)
        XCTAssertEqual(item.duration, expectedDuration)
        XCTAssertEqual(item.fileSizeBytes, expectedSize)
        XCTAssertEqual(item.summary, expectedSummary)
        XCTAssertEqual(item.integrityReport, expectedReport)
        XCTAssertEqual(item.metadata, expectedMetadata)
    }

    func testSortUsesSessionDateFromMetadata() {
        let urlA = URL(fileURLWithPath: "/tmp/a.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/b.m4a")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let modifiedDates: [URL: Date] = [
            urlA: Date(timeIntervalSince1970: 300),
            urlB: Date(timeIntervalSince1970: 50)
        ]
        let createdAtA = Date(timeIntervalSince1970: 1_700_000_000)
        let createdAtB = Date(timeIntervalSince1970: 1_700_000_100)
        let metadata: [URL: RecordingMetadata] = [
            urlA: RecordingMetadata(title: "A", createdAt: createdAtA),
            urlB: RecordingMetadata(title: "B", createdAt: createdAtB)
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { modifiedDates[$0] ?? .distantPast },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            metadataProvider: { metadata[$0] }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(viewModel.recordings.map(\.url), [urlB, urlA])
    }

    func testSearchFiltersByDisplayNameCaseInsensitive() {
        let urlA = URL(fileURLWithPath: "/tmp/TeamSync.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/OneOnOne.m4a")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let dates: [URL: Date] = [
            urlA: Date(timeIntervalSince1970: 10),
            urlB: Date(timeIntervalSince1970: 20)
        ]
        let metadata: [URL: RecordingMetadata] = [
            urlA: RecordingMetadata(title: "Team Sync")
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { dates[$0] ?? .distantPast },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            metadataProvider: { metadata[$0] }
        )

        viewModel.loadRecordings()
        viewModel.searchText = "team"

        XCTAssertEqual(viewModel.recordings.map(\.url), [urlA])

        viewModel.searchText = ""

        XCTAssertEqual(viewModel.recordings.map(\.url), [urlB, urlA])
    }

    func testSearchMatchesMetadataTitle() {
        let urlA = URL(fileURLWithPath: "/tmp/recording_a.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/recording_b.m4a")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let dates: [URL: Date] = [
            urlA: Date(timeIntervalSince1970: 10),
            urlB: Date(timeIntervalSince1970: 20)
        ]
        let metadata: [URL: RecordingMetadata] = [
            urlB: RecordingMetadata(title: "Weekly Review")
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { dates[$0] ?? .distantPast },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            metadataProvider: { metadata[$0] }
        )

        viewModel.loadRecordings()
        viewModel.searchText = "weekly"

        XCTAssertEqual(viewModel.recordings.map(\.url), [urlB])
    }

    func testSortOptionOrdersByDurationWithMissingDurationsLast() {
        let urlA = URL(fileURLWithPath: "/tmp/long.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/short.m4a")
        let urlC = URL(fileURLWithPath: "/tmp/unknown.m4a")
        let manager = MockRecordingManager(recordings: [urlA, urlB, urlC])
        let dates: [URL: Date] = [
            urlA: Date(timeIntervalSince1970: 10),
            urlB: Date(timeIntervalSince1970: 20),
            urlC: Date(timeIntervalSince1970: 30)
        ]
        let durations: [URL: TimeInterval?] = [
            urlA: 120,
            urlB: 45,
            urlC: nil
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { dates[$0] ?? .distantPast },
            durationProvider: { durations[$0] ?? nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()
        viewModel.sortOption = .durationLongest

        XCTAssertEqual(viewModel.recordings.map(\.url), [urlA, urlB, urlC])

        viewModel.sortOption = .durationShortest

        XCTAssertEqual(viewModel.recordings.map(\.url), [urlB, urlA, urlC])
    }

    func testRecordingItemDisplayNameStripsExtension() {
        let timestampMs = 1_700_000_000_000.0
        let date = Date(timeIntervalSince1970: timestampMs / 1000)
        let url = URL(fileURLWithPath: "/tmp/recording_\(Int(timestampMs))_ABC.m4a")
        let item = RecordingItem(
            url: url,
            modifiedAt: Date(timeIntervalSince1970: 0),
            duration: nil,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: nil
        )

        XCTAssertEqual(item.displayName, RecordingItem.defaultSessionTitle(for: date))
    }

    func testLoadRecordingsSurfacesIntegrityWarnings() {
        let url = URL(fileURLWithPath: "/tmp/recording_123.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let report = RecordingIntegrityReport(
            createdAt: Date(timeIntervalSince1970: 0),
            issues: [.missingSummary]
        )
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            summaryProvider: { _ in nil },
            integrityReportProvider: { _ in report }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(viewModel.recordings.first?.integrityWarningText,
                       "Analysis summary is missing. Try recording again to capture full insights.")
    }

    func testRecordingItemFormatDurationUsesMinutesForShortSessions() {
        XCTAssertEqual(RecordingItem.formatDuration(65), "01:05")
    }

    func testRecordingItemFormatDurationUsesHoursForLongSessions() {
        XCTAssertEqual(RecordingItem.formatDuration(3665), "1:01:05")
    }

    func testRecordingsSummaryTextIncludesCountAndTotalDuration() {
        let urlA = URL(fileURLWithPath: "/tmp/a.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/b.wav")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let durations: [URL: TimeInterval] = [
            urlA: 60,
            urlB: 90
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { durations[$0] },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(viewModel.recordingsSummaryText, "2 recordings • 02:30 total")
    }

    func testRecordingsSummaryTextIncludesTotalSizeWhenAvailable() {
        let urlA = URL(fileURLWithPath: "/tmp/a.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/b.wav")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let durations: [URL: TimeInterval] = [
            urlA: 60,
            urlB: 90
        ]
        let sizes: [URL: Int] = [
            urlA: 1024,
            urlB: 2048
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { durations[$0] },
            fileSizeProvider: { sizes[$0] }
        )
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let sizeText = formatter.string(fromByteCount: 3072)

        viewModel.loadRecordings()

        XCTAssertEqual(viewModel.recordingsSummaryText, "2 recordings • 02:30 total • \(sizeText)")
    }

    func testRecordingsSummaryTextUsesHoursForLongTotals() {
        let urlA = URL(fileURLWithPath: "/tmp/a.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/b.wav")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let durations: [URL: TimeInterval] = [
            urlA: 3600,
            urlB: 65
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { durations[$0] },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(viewModel.recordingsSummaryText, "2 recordings • 1:01:05 total")
    }

    func testRecordingsSummaryTextShowsCountWhenDurationMissing() {
        let url = URL(fileURLWithPath: "/tmp/only.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(viewModel.recordingsSummaryText, "1 recording")
    }

    func testRecentSummaryTextAggregatesLast7Days() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let urlA = URL(fileURLWithPath: "/tmp/recent-a.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/recent-b.m4a")
        let urlOld = URL(fileURLWithPath: "/tmp/old.m4a")
        let manager = MockRecordingManager(recordings: [urlA, urlB, urlOld])
        let dates: [URL: Date] = [
            urlA: now.addingTimeInterval(-60 * 60 * 24),
            urlB: now.addingTimeInterval(-60 * 60 * 24 * 6),
            urlOld: now.addingTimeInterval(-60 * 60 * 24 * 8)
        ]
        let summaries: [URL: AnalysisSummary] = [
            urlA: AnalysisSummary(
                version: 1,
                createdAt: now,
                durationSeconds: 60,
                pace: AnalysisSummary.PaceStats(
                    averageWPM: 120,
                    minWPM: 100,
                    maxWPM: 130,
                    totalWords: 120
                ),
                pauses: AnalysisSummary.PauseStats(
                    count: 3,
                    thresholdSeconds: 1.0,
                    averageDurationSeconds: 1.2
                ),
                crutchWords: AnalysisSummary.CrutchWordStats(
                    totalCount: 2,
                    counts: ["um": 2]
                )
            ),
            urlB: AnalysisSummary(
                version: 1,
                createdAt: now,
                durationSeconds: 120,
                pace: AnalysisSummary.PaceStats(
                    averageWPM: 120,
                    minWPM: 110,
                    maxWPM: 140,
                    totalWords: 240
                ),
                pauses: AnalysisSummary.PauseStats(
                    count: 1,
                    thresholdSeconds: 1.0,
                    averageDurationSeconds: 1.4
                ),
                crutchWords: AnalysisSummary.CrutchWordStats(
                    totalCount: 3,
                    counts: ["uh": 3]
                )
            ),
            urlOld: AnalysisSummary(
                version: 1,
                createdAt: now,
                durationSeconds: 120,
                pace: AnalysisSummary.PaceStats(
                    averageWPM: 100,
                    minWPM: 90,
                    maxWPM: 110,
                    totalWords: 200
                ),
                pauses: AnalysisSummary.PauseStats(
                    count: 10,
                    thresholdSeconds: 1.0,
                    averageDurationSeconds: 1.8
                ),
                crutchWords: AnalysisSummary.CrutchWordStats(
                    totalCount: 9,
                    counts: ["like": 9]
                )
            )
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { dates[$0] ?? .distantPast },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            summaryProvider: { summaries[$0] },
            now: { now }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(
            viewModel.recentSummaryText,
            "Last 7 days: Avg 120 WPM • Crutch 5 • Pauses/min 1.3"
        )
    }

    func testRecentSummaryTextOmitsWhenNoRecentSummaries() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let urlOld = URL(fileURLWithPath: "/tmp/old.m4a")
        let manager = MockRecordingManager(recordings: [urlOld])
        let summary = AnalysisSummary(
            version: 1,
            createdAt: now,
            durationSeconds: 120,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 100,
                minWPM: 90,
                maxWPM: 110,
                totalWords: 200
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 2,
                thresholdSeconds: 1.0,
                averageDurationSeconds: 1.8
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 4,
                counts: ["like": 4]
            )
        )
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in now.addingTimeInterval(-60 * 60 * 24 * 8) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            summaryProvider: { _ in summary },
            now: { now }
        )

        viewModel.loadRecordings()

        XCTAssertNil(viewModel.recentSummaryText)
    }

    func testTrendSummaryTextShowsSevenDayDelta() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let day: TimeInterval = 60 * 60 * 24
        let recentA = URL(fileURLWithPath: "/tmp/recent-a.m4a")
        let recentB = URL(fileURLWithPath: "/tmp/recent-b.m4a")
        let previousA = URL(fileURLWithPath: "/tmp/previous-a.m4a")
        let previousB = URL(fileURLWithPath: "/tmp/previous-b.m4a")
        let manager = MockRecordingManager(recordings: [recentA, recentB, previousA, previousB])
        let dates: [URL: Date] = [
            recentA: now.addingTimeInterval(-1 * day),
            recentB: now.addingTimeInterval(-2 * day),
            previousA: now.addingTimeInterval(-8 * day),
            previousB: now.addingTimeInterval(-9 * day)
        ]
        let summaries: [URL: AnalysisSummary] = [
            recentA: AnalysisSummary(
                version: 1,
                createdAt: now,
                durationSeconds: 120,
                pace: AnalysisSummary.PaceStats(
                    averageWPM: 120,
                    minWPM: 100,
                    maxWPM: 140,
                    totalWords: 240
                ),
                pauses: AnalysisSummary.PauseStats(
                    count: 2,
                    thresholdSeconds: 1.0,
                    averageDurationSeconds: 1.2
                ),
                crutchWords: AnalysisSummary.CrutchWordStats(
                    totalCount: 3,
                    counts: ["uh": 3]
                )
            ),
            recentB: AnalysisSummary(
                version: 1,
                createdAt: now,
                durationSeconds: 60,
                pace: AnalysisSummary.PaceStats(
                    averageWPM: 90,
                    minWPM: 80,
                    maxWPM: 100,
                    totalWords: 90
                ),
                pauses: AnalysisSummary.PauseStats(
                    count: 1,
                    thresholdSeconds: 1.0,
                    averageDurationSeconds: 1.0
                ),
                crutchWords: AnalysisSummary.CrutchWordStats(
                    totalCount: 1,
                    counts: ["like": 1]
                )
            ),
            previousA: AnalysisSummary(
                version: 1,
                createdAt: now,
                durationSeconds: 120,
                pace: AnalysisSummary.PaceStats(
                    averageWPM: 90,
                    minWPM: 70,
                    maxWPM: 110,
                    totalWords: 180
                ),
                pauses: AnalysisSummary.PauseStats(
                    count: 6,
                    thresholdSeconds: 1.0,
                    averageDurationSeconds: 1.5
                ),
                crutchWords: AnalysisSummary.CrutchWordStats(
                    totalCount: 6,
                    counts: ["um": 6]
                )
            ),
            previousB: AnalysisSummary(
                version: 1,
                createdAt: now,
                durationSeconds: 60,
                pace: AnalysisSummary.PaceStats(
                    averageWPM: 120,
                    minWPM: 110,
                    maxWPM: 130,
                    totalWords: 120
                ),
                pauses: AnalysisSummary.PauseStats(
                    count: 0,
                    thresholdSeconds: 1.0,
                    averageDurationSeconds: 0.0
                ),
                crutchWords: AnalysisSummary.CrutchWordStats(
                    totalCount: 1,
                    counts: ["so": 1]
                )
            )
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { dates[$0] ?? .distantPast },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            summaryProvider: { summaries[$0] },
            now: { now }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(
            viewModel.trendSummaryText,
            "Trend (7d vs prior): Pace +10 WPM • Crutch -3 • Pauses/min -1.0"
        )
    }

    func testTrendSummaryTextOmitsWhenMissingPreviousWindow() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let urlRecent = URL(fileURLWithPath: "/tmp/recent-only.m4a")
        let manager = MockRecordingManager(recordings: [urlRecent])
        let summary = AnalysisSummary(
            version: 1,
            createdAt: now,
            durationSeconds: 120,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 110,
                minWPM: 100,
                maxWPM: 120,
                totalWords: 220
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 2,
                thresholdSeconds: 1.0,
                averageDurationSeconds: 1.2
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 2,
                counts: ["uh": 2]
            )
        )
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in now.addingTimeInterval(-60 * 60 * 24 * 2) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            summaryProvider: { _ in summary },
            now: { now }
        )

        viewModel.loadRecordings()

        XCTAssertNil(viewModel.trendSummaryText)
    }

    func testMostRecentRecordingTextUsesNewestDate() {
        let urlA = URL(fileURLWithPath: "/tmp/old.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/new.m4a")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let dates: [URL: Date] = [
            urlA: Date(timeIntervalSince1970: 10),
            urlB: Date(timeIntervalSince1970: 20)
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { dates[$0] ?? .distantPast },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            mostRecentDateTextProvider: { date in
                "T\(Int(date.timeIntervalSince1970))"
            }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(viewModel.mostRecentRecordingText, "Most recent: T20")
    }

    func testMostRecentRecordingTextNilWhenEmpty() {
        let manager = MockRecordingManager(recordings: [])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in .distantPast },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()

        XCTAssertNil(viewModel.mostRecentRecordingText)
    }

    func testConfirmDeleteRecordingReloadsList() throws {
        let urlA = URL(fileURLWithPath: "/tmp/remove.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/keep.wav")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()
        XCTAssertEqual(viewModel.recordings.count, 2)

        let target = try XCTUnwrap(viewModel.recordings.first { $0.url == urlA })
        viewModel.requestDelete(target)
        viewModel.confirmDelete(target)

        XCTAssertEqual(manager.deleted, [urlA])
        XCTAssertEqual(viewModel.recordings.map(\.url), [urlB])
    }

    func testCancelDeleteClearsPendingWithoutDeleting() {
        let urlA = URL(fileURLWithPath: "/tmp/remove.m4a")
        let manager = MockRecordingManager(recordings: [urlA])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()

        let target = viewModel.recordings[0]
        viewModel.requestDelete(target)
        XCTAssertEqual(viewModel.pendingDelete, .single(target))

        viewModel.cancelDelete()

        XCTAssertNil(viewModel.pendingDelete)
        XCTAssertTrue(manager.deleted.isEmpty)
        XCTAssertEqual(viewModel.recordings.map(\.url), [urlA])
    }

    func testRequestDeleteWhileRecordingShowsMessageAndKeepsPendingNil() {
        let url = URL(fileURLWithPath: "/tmp/active.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )
        let subject = PassthroughSubject<Bool, Never>()

        viewModel.bind(recordingPublisher: subject.eraseToAnyPublisher())
        viewModel.loadRecordings()
        subject.send(true)

        let item = viewModel.recordings[0]
        viewModel.requestDelete(item)

        XCTAssertNil(viewModel.pendingDelete)
        XCTAssertEqual(
            viewModel.deleteErrorMessage,
            RecordingListViewModel.deleteWhileRecordingMessage
        )
        XCTAssertTrue(manager.deleted.isEmpty)
    }

    func testConfirmDeleteWhileRecordingDoesNotDelete() {
        let url = URL(fileURLWithPath: "/tmp/active-delete.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )
        let subject = PassthroughSubject<Bool, Never>()

        viewModel.bind(recordingPublisher: subject.eraseToAnyPublisher())
        viewModel.loadRecordings()
        subject.send(true)

        let item = viewModel.recordings[0]
        viewModel.confirmDelete(item)

        XCTAssertEqual(viewModel.recordings.map(\.url), [url])
        XCTAssertEqual(
            viewModel.deleteErrorMessage,
            RecordingListViewModel.deleteWhileRecordingMessage
        )
        XCTAssertTrue(manager.deleted.isEmpty)
    }

    func testReloadsWhenRecordingStops() {
        let urlA = URL(fileURLWithPath: "/tmp/a.m4a")
        let manager = MockRecordingManager(recordings: [urlA])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )
        let subject = PassthroughSubject<Bool, Never>()

        viewModel.bind(recordingPublisher: subject.eraseToAnyPublisher())

        XCTAssertEqual(manager.loadCount, 0)

        subject.send(true)
        XCTAssertEqual(manager.loadCount, 0)
        XCTAssertTrue(viewModel.isRecording)

        subject.send(false)
        XCTAssertEqual(manager.loadCount, 1)
        XCTAssertEqual(viewModel.recordings.map(\.url), [urlA])
        XCTAssertFalse(viewModel.isRecording)
    }

    func testRefreshRecordingsLoadsWhenIdle() {
        let url = URL(fileURLWithPath: "/tmp/refresh.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        XCTAssertEqual(manager.loadCount, 0)

        viewModel.refreshRecordings()

        XCTAssertEqual(manager.loadCount, 1)
        XCTAssertEqual(viewModel.recordings.map(\.url), [url])
    }

    func testRefreshRecordingsWhileRecordingDoesNotReload() {
        let url = URL(fileURLWithPath: "/tmp/refresh-recording.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )
        let subject = PassthroughSubject<Bool, Never>()

        viewModel.bind(recordingPublisher: subject.eraseToAnyPublisher())
        subject.send(true)

        viewModel.refreshRecordings()

        XCTAssertEqual(manager.loadCount, 0)
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(viewModel.recordings.isEmpty)
    }

    func testLoadRecordingsClearsPendingDeleteAndError() {
        let url = URL(fileURLWithPath: "/tmp/clear-delete.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()
        let item = viewModel.recordings[0]
        viewModel.requestDelete(item)
        viewModel.deleteErrorMessage = "error"

        viewModel.loadRecordings()

        XCTAssertNil(viewModel.pendingDelete)
        XCTAssertNil(viewModel.deleteErrorMessage)
    }

    func testRequestDeleteAllSetsPendingDelete() {
        let url = URL(fileURLWithPath: "/tmp/all.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()
        viewModel.requestDeleteAll()

        XCTAssertEqual(viewModel.pendingDelete, .all)
    }

    func testConfirmDeleteAllClearsRecordings() {
        let urlA = URL(fileURLWithPath: "/tmp/all-a.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/all-b.m4a")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()
        viewModel.requestDeleteAll()
        viewModel.confirmDeleteAll()

        XCTAssertEqual(manager.deleteAllCount, 1)
        XCTAssertTrue(viewModel.recordings.isEmpty)
        XCTAssertNil(viewModel.pendingDelete)
    }

    func testConfirmDeleteAllWhileRecordingDoesNotDelete() {
        let url = URL(fileURLWithPath: "/tmp/all-active.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )
        let subject = PassthroughSubject<Bool, Never>()

        viewModel.bind(recordingPublisher: subject.eraseToAnyPublisher())
        viewModel.loadRecordings()
        subject.send(true)

        viewModel.requestDeleteAll()
        viewModel.confirmDeleteAll()

        XCTAssertEqual(manager.deleteAllCount, 0)
        XCTAssertEqual(viewModel.recordings.map(\.url), [url])
        XCTAssertEqual(
            viewModel.deleteErrorMessage,
            RecordingListViewModel.deleteWhileRecordingMessage
        )
    }

    func testConfirmDeleteAllFailureKeepsListAndSetsErrorMessage() {
        struct BulkDeleteFailure: Error {}
        let url = URL(fileURLWithPath: "/tmp/bulk-fail.m4a")
        let manager = MockRecordingManager(recordings: [url])
        manager.deleteAllError = BulkDeleteFailure()
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()
        viewModel.requestDeleteAll()
        viewModel.confirmDeleteAll()

        XCTAssertEqual(viewModel.recordings.map(\.url), [url])
        XCTAssertNotNil(viewModel.deleteErrorMessage)
        XCTAssertEqual(manager.deleteAllCount, 0)
    }

    func testOpenRecordingsFolderSelectsDirectory() {
        let manager = MockRecordingManager(recordings: [])
        manager.recordingsDirectory = URL(fileURLWithPath: "/tmp/CalliopeRecordings")
        let workspace = SpyWorkspace()
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: workspace,
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.openRecordingsFolder()

        XCTAssertEqual(workspace.selections, [[manager.recordingsDirectory]])
    }

    func testLoadRecordingsIncludesSummary() {
        let url = URL(fileURLWithPath: "/tmp/summary.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(timeIntervalSince1970: 1),
            durationSeconds: 42,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 120,
                minWPM: 100,
                maxWPM: 140,
                totalWords: 80
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 2,
                thresholdSeconds: 1.0,
                averageDurationSeconds: 1.6
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 3,
                counts: ["um": 2, "uh": 1]
            ),
            processing: AnalysisSummary.ProcessingStats(
                latencyAverageMs: 12,
                latencyPeakMs: 25,
                utilizationAverage: 0.4,
                utilizationPeak: 0.9
            )
        )
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in 12 },
            fileSizeProvider: { _ in 2048 },
            summaryProvider: { _ in summary }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(viewModel.recordings.first?.summary, summary)
        XCTAssertEqual(
            viewModel.recordings.first?.summaryText,
            "Avg 120 WPM • Pauses 2 • Pauses/min 2.9 • Avg Pause 1.6s • Crutch 3 • Latency 12/25ms • Util 40/90%"
        )
    }

    func testSummaryTextOmitsPausesPerMinuteWhenDurationUnavailable() {
        let url = URL(fileURLWithPath: "/tmp/summary-zero.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(timeIntervalSince1970: 1),
            durationSeconds: 0,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 110,
                minWPM: 90,
                maxWPM: 130,
                totalWords: 50
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 1,
                thresholdSeconds: 1.0,
                averageDurationSeconds: 1.2
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 0,
                counts: [:]
            )
        )
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in 0 },
            fileSizeProvider: { _ in 2048 },
            summaryProvider: { _ in summary }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(
            viewModel.recordings.first?.summaryText,
            "Avg 110 WPM • Pauses 1 • Avg Pause 1.2s • Crutch 0"
        )
    }

    func testSummaryTextIncludesSpeakingStats() {
        let url = URL(fileURLWithPath: "/tmp/summary-speaking.m4a")
        let manager = MockRecordingManager(recordings: [url])
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(timeIntervalSince1970: 1),
            durationSeconds: 300,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 120,
                minWPM: 100,
                maxWPM: 140,
                totalWords: 600
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 2,
                thresholdSeconds: 1.0,
                averageDurationSeconds: 1.2
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 1,
                counts: ["um": 1]
            ),
            speaking: AnalysisSummary.SpeakingStats(
                timeSeconds: 65,
                turnCount: 3
            )
        )
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in 0 },
            fileSizeProvider: { _ in 2048 },
            summaryProvider: { _ in summary }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(
            viewModel.recordings.first?.summaryText,
            "Avg 120 WPM • Pauses 2 • Pauses/min 0.4 • Avg Pause 1.2s • Crutch 1 • Speaking 01:05 • Turns 3"
        )
    }

    func testRecordingItemCrutchBreakdownSortsAndFilters() {
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(timeIntervalSince1970: 1),
            durationSeconds: 90,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 100,
                minWPM: 90,
                maxWPM: 120,
                totalWords: 150
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 2,
                thresholdSeconds: 0.8,
                averageDurationSeconds: 1.1
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 12,
                counts: ["uh": 5, "like": 5, "um": 2, "": 3, "so": 0]
            )
        )
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/summary-breakdown.m4a"),
            modifiedAt: Date(timeIntervalSince1970: 1),
            duration: 90,
            fileSizeBytes: nil,
            summary: summary,
            integrityReport: nil
        )

        let breakdown = item.crutchBreakdown.map { "\($0.word):\($0.count)" }

        XCTAssertEqual(breakdown, ["like:5", "uh:5", "um:2"])
    }

    func testRecordingItemProcessingDetailLinesFormatsStats() {
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(timeIntervalSince1970: 1),
            durationSeconds: 120,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 130,
                minWPM: 110,
                maxWPM: 150,
                totalWords: 240
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 3,
                thresholdSeconds: 0.7,
                averageDurationSeconds: 1.4
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 1,
                counts: ["um": 1]
            ),
            processing: AnalysisSummary.ProcessingStats(
                latencyAverageMs: 12,
                latencyPeakMs: 25,
                utilizationAverage: 0.4,
                utilizationPeak: 0.9
            )
        )
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/summary-processing.m4a"),
            modifiedAt: Date(timeIntervalSince1970: 1),
            duration: 120,
            fileSizeBytes: nil,
            summary: summary,
            integrityReport: nil
        )

        XCTAssertEqual(
            item.processingDetailLines,
            ["Latency avg/peak: 12/25 ms", "Util avg/peak: 40/90%"]
        )
    }

    func testConfirmDeleteFailureKeepsListAndSetsErrorMessage() {
        struct DeleteFailure: Error {}
        let url = URL(fileURLWithPath: "/tmp/fail.m4a")
        let manager = MockRecordingManager(recordings: [url])
        manager.deleteError = DeleteFailure()
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil }
        )

        viewModel.loadRecordings()
        let target = viewModel.recordings[0]
        viewModel.requestDelete(target)
        viewModel.confirmDelete(target)

        XCTAssertEqual(viewModel.recordings.map(\.url), [url])
        XCTAssertNotNil(viewModel.deleteErrorMessage)
        XCTAssertTrue(manager.deleted.isEmpty)
    }

    func testPlayStartsPlaybackAndSetsActiveItem() {
        let url = URL(fileURLWithPath: "/tmp/play.m4a")
        let (viewModel, _, store) = makeViewModelWithPlayback(recordings: [url])

        viewModel.loadRecordings()
        let item = viewModel.recordings[0]
        viewModel.togglePlayPause(item)

        XCTAssertEqual(viewModel.activePlaybackURL, url)
        XCTAssertFalse(viewModel.isPlaybackPaused)
        XCTAssertEqual(store.players[url]?.playCount, 1)
    }

    func testPlayPauseResumeMaintainsActiveItem() {
        let url = URL(fileURLWithPath: "/tmp/pause.m4a")
        let (viewModel, _, store) = makeViewModelWithPlayback(recordings: [url])

        viewModel.loadRecordings()
        let item = viewModel.recordings[0]
        viewModel.togglePlayPause(item)
        viewModel.togglePlayPause(item)

        XCTAssertTrue(viewModel.isPlaybackPaused)
        XCTAssertEqual(store.players[url]?.pauseCount, 1)
        XCTAssertEqual(viewModel.activePlaybackURL, url)

        viewModel.togglePlayPause(item)

        XCTAssertFalse(viewModel.isPlaybackPaused)
        XCTAssertEqual(store.players[url]?.playCount, 2)
    }

    func testStopClearsPlaybackState() {
        let url = URL(fileURLWithPath: "/tmp/stop.m4a")
        let (viewModel, _, store) = makeViewModelWithPlayback(recordings: [url])

        viewModel.loadRecordings()
        let item = viewModel.recordings[0]
        viewModel.togglePlayPause(item)
        viewModel.stopPlayback()

        XCTAssertNil(viewModel.activePlaybackURL)
        XCTAssertFalse(viewModel.isPlaybackPaused)
        XCTAssertEqual(store.players[url]?.stopCount, 1)
    }

    func testStartingNewPlaybackStopsPrevious() {
        let urlA = URL(fileURLWithPath: "/tmp/one.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/two.m4a")
        let (viewModel, _, store) = makeViewModelWithPlayback(recordings: [urlA, urlB])

        viewModel.loadRecordings()
        let first = viewModel.recordings[0]
        let second = viewModel.recordings[1]

        viewModel.togglePlayPause(first)
        viewModel.togglePlayPause(second)

        XCTAssertEqual(viewModel.activePlaybackURL, urlB)
        XCTAssertEqual(store.players[urlA]?.stopCount, 1)
        XCTAssertEqual(store.players[urlB]?.playCount, 1)
    }

    func testLoadRecordingsStopsPlaybackWhenActiveItemMissing() {
        let url = URL(fileURLWithPath: "/tmp/missing.m4a")
        let (viewModel, manager, store) = makeViewModelWithPlayback(recordings: [url])

        viewModel.loadRecordings()
        let item = viewModel.recordings[0]
        viewModel.togglePlayPause(item)

        XCTAssertEqual(viewModel.activePlaybackURL, url)

        manager.recordings = []
        viewModel.loadRecordings()

        XCTAssertNil(viewModel.activePlaybackURL)
        XCTAssertFalse(viewModel.isPlaybackPaused)
        XCTAssertEqual(store.players[url]?.stopCount, 1)
    }

    func testPlaybackEndClearsIndicator() {
        let url = URL(fileURLWithPath: "/tmp/end.m4a")
        let (viewModel, _, store) = makeViewModelWithPlayback(recordings: [url])

        viewModel.loadRecordings()
        let item = viewModel.recordings[0]
        viewModel.togglePlayPause(item)

        store.players[url]?.onPlaybackEnded?()

        XCTAssertNil(viewModel.activePlaybackURL)
        XCTAssertFalse(viewModel.isPlaybackPaused)
    }

    func testRecordingStartStopsPlayback() {
        let url = URL(fileURLWithPath: "/tmp/active.m4a")
        let (viewModel, _, store) = makeViewModelWithPlayback(recordings: [url])
        let subject = PassthroughSubject<Bool, Never>()

        viewModel.bind(recordingPublisher: subject.eraseToAnyPublisher())
        viewModel.loadRecordings()
        let item = viewModel.recordings[0]
        viewModel.togglePlayPause(item)

        subject.send(true)

        XCTAssertTrue(viewModel.isRecording)
        XCTAssertNil(viewModel.activePlaybackURL)
        XCTAssertFalse(viewModel.isPlaybackPaused)
        XCTAssertEqual(store.players[url]?.stopCount, 1)
    }

    func testConfirmDeleteStopsActivePlayback() {
        let url = URL(fileURLWithPath: "/tmp/delete.m4a")
        let (viewModel, manager, store) = makeViewModelWithPlayback(recordings: [url])

        viewModel.loadRecordings()
        let item = viewModel.recordings[0]
        viewModel.togglePlayPause(item)
        viewModel.confirmDelete(item)

        XCTAssertNil(viewModel.activePlaybackURL)
        XCTAssertEqual(store.players[url]?.stopCount, 1)
        XCTAssertTrue(manager.deleted.contains(url))
    }
}
