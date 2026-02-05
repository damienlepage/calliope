//
//  PrivacyGuardrails.swift
//  Calliope
//
//  Created on [Date]
//

struct PrivacyGuardrails {
    struct State: Equatable {
        var hasAcceptedDisclosure: Bool
        var hasConfirmedHeadphones: Bool
    }

    static let disclosureTitle = "Privacy Guardrails"
    static let disclosureBody = "Calliope only processes your microphone input for live coaching."
    static let settingsStatements = [
        "All audio processing stays on this Mac.",
        "Only your microphone input is analyzed.",
        "System audio and other participants are never recorded."
    ]

    static func canStartRecording(state: State) -> Bool {
        state.hasAcceptedDisclosure && state.hasConfirmedHeadphones
    }
}
