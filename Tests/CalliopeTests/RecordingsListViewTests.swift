import SwiftUI
import XCTest
@testable import Calliope

@MainActor
final class RecordingsListViewTests: XCTestCase {
    private final class TestRecordingManager: RecordingManaging {
        func getAllRecordings() -> [URL] { [] }
        func cleanupOrphanedMetadata(for recordings: [URL]) {}
        func backfillMetadataIfNeeded(for recordings: [URL]) {}
        func deleteRecording(at url: URL) throws {}
        func deleteAllRecordings() throws {}
        func deleteRecordings(olderThan cutoff: Date) -> Int { 0 }
        func recordingsDirectoryURL() -> URL {
            URL(fileURLWithPath: "/tmp")
        }
    }

    func testRecordingsListViewBuilds() {
        let viewModel = RecordingListViewModel(manager: TestRecordingManager())
        let view = RecordingsListView(viewModel: viewModel) {}

        _ = view.body
    }

    func testRecordingsListLayoutUsesAccessibilitySizes() {
        XCTAssertTrue(
            RecordingsListLayout.usesAccessibilityLayout(dynamicTypeSize: .accessibility3)
        )
        XCTAssertFalse(
            RecordingsListLayout.usesAccessibilityLayout(dynamicTypeSize: .large)
        )
    }
}
