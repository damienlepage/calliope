//
//  MicTestEligibility.swift
//  Calliope
//
//  Created on [Date]
//

struct MicTestEligibility {
    enum Reason: Equatable {
        case microphonePermissionNotDetermined
        case microphonePermissionDenied
        case microphonePermissionRestricted
        case microphoneUnavailable

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
            }
        }
    }

    static func blockingReasons(
        microphonePermission: MicrophonePermissionState,
        hasMicrophoneInput: Bool
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
        if !hasMicrophoneInput {
            reasons.append(.microphoneUnavailable)
        }
        return reasons
    }

    static func canRun(
        microphonePermission: MicrophonePermissionState,
        hasMicrophoneInput: Bool
    ) -> Bool {
        blockingReasons(
            microphonePermission: microphonePermission,
            hasMicrophoneInput: hasMicrophoneInput
        ).isEmpty
    }
}
