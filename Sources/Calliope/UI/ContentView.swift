//
//  ContentView.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var audioCapture = AudioCapture()
    @StateObject private var audioAnalyzer = AudioAnalyzer()
    @StateObject private var feedbackViewModel = LiveFeedbackViewModel()
    @State private var hasAcceptedDisclosure = false
    @State private var hasConfirmedHeadphones = false

    var body: some View {
        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: hasAcceptedDisclosure,
            hasConfirmedHeadphones: hasConfirmedHeadphones
        )
        VStack(spacing: 20) {
            Text("Calliope")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Recording status
            HStack {
                Circle()
                    .fill(audioCapture.isRecording ? Color.red : Color.gray)
                    .frame(width: 12, height: 12)
                Text(audioCapture.isRecording ? "Recording" : "Stopped")
                    .font(.headline)
            }

            // Real-time feedback panel (placeholder values)
            FeedbackPanel(
                pace: feedbackViewModel.state.pace,
                crutchWords: feedbackViewModel.state.crutchWords,
                pauseCount: feedbackViewModel.state.pauseCount
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(PrivacyGuardrails.disclosureTitle)
                    .font(.headline)
                Text(PrivacyGuardrails.disclosureBody)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Toggle("I understand Calliope only analyzes my mic input", isOn: $hasAcceptedDisclosure)
                Toggle("I am using headphones or a headset", isOn: $hasConfirmedHeadphones)
                if !PrivacyGuardrails.canStartRecording(state: privacyState) {
                    Text("Start is disabled until both privacy checks are confirmed.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Control buttons
            HStack(spacing: 20) {
                Button(action: toggleRecording) {
                    Text(audioCapture.isRecording ? "Stop" : "Start")
                        .frame(width: 100, height: 40)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!audioCapture.isRecording && !PrivacyGuardrails.canStartRecording(state: privacyState))
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .onAppear {
            audioAnalyzer.setup(audioCapture: audioCapture)
            feedbackViewModel.bind(
                feedbackPublisher: audioAnalyzer.feedbackPublisher,
                recordingPublisher: audioCapture.$isRecording.eraseToAnyPublisher()
            )
        }
    }

    private func toggleRecording() {
        if audioCapture.isRecording {
            audioCapture.stopRecording()
        } else {
            let privacyState = PrivacyGuardrails.State(
                hasAcceptedDisclosure: hasAcceptedDisclosure,
                hasConfirmedHeadphones: hasConfirmedHeadphones
            )
            audioCapture.startRecording(privacyState: privacyState)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
