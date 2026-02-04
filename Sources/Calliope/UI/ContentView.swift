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
    @StateObject private var microphonePermission = MicrophonePermissionManager()
    @State private var hasAcceptedDisclosure = false
    @State private var hasConfirmedHeadphones = false

    var body: some View {
        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: hasAcceptedDisclosure,
            hasConfirmedHeadphones: hasConfirmedHeadphones
        )
        let blockingReasons = RecordingEligibility.blockingReasons(
            privacyState: privacyState,
            microphonePermission: microphonePermission.state
        )
        let canStartRecording = blockingReasons.isEmpty
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
                Text("Microphone Access")
                    .font(.headline)
                Text(microphonePermissionDescription(for: microphonePermission.state))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button("Grant Microphone Access") {
                    microphonePermission.requestAccess()
                }
                .buttonStyle(.bordered)
                .disabled(microphonePermission.state == .authorized)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text(PrivacyGuardrails.disclosureTitle)
                    .font(.headline)
                Text(PrivacyGuardrails.disclosureBody)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Recordings are stored locally at \(RecordingManager.shared.recordingsDirectoryURL().path)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Toggle("I understand Calliope only analyzes my mic input", isOn: $hasAcceptedDisclosure)
                Toggle("I am using headphones or a headset", isOn: $hasConfirmedHeadphones)
                if !blockingReasons.isEmpty {
                    Text(blockingReasonsText(blockingReasons))
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
                .disabled(!audioCapture.isRecording && !canStartRecording)
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
            microphonePermission.refresh()
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
            audioCapture.startRecording(
                privacyState: privacyState,
                microphonePermission: microphonePermission.state
            )
        }
    }

    private func microphonePermissionDescription(for state: MicrophonePermissionState) -> String {
        switch state {
        case .authorized:
            return "Microphone access is granted."
        case .notDetermined:
            return "Microphone access is required for live coaching."
        case .denied:
            return "Microphone access is denied. Enable it in System Settings > Privacy & Security > Microphone."
        case .restricted:
            return "Microphone access is restricted by system policy."
        }
    }

    private func blockingReasonsText(_ reasons: [RecordingEligibility.Reason]) -> String {
        let details = reasons.map(\.message).joined(separator: " ")
        return "Start is disabled. \(details)"
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
