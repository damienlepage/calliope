//
//  SessionViewState.swift
//  Calliope
//
//  Created on [Date]
//

struct SessionViewState: Equatable {
    let isRecording: Bool
    let status: AudioCaptureStatus
    let hasBlockingReasons: Bool

    var shouldShowTitle: Bool {
        if isRecording {
            return true
        }
        if case .error = status {
            return true
        }
        return false
    }

    var shouldShowIdlePrompt: Bool {
        if isRecording {
            return false
        }
        if case .error = status {
            return false
        }
        if hasBlockingReasons {
            return false
        }
        return true
    }

    var shouldShowFeedbackPanel: Bool {
        isRecording
    }

    var shouldShowStatus: Bool {
        if isRecording {
            return true
        }
        if case .error = status {
            return true
        }
        return false
    }

    var shouldShowBlockingReasons: Bool {
        guard !isRecording else { return false }
        if case .error = status {
            return true
        }
        return hasBlockingReasons
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
