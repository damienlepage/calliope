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
    case privacyGuardrailsNotSatisfied
    case systemAudioCaptureNotAllowed
    case audioFileCreationFailed
    case engineStartFailed
    case bufferWriteFailed
    case engineConfigurationChanged

    var message: String {
        switch self {
        case .microphonePermissionNotDetermined:
            return "Microphone access is required. Click Grant Microphone Access."
        case .microphonePermissionDenied:
            return "Microphone access is denied. Enable it in System Settings > Privacy & Security > Microphone."
        case .microphonePermissionRestricted:
            return "Microphone access is restricted by system policy."
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
        }
    }
}

enum AudioCaptureStatus: Equatable {
    case idle
    case recording
    case error(AudioCaptureError)
}

enum AudioInputSource: Equatable {
    case microphone
    case systemAudio
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

class AudioCapture: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published private(set) var status: AudioCaptureStatus = .idle
    @Published private(set) var currentRecordingURL: URL?
    @Published private(set) var inputDeviceName: String = "Unknown Microphone"

    private let bufferSubject = PassthroughSubject<AVAudioPCMBuffer, Never>()
    var audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> {
        bufferSubject.eraseToAnyPublisher()
    }

    private var backend: AudioCaptureBackend?
    private var audioFile: AudioFileWritable?
    private var tapFrameCounter: UInt = 0
    private let recordingManager: RecordingManager
    private let backendFactory: () -> AudioCaptureBackend
    private let audioFileFactory: (URL, [String: Any]) throws -> AudioFileWritable

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

    override init() {
        self.recordingManager = RecordingManager.shared
        self.backendFactory = { SystemAudioCaptureBackend() }
        self.audioFileFactory = { url, settings in
            try SystemAudioFileWriter(url: url, settings: settings)
        }
        super.init()
        // macOS doesn't use AVAudioSession - AVAudioEngine handles this directly
    }

    init(
        recordingManager: RecordingManager = .shared,
        backendFactory: @escaping () -> AudioCaptureBackend,
        audioFileFactory: @escaping (URL, [String: Any]) throws -> AudioFileWritable
    ) {
        self.recordingManager = recordingManager
        self.backendFactory = backendFactory
        self.audioFileFactory = audioFileFactory
        super.init()
    }

    func startRecording(
        privacyState: PrivacyGuardrails.State,
        microphonePermission: MicrophonePermissionState
    ) {
        guard !isRecording else { return }
        guard RecordingEligibility.canStart(
            privacyState: privacyState,
            microphonePermission: microphonePermission
        ) else {
            let error: AudioCaptureError = microphonePermission != .authorized
                ? permissionError(for: microphonePermission)
                : .privacyGuardrailsNotSatisfied
            updateStatus(.error(error))
            return
        }

        let backend = backendFactory()
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

        do {
            try backend.start()
            isRecording = true
            updateStatus(.recording)
        } catch {
            stopRecordingInternal(statusOverride: .error(.engineStartFailed))
        }
    }

    func startRecording(
        privacyState: PrivacyGuardrails.State,
        microphonePermissionProvider: MicrophonePermissionProviding
    ) {
        let state = microphonePermissionProvider.authorizationState()
        startRecording(privacyState: privacyState, microphonePermission: state)
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
        backend?.clearConfigurationChangeHandler()
        backend?.removeTap()
        backend?.stop()
        audioFile = nil
        backend = nil

        isRecording = false
        updateStatus(statusOverride)
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

    private func updateStatus(_ newStatus: AudioCaptureStatus) {
        if Thread.isMainThread {
            status = newStatus
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.status = newStatus
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

    private func permissionError(for state: MicrophonePermissionState) -> AudioCaptureError {
        switch state {
        case .notDetermined:
            return .microphonePermissionNotDetermined
        case .denied:
            return .microphonePermissionDenied
        case .restricted:
            return .microphonePermissionRestricted
        case .authorized:
            return .microphonePermissionNotDetermined
        }
    }

    func setRecordingURLForTesting(_ url: URL?) {
        currentRecordingURL = url
    }
}
