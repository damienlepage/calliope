//
//  RecordingEligibility.swift
//  Calliope
//
//  Created on [Date]
//

struct RecordingEligibility {
    static func canStart(
        privacyState: PrivacyGuardrails.State,
        microphonePermission: MicrophonePermissionState
    ) -> Bool {
        PrivacyGuardrails.canStartRecording(state: privacyState)
            && microphonePermission == .authorized
    }
}
