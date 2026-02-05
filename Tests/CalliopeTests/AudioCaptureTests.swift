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

    func testStartRecordingUpdatesInputDeviceName() {
        let backend = FakeAudioCaptureBackend(inputDeviceName: "Test Microphone")
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

        XCTAssertEqual(capture.inputDeviceName, "Test Microphone")
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
        XCTAssertEqual(capture.status, .error(.microphonePermissionDenied))
    }

    func testStartRecordingWithRestrictedPermissionSetsError() {
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

        capture.startRecording(privacyState: privacyState, microphonePermission: .restricted)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.microphonePermissionRestricted))
    }

    func testStartRecordingUsesPermissionProviderAuthorizationState() {
        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)

        do {
            let backend = FakeAudioCaptureBackend()
            let capture = AudioCapture(
                recordingManager: manager,
                backendFactory: { backend },
                audioFileFactory: { _, _ in FakeAudioFileWriter() }
            )
            let provider = TestPermissionProvider(state: .authorized)
            capture.startRecording(
                privacyState: privacyState,
                microphonePermissionProvider: provider
            )
            XCTAssertTrue(capture.isRecording)
            XCTAssertEqual(capture.status, .recording)
        }

        do {
            let backend = FakeAudioCaptureBackend()
            let capture = AudioCapture(
                recordingManager: manager,
                backendFactory: { backend },
                audioFileFactory: { _, _ in FakeAudioFileWriter() }
            )
            let provider = TestPermissionProvider(state: .denied)
            capture.startRecording(
                privacyState: privacyState,
                microphonePermissionProvider: provider
            )
            XCTAssertFalse(capture.isRecording)
            XCTAssertEqual(capture.status, .error(.microphonePermissionDenied))
        }

        do {
            let backend = FakeAudioCaptureBackend()
            let capture = AudioCapture(
                recordingManager: manager,
                backendFactory: { backend },
                audioFileFactory: { _, _ in FakeAudioFileWriter() }
            )
            let provider = TestPermissionProvider(state: .restricted)
            capture.startRecording(
                privacyState: privacyState,
                microphonePermissionProvider: provider
            )
            XCTAssertFalse(capture.isRecording)
            XCTAssertEqual(capture.status, .error(.microphonePermissionRestricted))
        }
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
        XCTAssertEqual(capture.status, .error(.microphonePermissionDenied))

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

    func testConfigurationChangeUpdatesInputDeviceName() {
        let backend = FakeAudioCaptureBackend(inputDeviceName: "Primary Mic")
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
        backend.inputDeviceName = "Secondary Mic"
        backend.simulateConfigurationChange()

        let configurationHandled = expectation(description: "configuration change handled")
        DispatchQueue.main.async {
            configurationHandled.fulfill()
        }
        wait(for: [configurationHandled], timeout: 1.0)

        XCTAssertEqual(capture.inputDeviceName, "Secondary Mic")
        XCTAssertEqual(capture.status, .error(.engineConfigurationChanged))
    }
}

private enum TestError: Error {
    case engineStart
    case audioFileCreation
}

private struct TestPermissionProvider: MicrophonePermissionProviding {
    let state: MicrophonePermissionState

    func authorizationState() -> MicrophonePermissionState {
        state
    }

    func requestAccess(_ completion: @escaping (MicrophonePermissionState) -> Void) {
        completion(state)
    }
}

private final class FakeAudioCaptureBackend: AudioCaptureBackend {
    let inputFormat: AVAudioFormat
    let inputSource: AudioInputSource
    var inputDeviceName: String
    var isStarted = false
    var installTapCalled = false
    var removeTapCalled = false
    var startError: Error?
    private var configurationChangeHandler: (() -> Void)?

    init(
        inputSource: AudioInputSource = .microphone,
        inputDeviceName: String = "Test Microphone"
    ) {
        self.inputSource = inputSource
        self.inputDeviceName = inputDeviceName
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
