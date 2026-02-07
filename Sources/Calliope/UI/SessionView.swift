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
    @Binding var sessionTitleDraft: String
    let onSaveSessionTitle: () -> Void
    let onSkipSessionTitle: () -> Void
    let onViewRecordings: () -> Void
    let onEditSessionTitle: () -> Void
    let onAcknowledgeVoiceIsolationRisk: () -> Void
    let onOpenSettings: () -> Void
    let onRetryCapture: () -> Void
    let onToggleRecording: () -> Void
    @State private var postSessionDetailItem: RecordingItem?
    private enum Layout {
        static let contentMaxWidth: CGFloat = 340
    }

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
        let postSessionActionsDisabled = audioCapture.isRecording
        let postSessionItemUnavailable = postSessionRecordingItem == nil
        let shouldShowVoiceIsolationAcknowledgement = voiceIsolationAcknowledgementMessage != nil
        let routeWarningText = audioCapture.isRecording
            ? AudioRouteWarningEvaluator.warningText(
                inputDeviceName: audioCapture.inputDeviceName,
                outputDeviceName: audioCapture.outputDeviceName,
                backendStatus: audioCapture.backendStatus
            )
            : nil
        let isSessionActive = audioCapture.isRecording
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button(action: onToggleRecording) {
                    Text(viewState.primaryButtonTitle)
                        .frame(minWidth: 100, minHeight: 40)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    audioCapture.isTestingMic || (!audioCapture.isRecording && !canStartRecording)
                )
                .accessibilityLabel(viewState.primaryButtonAccessibilityLabel)
                .accessibilityHint(viewState.primaryButtonAccessibilityHint)
                Spacer()
            }
            .frame(maxWidth: Layout.contentMaxWidth, alignment: .leading)

            if viewState.shouldShowTitle {
                Text("Calliope")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
            }

            if let routeWarningText {
                Text(routeWarningText)
                    .font(.footnote)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Audio route warning")
                    .accessibilityValue(routeWarningText)
            }
            if viewState.shouldShowIdlePrompt {
                Text("Ready when you are. Press Start to begin coaching.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: 320)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if viewState.shouldShowFeedbackPanel {
                FeedbackPanel(
                    pace: feedbackViewModel.state.pace,
                    crutchWords: feedbackViewModel.state.crutchWords,
                    pauseCount: feedbackViewModel.state.pauseCount,
                    pauseAverageDuration: feedbackViewModel.state.pauseAverageDuration,
                    speakingTimeSeconds: feedbackViewModel.state.speakingTimeSeconds,
                    speakingTimeTargetPercent: analysisPreferences.speakingTimeTargetPercent,
                    inputLevel: feedbackViewModel.state.inputLevel,
                    showSilenceWarning: feedbackViewModel.state.showSilenceWarning,
                    showWaitingForSpeech: feedbackViewModel.showWaitingForSpeech,
                    paceMin: analysisPreferences.paceMin,
                    paceMax: analysisPreferences.paceMax,
                    sessionDurationText: sessionDurationText,
                    sessionDurationSeconds: sessionDurationSeconds,
                    storageStatus: storageStatus,
                    liveTranscript: feedbackViewModel.liveTranscript,
                    coachingProfiles: coachingProfiles,
                    activeProfileLabel: activeProfileLabel,
                    selectedCoachingProfileID: $selectedCoachingProfileID
                )
                .opacity(isSessionActive ? 1.0 : 0.55)
                .saturation(isSessionActive ? 1.0 : 0.0)
            }

            if let postSessionReview, !audioCapture.isRecording {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Session recap")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
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
                        Button("Open Recording") {
                            postSessionDetailItem = postSessionRecordingItem
                        }
                        .buttonStyle(.bordered)
                        .disabled(postSessionActionsDisabled || postSessionItemUnavailable)
                        .accessibilityHint("Open the recording details for this session.")
                        Button("Edit Title", action: onEditSessionTitle)
                            .buttonStyle(.bordered)
                            .disabled(postSessionActionsDisabled || showTitlePrompt)
                            .accessibilityHint("Edit the saved title for this session.")
                        Button("Go to Recordings", action: onViewRecordings)
                            .buttonStyle(.bordered)
                            .disabled(postSessionActionsDisabled)
                            .accessibilityHint("Open the recordings list.")
                    }
                }
                .frame(maxWidth: Layout.contentMaxWidth, alignment: .leading)
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
                        .accessibilityAddTraits(.isHeader)
                    TextField("Optional title", text: $sessionTitleDraft)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Session title")
                        .accessibilityHint("Optional name for this session.")
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
                .frame(maxWidth: Layout.contentMaxWidth, alignment: .leading)
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
                .frame(maxWidth: Layout.contentMaxWidth, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Voice isolation warning")
                .accessibilityValue(voiceIsolationAcknowledgementMessage)
            }

            if viewState.shouldShowBlockingReasons, let blockingReasonsText {
                Text(blockingReasonsText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Session blocked")
                    .accessibilityValue(blockingReasonsText)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .sheet(item: $postSessionDetailItem) { item in
            RecordingDetailView(item: item)
        }
    }

}

#Preview {
    SessionViewPreview()
}

#Preview("Session Recording Layout") {
    SessionViewRecordingPreview()
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
            sessionTitleDraft: $sessionTitle,
            onSaveSessionTitle: {},
            onSkipSessionTitle: {},
            onViewRecordings: {},
            onEditSessionTitle: {},
            onAcknowledgeVoiceIsolationRisk: {},
            onOpenSettings: {},
            onRetryCapture: {},
            onToggleRecording: {}
        )
    }
}

private struct SessionViewRecordingPreview: View {
    @State private var sessionTitle = ""
    private let defaultProfile = CoachingProfile.default()
    private let focusedProfile = CoachingProfile(id: UUID(), name: "Focused", preferences: .default)
    private let audioCapture: AudioCapture = {
        let capture = AudioCapture(capturePreferencesStore: AudioCapturePreferencesStore())
        capture.isRecording = true
        return capture
    }()
    private let feedbackViewModel = LiveFeedbackViewModel(
        initialState: FeedbackState(
            pace: 155,
            crutchWords: 2,
            pauseCount: 3,
            pauseAverageDuration: 1.2,
            speakingTimeSeconds: 75,
            inputLevel: 0.6,
            showSilenceWarning: false
        )
    )

    var body: some View {
        SessionView(
            audioCapture: audioCapture,
            feedbackViewModel: feedbackViewModel,
            analysisPreferences: AnalysisPreferences.default,
            coachingProfiles: [
                defaultProfile,
                focusedProfile
            ],
            selectedCoachingProfileID: .constant(defaultProfile.id),
            sessionDurationText: "04:12",
            sessionDurationSeconds: 252,
            canStartRecording: true,
            blockingReasonsText: nil,
            voiceIsolationAcknowledgementMessage: nil,
            storageStatus: .ok,
            activeProfileLabel: "Profile: Default (App: Zoom)",
            showTitlePrompt: false,
            defaultSessionTitle: nil,
            postSessionReview: nil,
            postSessionRecordingItem: nil,
            sessionTitleDraft: $sessionTitle,
            onSaveSessionTitle: {},
            onSkipSessionTitle: {},
            onViewRecordings: {},
            onEditSessionTitle: {},
            onAcknowledgeVoiceIsolationRisk: {},
            onOpenSettings: {},
            onRetryCapture: {},
            onToggleRecording: {}
        )
    }
}
