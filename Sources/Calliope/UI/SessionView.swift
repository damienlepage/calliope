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
    let analysisPreferences: AnalysisPreferences
    let coachingProfiles: [CoachingProfile]
    @Binding var selectedCoachingProfileID: UUID?
    let sessionDurationText: String?
    let sessionDurationSeconds: Int?
    let canStartRecording: Bool
    let blockingReasonsText: String?
    let voiceIsolationAcknowledgementMessage: String?
    let storageStatus: RecordingStorageStatus
    let activeProfileLabel: String?
    let showTitlePrompt: Bool
    let defaultSessionTitle: String?
    let postSessionReview: PostSessionReview?
    let postSessionRecordingItem: RecordingItem?
    let isPostSessionPlaybackActive: Bool
    let isPostSessionPlaybackPaused: Bool
    @Binding var sessionTitleDraft: String
    let onSaveSessionTitle: () -> Void
    let onSkipSessionTitle: () -> Void
    let onViewRecordings: () -> Void
    let onPostSessionPlayPause: () -> Void
    let onPostSessionReveal: () -> Void
    let onAcknowledgeVoiceIsolationRisk: () -> Void
    let onOpenSettings: () -> Void
    let onRetryCapture: () -> Void
    let onToggleRecording: () -> Void
    @State private var postSessionDetailItem: RecordingItem?

    var body: some View {
        let viewState = SessionViewState(
            isRecording: audioCapture.isRecording,
            status: audioCapture.status,
            hasBlockingReasons: blockingReasonsText != nil,
            activeProfileLabel: activeProfileLabel
        )
        let titlePromptState = SessionTitlePromptState(
            draft: sessionTitleDraft,
            defaultTitle: defaultSessionTitle
        )
        let titleHintColor: Color = titlePromptState.helperTone == .warning ? .orange : .secondary
        let isPostSessionPlaying = isPostSessionPlaybackActive && !isPostSessionPlaybackPaused
        let isPostSessionPaused = isPostSessionPlaybackActive && isPostSessionPlaybackPaused
        let postSessionActionsDisabled = audioCapture.isRecording
        let postSessionItemUnavailable = postSessionRecordingItem == nil
        let captureStatusText = CaptureStatusFormatter.statusText(
            inputDeviceName: audioCapture.inputDeviceName,
            backendStatus: audioCapture.backendStatus,
            isRecording: audioCapture.isRecording
        )
        let recoveryAction = CaptureRecoveryActionMapper.recoveryAction(for: audioCapture.status)
        let shouldShowVoiceIsolationAcknowledgement = voiceIsolationAcknowledgementMessage != nil
            && recoveryAction?.kind != .acknowledgeVoiceIsolationRisk
        let routeWarningText = audioCapture.isRecording
            ? AudioRouteWarningEvaluator.warningText(
                inputDeviceName: audioCapture.inputDeviceName,
                outputDeviceName: audioCapture.outputDeviceName,
                backendStatus: audioCapture.backendStatus
            )
            : nil
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
                if let interruptionMessage = audioCapture.interruptionMessage {
                    Text(interruptionMessage)
                        .font(.footnote)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }
                if let recoveryAction {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recoveryAction.hint)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(recoveryAction.actionTitle) {
                            handleRecoveryAction(recoveryAction)
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            recoveryAction.kind == .retryStart
                                && (audioCapture.isTestingMic || !canStartRecording)
                        )
                    }
                    .frame(maxWidth: 320, alignment: .leading)
                }
                if let captureStatusText {
                    Text(captureStatusText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Capture status")
                        .accessibilityValue(captureStatusText)
                }
                if let routeWarningText {
                    Text(routeWarningText)
                        .font(.footnote)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                        .accessibilityLabel("Audio route warning")
                        .accessibilityValue(routeWarningText)
                }
                if viewState.shouldShowActiveProfileLabel, let activeProfileLabel {
                    Text(activeProfileLabel)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Active profile")
                        .accessibilityValue(activeProfileLabel)
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
                        paceMin: analysisPreferences.paceMin,
                        paceMax: analysisPreferences.paceMax,
                        sessionDurationText: sessionDurationText,
                        sessionDurationSeconds: sessionDurationSeconds,
                        storageStatus: storageStatus
                    )
                }

                if coachingProfiles.count > 1 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Coaching profile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Coaching profile", selection: $selectedCoachingProfileID) {
                            ForEach(coachingProfiles) { profile in
                                Text(profile.name)
                                    .tag(profile.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 260, alignment: .leading)
                        .accessibilityLabel("Coaching profile")
                    }
                    .frame(maxWidth: 320, alignment: .leading)
                }

                if let postSessionReview {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session recap")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(postSessionReview.summaryLines, id: \.self) { line in
                                Text(line)
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Session recap")
                        .accessibilityValue(postSessionReview.summaryLines.joined(separator: ", "))
                        HStack(spacing: 12) {
                            Button("View Recordings", action: onViewRecordings)
                                .buttonStyle(.bordered)
                                .disabled(postSessionActionsDisabled)
                            Button(isPostSessionPlaying ? "Pause" : "Play", action: onPostSessionPlayPause)
                                .buttonStyle(.bordered)
                                .disabled(postSessionActionsDisabled || postSessionItemUnavailable)
                                .accessibilityLabel(isPostSessionPlaying ? "Pause playback" : "Play recording")
                            Button("Reveal", action: onPostSessionReveal)
                                .buttonStyle(.bordered)
                                .disabled(postSessionActionsDisabled || postSessionItemUnavailable)
                            Button("Details") {
                                postSessionDetailItem = postSessionRecordingItem
                            }
                            .buttonStyle(.bordered)
                            .disabled(postSessionActionsDisabled || postSessionItemUnavailable)
                        }
                        if isPostSessionPlaying {
                            Text("Playing")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } else if isPostSessionPaused {
                            Text("Paused")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.15))
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Post-session review")
                }

                if showTitlePrompt {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Name this session")
                            .font(.headline)
                        TextField("Optional title", text: $sessionTitleDraft)
                            .textFieldStyle(.roundedBorder)
                        Text(titlePromptState.helperText)
                            .font(.footnote)
                            .foregroundColor(titleHintColor)
                        HStack(spacing: 12) {
                            Button("Save", action: onSaveSessionTitle)
                                .buttonStyle(.borderedProminent)
                                .disabled(!titlePromptState.isValid)
                            Button("Skip", action: onSkipSessionTitle)
                                .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2))
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Session title prompt")
                }

                if shouldShowVoiceIsolationAcknowledgement, let voiceIsolationAcknowledgementMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(voiceIsolationAcknowledgementMessage)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("I Understand", action: onAcknowledgeVoiceIsolationRisk)
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: 320, alignment: .leading)
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
        .sheet(item: $postSessionDetailItem) { item in
            RecordingDetailView(item: item)
        }
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

    private func handleRecoveryAction(_ action: CaptureRecoveryAction) {
        switch action.kind {
        case .retryStart:
            onRetryCapture()
        case .openSettings:
            onOpenSettings()
        case .acknowledgeVoiceIsolationRisk:
            onAcknowledgeVoiceIsolationRisk()
        }
    }
}

#Preview {
    SessionViewPreview()
}

private struct SessionViewPreview: View {
    @State private var sessionTitle = ""
    private let defaultProfile = CoachingProfile.default()
    private let focusedProfile = CoachingProfile(id: UUID(), name: "Focused", preferences: .default)

    var body: some View {
        SessionView(
            audioCapture: AudioCapture(capturePreferencesStore: AudioCapturePreferencesStore()),
            feedbackViewModel: LiveFeedbackViewModel(),
            analysisPreferences: AnalysisPreferences.default,
            coachingProfiles: [
                defaultProfile,
                focusedProfile
            ],
            selectedCoachingProfileID: .constant(defaultProfile.id),
            sessionDurationText: "00:32",
            sessionDurationSeconds: 32,
            canStartRecording: true,
            blockingReasonsText: nil,
            voiceIsolationAcknowledgementMessage: nil,
            storageStatus: .ok,
            activeProfileLabel: "Profile: Default (App: Default)",
            showTitlePrompt: true,
            defaultSessionTitle: "Session Jan 1, 2026 at 9:00 AM",
            postSessionReview: PostSessionReview(
                session: CompletedRecordingSession(
                    sessionID: "preview",
                    recordingURLs: [URL(fileURLWithPath: "/tmp/sample.m4a")],
                    createdAt: Date()
                ),
                summaryProvider: { _ in
                    AnalysisSummary(
                        version: 1,
                        createdAt: Date(),
                        durationSeconds: 180,
                        pace: AnalysisSummary.PaceStats(
                            averageWPM: 140,
                            minWPM: 100,
                            maxWPM: 180,
                            totalWords: 420
                        ),
                        pauses: AnalysisSummary.PauseStats(
                            count: 6,
                            thresholdSeconds: 0.8,
                            averageDurationSeconds: 1.4
                        ),
                        crutchWords: AnalysisSummary.CrutchWordStats(
                            totalCount: 5,
                            counts: ["um": 3, "you know": 2]
                        ),
                        speaking: AnalysisSummary.SpeakingStats(timeSeconds: 72, turnCount: 6)
                    )
                }
            ),
            postSessionRecordingItem: RecordingItem(
                url: URL(fileURLWithPath: "/tmp/sample.m4a"),
                modifiedAt: Date(),
                duration: 180,
                fileSizeBytes: 1024,
                summary: AnalysisSummary(
                    version: 1,
                    createdAt: Date(),
                    durationSeconds: 180,
                    pace: AnalysisSummary.PaceStats(
                        averageWPM: 140,
                        minWPM: 100,
                        maxWPM: 180,
                        totalWords: 420
                    ),
                    pauses: AnalysisSummary.PauseStats(
                        count: 6,
                        thresholdSeconds: 0.8,
                        averageDurationSeconds: 1.4
                    ),
                    crutchWords: AnalysisSummary.CrutchWordStats(
                        totalCount: 5,
                        counts: ["um": 3, "you know": 2]
                    ),
                    speaking: AnalysisSummary.SpeakingStats(timeSeconds: 72, turnCount: 6)
                ),
                integrityReport: nil,
                metadata: nil
            ),
            isPostSessionPlaybackActive: false,
            isPostSessionPlaybackPaused: false,
            sessionTitleDraft: $sessionTitle,
            onSaveSessionTitle: {},
            onSkipSessionTitle: {},
            onViewRecordings: {},
            onPostSessionPlayPause: {},
            onPostSessionReveal: {},
            onAcknowledgeVoiceIsolationRisk: {},
            onOpenSettings: {},
            onRetryCapture: {},
            onToggleRecording: {}
        )
    }
}
