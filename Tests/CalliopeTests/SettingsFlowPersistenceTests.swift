import Combine
import Foundation
import XCTest

@testable import Calliope

@MainActor
final class SettingsFlowPersistenceTests: XCTestCase {
    private final class MockRecordingManager: RecordingManaging {
        var recordings: [URL]
        var deleteOlderCount = 0
        var deleteOlderCutoff: Date?

        init(recordings: [URL]) {
            self.recordings = recordings
        }

        func getAllRecordings() -> [URL] {
            recordings
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
            deleteOlderCount += 1
            deleteOlderCutoff = cutoff
            return 0
        }

        func recordingsDirectoryURL() -> URL {
            URL(fileURLWithPath: "/tmp/CalliopeRecordings")
        }
    }

    private final class SpyWorkspace: WorkspaceOpening {
        func activateFileViewerSelecting(_ fileURLs: [URL]) {}
    }

    func testSettingsPersistAndApplyWhenReturningToSessionAndRecordings() {
        let suiteName = "SettingsFlowPersistenceTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName)

        let analysisStore = AnalysisPreferencesStore(defaults: defaults)
        analysisStore.paceMin = 135
        analysisStore.paceMax = 175
        analysisStore.pauseThreshold = 0.9
        analysisStore.crutchWords = ["um", "like"]
        analysisStore.speakingTimeTargetPercent = 42

        let activeStore = ActiveAnalysisPreferencesStore(
            basePreferencesStore: analysisStore,
            coachingProfileStore: CoachingProfileStore(defaults: defaults),
            perAppProfileStore: PerAppFeedbackProfileStore(defaults: defaults),
            frontmostAppPublisher: Just<String?>(nil).eraseToAnyPublisher(),
            recordingPublisher: Just(false).eraseToAnyPublisher()
        )

        XCTAssertEqual(activeStore.activePreferences, analysisStore.current)

        let retentionStore = RecordingRetentionPreferencesStore(defaults: defaults)
        let manager = MockRecordingManager(recordings: [
            URL(fileURLWithPath: "/tmp/recording.m4a")
        ])
        let now = Date(timeIntervalSince1970: 1_000_000)
        let recordingsViewModel = RecordingListViewModel(
            manager: manager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in now },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            recordingPreferencesStore: retentionStore,
            now: { now }
        )

        retentionStore.autoCleanEnabled = true
        retentionStore.retentionOption = .days60

        recordingsViewModel.refreshRecordings()

        XCTAssertEqual(manager.deleteOlderCount, 1)

        let reloadedAnalysisStore = AnalysisPreferencesStore(defaults: defaults)
        let reloadedRetentionStore = RecordingRetentionPreferencesStore(defaults: defaults)

        XCTAssertEqual(reloadedAnalysisStore.current, analysisStore.current)
        XCTAssertTrue(reloadedRetentionStore.autoCleanEnabled)
        XCTAssertEqual(reloadedRetentionStore.retentionOption, .days60)

        let reloadedActiveStore = ActiveAnalysisPreferencesStore(
            basePreferencesStore: reloadedAnalysisStore,
            coachingProfileStore: CoachingProfileStore(defaults: defaults),
            perAppProfileStore: PerAppFeedbackProfileStore(defaults: defaults),
            frontmostAppPublisher: Just<String?>(nil).eraseToAnyPublisher(),
            recordingPublisher: Just(false).eraseToAnyPublisher()
        )
        XCTAssertEqual(reloadedActiveStore.activePreferences, reloadedAnalysisStore.current)

        let reloadedManager = MockRecordingManager(recordings: [
            URL(fileURLWithPath: "/tmp/recording.m4a")
        ])
        let reloadedRecordingsViewModel = RecordingListViewModel(
            manager: reloadedManager,
            workspace: SpyWorkspace(),
            modificationDateProvider: { _ in now },
            durationProvider: { _ in nil },
            fileSizeProvider: { _ in nil },
            recordingPreferencesStore: reloadedRetentionStore,
            now: { now }
        )

        reloadedRecordingsViewModel.refreshRecordings()

        XCTAssertEqual(reloadedManager.deleteOlderCount, 1)
    }

    private func makeDefaults(_ suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
