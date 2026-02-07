import XCTest
@testable import Calliope

@MainActor
final class SessionViewTests: XCTestCase {
    func testSessionViewBuilds() {
        let audioCapture = AudioCapture(capturePreferencesStore: AudioCapturePreferencesStore())
        let feedbackViewModel = LiveFeedbackViewModel()
        let defaultProfile = CoachingProfile.default()
        let view = SessionView(
            audioCapture: audioCapture,
            feedbackViewModel: feedbackViewModel,
            analysisPreferences: AnalysisPreferences.default,
            coachingProfiles: [defaultProfile],
            selectedCoachingProfileID: .constant(defaultProfile.id),
            sessionDurationText: "00:12",
            sessionDurationSeconds: 12,
            canStartRecording: true,
            blockingReasonsText: nil,
            voiceIsolationAcknowledgementMessage: nil,
            storageStatus: .ok,
            activeProfileLabel: nil,
            showTitlePrompt: false,
            defaultSessionTitle: nil,
            postSessionReview: nil,
            postSessionRecordingItem: nil,
            sessionTitleDraft: .constant(""),
            onSaveSessionTitle: {},
            onSkipSessionTitle: {},
            onViewRecordings: {},
            onEditSessionTitle: {},
            onAcknowledgeVoiceIsolationRisk: {},
            onOpenSettings: {},
            onRetryCapture: {},
            onToggleRecording: {}
        )

        _ = view.body
    }

    func testSessionViewBuildsWhileRecording() {
        let audioCapture = AudioCapture(capturePreferencesStore: AudioCapturePreferencesStore())
        audioCapture.isRecording = true
        let feedbackViewModel = LiveFeedbackViewModel(
            initialState: FeedbackState(
                pace: 140,
                crutchWords: 1,
                pauseCount: 2,
                pauseAverageDuration: 1.1,
                speakingTimeSeconds: 42,
                inputLevel: 0.4,
                showSilenceWarning: false
            )
        )
        let defaultProfile = CoachingProfile.default()
        let view = SessionView(
            audioCapture: audioCapture,
            feedbackViewModel: feedbackViewModel,
            analysisPreferences: AnalysisPreferences.default,
            coachingProfiles: [defaultProfile],
            selectedCoachingProfileID: .constant(defaultProfile.id),
            sessionDurationText: "01:10",
            sessionDurationSeconds: 70,
            canStartRecording: true,
            blockingReasonsText: nil,
            voiceIsolationAcknowledgementMessage: nil,
            storageStatus: .ok,
            activeProfileLabel: ActiveProfileLabelFormatter.labelText(
                isRecording: true,
                coachingProfileName: defaultProfile.name,
                perAppProfile: nil
            ),
            showTitlePrompt: false,
            defaultSessionTitle: nil,
            postSessionReview: nil,
            postSessionRecordingItem: nil,
            sessionTitleDraft: .constant(""),
            onSaveSessionTitle: {},
            onSkipSessionTitle: {},
            onViewRecordings: {},
            onEditSessionTitle: {},
            onAcknowledgeVoiceIsolationRisk: {},
            onOpenSettings: {},
            onRetryCapture: {},
            onToggleRecording: {}
        )

        _ = view.body
    }
}
