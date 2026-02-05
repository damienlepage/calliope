//
//  AudioCapture.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Combine

enum AudioCaptureError: Equatable {
    case microphonePermissionNotDetermined
    case microphonePermissionDenied
    case microphonePermissionRestricted
    case microphoneUnavailable
    case privacyGuardrailsNotSatisfied
    case systemAudioCaptureNotAllowed
    case audioFileCreationFailed
    case engineStartFailed
    case bufferWriteFailed
    case engineConfigurationChanged
    case captureStartTimedOut

    var message: String {
        switch self {
        case .microphonePermissionNotDetermined:
            return "Microphone access is required. Click Grant Microphone Access."
        case .microphonePermissionDenied:
            return "Microphone access is denied. Enable it in System Settings > Privacy & Security > Microphone."
        case .microphonePermissionRestricted:
            return "Microphone access is restricted by system policy."
        case .microphoneUnavailable:
            return "No microphone input detected. Connect or enable a microphone."
        case .privacyGuardrailsNotSatisfied:
            return "Privacy guardrails must be accepted to start."
        case .systemAudioCaptureNotAllowed:
            return "System audio capture is not allowed."
        case .audioFileCreationFailed:
            return "Failed to create local recording file."
        case .engineStartFailed:
            return "Failed to start the audio engine."
        case .bufferWriteFailed:
            return "Failed to write an audio buffer."
        case .engineConfigurationChanged:
            return "Input device changed. Press Start again."
        case .captureStartTimedOut:
            return "Capture did not start in time. Press Start again."
        }
    }
}

enum AudioCaptureStatus: Equatable {
    case idle
    case recording
    case error(AudioCaptureError)
}

enum MicTestStatus: Equatable {
    case idle
    case running
    case success(String)
    case failure(String)

    var message: String? {
        switch self {
        case .idle:
            return nil
        case .running:
            return "Mic test running..."
        case .success(let message):
            return message
        case .failure(let message):
            return message
        }
    }
}

enum AudioCaptureBackendStatus: Equatable {
    case standard
    case voiceIsolation
    case voiceIsolationUnavailable

    var message: String {
        switch self {
        case .standard:
            return "Capture: Standard mic"
        case .voiceIsolation:
            return "Capture: Voice Isolation enabled"
        case .voiceIsolationUnavailable:
            return "Capture: Voice Isolation unavailable, using standard mic"
        }
    }
}

enum AudioInputSource: Equatable {
    case microphone
    case systemAudio
}

struct AudioCaptureBackendSelection {
    let backend: AudioCaptureBackend
    let status: AudioCaptureBackendStatus
}

protocol AudioCaptureBackend {
    var inputSource: AudioInputSource { get }
    var inputFormat: AVAudioFormat { get }
    var inputDeviceName: String { get }
    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void)
    func removeTap()
    func setConfigurationChangeHandler(_ handler: @escaping () -> Void)
    func clearConfigurationChangeHandler()
    func start() throws
    func stop()
}

protocol AudioFileWritable {
    func write(from buffer: AVAudioPCMBuffer) throws
}

final class SystemAudioFileWriter: AudioFileWritable {
    private let file: AVAudioFile

    init(url: URL, settings: [String: Any]) throws {
        file = try AVAudioFile(forWriting: url, settings: settings)
    }

    func write(from buffer: AVAudioPCMBuffer) throws {
        try file.write(from: buffer)
    }
}

final class SystemAudioCaptureBackend: AudioCaptureBackend {
    private let engine: AVAudioEngine
    private let inputNode: AVAudioInputNode
    private var configurationObserver: NSObjectProtocol?
    let inputFormat: AVAudioFormat
    let inputSource: AudioInputSource = .microphone
    var inputDeviceName: String {
        inputNode.auAudioUnit.deviceName
    }

    init() {
        engine = AVAudioEngine()
        inputNode = engine.inputNode
        inputFormat = inputNode.outputFormat(forBus: 0)
    }

    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void) {
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { buffer, _ in
            handler(buffer)
        }
    }

    func removeTap() {
        inputNode.removeTap(onBus: 0)
    }

    func setConfigurationChangeHandler(_ handler: @escaping () -> Void) {
        clearConfigurationChangeHandler()
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { _ in
            handler()
        }
    }

    func clearConfigurationChangeHandler() {
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
            self.configurationObserver = nil
        }
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }
}

enum VoiceIsolationBackendError: Error {
    case notSupported
}

final class VoiceIsolationAudioCaptureBackend: AudioCaptureBackend {
    private let engine: AVAudioEngine
    private let inputNode: AVAudioInputNode
    private var configurationObserver: NSObjectProtocol?
    let inputFormat: AVAudioFormat
    let inputSource: AudioInputSource = .microphone
    var inputDeviceName: String {
        inputNode.auAudioUnit.deviceName
    }

    init() throws {
        engine = AVAudioEngine()
        inputNode = engine.inputNode
        try Self.enableVoiceIsolation(on: inputNode)
        inputFormat = inputNode.outputFormat(forBus: 0)
    }

    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void) {
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { buffer, _ in
            handler(buffer)
        }
    }

    func removeTap() {
        inputNode.removeTap(onBus: 0)
    }

    func setConfigurationChangeHandler(_ handler: @escaping () -> Void) {
        clearConfigurationChangeHandler()
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { _ in
            handler()
        }
    }

    func clearConfigurationChangeHandler() {
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
            self.configurationObserver = nil
        }
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }

    private static func enableVoiceIsolation(on inputNode: AVAudioInputNode) throws {
        if #available(macOS 14.0, *) {
            try inputNode.setVoiceProcessingEnabled(true)
            guard inputNode.isVoiceProcessingEnabled else {
                throw VoiceIsolationBackendError.notSupported
            }
        } else {
            throw VoiceIsolationBackendError.notSupported
        }
    }
}

class AudioCapture: NSObject, ObservableObject {
    typealias AudioCaptureBackendSelector = (AudioCapturePreferences) -> AudioCaptureBackendSelection

    @Published var isRecording = false
    @Published private(set) var status: AudioCaptureStatus = .idle
    @Published private(set) var micTestStatus: MicTestStatus = .idle
    @Published private(set) var currentRecordingURL: URL?
    @Published private(set) var inputDeviceName: String = "Unknown Microphone"
    @Published private(set) var backendStatus: AudioCaptureBackendStatus = .standard

    private let bufferSubject = PassthroughSubject<AVAudioPCMBuffer, Never>()
    var audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> {
        bufferSubject.eraseToAnyPublisher()
    }

    private var backend: AudioCaptureBackend?
    private var audioFile: AudioFileWritable?
    private var tapFrameCounter: UInt = 0
    private var micTestBackend: AudioCaptureBackend?
    private var micTestWorkItem: DispatchWorkItem?
    private var micTestDidReceiveBuffer = false
    private let recordingManager: RecordingManager
    private let capturePreferencesStore: AudioCapturePreferencesStore
    private let backendSelector: AudioCaptureBackendSelector
    private let audioFileFactory: (URL, [String: Any]) throws -> AudioFileWritable
    private let recordingStartTimeout: TimeInterval
    private let recordingStartTimeoutQueue: DispatchQueue
    private let recordingStartConfirmation: () -> Bool
    private var recordingStartWorkItem: DispatchWorkItem?

    var statusText: String {
        switch status {
        case .idle:
            return "Stopped"
        case .recording:
            return "Recording"
        case .error(let error):
            return "Error: \(error.message)"
        }
    }

    init(
        recordingManager: RecordingManager = .shared,
        capturePreferencesStore: AudioCapturePreferencesStore = AudioCapturePreferencesStore(),
        backendSelector: @escaping AudioCaptureBackendSelector = AudioCapture.defaultBackendSelector,
        audioFileFactory: @escaping (URL, [String: Any]) throws -> AudioFileWritable = { url, settings in
            try SystemAudioFileWriter(url: url, settings: settings)
        },
        recordingStartTimeout: TimeInterval = 1.0,
        recordingStartTimeoutQueue: DispatchQueue = .main,
        recordingStartConfirmation: @escaping () -> Bool = { true }
    ) {
        self.recordingManager = recordingManager
        self.capturePreferencesStore = capturePreferencesStore
        self.backendSelector = backendSelector
        self.audioFileFactory = audioFileFactory
        self.recordingStartTimeout = recordingStartTimeout
        self.recordingStartTimeoutQueue = recordingStartTimeoutQueue
        self.recordingStartConfirmation = recordingStartConfirmation
        super.init()
        // macOS doesn't use AVAudioSession - AVAudioEngine handles this directly
    }

    static let defaultBackendSelector: AudioCaptureBackendSelector = { preferences in
        if preferences.voiceIsolationEnabled {
            if let backend = try? VoiceIsolationAudioCaptureBackend() {
                return AudioCaptureBackendSelection(
                    backend: backend,
                    status: .voiceIsolation
                )
            }
            return AudioCaptureBackendSelection(
                backend: SystemAudioCaptureBackend(),
                status: .voiceIsolationUnavailable
            )
        }
        return AudioCaptureBackendSelection(
            backend: SystemAudioCaptureBackend(),
            status: .standard
        )
    }

    var backendStatusText: String {
        backendStatus.message
    }

    var micTestStatusText: String? {
        micTestStatus.message
    }

    var isTestingMic: Bool {
        if case .running = micTestStatus {
            return true
        }
        return false
    }

    func startRecording(
        privacyState: PrivacyGuardrails.State,
        microphonePermission: MicrophonePermissionState,
        hasMicrophoneInput: Bool = true
    ) {
        guard !isRecording else { return }
        guard !isTestingMic else { return }
        micTestStatus = .idle
        let blockingReasons = RecordingEligibility.blockingReasons(
            privacyState: privacyState,
            microphonePermission: microphonePermission,
            hasMicrophoneInput: hasMicrophoneInput
        )
        guard blockingReasons.isEmpty else {
            if let reason = blockingReasons.first {
                updateStatus(.error(error(for: reason)))
            }
            return
        }

        let preferences = capturePreferencesStore.current
        let selection = backendSelector(preferences)
        let backend = selection.backend
        backendStatus = selection.status
        guard backend.inputSource == .microphone else {
            updateStatus(.error(.systemAudioCaptureNotAllowed))
            return
        }
        self.backend = backend
        refreshInputDeviceName(from: backend)
        let recordingFormat = backend.inputFormat
        backend.setConfigurationChangeHandler { [weak self] in
            self?.handleConfigurationChange()
        }

        // Recordings are written locally only; no network transmission.
        // Create audio file
        let url = recordingManager.getNewRecordingURL()
        do {
            audioFile = try audioFileFactory(url, recordingFormat.settings)
            currentRecordingURL = url
        } catch {
            updateStatus(.error(.audioFileCreationFailed))
            self.backend = nil
            return
        }

        tapFrameCounter = 0

        // Install tap to capture audio
        backend.installTap(bufferSize: 1024) { [weak self] buffer in
            guard let self = self, let audioFile = self.audioFile else { return }

            if let copiedBuffer = AudioBufferCopy.copy(buffer) {
                self.bufferSubject.send(copiedBuffer)
            }

            do {
                try audioFile.write(from: buffer)
            } catch {
                self.handleCaptureError(.bufferWriteFailed)
            }

            self.tapFrameCounter += 1
            if self.tapFrameCounter % 50 == 0 {
                print("AudioCapture received \(self.tapFrameCounter) buffers")
            }
        }

        scheduleRecordingStartTimeout()

        do {
            try backend.start()
            if recordingStartConfirmation() {
                markRecordingStarted()
            }
        } catch {
            cancelRecordingStartTimeout()
            stopRecordingInternal(statusOverride: .error(.engineStartFailed))
        }
    }

    func startMicTest(
        privacyState: PrivacyGuardrails.State,
        microphonePermission: MicrophonePermissionState,
        hasMicrophoneInput: Bool = true,
        duration: TimeInterval = 2.5
    ) {
        guard !isRecording else {
            updateMicTestStatus(.failure("Stop the current recording before running a mic test."))
            return
        }
        guard !isTestingMic else { return }
        let blockingReasons = RecordingEligibility.blockingReasons(
            privacyState: privacyState,
            microphonePermission: microphonePermission,
            hasMicrophoneInput: hasMicrophoneInput
        )
        guard blockingReasons.isEmpty else {
            if let reason = blockingReasons.first {
                updateMicTestStatus(.failure(error(for: reason).message))
            }
            return
        }

        let preferences = capturePreferencesStore.current
        let selection = backendSelector(preferences)
        let backend = selection.backend
        backendStatus = selection.status
        guard backend.inputSource == .microphone else {
            updateMicTestStatus(.failure(AudioCaptureError.systemAudioCaptureNotAllowed.message))
            return
        }

        micTestBackend = backend
        refreshInputDeviceName(from: backend)
        backend.setConfigurationChangeHandler { [weak self] in
            self?.handleMicTestConfigurationChange()
        }

        micTestDidReceiveBuffer = false
        updateMicTestStatus(.running)

        backend.installTap(bufferSize: 1024) { [weak self] _ in
            guard let self else { return }
            self.micTestDidReceiveBuffer = true
        }

        do {
            try backend.start()
        } catch {
            stopMicTest(status: .failure(AudioCaptureError.engineStartFailed.message))
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.finishMicTest()
        }
        micTestWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    func startRecording(
        privacyState: PrivacyGuardrails.State,
        microphonePermissionProvider: MicrophonePermissionProviding,
        hasMicrophoneInput: Bool = true
    ) {
        let state = microphonePermissionProvider.authorizationState()
        startRecording(
            privacyState: privacyState,
            microphonePermission: state,
            hasMicrophoneInput: hasMicrophoneInput
        )
    }

    func stopRecording() {
        if isRecording {
            stopRecordingInternal(statusOverride: .idle)
            return
        }
        if case .error = status {
            updateStatus(.idle)
        }
    }

    private func stopRecordingInternal(statusOverride: AudioCaptureStatus) {
        let wasRecording = isRecording
        cancelRecordingStartTimeout()
        backend?.clearConfigurationChangeHandler()
        backend?.removeTap()
        backend?.stop()
        audioFile = nil
        backend = nil

        isRecording = false
        updateStatus(statusOverride)
        cleanupFailedRecordingIfNeeded(wasRecording: wasRecording)
    }

    private func stopMicTest(status: MicTestStatus) {
        micTestWorkItem?.cancel()
        micTestWorkItem = nil
        micTestBackend?.clearConfigurationChangeHandler()
        micTestBackend?.removeTap()
        micTestBackend?.stop()
        micTestBackend = nil
        micTestDidReceiveBuffer = false
        updateMicTestStatus(status)
    }

    private func handleCaptureError(_ error: AudioCaptureError) {
        DispatchQueue.main.async { [weak self] in
            self?.stopRecordingInternal(statusOverride: .error(error))
        }
    }

    private func handleConfigurationChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isRecording else { return }
            self.refreshInputDeviceName(from: self.backend)
            self.stopRecordingInternal(statusOverride: .error(.engineConfigurationChanged))
        }
    }

    private func handleMicTestConfigurationChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isTestingMic else { return }
            self.refreshInputDeviceName(from: self.micTestBackend)
            self.stopMicTest(status: .failure(AudioCaptureError.engineConfigurationChanged.message))
        }
    }

    private func finishMicTest() {
        let status: MicTestStatus = micTestDidReceiveBuffer
            ? .success("Mic test succeeded.")
            : .failure("No mic input detected during the mic test.")
        stopMicTest(status: status)
    }

    private func updateStatus(_ newStatus: AudioCaptureStatus) {
        if case .recording = newStatus {
            cancelRecordingStartTimeout()
        }
        if case .error = newStatus {
            cancelRecordingStartTimeout()
        }
        if Thread.isMainThread {
            status = newStatus
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.status = newStatus
            }
        }
    }

    private func updateMicTestStatus(_ newStatus: MicTestStatus) {
        if Thread.isMainThread {
            micTestStatus = newStatus
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.micTestStatus = newStatus
            }
        }
    }

    private func refreshInputDeviceName(from backend: AudioCaptureBackend?) {
        guard let backend else { return }
        let deviceName = backend.inputDeviceName
        if Thread.isMainThread {
            inputDeviceName = deviceName
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.inputDeviceName = deviceName
            }
        }
    }

    private func error(for reason: RecordingEligibility.Reason) -> AudioCaptureError {
        switch reason {
        case .microphonePermissionNotDetermined:
            return .microphonePermissionNotDetermined
        case .microphonePermissionDenied:
            return .microphonePermissionDenied
        case .microphonePermissionRestricted:
            return .microphonePermissionRestricted
        case .microphoneUnavailable:
            return .microphoneUnavailable
        case .disclosureNotAccepted:
            return .privacyGuardrailsNotSatisfied
        }
    }

    func setRecordingURLForTesting(_ url: URL?) {
        currentRecordingURL = url
    }

    private func markRecordingStarted() {
        isRecording = true
        updateStatus(.recording)
    }

    private func scheduleRecordingStartTimeout() {
        cancelRecordingStartTimeout()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.isRecording {
                return
            }
            if case .error = self.status {
                return
            }
            self.stopRecordingInternal(statusOverride: .error(.captureStartTimedOut))
        }
        recordingStartWorkItem = workItem
        recordingStartTimeoutQueue.asyncAfter(
            deadline: .now() + recordingStartTimeout,
            execute: workItem
        )
    }

    private func cancelRecordingStartTimeout() {
        recordingStartWorkItem?.cancel()
        recordingStartWorkItem = nil
    }

    private func cleanupFailedRecordingIfNeeded(wasRecording: Bool) {
        guard !wasRecording else { return }
        guard let url = currentRecordingURL else { return }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = values?.fileSize ?? 0
        guard fileSize == 0 else { return }
        try? recordingManager.deleteRecording(at: url)
    }
}
