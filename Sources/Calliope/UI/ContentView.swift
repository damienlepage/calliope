//
//  ContentView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

@MainActor
struct ContentView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    private let appState: CalliopeAppState
    @ObservedObject private var audioCapture: AudioCapture
    @ObservedObject private var feedbackViewModel: LiveFeedbackViewModel
    @ObservedObject private var microphonePermission: MicrophonePermissionManager
    @ObservedObject private var speechPermission: SpeechPermissionManager
    @ObservedObject private var microphoneDevices: MicrophoneDeviceManager
    @ObservedObject private var audioCapturePreferencesStore: AudioCapturePreferencesStore
    @ObservedObject private var preferencesStore: AnalysisPreferencesStore
    @ObservedObject private var activePreferencesStore: ActiveAnalysisPreferencesStore
    @ObservedObject private var recordingsViewModel: RecordingListViewModel
    @ObservedObject private var overlayPreferencesStore: OverlayPreferencesStore
    @ObservedObject private var coachingProfileStore: CoachingProfileStore
    @StateObject private var appLifecycleMonitor = AppLifecycleMonitor()
    private let privacyDisclosureStore: PrivacyDisclosureStore
    private let quickStartStore: QuickStartStore
    @State private var hasAcceptedDisclosure: Bool
    @State private var hasAcknowledgedVoiceIsolationRisk: Bool
    @State private var isDisclosureSheetPresented: Bool
    @State private var isQuickStartSheetPresented: Bool
    @State private var isQuickStartPending: Bool
    @State private var postSessionCoordinator = PostSessionReviewCoordinator()
    private let settingsActionModel: MicrophoneSettingsActionModel
    private let soundSettingsActionModel: SoundSettingsActionModel
    private let speechSettingsActionModel: SpeechSettingsActionModel
    private enum Layout {
        static let sessionWidth: CGFloat = 420
        static let recordingsWidth: CGFloat = 760
        static let settingsWidth: CGFloat = 520
        static let height: CGFloat = 760
    }
    private struct ViewState {
        let privacyState: PrivacyGuardrails.State
        let sessionDurationText: String?
        let sessionDurationSeconds: Int?
        let activePreferences: AnalysisPreferences
        let overlayCaptureStatusText: String
        let activeProfileLabel: String?
        let pendingSessionForTitle: CompletedRecordingSession?
        let postSessionReview: PostSessionReview?
        let defaultSessionTitle: String?
        let postSessionRecordingItem: RecordingItem?
        let requiresVoiceIsolationAcknowledgement: Bool
        let blockingReasons: [RecordingEligibility.Reason]
        let canStartRecording: Bool
        let showOpenSettingsAction: Bool
        let showOpenSoundSettingsAction: Bool
        let showOpenSpeechSettingsAction: Bool
        let blockingReasonsText: String?
        let voiceIsolationAcknowledgementMessage: String?
    }

    init(appState: CalliopeAppState) {
        self.appState = appState
        _audioCapture = ObservedObject(initialValue: appState.audioCapture)
        _feedbackViewModel = ObservedObject(initialValue: appState.feedbackViewModel)
        _microphonePermission = ObservedObject(initialValue: appState.microphonePermission)
        _speechPermission = ObservedObject(initialValue: appState.speechPermission)
        _microphoneDevices = ObservedObject(initialValue: appState.microphoneDevices)
        _audioCapturePreferencesStore = ObservedObject(
            initialValue: appState.audioCapturePreferencesStore
        )
        _preferencesStore = ObservedObject(initialValue: appState.preferencesStore)
        _activePreferencesStore = ObservedObject(initialValue: appState.activePreferencesStore)
        _recordingsViewModel = ObservedObject(initialValue: appState.recordingsViewModel)
        _overlayPreferencesStore = ObservedObject(initialValue: appState.overlayPreferencesStore)
        _coachingProfileStore = ObservedObject(initialValue: appState.coachingProfileStore)
        privacyDisclosureStore = appState.privacyDisclosureStore
        quickStartStore = appState.quickStartStore
        let accepted = privacyDisclosureStore.hasAcceptedDisclosure
        let hasSeenQuickStart = quickStartStore.hasSeenQuickStart
        _hasAcceptedDisclosure = State(initialValue: accepted)
        _hasAcknowledgedVoiceIsolationRisk = State(initialValue: false)
        _isDisclosureSheetPresented = State(
            initialValue: PrivacyDisclosureGate.requiresDisclosure(hasAcceptedDisclosure: accepted)
        )
        _isQuickStartSheetPresented = State(initialValue: accepted && !hasSeenQuickStart)
        _isQuickStartPending = State(initialValue: false)
        self.settingsActionModel = appState.settingsActionModel
        self.soundSettingsActionModel = appState.soundSettingsActionModel
        self.speechSettingsActionModel = appState.speechSettingsActionModel
    }

    var body: some View {
        content(viewState)
    }

    private var viewState: ViewState {
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
        let pendingSessionForTitle = postSessionCoordinator.pendingSessionForTitle
        let postSessionReview = postSessionCoordinator.postSessionReview
        let defaultSessionTitle = pendingSessionForTitle.map {
            RecordingMetadata.defaultSessionTitle(for: $0.createdAt)
        }
        let postSessionRecordingItem = postSessionReview.map {
            recordingsViewModel.item(for: $0.recordingURL)
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
        return ViewState(
            privacyState: privacyState,
            sessionDurationText: sessionDurationText,
            sessionDurationSeconds: sessionDurationSeconds,
            activePreferences: activePreferences,
            overlayCaptureStatusText: overlayCaptureStatusText,
            activeProfileLabel: activeProfileLabel,
            pendingSessionForTitle: pendingSessionForTitle,
            postSessionReview: postSessionReview,
            defaultSessionTitle: defaultSessionTitle,
            postSessionRecordingItem: postSessionRecordingItem,
            requiresVoiceIsolationAcknowledgement: requiresVoiceIsolationAcknowledgement,
            blockingReasons: blockingReasons,
            canStartRecording: canStartRecording,
            showOpenSettingsAction: showOpenSettingsAction,
            showOpenSoundSettingsAction: showOpenSoundSettingsAction,
            showOpenSpeechSettingsAction: showOpenSpeechSettingsAction,
            blockingReasonsText: blockingReasonsText,
            voiceIsolationAcknowledgementMessage: voiceIsolationAcknowledgementMessage
        )
    }

    @ViewBuilder
    private func content(_ viewState: ViewState) -> some View {
        contentWithSheets(viewState)
    }

    @ViewBuilder
    private func contentWithSheets(_ viewState: ViewState) -> some View {
        contentWithFocusedValues(viewState)
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

    @ViewBuilder
    private func contentWithFocusedValues(_ viewState: ViewState) -> some View {
        let toggleRecordingAction: (() -> Void)? = navigationState.selection == .session
            ? { toggleRecording() }
            : nil
        let refreshRecordingsAction: (() -> Void)? = navigationState.selection == .recordings
            ? { refreshRecordings() }
            : nil
        let openRecordingsFolderAction: (() -> Void)? = navigationState.selection == .recordings
            ? { openRecordingsFolder() }
            : nil

        contentWithLifecycle(viewState)
            .focusedSceneValue(
                \.toggleRecording,
                toggleRecordingAction
            )
            .focusedSceneValue(
                \.refreshRecordings,
                refreshRecordingsAction
            )
            .focusedSceneValue(
                \.openRecordingsFolder,
                openRecordingsFolderAction
            )
    }

    @ViewBuilder
    private func contentWithLifecycle(_ viewState: ViewState) -> some View {
        contentBase(viewState)
            .toolbar {
                contentToolbar()
            }
            .onAppear {
                appState.configureIfNeeded()
                appState.refreshOnAppear()
            }
            .onReceive(appLifecycleMonitor.$isActive) { isActive in
                guard isActive else { return }
                appState.refreshOnAppear()
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
                postSessionCoordinator.handleCompletedSession(newValue) { session in
                    loadPostSessionReview(for: session)
                }
            }
            .onChange(of: audioCapture.isRecording) { isRecording in
                if isRecording {
                    postSessionCoordinator.handleRecordingStarted()
                } else {
                    hasAcknowledgedVoiceIsolationRisk = false
                }
            }
            .onChange(of: overlayPreferencesStore.alwaysOnTop) { newValue in
                WindowLevelController.apply(alwaysOnTop: newValue)
            }
    }

    @ViewBuilder
    private func contentBase(_ viewState: ViewState) -> some View {
        ZStack(alignment: .topTrailing) {
            mainContent(viewState)
            overlayView(viewState)
        }
        .frame(width: contentWidth, height: Layout.height)
    }

    @ToolbarContentBuilder
    private func contentToolbar() -> some ToolbarContent {
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

    @ViewBuilder
    private func overlayView(_ viewState: ViewState) -> some View {
        if OverlayVisibility.shouldShowCompactOverlay(
            isEnabled: overlayPreferencesStore.showCompactOverlay,
            isRecording: audioCapture.isRecording
        ) {
            CompactFeedbackOverlay(
                pace: feedbackViewModel.state.pace,
                crutchWords: feedbackViewModel.state.crutchWords,
                pauseCount: feedbackViewModel.state.pauseCount,
                pauseAverageDuration: feedbackViewModel.state.pauseAverageDuration,
                speakingTimeSeconds: feedbackViewModel.state.speakingTimeSeconds,
                speakingTimeTargetPercent: viewState.activePreferences.speakingTimeTargetPercent,
                inputLevel: feedbackViewModel.state.inputLevel,
                showSilenceWarning: feedbackViewModel.state.showSilenceWarning,
                showWaitingForSpeech: feedbackViewModel.showWaitingForSpeech,
                captureStatusText: viewState.overlayCaptureStatusText,
                paceMin: viewState.activePreferences.paceMin,
                paceMax: viewState.activePreferences.paceMax,
                sessionDurationText: viewState.sessionDurationText,
                sessionDurationSeconds: viewState.sessionDurationSeconds,
                storageStatus: audioCapture.storageStatus,
                interruptionMessage: audioCapture.interruptionMessage,
                activeProfileLabel: viewState.activeProfileLabel
            )
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
    }

    @ViewBuilder
    private func mainContent(_ viewState: ViewState) -> some View {
        switch navigationState.selection {
        case .session:
            SessionView(
                audioCapture: audioCapture,
                feedbackViewModel: feedbackViewModel,
                analysisPreferences: viewState.activePreferences,
                coachingProfiles: coachingProfileStore.profiles,
                selectedCoachingProfileID: Binding(
                    get: { coachingProfileStore.selectedProfileID },
                    set: { coachingProfileStore.selectedProfileID = $0 }
                ),
                sessionDurationText: viewState.sessionDurationText,
                sessionDurationSeconds: viewState.sessionDurationSeconds,
                canStartRecording: viewState.canStartRecording,
                blockingReasonsText: viewState.blockingReasonsText,
                voiceIsolationAcknowledgementMessage: viewState.voiceIsolationAcknowledgementMessage,
                storageStatus: audioCapture.storageStatus,
                activeProfileLabel: viewState.activeProfileLabel,
                showTitlePrompt: viewState.pendingSessionForTitle != nil,
                defaultSessionTitle: viewState.defaultSessionTitle,
                postSessionReview: viewState.postSessionReview,
                postSessionRecordingItem: viewState.postSessionRecordingItem,
                sessionTitleDraft: Binding(
                    get: { postSessionCoordinator.sessionTitleDraft },
                    set: { postSessionCoordinator.sessionTitleDraft = $0 }
                ),
                onSaveSessionTitle: saveSessionTitle,
                onSkipSessionTitle: skipSessionTitle,
                onViewRecordings: { navigationState.selection = .recordings },
                onEditSessionTitle: {
                    editSessionTitle(using: viewState.postSessionRecordingItem)
                },
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
                coachingProfileStore: coachingProfileStore,
                hasAcceptedDisclosure: hasAcceptedDisclosure,
                recordingsPath: PathDisplayFormatter.displayPath(
                    RecordingManager.shared.recordingsDirectoryURL()
                ),
                showOpenSettingsAction: viewState.showOpenSettingsAction,
                showOpenSoundSettingsAction: viewState.showOpenSoundSettingsAction,
                showOpenSpeechSettingsAction: viewState.showOpenSpeechSettingsAction,
                onRequestMicAccess: microphonePermission.requestAccess,
                onRequestSpeechAccess: speechPermission.requestAccess,
                onOpenSystemSettings: settingsActionModel.openSystemSettings,
                onOpenSoundSettings: soundSettingsActionModel.openSoundSettings,
                onOpenSpeechSettings: speechSettingsActionModel.openSystemSettings
            )
        }
    }

    private var contentWidth: CGFloat {
        switch navigationState.selection {
        case .session:
            return Layout.sessionWidth
        case .recordings:
            return Layout.recordingsWidth
        case .settings:
            return Layout.settingsWidth
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

    private func refreshRecordings() {
        recordingsViewModel.refreshRecordings()
    }

    private func openRecordingsFolder() {
        recordingsViewModel.openRecordingsFolder()
    }

    private func saveSessionTitle() {
        guard let pendingSession = postSessionCoordinator.pendingSessionForTitle else { return }
        let didSave = RecordingManager.shared.saveSessionTitle(
            postSessionCoordinator.sessionTitleDraft,
            for: pendingSession.recordingURLs,
            createdAt: pendingSession.createdAt,
            coachingProfile: coachingProfileStore.selectedProfile
        )
        guard didSave else {
            skipSessionTitle()
            return
        }
        recordingsViewModel.refreshRecordings()
        postSessionCoordinator.handleTitleSaved()
    }

    private func skipSessionTitle() {
        postSessionCoordinator.handleTitleSkipped()
    }

    private func editSessionTitle(using recordingItem: RecordingItem?) {
        guard postSessionCoordinator.pendingSessionForTitle == nil else { return }
        if let title = recordingItem?.metadata?.title,
           let normalized = RecordingMetadata.normalizedTitle(title) {
            postSessionCoordinator.sessionTitleDraft = normalized
        } else {
            postSessionCoordinator.sessionTitleDraft = ""
        }
        postSessionCoordinator.handleEditTitle()
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
@MainActor
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(appState: CalliopeAppState())
            .environmentObject(AppNavigationState())
    }
}
#endif
