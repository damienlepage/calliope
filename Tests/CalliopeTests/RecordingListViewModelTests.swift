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
        var loadCount = 0
        var recordingsDirectory = URL(fileURLWithPath: "/tmp/CalliopeRecordings")
        var deleteError: Error?

        init(recordings: [URL]) {
            self.recordings = recordings
        }

        func getAllRecordings() -> [URL] {
            loadCount += 1
            return recordings
        }

        func deleteRecording(at url: URL) throws {
            if let deleteError {
                throw deleteError
            }
            deleted.append(url)
            recordings.removeAll { $0 == url }
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

    func testLoadRecordingsPreservesManagerOrder() {
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

        XCTAssertEqual(viewModel.recordings.map(\.url), [urlA, urlB])
        XCTAssertEqual(viewModel.recordings.map(\.modifiedAt), [dates[urlA]!, dates[urlB]!])
        XCTAssertEqual(viewModel.recordings.map(\.duration), [durations[urlA]!, durations[urlB]!])
        XCTAssertEqual(viewModel.recordings.map(\.fileSizeBytes), [sizes[urlA]!, sizes[urlB]!])
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

    func testConfirmDeleteRecordingReloadsList() {
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

        let target = viewModel.recordings[0]
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
        XCTAssertEqual(viewModel.pendingDelete, target)

        viewModel.cancelDelete()

        XCTAssertNil(viewModel.pendingDelete)
        XCTAssertTrue(manager.deleted.isEmpty)
        XCTAssertEqual(viewModel.recordings.map(\.url), [urlA])
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
            "Avg 120 WPM • Pauses 2 • Avg Pause 1.6s • Crutch 3"
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
