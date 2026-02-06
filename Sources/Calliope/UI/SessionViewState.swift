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
        isRecording || status == .error
    }

    var primaryButtonTitle: String {
        isRecording ? "Stop" : "Start"
    }
}
