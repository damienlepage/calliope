import Foundation
import XCTest
@testable import Calliope

final class RecordingsFolderActionModelTests: XCTestCase {
    private final class MockRecordingManager: RecordingManaging {
        let directoryURL: URL

        init(directoryURL: URL) {
            self.directoryURL = directoryURL
        }

        func getAllRecordings() -> [URL] {
            []
        }

        func cleanupOrphanedMetadata(for recordings: [URL]) {}

        func backfillMetadataIfNeeded(for recordings: [URL]) {}

        func saveSessionTitle(
            _ rawTitle: String,
            for recordingURLs: [URL],
            createdAt: Date?,
            coachingProfile: CoachingProfile?
        ) -> Bool {
            true
        }

        func deleteRecording(at url: URL) throws {}

        func deleteAllRecordings() throws {}

        func deleteRecordings(olderThan cutoff: Date) -> Int {
            0
        }

        func recordingsDirectoryURL() -> URL {
            directoryURL
        }
    }

    private final class MockWorkspace: WorkspaceOpening {
        private(set) var openedURLs: [URL] = []

        func activateFileViewerSelecting(_ fileURLs: [URL]) {
            openedURLs = fileURLs
        }
    }

    func testOpenRecordingsFolderUsesManagerDirectory() {
        let directoryURL = URL(fileURLWithPath: "/tmp/CalliopeRecordings")
        let manager = MockRecordingManager(directoryURL: directoryURL)
        let workspace = MockWorkspace()
        let model = RecordingsFolderActionModel(manager: manager, workspace: workspace)

        model.openRecordingsFolder()

        XCTAssertEqual(workspace.openedURLs, [directoryURL])
    }
}
