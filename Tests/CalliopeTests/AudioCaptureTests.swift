import AppKit
import AVFoundation
import Combine
import XCTest
@testable import Calliope

final class AudioCaptureTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

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

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .idle)
        backend.simulateBuffer()

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

        backend.simulateBuffer()
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

    func testRecordingSegmentRotatesWhenMaxDurationExceeded() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let preferencesStore = makePreferencesStore()
        preferencesStore.maxSegmentDuration = 1.0
        var currentTime = Date()
        var createdURLs: [URL] = []
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { url, _ in
                createdURLs.append(url)
                return FakeAudioFileWriter()
            },
            now: { currentTime }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        let firstURL = capture.currentRecordingURL
        backend.simulateBuffer()

        currentTime = currentTime.addingTimeInterval(1.2)
        backend.simulateBuffer()
        let secondURL = capture.currentRecordingURL

        XCTAssertEqual(createdURLs.count, 2)
        XCTAssertNotNil(firstURL)
        XCTAssertNotNil(secondURL)
        XCTAssertNotEqual(firstURL, secondURL)
        XCTAssertTrue(firstURL?.lastPathComponent.contains("part-01") ?? false)
        XCTAssertTrue(secondURL?.lastPathComponent.contains("part-02") ?? false)
        capture.stopRecording()
    }

    func testRecordingSegmentDoesNotRotateWhenDisabled() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let preferencesStore = makePreferencesStore()
        preferencesStore.maxSegmentDuration = 0
        var currentTime = Date()
        var createdURLs: [URL] = []
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { url, _ in
                createdURLs.append(url)
                return FakeAudioFileWriter()
            },
            now: { currentTime }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        currentTime = currentTime.addingTimeInterval(3.0)
        backend.simulateBuffer()

        XCTAssertEqual(createdURLs.count, 1)
        capture.stopRecording()
    }

    func testStartRecordingSelectsPreferredMicrophoneWhenConfigured() {
        let backend = FakeAudioCaptureBackend()
        backend.selectionResult = .selected
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let preferencesStore = makePreferencesStore()
        preferencesStore.preferredMicrophoneName = "USB Mic"
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertEqual(backend.selectInputDeviceCalls, ["USB Mic"])
        XCTAssertNil(capture.deviceSelectionMessage)
    }

    func testStartRecordingFallsBackWhenPreferredMicrophoneUnavailable() {
        let backend = FakeAudioCaptureBackend()
        backend.selectionResult = .fallbackToDefault
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let preferencesStore = makePreferencesStore()
        preferencesStore.preferredMicrophoneName = "USB Mic"
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertEqual(backend.selectInputDeviceCalls, ["USB Mic"])
        XCTAssertEqual(
            capture.deviceSelectionMessage,
            "Preferred microphone \"USB Mic\" not available. Using system default."
        )
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
            backend.simulateBuffer()
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
        backend.simulateBuffer()

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

    func testStartRecordingConfirmationMarksRecordingWithoutBuffer() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            recordingStartConfirmation: { true }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.status, .recording)
        XCTAssertTrue(backend.isStarted)

        capture.stopRecording()
    }

    func testStartRecordingWhileAwaitingStartIsIgnored() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            recordingStartTimeout: 0.2,
            recordingStartConfirmation: { false }
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        XCTAssertEqual(backend.startCallCount, 1)
        XCTAssertEqual(backend.installTapCallCount, 1)
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

    func testConfigurationChangeMarksInterruptionWithoutStopping() {
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
        backend.simulateBuffer()

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.status, .recording)

        backend.simulateConfigurationChange()

        let configurationHandled = expectation(description: "configuration change handled")
        DispatchQueue.main.async {
            configurationHandled.fulfill()
        }
        wait(for: [configurationHandled], timeout: 1.0)

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.status, .recording)
        XCTAssertEqual(capture.interruption, .inputRouteChanged)
        XCTAssertFalse(backend.removeTapCalled)
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
        backend.simulateBuffer()
        backend.inputDeviceName = "Secondary Mic"
        backend.simulateConfigurationChange()

        let configurationHandled = expectation(description: "configuration change handled")
        DispatchQueue.main.async {
            configurationHandled.fulfill()
        }
        wait(for: [configurationHandled], timeout: 1.0)

        XCTAssertEqual(capture.inputDeviceName, "Secondary Mic")
        XCTAssertEqual(capture.status, .recording)
        XCTAssertEqual(capture.interruption, .inputRouteChanged)
    }

    func testSystemSleepStopsRecordingAndSetsInterruption() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let workspaceCenter = NotificationCenter()
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            workspaceNotificationCenter: workspaceCenter
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        workspaceCenter.post(name: NSWorkspace.willSleepNotification, object: nil)

        let sleepHandled = expectation(description: "sleep handled")
        DispatchQueue.main.async {
            sleepHandled.fulfill()
        }
        wait(for: [sleepHandled], timeout: 1.0)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .idle)
        XCTAssertEqual(capture.interruption, .systemSleep)
        XCTAssertTrue(backend.removeTapCalled)
    }

    func testSystemWakeReportsReadyMessageAfterSleep() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let workspaceCenter = NotificationCenter()
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            workspaceNotificationCenter: workspaceCenter
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        workspaceCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
        workspaceCenter.post(name: NSWorkspace.didWakeNotification, object: nil)

        let wakeHandled = expectation(description: "wake handled")
        DispatchQueue.main.async {
            wakeHandled.fulfill()
        }
        wait(for: [wakeHandled], timeout: 1.0)

        XCTAssertFalse(capture.isRecording)
        XCTAssertEqual(capture.status, .idle)
        XCTAssertEqual(capture.interruption, .systemWake)
    }

    func testAppResignActiveSetsInterruptionWithoutStoppingRecording() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let notificationCenter = NotificationCenter()
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            notificationCenter: notificationCenter
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        notificationCenter.post(name: NSApplication.willResignActiveNotification, object: nil)

        let resignHandled = expectation(description: "resign active handled")
        DispatchQueue.main.async {
            resignHandled.fulfill()
        }
        wait(for: [resignHandled], timeout: 1.0)

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.status, .recording)
        XCTAssertEqual(capture.interruption, .appInactive)
    }

    func testAppBecomeActiveClearsInactiveInterruption() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let notificationCenter = NotificationCenter()
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            notificationCenter: notificationCenter
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        notificationCenter.post(name: NSApplication.willResignActiveNotification, object: nil)
        notificationCenter.post(name: NSApplication.didBecomeActiveNotification, object: nil)

        let becomeHandled = expectation(description: "become active handled")
        DispatchQueue.main.async {
            becomeHandled.fulfill()
        }
        wait(for: [becomeHandled], timeout: 1.0)

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.status, .recording)
        XCTAssertNil(capture.interruption)
    }

    func testInputDisconnectSetsNonBlockingInterruption() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let notificationCenter = NotificationCenter()
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            notificationCenter: notificationCenter
        )

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        notificationCenter.post(name: .AVCaptureDeviceWasDisconnected, object: nil)

        let disconnectHandled = expectation(description: "disconnect handled")
        DispatchQueue.main.async {
            disconnectHandled.fulfill()
        }
        wait(for: [disconnectHandled], timeout: 1.0)

        XCTAssertTrue(capture.isRecording)
        XCTAssertEqual(capture.status, .recording)
        XCTAssertEqual(capture.interruption, .inputDisconnected)
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

    func testRecordingRolloverCreatesNewSegment() {
        let backend = FakeAudioCaptureBackend()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let preferencesStore = makePreferencesStore()
        preferencesStore.maxSegmentDuration = 1.0
        var now = Date()
        var createdURLs: [URL] = []
        var writers: [FakeAudioFileWriter] = []
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { url, _ in
                createdURLs.append(url)
                let writer = FakeAudioFileWriter()
                writers.append(writer)
                return writer
            },
            now: { now }
        )

        let privacyState = PrivacyGuardrails.State(hasAcceptedDisclosure: true)
        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        now = now.addingTimeInterval(2.0)
        backend.simulateBuffer()

        XCTAssertEqual(createdURLs.count, 2)
        XCTAssertEqual(capture.currentRecordingURL, createdURLs.last)
        XCTAssertTrue(createdURLs.first?.lastPathComponent.contains("part-01") == true)
        XCTAssertTrue(createdURLs.last?.lastPathComponent.contains("part-02") == true)
        XCTAssertEqual(writers.count, 2)
    }

    func testRecordingPublishesBuffersAndWritesToFile() {
        let backend = FakeAudioCaptureBackend()
        let fileWriter = FakeAudioFileWriter()
        let manager = RecordingManager(baseDirectory: FileManager.default.temporaryDirectory)
        let capture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: makePreferencesStore(),
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in fileWriter },
            captureStartValidationTimeout: 0.2,
            inputLevelProvider: { _ in 1.0 },
            fileSizeProvider: { _ in 1 }
        )

        let bufferExpectation = expectation(description: "buffer published")
        capture.audioBufferPublisher
            .sink { _ in
                bufferExpectation.fulfill()
            }
            .store(in: &cancellables)

        let privacyState = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        backend.simulateBuffer()

        wait(for: [bufferExpectation], timeout: 1.0)

        XCTAssertGreaterThan(fileWriter.writeCount, 0)
        XCTAssertTrue(capture.isRecording)
        capture.stopRecording()
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
    var installTapCallCount = 0
    var startCallCount = 0
    var startError: Error?
    var selectionResult: AudioInputDeviceSelectionResult = .notRequested
    var selectInputDeviceCalls: [String?] = []
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
        installTapCallCount += 1
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

    func selectInputDevice(named preferredName: String?) -> AudioInputDeviceSelectionResult {
        selectInputDeviceCalls.append(preferredName)
        return selectionResult
    }

    func start() throws {
        if let startError {
            throw startError
        }
        startCallCount += 1
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
    private(set) var writeCount = 0
    var onWrite: ((AVAudioPCMBuffer) -> Void)?

    func write(from buffer: AVAudioPCMBuffer) throws {
        writeCount += 1
        onWrite?(buffer)
    }
}
