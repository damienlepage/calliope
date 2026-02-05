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
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
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

    func testStartRecordingUpdatesBackendStatusFromSelector() {
        let backend = FakeAudioCaptureBackend()
        let fileWriter = FakeAudioFileWriter()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let preferencesStore = makePreferencesStore()
        preferencesStore.voiceIsolationEnabled = true
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { preferences in
                XCTAssertTrue(preferences.voiceIsolationEnabled)
                return AudioCaptureBackendSelection(backend: backend, status: .voiceIsolation)
            },
            audioFileFactory: { _, _ in fileWriter }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertEqual(capture.backendStatus, .voiceIsolation)
    }

    func testVoiceIsolationUnavailableFallsBackToStandardStatus() {
        let backend = FakeAudioCaptureBackend()
        let fileWriter = FakeAudioFileWriter()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let preferencesStore = makePreferencesStore()
        preferencesStore.voiceIsolationEnabled = true
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .voiceIsolationUnavailable)
            },
            audioFileFactory: { _, _ in fileWriter }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.backendStatus, .voiceIsolationUnavailable)
    }

    func testStartRecordingUpdatesInputDeviceName() {
        let backend = FakeAudioCaptureBackend(inputDeviceName: "Test Microphone")
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
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
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
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
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
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
                capturePreferencesStore: makePreferencesStore(),
                backendSelector: { _ in
                    AudioCaptureBackendSelection(backend: backend, status: .standard)
                },
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
                capturePreferencesStore: makePreferencesStore(),
                backendSelector: { _ in
                    AudioCaptureBackendSelection(backend: backend, status: .standard)
                },
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
                capturePreferencesStore: makePreferencesStore(),
                backendSelector: { _ in
                    AudioCaptureBackendSelection(backend: backend, status: .standard)
                },
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
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
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

    func testStartRecordingEngineFailureCleansUpEmptyRecordingFile() {
        let backend = FakeAudioCaptureBackend()
        backend.startError = TestError.engineStart
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("AudioCaptureTests.\(UUID().uuidString)", isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempRoot)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { url, _ in
                FileManager.default.createFile(atPath: url.path, contents: Data(), attributes: nil)
                return FakeAudioFileWriter()
            }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertEqual(capture.status, .error(.engineStartFailed))
        guard let url = capture.currentRecordingURL else {
            XCTFail("Expected a recording URL")
            return
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testStartRecordingAudioFileFailureSetsError() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
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
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
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

    func testStartRecordingTimeoutStopsCaptureAndShowsError() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            recordingStartTimeout: 0.05,
            recordingStartConfirmation: { false }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        let timeoutHandled = expectation(description: "start timeout handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            timeoutHandled.fulfill()
        }
        wait(for: [timeoutHandled], timeout: 1.0)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.captureStartTimedOut))
        XCTAssertTrue(backend.removeTapCalled)
        XCTAssertFalse(backend.isStarted)
    }

    func testStartRecordingTimeoutDoesNotFireOnSuccess() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            recordingStartTimeout: 0.05
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        let timeoutHandled = expectation(description: "start timeout not fired")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            timeoutHandled.fulfill()
        }
        wait(for: [timeoutHandled], timeout: 1.0)

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.status, .recording)
        XCTAssertTrue(backend.isStarted)
        XCTAssertFalse(backend.removeTapCalled)
    }

    func testCaptureStartValidationStopsWhenInputLevelMissing() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            captureStartValidationTimeout: 0.05,
            captureStartValidationThreshold: 0.5,
            inputLevelProvider: { _ in 0.0 },
            fileSizeProvider: { _ in 1 }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        let validationHandled = expectation(description: "validation handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            validationHandled.fulfill()
        }
        wait(for: [validationHandled], timeout: 1.0)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.captureStartValidationFailed))
        XCTAssertTrue(backend.removeTapCalled)
        XCTAssertFalse(backend.isStarted)
    }

    func testCaptureStartValidationStopsWhenFileSizeMissing() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            captureStartValidationTimeout: 0.05,
            captureStartValidationThreshold: 0.5,
            inputLevelProvider: { _ in 1.0 },
            fileSizeProvider: { _ in 0 }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        let validationHandled = expectation(description: "validation handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            validationHandled.fulfill()
        }
        wait(for: [validationHandled], timeout: 1.0)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .error(.captureStartValidationFailed))
        XCTAssertTrue(backend.removeTapCalled)
        XCTAssertFalse(backend.isStarted)
    }

    func testCaptureStartValidationDoesNotFireOnSuccess() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            captureStartValidationTimeout: 0.05,
            captureStartValidationThreshold: 0.5,
            inputLevelProvider: { _ in 1.0 },
            fileSizeProvider: { _ in 10 }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        let validationHandled = expectation(description: "validation handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            validationHandled.fulfill()
        }
        wait(for: [validationHandled], timeout: 1.0)

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.status, .recording)
        XCTAssertTrue(backend.isStarted)
        XCTAssertFalse(backend.removeTapCalled)
    }

    func testStopRecordingClearsErrorWhenNotRecording() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
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
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
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
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
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

    func testMicTestSucceedsWhenBufferReceived() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startMicTest(
            privacyState: privacyState,
            microphonePermission: .authorized,
            duration: 0.05
        )
        backend.simulateBuffer()

        let testCompleted = expectation(description: "mic test completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            testCompleted.fulfill()
        }
        wait(for: [testCompleted], timeout: 1.0)

        XCTAssertEqual(capture.micTestStatus, .success("Mic test succeeded."))
        XCTAssertFalse(capture.isTestingMic)
        XCTAssertTrue(backend.removeTapCalled)
        XCTAssertFalse(backend.isStarted)
    }

    func testStartRecordingClearsMicTestStatus() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startMicTest(
            privacyState: privacyState,
            microphonePermission: .authorized,
            duration: 0.05
        )
        backend.simulateBuffer()

        let testCompleted = expectation(description: "mic test completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            testCompleted.fulfill()
        }
        wait(for: [testCompleted], timeout: 1.0)

        XCTAssertEqual(capture.micTestStatus, .success("Mic test succeeded."))

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertEqual(capture.micTestStatus, .idle)
        capture.stopRecording()
    }

    func testMicTestFailsWhenNoInputDetected() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startMicTest(
            privacyState: privacyState,
            microphonePermission: .authorized,
            duration: 0.05
        )

        let testCompleted = expectation(description: "mic test completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            testCompleted.fulfill()
        }
        wait(for: [testCompleted], timeout: 1.0)

        XCTAssertEqual(
            capture.micTestStatus,
            .failure("No mic input detected during the mic test.")
        )
        XCTAssertFalse(capture.isTestingMic)
        XCTAssertTrue(backend.removeTapCalled)
    }

    func testMicTestFailureWhenEngineStartFails() {
        let backend = FakeAudioCaptureBackend()
        backend.startError = TestError.engineStart
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startMicTest(
            privacyState: privacyState,
            microphonePermission: .authorized,
            duration: 0.05
        )

        XCTAssertEqual(
            capture.micTestStatus,
            .failure(AudioCaptureError.engineStartFailed.message)
        )
        XCTAssertTrue(backend.removeTapCalled)
        XCTAssertFalse(backend.isStarted)
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

private func makePreferencesStore() -> AudioCapturePreferencesStore {
    let suiteName = "AudioCaptureTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return AudioCapturePreferencesStore(defaults: defaults)
}

private final class FakeAudioCaptureBackend: AudioCaptureBackend {
    let inputFormat: AVAudioFormat
    let inputSource: AudioInputSource
    var inputDeviceName: String
    var isStarted = false
    var installTapCalled = false
    var removeTapCalled = false
    var startError: Error?
    private var tapHandler: ((AVAudioPCMBuffer) -> Void)?
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
        tapHandler = handler
    }

    func removeTap() {
        removeTapCalled = true
        tapHandler = nil
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

    func simulateBuffer() {
        guard let tapHandler else { return }
        let buffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: 1)!
        buffer.frameLength = 1
        tapHandler(buffer)
    }
}

private final class FakeAudioFileWriter: AudioFileWritable {
    func write(from buffer: AVAudioPCMBuffer) throws {
        return
    }
}
