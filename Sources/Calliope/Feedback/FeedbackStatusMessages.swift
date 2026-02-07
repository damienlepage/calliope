//
//  FeedbackStatusMessages.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct FeedbackStatusMessages: Equatable {
    let warnings: [String]
    let notes: [String]

    var isEmpty: Bool {
        warnings.isEmpty && notes.isEmpty
    }

    static func build(
        storageStatus: RecordingStorageStatus,
        interruptionMessage: String?,
        showSilenceWarning: Bool,
        showWaitingForSpeech: Bool
    ) -> FeedbackStatusMessages {
        var warnings: [String] = []
        var notes: [String] = []

        if let storageWarningText = RecordingStorageWarningFormatter.warningText(status: storageStatus) {
            warnings.append(storageWarningText)
        }
        if let interruptionMessage {
            warnings.append(interruptionMessage)
        }
        if showSilenceWarning {
            warnings.append("No mic input detected")
            notes.append("Check your microphone or input selection in Settings.")
        }
        if showWaitingForSpeech {
            notes.append("Waiting for speech")
        }

        return FeedbackStatusMessages(warnings: warnings, notes: notes)
    }
}
