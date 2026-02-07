//
//  CaptureRecoveryActionMapper.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct CaptureRecoveryAction: Equatable {
    enum Kind: Equatable {
        case retryStart
        case openSettings
        case acknowledgeVoiceIsolationRisk
    }

    let hint: String
    let actionTitle: String
    let kind: Kind
}

struct CaptureRecoveryActionMapper {
    static func recoveryAction(for status: AudioCaptureStatus) -> CaptureRecoveryAction? {
        guard case .error(let error) = status else {
            return nil
        }
        return recoveryAction(for: error)
    }

    static func recoveryAction(for error: AudioCaptureError) -> CaptureRecoveryAction {
        switch error {
        case .microphonePermissionNotDetermined:
            return CaptureRecoveryAction(
                hint: "Grant microphone access in Settings to retry.",
                actionTitle: "Open Settings",
                kind: .openSettings
            )
        case .microphonePermissionDenied, .microphonePermissionRestricted:
            return CaptureRecoveryAction(
                hint: "Enable microphone access in Settings to resume.",
                actionTitle: "Open Settings",
                kind: .openSettings
            )
        case .microphoneUnavailable:
            return CaptureRecoveryAction(
                hint: "Connect or select a microphone, then try again.",
                actionTitle: "Open Settings",
                kind: .openSettings
            )
        case .privacyGuardrailsNotSatisfied:
            return CaptureRecoveryAction(
                hint: "Review privacy guardrails to continue.",
                actionTitle: "Open Settings",
                kind: .openSettings
            )
        case .voiceIsolationRiskNotAcknowledged:
            return CaptureRecoveryAction(
                hint: "Acknowledge the voice isolation warning to continue.",
                actionTitle: "I Understand",
                kind: .acknowledgeVoiceIsolationRisk
            )
        case .systemAudioCaptureNotAllowed:
            return CaptureRecoveryAction(
                hint: "Allow audio capture in Settings, then try again.",
                actionTitle: "Open Settings",
                kind: .openSettings
            )
        case .audioFileCreationFailed:
            return CaptureRecoveryAction(
                hint: "Retry capture. If it persists, check storage settings.",
                actionTitle: "Retry Start",
                kind: .retryStart
            )
        case .engineStartFailed:
            return CaptureRecoveryAction(
                hint: "Retry capture. If it persists, check your input device.",
                actionTitle: "Retry Start",
                kind: .retryStart
            )
        case .bufferWriteFailed:
            return CaptureRecoveryAction(
                hint: "Retry capture. If it persists, restart Calliope.",
                actionTitle: "Retry Start",
                kind: .retryStart
            )
        case .engineConfigurationChanged:
            return CaptureRecoveryAction(
                hint: "Input changed. Retry to restart capture.",
                actionTitle: "Retry Start",
                kind: .retryStart
            )
        case .captureStartTimedOut:
            return CaptureRecoveryAction(
                hint: "Capture did not start. Retry when ready.",
                actionTitle: "Retry Start",
                kind: .retryStart
            )
        case .captureStartValidationFailed:
            return CaptureRecoveryAction(
                hint: "No mic input detected. Check your mic and retry.",
                actionTitle: "Retry Start",
                kind: .retryStart
            )
        }
    }
}
