import XCTest
@testable import Calliope

final class AudioRouteWarningEvaluatorTests: XCTestCase {
    func testWarnsForBuiltInMicAndSpeakersWithStandardBackend() {
        let result = AudioRouteWarningEvaluator.warningState(
            inputDeviceName: "Built-in Microphone",
            outputDeviceName: "MacBook Pro Speakers",
            backendStatus: .standard
        )

        XCTAssertEqual(
            result,
            .warning(message: "Built-in speakers and mic detected. Use a headset or external mic to reduce bleed.")
        )
    }

    func testWarnsForBuiltInMicAndSpeakersWithVoiceIsolation() {
        let result = AudioRouteWarningEvaluator.warningState(
            inputDeviceName: "Internal Microphone",
            outputDeviceName: "Built-in Output",
            backendStatus: .voiceIsolation
        )

        XCTAssertEqual(
            result,
            .warning(message: "Built-in speakers and mic detected. Voice Isolation helps, but a headset reduces bleed.")
        )
    }

    func testWarnsForSpeakerOutputWhenNotUsingVoiceIsolation() {
        let result = AudioRouteWarningEvaluator.warningState(
            inputDeviceName: "USB Mic",
            outputDeviceName: "Studio Display Speakers",
            backendStatus: .standard
        )

        XCTAssertEqual(
            result,
            .warning(message: "Speaker output may feed into the mic. Consider a headset for best isolation.")
        )
    }

    func testNoWarningForHeadphones() {
        let result = AudioRouteWarningEvaluator.warningState(
            inputDeviceName: "Built-in Microphone",
            outputDeviceName: "AirPods Pro",
            backendStatus: .standard
        )

        XCTAssertEqual(result, .ok)
    }

    func testRequiresAcknowledgementWhenVoiceIsolationUnavailableAndWarning() {
        let result = AudioRouteWarningEvaluator.requiresVoiceIsolationAcknowledgement(
            inputDeviceName: "Built-in Microphone",
            outputDeviceName: "MacBook Pro Speakers",
            backendStatus: .voiceIsolationUnavailable
        )

        XCTAssertTrue(result)
    }

    func testDoesNotRequireAcknowledgementWhenVoiceIsolationUnavailableButHeadphones() {
        let result = AudioRouteWarningEvaluator.requiresVoiceIsolationAcknowledgement(
            inputDeviceName: "Built-in Microphone",
            outputDeviceName: "AirPods Max",
            backendStatus: .voiceIsolationUnavailable
        )

        XCTAssertFalse(result)
    }

    func testDoesNotRequireAcknowledgementWhenVoiceIsolationAvailable() {
        let result = AudioRouteWarningEvaluator.requiresVoiceIsolationAcknowledgement(
            inputDeviceName: "Built-in Microphone",
            outputDeviceName: "MacBook Pro Speakers",
            backendStatus: .voiceIsolation
        )

        XCTAssertFalse(result)
    }
}
