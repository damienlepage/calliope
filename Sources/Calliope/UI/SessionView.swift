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
    @State private var showCaptions: Bool = true

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
        let captureStatusText = CaptureStatusFormatter.statusText(
            inputDeviceName: audioCapture.inputDeviceName,
            backendStatus: audioCapture.backendStatus,
            isRecording: audioCapture.isRecording
        )
        let captureRecoveryBanner = CaptureRecoveryBannerState.from(status: audioCapture.status)
        let shouldShowVoiceIsolationAcknowledgement = voiceIsolationAcknowledgementMessage != nil
        let routeWarningText = audioCapture.isRecording
            ? AudioRouteWarningEvaluator.warningText(
                inputDeviceName: audioCapture.inputDeviceName,
                outputDeviceName: audioCapture.outputDeviceName,
                backendStatus: audioCapture.backendStatus
            )
            : nil
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
            if let captureRecoveryBanner {
                VStack(alignment: .leading, spacing: 8) {
                    Text(captureRecoveryBanner.title)
                        .font(.headline)
                    Text(captureRecoveryBanner.message)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 12) {
                        Button(captureRecoveryBanner.primaryActionTitle, action: onRetryCapture)
                            .buttonStyle(.borderedProminent)
                            .disabled(audioCapture.isTestingMic || !canStartRecording)
                        Button(captureRecoveryBanner.secondaryActionTitle, action: onOpenSettings)
                            .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: 340, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.12))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.25))
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Capture recovery")
                .accessibilityValue("\(captureRecoveryBanner.title). \(captureRecoveryBanner.message)")
            }
            if viewState.shouldShowRecordingDetails, let interruptionMessage = audioCapture.interruptionMessage {
                Text(interruptionMessage)
                    .font(.footnote)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if viewState.shouldShowRecordingDetails, let captureStatusText {
                Text(captureStatusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Capture status")
                    .accessibilityValue(captureStatusText)
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
                    .fixedSize(horizontal: false, vertical: true)
            }
            if viewState.shouldShowFeedbackPanel {
                FeedbackPanel(
                    pace: feedbackViewModel.state.pace,
                    crutchWords: feedbackViewModel.state.crutchWords,
                    pauseCount: feedbackViewModel.state.pauseCount,
                    pauseAverageDuration: feedbackViewModel.state.pauseAverageDuration,
                    speakingTimeSeconds: feedbackViewModel.state.speakingTimeSeconds,
                    inputLevel: feedbackViewModel.state.inputLevel,
                    showSilenceWarning: feedbackViewModel.state.showSilenceWarning,
                    showWaitingForSpeech: feedbackViewModel.showWaitingForSpeech,
                    paceMin: analysisPreferences.paceMin,
                    paceMax: analysisPreferences.paceMax,
                    sessionDurationText: sessionDurationText,
                    sessionDurationSeconds: sessionDurationSeconds,
                    storageStatus: storageStatus
                )
            }

                if audioCapture.isRecording {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Live captions")
                                .font(.headline)
                            Spacer()
                            Toggle("CC", isOn: $showCaptions)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .accessibilityLabel("Closed captions")
                                .accessibilityValue(showCaptions ? "On" : "Off")
                                .accessibilityHint("Toggle live captions on or off.")
                        }
                        if showCaptions {
                            Text(captionBodyText(for: feedbackViewModel.liveTranscript))
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.secondary.opacity(0.08))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondary.opacity(0.12))
                                )
                                .accessibilityLabel("Live captions")
                                .accessibilityValue(
                                    captionBodyText(for: feedbackViewModel.liveTranscript)
                                )
                        }
                    }
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding(.top, 4)
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

                if let postSessionReview, !audioCapture.isRecording {
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
                            Button("Open Recording") {
                                postSessionDetailItem = postSessionRecordingItem
                            }
                            .buttonStyle(.bordered)
                            .disabled(postSessionActionsDisabled || postSessionItemUnavailable)
                            Button("Edit Title", action: onEditSessionTitle)
                                .buttonStyle(.bordered)
                                .disabled(postSessionActionsDisabled || showTitlePrompt)
                            Button("Go to Recordings", action: onViewRecordings)
                                .buttonStyle(.bordered)
                                .disabled(postSessionActionsDisabled)
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
                            .frame(minWidth: 100, minHeight: 40)
                            .padding(.horizontal, 8)
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
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .sheet(item: $postSessionDetailItem) { item in
            RecordingDetailView(item: item)
        }
        .onChange(of: audioCapture.isRecording) { isRecording in
            if isRecording {
                showCaptions = true
            }
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

    private func captionBodyText(for transcript: String) -> String {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Listening for speech..." : trimmed
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
