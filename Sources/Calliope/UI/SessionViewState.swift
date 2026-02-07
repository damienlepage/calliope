//
//  SessionViewState.swift
//  Calliope
//
//  Created on [Date]
//

struct SessionViewState: Equatable {
    let isRecording: Bool

    var shouldShowIdlePrompt: Bool {
        !isRecording
    }

    var shouldShowFeedbackPanel: Bool {
        true
    }

    var primaryButtonTitle: String {
        isRecording ? "Stop" : "Start"
    }

    var primaryButtonAccessibilityLabel: String {
        isRecording ? "Stop recording" : "Start recording"
    }

    var primaryButtonAccessibilityHint: String {
        isRecording
            ? "Ends the current coaching session."
            : "Begins a new coaching session."
    }
}
