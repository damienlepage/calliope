//
//  DiagnosticsExportActionModelTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import Foundation
import XCTest
@testable import Calliope

final class DiagnosticsExportActionModelTests: XCTestCase {
    func testExportWritesReportAndRevealsInFinder() {
        let report = DiagnosticsReport(
            createdAt: Date(timeIntervalSince1970: 1_700_000_123),
            app: DiagnosticsReport.AppInfo(shortVersion: "2.0", buildVersion: "200"),
            systemVersion: "macOS 15.0",
            permissions: DiagnosticsReport.PermissionsInfo(microphone: "authorized", speech: "authorized"),
            capturePreferences: DiagnosticsReport.CapturePreferencesInfo(
                voiceIsolationEnabled: true,
                preferredMicrophoneName: "Studio Mic",
                maxSegmentDurationSeconds: 3600
            ),
            captureDiagnostics: DiagnosticsReport.CaptureDiagnosticsInfo(
                backendStatus: "voice_isolation",
                inputDeviceName: "Studio Mic",
                outputDeviceName: "Studio Output",
                inputSampleRateHz: 48_000,
                inputChannelCount: 1
            ),
            retentionPreferences: DiagnosticsReport.RetentionPreferencesInfo(
                autoCleanEnabled: false,
                retentionDays: 30
            ),
            recordingsCount: 4,
            appLaunchAt: Date(timeIntervalSince1970: 1_700_000_000),
            sessionReadyLatencySeconds: 1.2,
            sessionReadyTargetSeconds: 2.0,
            sessionReadyStatus: .onTarget
        )
        let recordingsDirectory = URL(fileURLWithPath: "/tmp/calliope-tests")
        let expectedURL = recordingsDirectory.appendingPathComponent("Diagnostics/report.json")
        let manager = TestRecordingManager(recordingsDirectory: recordingsDirectory)
        let workspace = WorkspaceSpy()
        let writer = WriterSpy(resultURL: expectedURL)
        var capturedDirectory: URL?

        let model = DiagnosticsExportActionModel(
            manager: manager,
            workspace: workspace,
            writerFactory: { directory in
                capturedDirectory = directory
                return writer
            }
        )

        model.export(report: report)

        XCTAssertEqual(capturedDirectory, recordingsDirectory)
        XCTAssertEqual(writer.capturedReport, report)
        XCTAssertEqual(workspace.revealedURLs, [expectedURL])
    }
}

private final class TestRecordingManager: RecordingManaging {
    private let recordingsDirectory: URL

    init(recordingsDirectory: URL) {
        self.recordingsDirectory = recordingsDirectory
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
        recordingsDirectory
    }
}

private final class WorkspaceSpy: WorkspaceOpening {
    private(set) var revealedURLs: [URL] = []

    func activateFileViewerSelecting(_ fileURLs: [URL]) {
        revealedURLs = fileURLs
    }
}

private final class WriterSpy: DiagnosticsReportWriting {
    private let resultURL: URL
    private(set) var capturedReport: DiagnosticsReport?

    init(resultURL: URL) {
        self.resultURL = resultURL
    }

    func writeReport(_ report: DiagnosticsReport) throws -> URL {
        capturedReport = report
        return resultURL
    }
}
