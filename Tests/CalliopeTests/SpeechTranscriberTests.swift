import Speech
import XCTest
@testable import Calliope

final class SpeechTranscriberTests: XCTestCase {
    func testStartTranscriptionFailsWhenOnDeviceRecognitionUnsupported() {
        let recognizer = FakeSpeechRecognizer(
            isAvailable: true,
            supportsOnDeviceRecognition: false
        )
        var didRequestAuthorization = false
        let transcriber = SpeechTranscriber(
            speechRecognizer: recognizer,
            requestAuthorization: { _ in
                didRequestAuthorization = true
            }
        )
        var observedStates: [SpeechTranscriberState] = []
        transcriber.onStateChange = { observedStates.append($0) }

        transcriber.startTranscription()

        XCTAssertEqual(observedStates.last, .error)
        XCTAssertFalse(didRequestAuthorization)
    }

    func testNoSpeechErrorMapsToStoppedState() {
        let transcriber = SpeechTranscriber()
        var observedStates: [SpeechTranscriberState] = []
        transcriber.onStateChange = { observedStates.append($0) }

        let error = NSError(
            domain: SFSpeechRecognizerErrorDomain,
            code: SFSpeechRecognizerErrorCode.noSpeech.rawValue,
            userInfo: nil
        )
        transcriber.handleRecognitionError(error)

        XCTAssertEqual(observedStates.last, .stopped)
    }

    func testCanceledErrorMapsToStoppedState() {
        let transcriber = SpeechTranscriber()
        var observedStates: [SpeechTranscriberState] = []
        transcriber.onStateChange = { observedStates.append($0) }

        let error = NSError(
            domain: SFSpeechRecognizerErrorDomain,
            code: SFSpeechRecognizerErrorCode.canceled.rawValue,
            userInfo: nil
        )
        transcriber.handleRecognitionError(error)

        XCTAssertEqual(observedStates.last, .stopped)
    }

    func testUnknownErrorMapsToErrorState() {
        let transcriber = SpeechTranscriber()
        var observedStates: [SpeechTranscriberState] = []
        transcriber.onStateChange = { observedStates.append($0) }

        let error = NSError(domain: "TestErrorDomain", code: 1, userInfo: nil)
        transcriber.handleRecognitionError(error)

        XCTAssertEqual(observedStates.last, .error)
    }

    func testStopIgnoresSubsequentErrors() {
        let transcriber = SpeechTranscriber()
        var observedStates: [SpeechTranscriberState] = []
        transcriber.onStateChange = { observedStates.append($0) }

        transcriber.stopTranscription()

        let error = NSError(domain: "TestErrorDomain", code: 1, userInfo: nil)
        transcriber.handleRecognitionError(error)

        XCTAssertEqual(observedStates.last, .stopped)
    }
}

private final class FakeSpeechRecognizer: SpeechRecognizing {
    let isAvailable: Bool
    let supportsOnDeviceRecognition: Bool

    init(isAvailable: Bool, supportsOnDeviceRecognition: Bool) {
        self.isAvailable = isAvailable
        self.supportsOnDeviceRecognition = supportsOnDeviceRecognition
    }

    func recognitionTask(
        with request: SFSpeechAudioBufferRecognitionRequest,
        resultHandler: @escaping SFSpeechRecognitionTaskHandler
    ) -> SFSpeechRecognitionTask {
        fatalError("recognitionTask should not be called in this test.")
    }
}
