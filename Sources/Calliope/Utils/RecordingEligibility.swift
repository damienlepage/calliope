//
//  RecordingEligibility.swift
//  Calliope
//
//  Created on [Date]
//

struct RecordingEligibility {
    enum Reason: Equatable {
        case microphonePermissionNotDetermined
        case microphonePermissionDenied
        case microphonePermissionRestricted
        case microphoneUnavailable
        case disclosureNotAccepted

        var message: String {
            switch self {
            case .microphonePermissionNotDetermined:
                return "Microphone access is required. Click Grant Microphone Access."
            case .microphonePermissionDenied:
                return "Microphone access is denied. Enable it in System Settings > Privacy & Security > Microphone."
            case .microphonePermissionRestricted:
                return "Microphone access is restricted by system policy."
            case .microphoneUnavailable:
                return "No microphone input detected. Connect or enable a microphone."
            case .disclosureNotAccepted:
                return "Confirm the privacy disclosure."
            }
        }
    }

    static func blockingReasons(
        privacyState: PrivacyGuardrails.State,
        microphonePermission: MicrophonePermissionState,
        hasMicrophoneInput: Bool = true
    ) -> [Reason] {
        var reasons: [Reason] = []
        if microphonePermission != .authorized {
            switch microphonePermission {
            case .notDetermined:
                reasons.append(.microphonePermissionNotDetermined)
            case .denied:
                reasons.append(.microphonePermissionDenied)
            case .restricted:
                reasons.append(.microphonePermissionRestricted)
            case .authorized:
                break
            }
        }
        if microphonePermission == .authorized, !hasMicrophoneInput {
            reasons.append(.microphoneUnavailable)
        }
        if !privacyState.hasAcceptedDisclosure {
            reasons.append(.disclosureNotAccepted)
        }
        return reasons
    }

    static func canStart(
        privacyState: PrivacyGuardrails.State,
        microphonePermission: MicrophonePermissionState,
        hasMicrophoneInput: Bool = true
    ) -> Bool {
        blockingReasons(
            privacyState: privacyState,
            microphonePermission: microphonePermission,
            hasMicrophoneInput: hasMicrophoneInput
        ).isEmpty
    }
}
