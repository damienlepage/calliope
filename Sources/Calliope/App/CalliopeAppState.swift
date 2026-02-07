//
//  CalliopeAppState.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import SwiftUI

final class CalliopeAppState: ObservableObject {
    let audioCapture: AudioCapture
    let audioAnalyzer: AudioAnalyzer
    let feedbackViewModel: LiveFeedbackViewModel
    let microphonePermission: MicrophonePermissionManager
    let speechPermission: SpeechPermissionManager
    let microphoneDevices: MicrophoneDeviceManager
    let audioCapturePreferencesStore: AudioCapturePreferencesStore
    let recordingPreferencesStore: RecordingRetentionPreferencesStore
    let preferencesStore: AnalysisPreferencesStore
    let activePreferencesStore: ActiveAnalysisPreferencesStore
    let frontmostAppMonitor: FrontmostAppMonitor
    let recordingsViewModel: RecordingListViewModel
    let overlayPreferencesStore: OverlayPreferencesStore
    let perAppProfileStore: PerAppFeedbackProfileStore
    let coachingProfileStore: CoachingProfileStore
    let privacyDisclosureStore: PrivacyDisclosureStore
    let quickStartStore: QuickStartStore
    let settingsActionModel: MicrophoneSettingsActionModel
    let soundSettingsActionModel: SoundSettingsActionModel
    let speechSettingsActionModel: SpeechSettingsActionModel

    private var didConfigure = false

    init(
        audioCapturePreferencesStore: AudioCapturePreferencesStore = AudioCapturePreferencesStore(),
        recordingPreferencesStore: RecordingRetentionPreferencesStore = RecordingRetentionPreferencesStore(),
        overlayPreferencesStore: OverlayPreferencesStore = OverlayPreferencesStore(),
        perAppProfileStore: PerAppFeedbackProfileStore = PerAppFeedbackProfileStore(),
        coachingProfileStore: CoachingProfileStore = CoachingProfileStore(),
        privacyDisclosureStore: PrivacyDisclosureStore = PrivacyDisclosureStore(),
        quickStartStore: QuickStartStore = QuickStartStore(),
        settingsActionModel: MicrophoneSettingsActionModel = MicrophoneSettingsActionModel(),
        soundSettingsActionModel: SoundSettingsActionModel = SoundSettingsActionModel(),
        speechSettingsActionModel: SpeechSettingsActionModel = SpeechSettingsActionModel()
    ) {
        let basePreferencesStore = AnalysisPreferencesStore()
        let frontmostAppMonitor = FrontmostAppMonitor()
        let audioCapture = AudioCapture(
            capturePreferencesStore: audioCapturePreferencesStore
        )
        let activePreferencesStore = ActiveAnalysisPreferencesStore(
            basePreferencesStore: basePreferencesStore,
            coachingProfileStore: coachingProfileStore,
            perAppProfileStore: perAppProfileStore,
            frontmostAppPublisher: frontmostAppMonitor.$frontmostAppIdentifier.eraseToAnyPublisher(),
            recordingPublisher: audioCapture.$isRecording.eraseToAnyPublisher()
        )
        self.audioCapturePreferencesStore = audioCapturePreferencesStore
        self.recordingPreferencesStore = recordingPreferencesStore
        self.overlayPreferencesStore = overlayPreferencesStore
        self.perAppProfileStore = perAppProfileStore
        self.coachingProfileStore = coachingProfileStore
        self.privacyDisclosureStore = privacyDisclosureStore
        self.quickStartStore = quickStartStore
        self.settingsActionModel = settingsActionModel
        self.soundSettingsActionModel = soundSettingsActionModel
        self.speechSettingsActionModel = speechSettingsActionModel
        self.preferencesStore = basePreferencesStore
        self.frontmostAppMonitor = frontmostAppMonitor
        self.activePreferencesStore = activePreferencesStore
        self.audioCapture = audioCapture
        self.audioAnalyzer = AudioAnalyzer()
        self.feedbackViewModel = LiveFeedbackViewModel()
        self.microphonePermission = MicrophonePermissionManager()
        self.speechPermission = SpeechPermissionManager()
        self.microphoneDevices = MicrophoneDeviceManager()
        self.recordingsViewModel = RecordingListViewModel(
            recordingPreferencesStore: recordingPreferencesStore
        )
        configureIfNeeded()
    }

    func configureIfNeeded() {
        guard !didConfigure else { return }
        didConfigure = true

        audioAnalyzer.setup(
            audioCapture: audioCapture,
            preferencesStore: activePreferencesStore,
            speechPermission: speechPermission
        )
        feedbackViewModel.bind(
            feedbackPublisher: audioAnalyzer.feedbackPublisher,
            recordingPublisher: audioCapture.$isRecording.eraseToAnyPublisher(),
            transcriptionPublisher: audioAnalyzer.transcriptionPublisher
        )
        recordingsViewModel.bind(
            recordingPublisher: audioCapture.$isRecording.eraseToAnyPublisher()
        )
    }

    func refreshOnAppear() {
        microphonePermission.refresh()
        speechPermission.refresh()
        microphoneDevices.refresh()
        frontmostAppMonitor.refresh()
        audioCapture.refreshDiagnostics()
        WindowLevelController.apply(alwaysOnTop: overlayPreferencesStore.alwaysOnTop)
    }
}
