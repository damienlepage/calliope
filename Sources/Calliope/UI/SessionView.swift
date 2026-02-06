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
    let sessionDurationSeconds: Int?
    let canStartRecording: Bool
    let blockingReasonsText: String?
    let storageStatus: RecordingStorageStatus
    let onToggleRecording: () -> Void

    var body: some View {
        let viewState = SessionViewState(
            isRecording: audioCapture.isRecording,
            status: audioCapture.status,
            hasBlockingReasons: blockingReasonsText != nil
        )
        let captureStatusText = CaptureStatusFormatter.statusText(
            inputDeviceName: audioCapture.inputDeviceName,
            backendStatus: audioCapture.backendStatus,
            isRecording: audioCapture.isRecording
        )
        ScrollView {
            VStack(spacing: 20) {
                if viewState.shouldShowTitle {
                    Text("Calliope")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                if viewState.shouldShowStatus {
                    HStack {
                        Circle()
                            .fill(statusColor(for: audioCapture.status))
                            .frame(width: 12, height: 12)
                        Text(audioCapture.statusText)
                            .font(.headline)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Session status")
                    .accessibilityValue(audioCapture.statusText)
                }
                if let captureStatusText {
                    Text(captureStatusText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Capture status")
                        .accessibilityValue(captureStatusText)
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
                        processingLatencyStatus: feedbackViewModel.state.processingLatencyStatus,
                        processingLatencyAverage: feedbackViewModel.state.processingLatencyAverage,
                        processingUtilizationStatus: feedbackViewModel.state.processingUtilizationStatus,
                        processingUtilizationAverage: feedbackViewModel.state.processingUtilizationAverage,
                        paceMin: preferencesStore.paceMin,
                        paceMax: preferencesStore.paceMax,
                        sessionDurationText: sessionDurationText,
                        sessionDurationSeconds: sessionDurationSeconds,
                        storageStatus: storageStatus
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
                    .accessibilityLabel(viewState.primaryButtonAccessibilityLabel)
                    .accessibilityHint(viewState.primaryButtonAccessibilityHint)
                }

                if viewState.shouldShowBlockingReasons, let blockingReasonsText {
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
        sessionDurationSeconds: 32,
        canStartRecording: true,
        blockingReasonsText: nil,
        storageStatus: .ok,
        onToggleRecording: {}
    )
}
