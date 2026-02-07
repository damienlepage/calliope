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
    @Binding var sessionTitleDraft: String
    let onSaveSessionTitle: () -> Void
    let onSkipSessionTitle: () -> Void
    let onViewRecordings: () -> Void
    let onAcknowledgeVoiceIsolationRisk: () -> Void
    let onToggleRecording: () -> Void

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
        let captureStatusText = CaptureStatusFormatter.statusText(
            inputDeviceName: audioCapture.inputDeviceName,
            backendStatus: audioCapture.backendStatus,
            isRecording: audioCapture.isRecording
        )
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
                        Button("View Recordings", action: onViewRecordings)
                            .buttonStyle(.link)
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

                if let voiceIsolationAcknowledgementMessage {
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
            sessionTitleDraft: $sessionTitle,
            onSaveSessionTitle: {},
            onSkipSessionTitle: {},
            onViewRecordings: {},
            onAcknowledgeVoiceIsolationRisk: {},
            onToggleRecording: {}
        )
    }
}
