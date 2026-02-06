//
//  SessionView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct SessionView: View {
    @ObservedObject var audioCapture: AudioCapture
    @ObservedObject var feedbackViewModel: LiveFeedbackViewModel
    @ObservedObject var preferencesStore: AnalysisPreferencesStore
    let sessionDurationText: String?
    let canStartRecording: Bool
    let blockingReasonsText: String?
    let onToggleRecording: () -> Void

    var body: some View {
        let viewState = SessionViewState(
            isRecording: audioCapture.isRecording,
            status: audioCapture.status
        )
        ScrollView {
            VStack(spacing: 20) {
                Text("Calliope")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if viewState.shouldShowStatus {
                    HStack {
                        Circle()
                            .fill(statusColor(for: audioCapture.status))
                            .frame(width: 12, height: 12)
                        Text(audioCapture.statusText)
                            .font(.headline)
                    }
                }
                if viewState.shouldShowRecordingIndicators {
                    Text("Microphone: \(audioCapture.inputDeviceName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if viewState.shouldShowRecordingIndicators {
                    Text(audioCapture.backendStatusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if viewState.shouldShowIdlePrompt {
                    Text("Ready when you are. Press Start to begin coaching.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: 320)
                }
                if viewState.shouldShowFeedbackPanel {
                    FeedbackPanel(
                        pace: feedbackViewModel.state.pace,
                        crutchWords: feedbackViewModel.state.crutchWords,
                        pauseCount: feedbackViewModel.state.pauseCount,
                        pauseAverageDuration: feedbackViewModel.state.pauseAverageDuration,
                        inputLevel: feedbackViewModel.state.inputLevel,
                        showSilenceWarning: feedbackViewModel.state.showSilenceWarning,
                        showWaitingForSpeech: feedbackViewModel.showWaitingForSpeech,
                        paceMin: preferencesStore.paceMin,
                        paceMax: preferencesStore.paceMax,
                        sessionDurationText: sessionDurationText
                    )
                }

                HStack(spacing: 20) {
                    Button(action: onToggleRecording) {
                        Text(viewState.primaryButtonTitle)
                            .frame(width: 100, height: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        audioCapture.isTestingMic || (!audioCapture.isRecording && !canStartRecording)
                    )
                }

                if let blockingReasonsText {
                    Text(blockingReasonsText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusColor(for status: AudioCaptureStatus) -> Color {
        switch status {
        case .idle:
            return .gray
        case .recording:
            return .red
        case .error:
            return .orange
        }
    }
}

#Preview {
    SessionView(
        audioCapture: AudioCapture(capturePreferencesStore: AudioCapturePreferencesStore()),
        feedbackViewModel: LiveFeedbackViewModel(),
        preferencesStore: AnalysisPreferencesStore(),
        sessionDurationText: "00:32",
        canStartRecording: true,
        blockingReasonsText: nil,
        onToggleRecording: {}
    )
}
