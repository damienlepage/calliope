//
//  SessionViewState.swift
//  Calliope
//
//  Created on [Date]
//

struct SessionViewState: Equatable {
    let isRecording: Bool
    let hasPausedSession: Bool

    var primaryButtonTitle: String {
        if isRecording {
            return "Stop"
        }
        if hasPausedSession {
            return "Resume"
        }
        return "Start"
    }

    var primaryButtonAccessibilityLabel: String {
        if isRecording {
            return "Stop recording"
        }
        if hasPausedSession {
            return "Resume recording"
        }
        return "Start recording"
    }

    var primaryButtonAccessibilityHint: String {
        if isRecording {
            return "Ends the current coaching session."
        }
        if hasPausedSession {
            return "Continues the current coaching session."
        }
        return "Begins a new coaching session."
    }
}
