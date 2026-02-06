//
//  SessionViewState.swift
//  Calliope
//
//  Created on [Date]
//

struct SessionViewState: Equatable {
    let isRecording: Bool
    let status: AudioCaptureStatus

    var shouldShowIdlePrompt: Bool {
        !isRecording
    }

    var shouldShowFeedbackPanel: Bool {
        isRecording
    }

    var shouldShowRecordingIndicators: Bool {
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
        !isRecording
    }

    var primaryButtonTitle: String {
        isRecording ? "Stop" : "Start"
    }
}
