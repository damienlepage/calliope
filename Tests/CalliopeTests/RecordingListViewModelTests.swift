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

        init(recordings: [URL]) {
            self.recordings = recordings
        }

        func getAllRecordings() -> [URL] {
            loadCount += 1
            recordings
        }

        func deleteRecording(at url: URL) throws {
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

        subject.send(false)
        XCTAssertEqual(manager.loadCount, 1)
        XCTAssertEqual(viewModel.recordings.map(\.url), [urlA])
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
                thresholdSeconds: 1.0
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
            "Avg 120 WPM • Pauses 2 • Crutch 3"
        )
    }
}
