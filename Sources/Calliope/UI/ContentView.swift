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
    @StateObject private var preferencesStore = AnalysisPreferencesStore()
    @StateObject private var overlayPreferencesStore: OverlayPreferencesStore
    @State private var privacyDisclosureStore: PrivacyDisclosureStore
    @State private var hasAcceptedDisclosure: Bool

    init(
        overlayPreferencesStore: OverlayPreferencesStore = OverlayPreferencesStore(),
        privacyDisclosureStore: PrivacyDisclosureStore = PrivacyDisclosureStore()
    ) {
        _privacyDisclosureStore = State(initialValue: privacyDisclosureStore)
        _overlayPreferencesStore = StateObject(wrappedValue: overlayPreferencesStore)
        _hasAcceptedDisclosure = State(initialValue: privacyDisclosureStore.hasAcceptedDisclosure)
    }

    var body: some View {
        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: hasAcceptedDisclosure
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
                    .fill(statusColor(for: audioCapture.status))
                    .frame(width: 12, height: 12)
                Text(audioCapture.statusText)
                    .font(.headline)
            }

            // Real-time feedback panel (placeholder values)
            FeedbackPanel(
                pace: feedbackViewModel.state.pace,
                crutchWords: feedbackViewModel.state.crutchWords,
                pauseCount: feedbackViewModel.state.pauseCount,
                paceMin: preferencesStore.paceMin,
                paceMax: preferencesStore.paceMax
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
                ForEach(PrivacyGuardrails.settingsStatements, id: \.self) { statement in
                    Text(statement)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Text("Recordings are stored locally at \(RecordingManager.shared.recordingsDirectoryURL().path)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Toggle("I understand Calliope only analyzes my mic input", isOn: $hasAcceptedDisclosure)
                if !blockingReasons.isEmpty {
                    Text(blockingReasonsText(blockingReasons))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("Sensitivity Preferences")
                    .font(.headline)
                HStack {
                    Text("Pace Min")
                        .font(.subheadline)
                    Spacer()
                    Stepper(
                        value: $preferencesStore.paceMin,
                        in: 60...220,
                        step: 5
                    ) {
                        Text("\(Int(preferencesStore.paceMin)) WPM")
                            .font(.subheadline)
                    }
                }
                HStack {
                    Text("Pace Max")
                        .font(.subheadline)
                    Spacer()
                    Stepper(
                        value: $preferencesStore.paceMax,
                        in: 80...260,
                        step: 5
                    ) {
                        Text("\(Int(preferencesStore.paceMax)) WPM")
                            .font(.subheadline)
                    }
                }
                HStack {
                    Text("Pause Threshold")
                        .font(.subheadline)
                    Spacer()
                    Stepper(
                        value: $preferencesStore.pauseThreshold,
                        in: 0.5...5.0,
                        step: 0.1
                    ) {
                        Text(String(format: "%.1f s", preferencesStore.pauseThreshold))
                            .font(.subheadline)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Crutch Words (comma or newline separated)")
                        .font(.subheadline)
                    TextField("uh, um, you know", text: crutchWordsBinding())
                        .textFieldStyle(.roundedBorder)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("Overlay")
                    .font(.headline)
                Toggle("Always on top", isOn: $overlayPreferencesStore.alwaysOnTop)
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
        .frame(width: 400, height: 620)
        .onAppear {
            audioAnalyzer.setup(audioCapture: audioCapture, preferencesStore: preferencesStore)
            feedbackViewModel.bind(
                feedbackPublisher: audioAnalyzer.feedbackPublisher,
                recordingPublisher: audioCapture.$isRecording.eraseToAnyPublisher()
            )
            microphonePermission.refresh()
            WindowLevelController.apply(alwaysOnTop: overlayPreferencesStore.alwaysOnTop)
        }
        .onChange(of: preferencesStore.paceMin) { newValue in
            if newValue > preferencesStore.paceMax {
                preferencesStore.paceMax = newValue
            }
        }
        .onChange(of: preferencesStore.paceMax) { newValue in
            if newValue < preferencesStore.paceMin {
                preferencesStore.paceMin = newValue
            }
        }
        .onChange(of: hasAcceptedDisclosure) { newValue in
            privacyDisclosureStore.hasAcceptedDisclosure = newValue
        }
        .onChange(of: overlayPreferencesStore.alwaysOnTop) { newValue in
            WindowLevelController.apply(alwaysOnTop: newValue)
        }
    }

    private func toggleRecording() {
        if audioCapture.isRecording {
            audioCapture.stopRecording()
        } else {
            let privacyState = PrivacyGuardrails.State(
                hasAcceptedDisclosure: hasAcceptedDisclosure
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

    private func crutchWordsBinding() -> Binding<String> {
        Binding(
            get: { AnalysisPreferencesStore.formatCrutchWords(preferencesStore.crutchWords) },
            set: { preferencesStore.crutchWords = AnalysisPreferencesStore.parseCrutchWords(from: $0) }
        )
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

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
