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
    let voiceIsolationAcknowledgementMessage: String?
    let activeProfileLabel: String?
    let onAcknowledgeVoiceIsolationRisk: () -> Void
    let onOpenSettings: () -> Void
    let onRetryCapture: () -> Void
    let onToggleRecording: () -> Void
    private enum Layout {
        static let contentMaxWidth: CGFloat = 340
    }

    var body: some View {
        let viewState = SessionViewState(
            isRecording: audioCapture.isRecording,
            hasPausedSession: audioCapture.hasPausedSession
        )
        let shouldShowVoiceIsolationAcknowledgement = voiceIsolationAcknowledgementMessage != nil
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

            FeedbackPanel(
                pace: feedbackViewModel.state.pace,
                crutchWords: feedbackViewModel.state.crutchWords,
                pauseCount: feedbackViewModel.state.pauseCount,
                pauseAverageDuration: feedbackViewModel.state.pauseAverageDuration,
                speakingTimeSeconds: feedbackViewModel.state.speakingTimeSeconds,
                speakingTimeTargetPercent: analysisPreferences.speakingTimeTargetPercent,
                inputLevel: feedbackViewModel.state.inputLevel,
                paceMin: analysisPreferences.paceMin,
                paceMax: analysisPreferences.paceMax,
                sessionDurationText: sessionDurationText,
                sessionDurationSeconds: sessionDurationSeconds,
                liveTranscript: feedbackViewModel.liveTranscript,
                coachingProfiles: coachingProfiles,
                activeProfileLabel: activeProfileLabel,
                selectedCoachingProfileID: $selectedCoachingProfileID
            )
            .opacity(isSessionActive ? 1.0 : 0.55)
            .saturation(isSessionActive ? 1.0 : 0.0)

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

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
    }

}

#Preview {
    SessionViewPreview()
}

#Preview("Session Recording Layout") {
    SessionViewRecordingPreview()
}

private struct SessionViewPreview: View {
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
            voiceIsolationAcknowledgementMessage: nil,
            activeProfileLabel: "Profile: Default (App: Default)",
            onAcknowledgeVoiceIsolationRisk: {},
            onOpenSettings: {},
            onRetryCapture: {},
            onToggleRecording: {}
        )
    }
}

private struct SessionViewRecordingPreview: View {
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
            voiceIsolationAcknowledgementMessage: nil,
            activeProfileLabel: "Profile: Default (App: Zoom)",
            onAcknowledgeVoiceIsolationRisk: {},
            onOpenSettings: {},
            onRetryCapture: {},
            onToggleRecording: {}
        )
    }
}
