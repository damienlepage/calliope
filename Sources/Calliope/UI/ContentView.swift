//
//  ContentView.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @StateObject private var audioCapture: AudioCapture
    @StateObject private var audioAnalyzer = AudioAnalyzer()
    @StateObject private var feedbackViewModel = LiveFeedbackViewModel()
    @StateObject private var microphonePermission = MicrophonePermissionManager()
    @StateObject private var speechPermission = SpeechPermissionManager()
    @StateObject private var microphoneDevices = MicrophoneDeviceManager()
    @StateObject private var audioCapturePreferencesStore: AudioCapturePreferencesStore
    @StateObject private var recordingPreferencesStore: RecordingRetentionPreferencesStore
    @StateObject private var preferencesStore = AnalysisPreferencesStore()
    @StateObject private var activePreferencesStore: ActiveAnalysisPreferencesStore
    @StateObject private var frontmostAppMonitor: FrontmostAppMonitor
    @StateObject private var recordingsViewModel: RecordingListViewModel
    @StateObject private var overlayPreferencesStore: OverlayPreferencesStore
    @StateObject private var perAppProfileStore: PerAppFeedbackProfileStore
    @StateObject private var coachingProfileStore: CoachingProfileStore
    @StateObject private var conferencingVerificationStore: ConferencingCompatibilityVerificationStore
    @State private var privacyDisclosureStore: PrivacyDisclosureStore
    @State private var quickStartStore: QuickStartStore
    @State private var hasAcceptedDisclosure: Bool
    @State private var hasAcknowledgedVoiceIsolationRisk: Bool
    @State private var isDisclosureSheetPresented: Bool
    @State private var isQuickStartSheetPresented: Bool
    @State private var isQuickStartPending: Bool
    @State private var pendingSessionForTitle: CompletedRecordingSession?
    @State private var postSessionReview: PostSessionReview?
    @State private var sessionTitleDraft: String = ""
    private let settingsActionModel: MicrophoneSettingsActionModel
    private let soundSettingsActionModel: SoundSettingsActionModel
    private let speechSettingsActionModel: SpeechSettingsActionModel
    private let recordingsFolderActionModel: RecordingsFolderActionModel

    init(
        audioCapturePreferencesStore: AudioCapturePreferencesStore = AudioCapturePreferencesStore(),
        recordingPreferencesStore: RecordingRetentionPreferencesStore = RecordingRetentionPreferencesStore(),
        overlayPreferencesStore: OverlayPreferencesStore = OverlayPreferencesStore(),
        perAppProfileStore: PerAppFeedbackProfileStore = PerAppFeedbackProfileStore(),
        coachingProfileStore: CoachingProfileStore = CoachingProfileStore(),
        conferencingVerificationStore: ConferencingCompatibilityVerificationStore = ConferencingCompatibilityVerificationStore(),
        privacyDisclosureStore: PrivacyDisclosureStore = PrivacyDisclosureStore(),
        quickStartStore: QuickStartStore = QuickStartStore(),
        settingsActionModel: MicrophoneSettingsActionModel = MicrophoneSettingsActionModel(),
        soundSettingsActionModel: SoundSettingsActionModel = SoundSettingsActionModel(),
        speechSettingsActionModel: SpeechSettingsActionModel = SpeechSettingsActionModel(),
        recordingsFolderActionModel: RecordingsFolderActionModel = RecordingsFolderActionModel()
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
        _privacyDisclosureStore = State(initialValue: privacyDisclosureStore)
        _quickStartStore = State(initialValue: quickStartStore)
        _overlayPreferencesStore = StateObject(wrappedValue: overlayPreferencesStore)
        _audioCapturePreferencesStore = StateObject(wrappedValue: audioCapturePreferencesStore)
        _recordingPreferencesStore = StateObject(wrappedValue: recordingPreferencesStore)
        _perAppProfileStore = StateObject(wrappedValue: perAppProfileStore)
        _coachingProfileStore = StateObject(wrappedValue: coachingProfileStore)
        _conferencingVerificationStore = StateObject(wrappedValue: conferencingVerificationStore)
        _preferencesStore = StateObject(wrappedValue: basePreferencesStore)
        _frontmostAppMonitor = StateObject(wrappedValue: frontmostAppMonitor)
        _activePreferencesStore = StateObject(wrappedValue: activePreferencesStore)
        _audioCapture = StateObject(wrappedValue: audioCapture)
        _recordingsViewModel = StateObject(wrappedValue: RecordingListViewModel(
            recordingPreferencesStore: recordingPreferencesStore
        ))
        let accepted = privacyDisclosureStore.hasAcceptedDisclosure
        let hasSeenQuickStart = quickStartStore.hasSeenQuickStart
        _hasAcceptedDisclosure = State(initialValue: accepted)
        _hasAcknowledgedVoiceIsolationRisk = State(initialValue: false)
        _isDisclosureSheetPresented = State(
            initialValue: PrivacyDisclosureGate.requiresDisclosure(hasAcceptedDisclosure: accepted)
        )
        _isQuickStartSheetPresented = State(initialValue: accepted && !hasSeenQuickStart)
        _isQuickStartPending = State(initialValue: false)
        self.settingsActionModel = settingsActionModel
        self.soundSettingsActionModel = soundSettingsActionModel
        self.speechSettingsActionModel = speechSettingsActionModel
        self.recordingsFolderActionModel = recordingsFolderActionModel
    }

    var body: some View {
        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: hasAcceptedDisclosure
        )
        let sessionDurationText = feedbackViewModel.sessionDurationSeconds
            .map(SessionDurationFormatter.format)
        let sessionDurationSeconds = feedbackViewModel.sessionDurationSeconds
        let activePreferences = activePreferencesStore.activePreferences
        let overlayCaptureStatusText = CaptureStatusFormatter.overlayStatusText(
            inputDeviceName: audioCapture.inputDeviceName,
            backendStatus: audioCapture.backendStatus
        )
        let activeProfileLabel = ActiveProfileLabelFormatter.labelText(
            isRecording: audioCapture.isRecording,
            coachingProfileName: coachingProfileStore.selectedProfile?.name,
            perAppProfile: activePreferencesStore.activeProfile
        )
        let defaultSessionTitle = pendingSessionForTitle.map {
            RecordingMetadata.defaultSessionTitle(for: $0.createdAt)
        }
        let requiresVoiceIsolationAcknowledgement = voiceIsolationAcknowledgementRequired()
        let blockingReasons = RecordingEligibility.blockingReasons(
            privacyState: privacyState,
            microphonePermission: microphonePermission.state,
            hasMicrophoneInput: microphoneDevices.hasMicrophoneInput,
            requiresVoiceIsolationAcknowledgement: requiresVoiceIsolationAcknowledgement,
            hasAcknowledgedVoiceIsolationRisk: hasAcknowledgedVoiceIsolationRisk
        )
        let canStartRecording = blockingReasons.isEmpty
        let showOpenSettingsAction = settingsActionModel.shouldShow(for: blockingReasons)
        let showOpenSoundSettingsAction = soundSettingsActionModel.shouldShow(for: blockingReasons)
        let showOpenSpeechSettingsAction = speechSettingsActionModel.shouldShow(
            state: speechPermission.state
        )
        let blockingReasonsText = blockingReasonsText(blockingReasons)
        let voiceIsolationAcknowledgementMessage = blockingReasons.first(
            where: { $0 == .voiceIsolationRiskUnacknowledged }
        )?.message
        ZStack(alignment: .topTrailing) {
            Group {
                switch navigationState.selection {
                case .session:
                    SessionView(
                        audioCapture: audioCapture,
                        feedbackViewModel: feedbackViewModel,
                        analysisPreferences: activePreferences,
                        coachingProfiles: coachingProfileStore.profiles,
                        selectedCoachingProfileID: Binding(
                            get: { coachingProfileStore.selectedProfileID },
                            set: { coachingProfileStore.selectedProfileID = $0 }
                        ),
                        sessionDurationText: sessionDurationText,
                        sessionDurationSeconds: sessionDurationSeconds,
                        canStartRecording: canStartRecording,
                        blockingReasonsText: blockingReasonsText,
                        voiceIsolationAcknowledgementMessage: voiceIsolationAcknowledgementMessage,
                        storageStatus: audioCapture.storageStatus,
                        activeProfileLabel: activeProfileLabel,
                        showTitlePrompt: pendingSessionForTitle != nil,
                        defaultSessionTitle: defaultSessionTitle,
                        titleSummary: postSessionReview?.summary,
                        sessionTitleDraft: $sessionTitleDraft,
                        onSaveSessionTitle: saveSessionTitle,
                        onSkipSessionTitle: skipSessionTitle,
                        onViewRecordings: { navigationState.selection = .recordings },
                        onAcknowledgeVoiceIsolationRisk: acknowledgeVoiceIsolationRisk,
                        onOpenSettings: { navigationState.selection = .settings },
                        onRetryCapture: toggleRecording,
                        onToggleRecording: toggleRecording
                    )
                case .recordings:
                    RecordingsView(viewModel: recordingsViewModel)
                case .settings:
                    SettingsView(
                        microphonePermission: microphonePermission,
                        speechPermission: speechPermission,
                        microphoneDevices: microphoneDevices,
                        preferencesStore: preferencesStore,
                        overlayPreferencesStore: overlayPreferencesStore,
                        audioCapturePreferencesStore: audioCapturePreferencesStore,
                        recordingPreferencesStore: recordingPreferencesStore,
                        perAppProfileStore: perAppProfileStore,
                        coachingProfileStore: coachingProfileStore,
                        conferencingVerificationStore: conferencingVerificationStore,
                        audioCapture: audioCapture,
                        audioAnalyzer: audioAnalyzer,
                        hasAcceptedDisclosure: hasAcceptedDisclosure,
                        recordingsPath: PathDisplayFormatter.displayPath(
                            RecordingManager.shared.recordingsDirectoryURL()
                        ),
                        showOpenSettingsAction: showOpenSettingsAction,
                        showOpenSoundSettingsAction: showOpenSoundSettingsAction,
                        showOpenSpeechSettingsAction: showOpenSpeechSettingsAction,
                        onRequestMicAccess: microphonePermission.requestAccess,
                        onRequestSpeechAccess: speechPermission.requestAccess,
                        onOpenSystemSettings: settingsActionModel.openSystemSettings,
                        onOpenSoundSettings: soundSettingsActionModel.openSoundSettings,
                        onOpenSpeechSettings: speechSettingsActionModel.openSystemSettings,
                        onOpenRecordingsFolder: recordingsFolderActionModel.openRecordingsFolder,
                        onRunMicTest: runMicTest,
                        onShowQuickStart: showQuickStart
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
                        processingUtilizationStatus: feedbackViewModel.state.processingUtilizationStatus,
                        processingUtilizationAverage: feedbackViewModel.state.processingUtilizationAverage,
                        captureStatusText: overlayCaptureStatusText,
                        paceMin: activePreferences.paceMin,
                        paceMax: activePreferences.paceMax,
                        sessionDurationText: sessionDurationText,
                        sessionDurationSeconds: sessionDurationSeconds,
                        storageStatus: audioCapture.storageStatus,
                    interruptionMessage: audioCapture.interruptionMessage,
                    activeProfileLabel: activeProfileLabel
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
                .accessibilityLabel("View")
                .accessibilityHint("Switch between Session, Recordings, and Settings.")
            }
        }
        .onAppear {
            audioAnalyzer.setup(
                audioCapture: audioCapture,
                preferencesStore: activePreferencesStore,
                speechPermission: speechPermission
            )
            feedbackViewModel.bind(
                feedbackPublisher: audioAnalyzer.feedbackPublisher,
                recordingPublisher: audioCapture.$isRecording.eraseToAnyPublisher()
            )
            recordingsViewModel.bind(
                recordingPublisher: audioCapture.$isRecording.eraseToAnyPublisher()
            )
            microphonePermission.refresh()
            speechPermission.refresh()
            microphoneDevices.refresh()
            frontmostAppMonitor.refresh()
            audioCapture.refreshDiagnostics()
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
            if newValue, !quickStartStore.hasSeenQuickStart {
                isQuickStartPending = true
            }
        }
        .onChange(of: isDisclosureSheetPresented) { newValue in
            if !newValue, isQuickStartPending {
                isQuickStartSheetPresented = true
                isQuickStartPending = false
            }
        }
        .onChange(of: audioCapture.completedRecordingSession) { newValue in
            guard let newValue else { return }
            writeDefaultMetadata(for: newValue)
            pendingSessionForTitle = newValue
            postSessionReview = loadPostSessionReview(for: newValue)
            sessionTitleDraft = ""
        }
        .onChange(of: pendingSessionForTitle) { newValue in
            guard let newValue else {
                postSessionReview = nil
                return
            }
            postSessionReview = loadPostSessionReview(for: newValue)
        }
        .onChange(of: audioCapture.isRecording) { isRecording in
            if !isRecording {
                hasAcknowledgedVoiceIsolationRisk = false
            }
        }
        .onChange(of: overlayPreferencesStore.alwaysOnTop) { newValue in
            WindowLevelController.apply(alwaysOnTop: newValue)
        }
        .focusedSceneValue(
            \.toggleRecording,
            navigationState.selection == .session ? toggleRecording : nil
        )
        .focusedSceneValue(
            \.refreshRecordings,
            navigationState.selection == .recordings ? refreshRecordings : nil
        )
        .focusedSceneValue(
            \.openRecordingsFolder,
            navigationState.selection == .recordings ? openRecordingsFolder : nil
        )
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
        .sheet(isPresented: $isQuickStartSheetPresented) {
            QuickStartSheet {
                quickStartStore.hasSeenQuickStart = true
                isQuickStartSheetPresented = false
            }
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
                hasMicrophoneInput: microphoneDevices.hasMicrophoneInput,
                requiresVoiceIsolationAcknowledgement: voiceIsolationAcknowledgementRequired(),
                hasAcknowledgedVoiceIsolationRisk: hasAcknowledgedVoiceIsolationRisk
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

    private func refreshRecordings() {
        recordingsViewModel.refreshRecordings()
    }

    private func openRecordingsFolder() {
        recordingsViewModel.openRecordingsFolder()
    }

    private func showQuickStart() {
        isQuickStartSheetPresented = true
    }

    private func saveSessionTitle() {
        guard let pendingSession = pendingSessionForTitle else { return }
        let didSave = RecordingManager.shared.saveSessionTitle(
            sessionTitleDraft,
            for: pendingSession.recordingURLs,
            createdAt: pendingSession.createdAt,
            coachingProfile: coachingProfileStore.selectedProfile
        )
        guard didSave else {
            skipSessionTitle()
            return
        }
        recordingsViewModel.refreshRecordings()
        pendingSessionForTitle = nil
        postSessionReview = nil
        sessionTitleDraft = ""
    }

    private func skipSessionTitle() {
        pendingSessionForTitle = nil
        postSessionReview = nil
        sessionTitleDraft = ""
    }

    private func writeDefaultMetadata(for session: CompletedRecordingSession) {
        RecordingManager.shared.writeDefaultMetadataIfNeeded(
            for: session.recordingURLs,
            createdAt: session.createdAt,
            coachingProfile: coachingProfileStore.selectedProfile
        )
    }

    private func loadPostSessionReview(for session: CompletedRecordingSession) -> PostSessionReview? {
        PostSessionReview(session: session)
    }

    private func blockingReasonsText(_ reasons: [RecordingEligibility.Reason]) -> String? {
        guard !reasons.isEmpty else {
            return nil
        }
        let details = reasons.map(\.message).joined(separator: " ")
        return "Start is disabled. \(details)"
    }

    private func acknowledgeVoiceIsolationRisk() {
        hasAcknowledgedVoiceIsolationRisk = true
    }

    private func voiceIsolationAcknowledgementRequired() -> Bool {
        AudioRouteWarningEvaluator.requiresVoiceIsolationAcknowledgement(
            inputDeviceName: audioCapture.inputDeviceName,
            outputDeviceName: audioCapture.outputDeviceName,
            backendStatus: audioCapture.backendStatus
        )
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppNavigationState())
    }
}
#endif
