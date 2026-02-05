//
//  RecordingListViewModelTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import Foundation
import XCTest
@testable import Calliope

@MainActor
final class RecordingListViewModelTests: XCTestCase {
    private final class MockRecordingManager: RecordingManaging {
        var recordings: [URL]
        var deleted: [URL] = []

        init(recordings: [URL]) {
            self.recordings = recordings
        }

        func getAllRecordings() -> [URL] {
            recordings
        }

        func deleteRecording(at url: URL) throws {
            deleted.append(url)
            recordings.removeAll { $0 == url }
        }
    }

    private final class NoopWorkspace: WorkspaceOpening {
        func activateFileViewerSelecting(_ fileURLs: [URL]) {}
    }

    func testLoadRecordingsPreservesManagerOrder() {
        let urlA = URL(fileURLWithPath: "/tmp/a.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/b.wav")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let dates: [URL: Date] = [
            urlA: Date(timeIntervalSince1970: 10),
            urlB: Date(timeIntervalSince1970: 20)
        ]
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: NoopWorkspace(),
            modificationDateProvider: { dates[$0] ?? .distantPast }
        )

        viewModel.loadRecordings()

        XCTAssertEqual(viewModel.recordings.map(\.url), [urlA, urlB])
        XCTAssertEqual(viewModel.recordings.map(\.modifiedAt), [dates[urlA]!, dates[urlB]!])
    }

    func testDeleteRecordingReloadsList() {
        let urlA = URL(fileURLWithPath: "/tmp/remove.m4a")
        let urlB = URL(fileURLWithPath: "/tmp/keep.wav")
        let manager = MockRecordingManager(recordings: [urlA, urlB])
        let viewModel = RecordingListViewModel(
            manager: manager,
            workspace: NoopWorkspace(),
            modificationDateProvider: { _ in Date(timeIntervalSince1970: 1) }
        )

        viewModel.loadRecordings()
        XCTAssertEqual(viewModel.recordings.count, 2)

        viewModel.delete(viewModel.recordings[0])

        XCTAssertEqual(manager.deleted, [urlA])
        XCTAssertEqual(viewModel.recordings.map(\.url), [urlB])
    }
}
