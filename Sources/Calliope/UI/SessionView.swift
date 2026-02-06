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
        ScrollView {
            VStack(spacing: 20) {
                Text("Calliope")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack {
                    Circle()
                        .fill(statusColor(for: audioCapture.status))
                        .frame(width: 12, height: 12)
                    Text(audioCapture.statusText)
                        .font(.headline)
                }
                if audioCapture.isRecording {
                    Text("Microphone: \(audioCapture.inputDeviceName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(audioCapture.backendStatusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                FeedbackPanel(
                    pace: feedbackViewModel.state.pace,
                    crutchWords: feedbackViewModel.state.crutchWords,
                    pauseCount: feedbackViewModel.state.pauseCount,
                    inputLevel: feedbackViewModel.state.inputLevel,
                    showSilenceWarning: feedbackViewModel.state.showSilenceWarning,
                    showWaitingForSpeech: feedbackViewModel.showWaitingForSpeech,
                    paceMin: preferencesStore.paceMin,
                    paceMax: preferencesStore.paceMax,
                    sessionDurationText: sessionDurationText
                )

                HStack(spacing: 20) {
                    Button(action: onToggleRecording) {
                        Text(audioCapture.isRecording ? "Stop" : "Start")
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
