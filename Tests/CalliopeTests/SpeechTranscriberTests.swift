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
            },
            logger: NoOpSpeechTranscriberLogger()
        )
        var observedStates: [SpeechTranscriberState] = []
        transcriber.onStateChange = { observedStates.append($0) }

        transcriber.startTranscription()

        XCTAssertEqual(observedStates.last, .error)
        XCTAssertFalse(didRequestAuthorization)
    }

    func testStartTranscriptionFailsWhenRecognizerUnavailable() {
        let recognizer = FakeSpeechRecognizer(
            isAvailable: false,
            supportsOnDeviceRecognition: true
        )
        var didRequestAuthorization = false
        let transcriber = SpeechTranscriber(
            speechRecognizer: recognizer,
            requestAuthorization: { _ in
                didRequestAuthorization = true
            },
            logger: NoOpSpeechTranscriberLogger()
        )
        var observedStates: [SpeechTranscriberState] = []
        transcriber.onStateChange = { observedStates.append($0) }

        transcriber.startTranscription()

        XCTAssertEqual(observedStates.last, .error)
        XCTAssertFalse(didRequestAuthorization)
    }

    func testStartTranscriptionFailsWhenAuthorizationDenied() {
        let recognizer = FakeSpeechRecognizer(
            isAvailable: true,
            supportsOnDeviceRecognition: true
        )
        let transcriber = SpeechTranscriber(
            speechRecognizer: recognizer,
            requestAuthorization: { completion in
                completion(.denied)
            },
            logger: NoOpSpeechTranscriberLogger()
        )
        var observedStates: [SpeechTranscriberState] = []

        let expectation = expectation(description: "Updates to error state")
        transcriber.onStateChange = { state in
            observedStates.append(state)
            if state == .error {
                expectation.fulfill()
            }
        }

        transcriber.startTranscription()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(observedStates.last, .error)
    }

    func testNoSpeechErrorMapsToStoppedState() {
        let transcriber = SpeechTranscriber(logger: NoOpSpeechTranscriberLogger())
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
        let transcriber = SpeechTranscriber(logger: NoOpSpeechTranscriberLogger())
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

    func testAFAssistantNoSpeechErrorMapsToStoppedState() {
        let transcriber = SpeechTranscriber(logger: NoOpSpeechTranscriberLogger())
        var observedStates: [SpeechTranscriberState] = []
        transcriber.onStateChange = { observedStates.append($0) }

        let error = NSError(domain: "kAFAssistantErrorDomain", code: 1110, userInfo: nil)
        transcriber.handleRecognitionError(error)

        XCTAssertEqual(observedStates.last, .stopped)
    }

    func testUnknownErrorMapsToErrorState() {
        let transcriber = SpeechTranscriber(logger: NoOpSpeechTranscriberLogger())
        var observedStates: [SpeechTranscriberState] = []
        transcriber.onStateChange = { observedStates.append($0) }

        let error = NSError(domain: "TestErrorDomain", code: 1, userInfo: nil)
        transcriber.handleRecognitionError(error)

        XCTAssertEqual(observedStates.last, .error)
    }

    func testStopIgnoresSubsequentErrors() {
        let transcriber = SpeechTranscriber(logger: NoOpSpeechTranscriberLogger())
        var observedStates: [SpeechTranscriberState] = []
        transcriber.onStateChange = { observedStates.append($0) }

        transcriber.stopTranscription()

        let error = NSError(domain: "TestErrorDomain", code: 1, userInfo: nil)
        transcriber.handleRecognitionError(error)

        XCTAssertEqual(observedStates.last, .stopped)
    }
}

private struct NoOpSpeechTranscriberLogger: SpeechTranscriberLogging {
    func info(_ message: String) {}
    func error(_ message: String) {}
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
        resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void
    ) -> SFSpeechRecognitionTask {
        fatalError("recognitionTask should not be called in this test.")
    }
}
