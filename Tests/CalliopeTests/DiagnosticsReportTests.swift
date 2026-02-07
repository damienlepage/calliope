//
//  DiagnosticsReportTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import Foundation
import XCTest
@testable import Calliope

final class DiagnosticsReportTests: XCTestCase {
    func testEncodeDecodeRoundTrip() throws {
        let report = DiagnosticsReport(
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            app: DiagnosticsReport.AppInfo(shortVersion: "1.2.3", buildVersion: "456"),
            systemVersion: "macOS 14.2.1",
            permissions: DiagnosticsReport.PermissionsInfo(microphone: "authorized", speech: "denied"),
            capturePreferences: DiagnosticsReport.CapturePreferencesInfo(
                voiceIsolationEnabled: true,
                preferredMicrophoneName: "External Mic",
                maxSegmentDurationSeconds: 7200
            ),
            retentionPreferences: DiagnosticsReport.RetentionPreferencesInfo(
                autoCleanEnabled: true,
                retentionDays: 60
            ),
            recordingsCount: 12
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(report)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DiagnosticsReport.self, from: data)

        XCTAssertEqual(decoded, report)
    }

    func testWriterCreatesDiagnosticsFile() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: baseDirectory) }

        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let report = DiagnosticsReport(
            createdAt: createdAt,
            app: DiagnosticsReport.AppInfo(shortVersion: nil, buildVersion: nil),
            systemVersion: "macOS 14.0",
            permissions: DiagnosticsReport.PermissionsInfo(microphone: "authorized", speech: "authorized"),
            capturePreferences: DiagnosticsReport.CapturePreferencesInfo(
                voiceIsolationEnabled: false,
                preferredMicrophoneName: nil,
                maxSegmentDurationSeconds: 3600
            ),
            retentionPreferences: DiagnosticsReport.RetentionPreferencesInfo(
                autoCleanEnabled: false,
                retentionDays: 30
            ),
            recordingsCount: 0
        )

        let writer = DiagnosticsReportWriter(recordingsDirectory: baseDirectory)
        let reportURL = try writer.writeReport(report)

        XCTAssertEqual(reportURL.lastPathComponent, DiagnosticsReport.filename(for: createdAt))
        XCTAssertTrue(reportURL.path.contains("/Diagnostics/"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: reportURL.path))

        let data = try Data(contentsOf: reportURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DiagnosticsReport.self, from: data)
        XCTAssertEqual(decoded, report)
    }
}
