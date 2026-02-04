import AVFoundation
import XCTest
@testable import Calliope

final class AudioCaptureTests: XCTestCase {
    func testStartStopUpdatesStatus() {
        let backend = FakeAudioCaptureBackend()
        let fileWriter = FakeAudioFileWriter()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            backendFactory: { backend },
            audioFileFactory: { _, _ in fileWriter }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true,
            hasConfirmedHeadphones: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.status, .recording)
        XCTAssertTrue(backend.isStarted)
        XCTAssertTrue(backend.installTapCalled)

        capture.stopRecording()

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .idle)
        XCTAssertTrue(backend.removeTapCalled)
    }

    func testStartRecordingWithoutPermissionSetsError() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            backendFactory: { backend },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true,
            hasConfirmedHeadphones: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .denied)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.microphonePermissionMissing))
    }

    func testStartRecordingEngineFailureSetsError() {
        let backend = FakeAudioCaptureBackend()
        backend.startError = TestError.engineStart
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            backendFactory: { backend },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true,
            hasConfirmedHeadphones: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.engineStartFailed))
        XCTAssertTrue(backend.removeTapCalled)
    }

    func testStartRecordingAudioFileFailureSetsError() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            backendFactory: { backend },
            audioFileFactory: { _, _ in throw TestError.audioFileCreation }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true,
            hasConfirmedHeadphones: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.audioFileCreationFailed))
    }
}

private enum TestError: Error {
    case engineStart
    case audioFileCreation
}

private final class FakeAudioCaptureBackend: AudioCaptureBackend {
    let inputFormat: AVAudioFormat
    var isStarted = false
    var installTapCalled = false
    var removeTapCalled = false
    var startError: Error?

    init() {
        self.inputFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void) {
        installTapCalled = true
    }

    func removeTap() {
        removeTapCalled = true
    }

    func start() throws {
        if let startError {
            throw startError
        }
        isStarted = true
    }

    func stop() {
        isStarted = false
    }
}

private final class FakeAudioFileWriter: AudioFileWritable {
    func write(from buffer: AVAudioPCMBuffer) throws {
        return
    }
}
