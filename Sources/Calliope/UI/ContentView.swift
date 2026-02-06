//
//  ContentView.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var navigationState = AppNavigationState()
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
    private let soundSettingsActionModel: SoundSettingsActionModel
    private let recordingsFolderActionModel: RecordingsFolderActionModel

    init(
        audioCapturePreferencesStore: AudioCapturePreferencesStore = AudioCapturePreferencesStore(),
        overlayPreferencesStore: OverlayPreferencesStore = OverlayPreferencesStore(),
        privacyDisclosureStore: PrivacyDisclosureStore = PrivacyDisclosureStore(),
        settingsActionModel: MicrophoneSettingsActionModel = MicrophoneSettingsActionModel(),
        soundSettingsActionModel: SoundSettingsActionModel = SoundSettingsActionModel(),
        recordingsFolderActionModel: RecordingsFolderActionModel = RecordingsFolderActionModel()
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
        self.soundSettingsActionModel = soundSettingsActionModel
        self.recordingsFolderActionModel = recordingsFolderActionModel
    }

    var body: some View {
        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: hasAcceptedDisclosure
        )
        let sessionDurationText = feedbackViewModel.sessionDurationSeconds
            .map(SessionDurationFormatter.format)
        let sessionDurationSeconds = feedbackViewModel.sessionDurationSeconds
        let overlayCaptureStatusText = CaptureStatusFormatter.overlayStatusText(
            inputDeviceName: audioCapture.inputDeviceName,
            backendStatus: audioCapture.backendStatus
        )
        let blockingReasons = RecordingEligibility.blockingReasons(
            privacyState: privacyState,
            microphonePermission: microphonePermission.state,
            hasMicrophoneInput: microphoneDevices.hasMicrophoneInput
        )
        let canStartRecording = blockingReasons.isEmpty
        let showOpenSettingsAction = settingsActionModel.shouldShow(for: blockingReasons)
        let showOpenSoundSettingsAction = soundSettingsActionModel.shouldShow(for: blockingReasons)
        let blockingReasonsText = blockingReasonsText(blockingReasons)
        ZStack(alignment: .topTrailing) {
            Group {
                switch navigationState.selection {
                case .session:
                    SessionView(
                        audioCapture: audioCapture,
                        feedbackViewModel: feedbackViewModel,
                        preferencesStore: preferencesStore,
                        sessionDurationText: sessionDurationText,
                        sessionDurationSeconds: sessionDurationSeconds,
                        canStartRecording: canStartRecording,
                        blockingReasonsText: blockingReasonsText,
                        onToggleRecording: toggleRecording
                    )
                case .recordings:
                    RecordingsView(viewModel: recordingsViewModel)
                case .settings:
                    SettingsView(
                        microphonePermission: microphonePermission,
                        microphoneDevices: microphoneDevices,
                        preferencesStore: preferencesStore,
                        overlayPreferencesStore: overlayPreferencesStore,
                        audioCapturePreferencesStore: audioCapturePreferencesStore,
                        audioCapture: audioCapture,
                        hasAcceptedDisclosure: hasAcceptedDisclosure,
                        recordingsPath: PathDisplayFormatter.displayPath(
                            RecordingManager.shared.recordingsDirectoryURL()
                        ),
                        showOpenSettingsAction: showOpenSettingsAction,
                        showOpenSoundSettingsAction: showOpenSoundSettingsAction,
                        onRequestMicAccess: microphonePermission.requestAccess,
                        onOpenSystemSettings: settingsActionModel.openSystemSettings,
                        onOpenSoundSettings: soundSettingsActionModel.openSoundSettings,
                        onOpenRecordingsFolder: recordingsFolderActionModel.openRecordingsFolder,
                        onRunMicTest: runMicTest
                    )
                }
            }
            if OverlayVisibility.shouldShowCompactOverlay(
                isEnabled: overlayPreferencesStore.showCompactOverlay,
                isRecording: audioCapture.isRecording
            ) {
                CompactFeedbackOverlay(
                    pace: feedbackViewModel.state.pace,
                    crutchWords: feedbackViewModel.state.crutchWords,
                    pauseCount: feedbackViewModel.state.pauseCount,
                    pauseAverageDuration: feedbackViewModel.state.pauseAverageDuration,
                    inputLevel: feedbackViewModel.state.inputLevel,
                    showSilenceWarning: feedbackViewModel.state.showSilenceWarning,
                    showWaitingForSpeech: feedbackViewModel.showWaitingForSpeech,
                    processingLatencyStatus: feedbackViewModel.state.processingLatencyStatus,
                    processingLatencyAverage: feedbackViewModel.state.processingLatencyAverage,
                    captureStatusText: overlayCaptureStatusText,
                    paceMin: preferencesStore.paceMin,
                    paceMax: preferencesStore.paceMax,
                    sessionDurationText: sessionDurationText,
                    sessionDurationSeconds: sessionDurationSeconds
                )
                .padding(.top, 12)
                .padding(.trailing, 12)
            }
        }
        .frame(width: 420, height: 760)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("View", selection: $navigationState.selection) {
                    ForEach(AppSection.allCases) { section in
                        Text(section.title)
                            .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            }
        }
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
                recordingsPath: PathDisplayFormatter.displayPath(
                    RecordingManager.shared.recordingsDirectoryURL()
                )
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

    private func blockingReasonsText(_ reasons: [RecordingEligibility.Reason]) -> String? {
        guard !reasons.isEmpty else {
            return nil
        }
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
