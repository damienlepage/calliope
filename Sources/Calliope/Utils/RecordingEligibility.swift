//
//  RecordingEligibility.swift
//  Calliope
//
//  Created on [Date]
//

struct RecordingEligibility {
    enum Reason: Equatable {
        case microphonePermissionMissing
        case disclosureNotAccepted

        var message: String {
            switch self {
            case .microphonePermissionMissing:
                return "Microphone access is required."
            case .disclosureNotAccepted:
                return "Confirm the privacy disclosure."
            }
        }
    }

    static func blockingReasons(
        privacyState: PrivacyGuardrails.State,
        microphonePermission: MicrophonePermissionState
    ) -> [Reason] {
        var reasons: [Reason] = []
        if microphonePermission != .authorized {
            reasons.append(.microphonePermissionMissing)
        }
        if !privacyState.hasAcceptedDisclosure {
            reasons.append(.disclosureNotAccepted)
        }
        return reasons
    }

    static func canStart(
        privacyState: PrivacyGuardrails.State,
        microphonePermission: MicrophonePermissionState
    ) -> Bool {
        blockingReasons(
            privacyState: privacyState,
            microphonePermission: microphonePermission
        ).isEmpty
    }
}
