import Foundation
import XCTest
@testable import Calliope

final class RecordingIntegrityValidatorTests: XCTestCase {
    func testValidateWritesReportWhenSummaryMissing() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingURL = tempDir.appendingPathComponent("recording.m4a")
        FileManager.default.createFile(atPath: recordingURL.path, contents: Data([0x1]))

        let validator = RecordingIntegrityValidator(
            summaryURLProvider: { manager.summaryURL(for: $0) },
            integrityWriter: manager,
            now: { Date(timeIntervalSince1970: 10) }
        )

        validator.validate(recordingURLs: [recordingURL])

        let report = manager.readIntegrityReport(for: recordingURL)
        XCTAssertNotNil(report)
        XCTAssertEqual(report?.issues, [.missingSummary])
    }

    func testValidateReportsMissingAudioAndSummary() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingURL = tempDir.appendingPathComponent("missing.m4a")

        let validator = RecordingIntegrityValidator(
            summaryURLProvider: { manager.summaryURL(for: $0) },
            integrityWriter: manager,
            now: { Date(timeIntervalSince1970: 10) }
        )

        validator.validate(recordingURLs: [recordingURL])

        let report = manager.readIntegrityReport(for: recordingURL)
        XCTAssertNotNil(report)
        XCTAssertEqual(report?.issues, [.missingAudioFile, .missingSummary])
    }

    func testValidateDeletesReportWhenArtifactsPresent() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingURL = tempDir.appendingPathComponent("valid.m4a")
        FileManager.default.createFile(atPath: recordingURL.path, contents: Data([0x1]))

        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(timeIntervalSince1970: 1),
            durationSeconds: 10,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 100,
                minWPM: 90,
                maxWPM: 110,
                totalWords: 20
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 0,
                thresholdSeconds: 0.8,
                averageDurationSeconds: 0
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 0,
                counts: [:]
            )
        )
        try manager.writeSummary(summary, for: recordingURL)
        let existingReport = RecordingIntegrityReport(
            createdAt: Date(timeIntervalSince1970: 2),
            issues: [.missingSummary]
        )
        try manager.writeIntegrityReport(existingReport, for: recordingURL)

        let validator = RecordingIntegrityValidator(
            summaryURLProvider: { manager.summaryURL(for: $0) },
            integrityWriter: manager,
            now: { Date(timeIntervalSince1970: 10) }
        )

        validator.validate(recordingURLs: [recordingURL])

        let report = manager.readIntegrityReport(for: recordingURL)
        XCTAssertNil(report)
    }
}
