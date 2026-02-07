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
            captureDiagnostics: DiagnosticsReport.CaptureDiagnosticsInfo(
                backendStatus: "voice_isolation",
                inputDeviceName: "External Mic",
                outputDeviceName: "Studio Output",
                inputSampleRateHz: 48_000,
                inputChannelCount: 1
            ),
            retentionPreferences: DiagnosticsReport.RetentionPreferencesInfo(
                autoCleanEnabled: true,
                retentionDays: 60
            ),
            recordingsCount: 12,
            appLaunchAt: Date(timeIntervalSince1970: 1_699_999_000),
            sessionReadyLatencySeconds: 1.6,
            sessionReadyTargetSeconds: 2.0,
            sessionReadyStatus: .onTarget
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
            captureDiagnostics: DiagnosticsReport.CaptureDiagnosticsInfo(
                backendStatus: "standard",
                inputDeviceName: "Built-in Mic",
                outputDeviceName: "Built-in Output",
                inputSampleRateHz: nil,
                inputChannelCount: nil
            ),
            retentionPreferences: DiagnosticsReport.RetentionPreferencesInfo(
                autoCleanEnabled: false,
                retentionDays: 30
            ),
            recordingsCount: 0,
            appLaunchAt: Date(timeIntervalSince1970: 1_699_999_500),
            sessionReadyLatencySeconds: nil,
            sessionReadyTargetSeconds: 2.0,
            sessionReadyStatus: .unknown
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

    func testReadinessStatusUsesTargetSeconds() {
        let appVersion = AppVersionInfo(infoDictionary: [
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "100"
        ])

        let reportOnTarget = DiagnosticsReport.make(
            appVersion: appVersion,
            systemVersion: "macOS 14.0",
            microphonePermission: .authorized,
            speechPermission: .authorized,
            capturePreferences: AudioCapturePreferences.default,
            captureDiagnostics: DiagnosticsReport.CaptureDiagnosticsInfo(
                backendStatus: "standard",
                inputDeviceName: "Built-in Mic",
                outputDeviceName: "Built-in Output",
                inputSampleRateHz: 48_000,
                inputChannelCount: 2
            ),
            retentionPreferences: RecordingRetentionPreferences.default,
            recordingsCount: 0,
            appLaunchAt: Date(timeIntervalSince1970: 1_700_000_000),
            sessionReadyLatencySeconds: 1.5,
            now: Date(timeIntervalSince1970: 1_700_000_010)
        )
        XCTAssertEqual(reportOnTarget.sessionReadyTargetSeconds, 2.0)
        XCTAssertEqual(reportOnTarget.sessionReadyStatus, .onTarget)

        let reportSlow = DiagnosticsReport.make(
            appVersion: appVersion,
            systemVersion: "macOS 14.0",
            microphonePermission: .authorized,
            speechPermission: .authorized,
            capturePreferences: AudioCapturePreferences.default,
            captureDiagnostics: DiagnosticsReport.CaptureDiagnosticsInfo(
                backendStatus: "standard",
                inputDeviceName: "Built-in Mic",
                outputDeviceName: "Built-in Output",
                inputSampleRateHz: 48_000,
                inputChannelCount: 2
            ),
            retentionPreferences: RecordingRetentionPreferences.default,
            recordingsCount: 0,
            appLaunchAt: Date(timeIntervalSince1970: 1_700_000_000),
            sessionReadyLatencySeconds: 2.1,
            now: Date(timeIntervalSince1970: 1_700_000_010)
        )
        XCTAssertEqual(reportSlow.sessionReadyStatus, .slow)

        let reportUnknown = DiagnosticsReport.make(
            appVersion: appVersion,
            systemVersion: "macOS 14.0",
            microphonePermission: .authorized,
            speechPermission: .authorized,
            capturePreferences: AudioCapturePreferences.default,
            captureDiagnostics: DiagnosticsReport.CaptureDiagnosticsInfo(
                backendStatus: "standard",
                inputDeviceName: "Built-in Mic",
                outputDeviceName: "Built-in Output",
                inputSampleRateHz: 48_000,
                inputChannelCount: 2
            ),
            retentionPreferences: RecordingRetentionPreferences.default,
            recordingsCount: 0,
            appLaunchAt: Date(timeIntervalSince1970: 1_700_000_000),
            sessionReadyLatencySeconds: nil,
            now: Date(timeIntervalSince1970: 1_700_000_010)
        )
        XCTAssertEqual(reportUnknown.sessionReadyStatus, .unknown)
    }
}
