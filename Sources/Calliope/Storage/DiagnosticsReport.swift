//
//  DiagnosticsReport.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct DiagnosticsReport: Codable, Equatable {
    enum LaunchReadinessStatus: String, Codable, Equatable {
        case unknown
        case onTarget = "on_target"
        case slow
    }
    struct AppInfo: Codable, Equatable {
        let shortVersion: String?
        let buildVersion: String?
    }

    struct PermissionsInfo: Codable, Equatable {
        let microphone: String
        let speech: String
    }

    struct CapturePreferencesInfo: Codable, Equatable {
        let voiceIsolationEnabled: Bool
        let preferredMicrophoneName: String?
        let maxSegmentDurationSeconds: TimeInterval
    }

    struct CaptureDiagnosticsInfo: Codable, Equatable {
        let backendStatus: String
        let inputDeviceName: String
        let outputDeviceName: String
        let inputSampleRateHz: Double?
        let inputChannelCount: Int?
    }

    struct RetentionPreferencesInfo: Codable, Equatable {
        let autoCleanEnabled: Bool
        let retentionDays: Int
    }

    let createdAt: Date
    let app: AppInfo
    let systemVersion: String
    let permissions: PermissionsInfo
    let capturePreferences: CapturePreferencesInfo
    let captureDiagnostics: CaptureDiagnosticsInfo
    let retentionPreferences: RetentionPreferencesInfo
    let recordingsCount: Int
    let appLaunchAt: Date
    let sessionReadyLatencySeconds: TimeInterval?
    let sessionReadyTargetSeconds: TimeInterval
    let sessionReadyStatus: LaunchReadinessStatus

    static func make(
        appVersion: AppVersionInfo,
        systemVersion: String,
        microphonePermission: MicrophonePermissionState,
        speechPermission: SpeechPermissionState,
        capturePreferences: AudioCapturePreferences,
        captureDiagnostics: CaptureDiagnosticsInfo,
        retentionPreferences: RecordingRetentionPreferences,
        recordingsCount: Int,
        appLaunchAt: Date,
        sessionReadyLatencySeconds: TimeInterval?,
        now: Date = Date()
    ) -> DiagnosticsReport {
        let readinessTargetSeconds = LaunchReadinessTracker.targetSeconds
        return DiagnosticsReport(
            createdAt: now,
            app: AppInfo(
                shortVersion: appVersion.shortVersion,
                buildVersion: appVersion.buildVersion
            ),
            systemVersion: systemVersion,
            permissions: PermissionsInfo(
                microphone: permissionLabel(for: microphonePermission),
                speech: permissionLabel(for: speechPermission)
            ),
            capturePreferences: CapturePreferencesInfo(
                voiceIsolationEnabled: capturePreferences.voiceIsolationEnabled,
                preferredMicrophoneName: capturePreferences.preferredMicrophoneName,
                maxSegmentDurationSeconds: capturePreferences.maxSegmentDuration
            ),
            captureDiagnostics: captureDiagnostics,
            retentionPreferences: RetentionPreferencesInfo(
                autoCleanEnabled: retentionPreferences.autoCleanEnabled,
                retentionDays: retentionPreferences.retentionOption.days
            ),
            recordingsCount: recordingsCount,
            appLaunchAt: appLaunchAt,
            sessionReadyLatencySeconds: sessionReadyLatencySeconds,
            sessionReadyTargetSeconds: readinessTargetSeconds,
            sessionReadyStatus: readinessStatus(
                latencySeconds: sessionReadyLatencySeconds,
                targetSeconds: readinessTargetSeconds
            )
        )
    }

    static func filename(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "Calliope-Diagnostics-\(formatter.string(from: date)).json"
    }

    private static func permissionLabel(for state: MicrophonePermissionState) -> String {
        switch state {
        case .notDetermined:
            return "not_determined"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .authorized:
            return "authorized"
        }
    }

    private static func permissionLabel(for state: SpeechPermissionState) -> String {
        switch state {
        case .notDetermined:
            return "not_determined"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .authorized:
            return "authorized"
        }
    }

    private static func readinessStatus(
        latencySeconds: TimeInterval?,
        targetSeconds: TimeInterval
    ) -> LaunchReadinessStatus {
        guard let latencySeconds else {
            return .unknown
        }
        return latencySeconds <= targetSeconds ? .onTarget : .slow
    }
}
