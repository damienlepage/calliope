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
            hasAcceptedDisclosure: true
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
            hasAcceptedDisclosure: true
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
            hasAcceptedDisclosure: true
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
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.audioFileCreationFailed))
    }

    func testStartRecordingRejectsSystemAudioBackend() {
        let backend = FakeAudioCaptureBackend(inputSource: .systemAudio)
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            backendFactory: { backend },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.systemAudioCaptureNotAllowed))
        XCTAssertFalse(backend.isStarted)
        XCTAssertFalse(backend.installTapCalled)
    }

    func testStopRecordingClearsErrorWhenNotRecording() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            backendFactory: { backend },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .denied)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.microphonePermissionMissing))

        capture.stopRecording()

        XCTAssertEqual(capture.status, .idle)
    }

    func testConfigurationChangeStopsRecordingWithError() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            backendFactory: { backend },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.status, .recording)

        backend.simulateConfigurationChange()

        let configurationHandled = expectation(description: "configuration change handled")
        DispatchQueue.main.async {
            configurationHandled.fulfill()
        }
        wait(for: [configurationHandled], timeout: 1.0)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.engineConfigurationChanged))
        XCTAssertTrue(backend.removeTapCalled)
    }
}

private enum TestError: Error {
    case engineStart
    case audioFileCreation
}

private final class FakeAudioCaptureBackend: AudioCaptureBackend {
    let inputFormat: AVAudioFormat
    let inputSource: AudioInputSource
    var isStarted = false
    var installTapCalled = false
    var removeTapCalled = false
    var startError: Error?
    private var configurationChangeHandler: (() -> Void)?

    init(inputSource: AudioInputSource = .microphone) {
        self.inputSource = inputSource
        self.inputFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void) {
        installTapCalled = true
    }

    func removeTap() {
        removeTapCalled = true
    }

    func setConfigurationChangeHandler(_ handler: @escaping () -> Void) {
        configurationChangeHandler = handler
    }

    func clearConfigurationChangeHandler() {
        configurationChangeHandler = nil
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

    func simulateConfigurationChange() {
        configurationChangeHandler?()
    }
}

private final class FakeAudioFileWriter: AudioFileWritable {
    func write(from buffer: AVAudioPCMBuffer) throws {
        return
    }
}
