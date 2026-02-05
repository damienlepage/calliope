//
//  ContentView.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var audioCapture: AudioCapture
    @StateObject private var audioAnalyzer = AudioAnalyzer()
    @StateObject private var feedbackViewModel = LiveFeedbackViewModel()
    @StateObject private var microphonePermission = MicrophonePermissionManager()
    @StateObject private var microphoneDevices = MicrophoneDeviceManager()
    @StateObject private var audioCapturePreferencesStore: AudioCapturePreferencesStore
    @StateObject private var preferencesStore = AnalysisPreferencesStore()
    @StateObject private var recordingsViewModel = RecordingListViewModel()
    @StateObject private var overlayPreferencesStore: OverlayPreferencesStore
    @State private var privacyDisclosureStore: PrivacyDisclosureStore
    @State private var hasAcceptedDisclosure: Bool
    @State private var isDisclosureSheetPresented: Bool
    private let settingsActionModel: MicrophoneSettingsActionModel

    init(
        audioCapturePreferencesStore: AudioCapturePreferencesStore = AudioCapturePreferencesStore(),
        overlayPreferencesStore: OverlayPreferencesStore = OverlayPreferencesStore(),
        privacyDisclosureStore: PrivacyDisclosureStore = PrivacyDisclosureStore(),
        settingsActionModel: MicrophoneSettingsActionModel = MicrophoneSettingsActionModel()
    ) {
        _privacyDisclosureStore = State(initialValue: privacyDisclosureStore)
        _overlayPreferencesStore = StateObject(wrappedValue: overlayPreferencesStore)
        _audioCapturePreferencesStore = StateObject(wrappedValue: audioCapturePreferencesStore)
        _audioCapture = StateObject(wrappedValue: AudioCapture(
            capturePreferencesStore: audioCapturePreferencesStore
        ))
        let accepted = privacyDisclosureStore.hasAcceptedDisclosure
        _hasAcceptedDisclosure = State(initialValue: accepted)
        _isDisclosureSheetPresented = State(
            initialValue: PrivacyDisclosureGate.requiresDisclosure(hasAcceptedDisclosure: accepted)
        )
        self.settingsActionModel = settingsActionModel
    }

    var body: some View {
        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: hasAcceptedDisclosure
        )
        let sessionDurationText = feedbackViewModel.sessionDurationSeconds
            .map(SessionDurationFormatter.format)
        let blockingReasons = RecordingEligibility.blockingReasons(
            privacyState: privacyState,
            microphonePermission: microphonePermission.state,
            hasMicrophoneInput: microphoneDevices.hasMicrophoneInput
        )
        let canStartRecording = blockingReasons.isEmpty
        let showOpenSettingsAction = settingsActionModel.shouldShow(for: blockingReasons)
        ZStack(alignment: .topTrailing) {
            ScrollView {
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
                    if audioCapture.isRecording {
                        Text("Microphone: \(audioCapture.inputDeviceName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(audioCapture.backendStatusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Real-time feedback panel (placeholder values)
                    FeedbackPanel(
                        pace: feedbackViewModel.state.pace,
                        crutchWords: feedbackViewModel.state.crutchWords,
                        pauseCount: feedbackViewModel.state.pauseCount,
                        inputLevel: feedbackViewModel.state.inputLevel,
                        showSilenceWarning: feedbackViewModel.state.showSilenceWarning,
                        paceMin: preferencesStore.paceMin,
                        paceMax: preferencesStore.paceMax,
                        sessionDurationText: sessionDurationText
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
                        if showOpenSettingsAction {
                            Button("Open System Settings") {
                                settingsActionModel.openSystemSettings()
                            }
                            .buttonStyle(.bordered)
                        }
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
                        Text(
                            hasAcceptedDisclosure
                                ? "Disclosure accepted."
                                : "Disclosure required before starting a session."
                        )
                        .font(.footnote)
                        .foregroundColor(.secondary)
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
                        Button("Reset to Defaults") {
                            preferencesStore.resetToDefaults()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overlay")
                            .font(.headline)
                        Toggle("Show compact overlay", isOn: $overlayPreferencesStore.showCompactOverlay)
                        Toggle("Always on top", isOn: $overlayPreferencesStore.alwaysOnTop)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capture")
                            .font(.headline)
                        Toggle("Enable voice isolation (if supported)", isOn: $audioCapturePreferencesStore.voiceIsolationEnabled)
                        Button("Test Mic") {
                            runMicTest()
                        }
                        .buttonStyle(.bordered)
                        .disabled(audioCapture.isRecording || audioCapture.isTestingMic)
                        if let statusText = audioCapture.micTestStatusText {
                            Text(statusText)
                                .font(.footnote)
                                .foregroundColor(micTestStatusColor(for: audioCapture.micTestStatus))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    RecordingsListView(viewModel: recordingsViewModel)

                    // Control buttons
                    HStack(spacing: 20) {
                        Button(action: toggleRecording) {
                            Text(audioCapture.isRecording ? "Stop" : "Start")
                                .frame(width: 100, height: 40)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(audioCapture.isTestingMic || (!audioCapture.isRecording && !canStartRecording))
                    }
                }
                .padding()
            }
            if OverlayVisibility.shouldShowCompactOverlay(
                isEnabled: overlayPreferencesStore.showCompactOverlay
            ) {
                CompactFeedbackOverlay(
                    pace: feedbackViewModel.state.pace,
                    crutchWords: feedbackViewModel.state.crutchWords,
                    pauseCount: feedbackViewModel.state.pauseCount,
                    inputLevel: feedbackViewModel.state.inputLevel,
                    showSilenceWarning: feedbackViewModel.state.showSilenceWarning,
                    paceMin: preferencesStore.paceMin,
                    paceMax: preferencesStore.paceMax,
                    sessionDurationText: sessionDurationText
                )
                .padding(.top, 12)
                .padding(.trailing, 12)
            }
        }
        .frame(width: 420, height: 760)
        .onAppear {
            audioAnalyzer.setup(audioCapture: audioCapture, preferencesStore: preferencesStore)
            feedbackViewModel.bind(
                feedbackPublisher: audioAnalyzer.feedbackPublisher,
                recordingPublisher: audioCapture.$isRecording.eraseToAnyPublisher()
            )
            recordingsViewModel.bind(
                recordingPublisher: audioCapture.$isRecording.eraseToAnyPublisher()
            )
            microphonePermission.refresh()
            microphoneDevices.refresh()
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
            isDisclosureSheetPresented = PrivacyDisclosureGate.requiresDisclosure(
                hasAcceptedDisclosure: newValue
            )
        }
        .onChange(of: overlayPreferencesStore.alwaysOnTop) { newValue in
            WindowLevelController.apply(alwaysOnTop: newValue)
        }
        .sheet(isPresented: $isDisclosureSheetPresented) {
            PrivacyDisclosureSheet(
                recordingsPath: RecordingManager.shared.recordingsDirectoryURL().path
            ) {
                hasAcceptedDisclosure = true
            }
            .interactiveDismissDisabled(true)
        }
    }

    private func toggleRecording() {
        if audioCapture.isRecording {
            audioCapture.stopRecording()
        } else {
            microphonePermission.refresh()
            microphoneDevices.refresh()
            let privacyState = PrivacyGuardrails.State(
                hasAcceptedDisclosure: hasAcceptedDisclosure
            )
            audioCapture.startRecording(
                privacyState: privacyState,
                microphonePermission: microphonePermission.state,
                hasMicrophoneInput: microphoneDevices.hasMicrophoneInput
            )
        }
    }

    private func runMicTest() {
        microphonePermission.refresh()
        microphoneDevices.refresh()
        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: hasAcceptedDisclosure
        )
        audioCapture.startMicTest(
            privacyState: privacyState,
            microphonePermission: microphonePermission.state,
            hasMicrophoneInput: microphoneDevices.hasMicrophoneInput
        )
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

    private func micTestStatusColor(for status: MicTestStatus) -> Color {
        switch status {
        case .idle:
            return .secondary
        case .running:
            return .secondary
        case .success:
            return .green
        case .failure:
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
