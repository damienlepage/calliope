import Speech
import XCTest
@testable import Calliope

final class SpeechTranscriberTests: XCTestCase {
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
