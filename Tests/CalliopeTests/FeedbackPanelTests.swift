import XCTest
@testable import Calliope

@MainActor
final class FeedbackPanelTests: XCTestCase {
    func testFeedbackPanelBuildsWithCaptionsAndProfile() {
        let defaultProfile = CoachingProfile.default()
        let view = FeedbackPanel(
            pace: 150,
            crutchWords: 2,
            pauseCount: 1,
            pauseAverageDuration: 1.0,
            speakingTimeSeconds: 45,
            speakingTimeTargetPercent: Constants.speakingTimeTargetPercent,
            inputLevel: 0.5,
            showSilenceWarning: false,
            showWaitingForSpeech: false,
            paceMin: Constants.targetPaceMin,
            paceMax: Constants.targetPaceMax,
            sessionDurationText: "00:45",
            sessionDurationSeconds: 45,
            storageStatus: .ok,
            liveTranscript: "Testing live captions.",
            coachingProfiles: [defaultProfile],
            activeProfileLabel: "Profile: Default (App: Default)",
            showCaptions: .constant(true),
            selectedCoachingProfileID: .constant(defaultProfile.id)
        )

        _ = view.body
    }
}
