//
//  PrivacyGuardrails.swift
//  Calliope
//
//  Created on [Date]
//

struct PrivacyGuardrails {
    struct State: Equatable {
        var hasAcceptedDisclosure: Bool
    }

    static let disclosureTitle = "Privacy Guardrails"
    static let disclosureBody = "All audio processing stays on this Mac."
    static let settingsStatements = [
        "Only your microphone input is analyzed.",
        "System audio and other participants are never recorded."
    ]

    static func canStartRecording(state: State) -> Bool {
        state.hasAcceptedDisclosure
    }
}
