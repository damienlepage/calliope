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
    static let disclosureBody = "Calliope only processes your microphone input. Use headphones to avoid capturing other participants."

    static func canStartRecording(state: State) -> Bool {
        state.hasAcceptedDisclosure && state.hasConfirmedHeadphones
    }
}
