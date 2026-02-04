//
//  AudioCapture.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Combine

enum AudioCaptureError: Equatable {
    case microphonePermissionMissing
    case privacyGuardrailsNotSatisfied
    case audioFileCreationFailed
    case engineStartFailed
    case bufferWriteFailed

    var message: String {
        switch self {
        case .microphonePermissionMissing:
            return "Microphone permission is required."
        case .privacyGuardrailsNotSatisfied:
            return "Privacy guardrails must be accepted to start."
        case .audioFileCreationFailed:
            return "Failed to create local recording file."
        case .engineStartFailed:
            return "Failed to start the audio engine."
        case .bufferWriteFailed:
            return "Failed to write an audio buffer."
        }
    }
}

enum AudioCaptureStatus: Equatable {
    case idle
    case recording
    case error(AudioCaptureError)
}

protocol AudioCaptureBackend {
    var inputFormat: AVAudioFormat { get }
    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void)
    func removeTap()
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
    let inputFormat: AVAudioFormat

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
                ? .microphonePermissionMissing
                : .privacyGuardrailsNotSatisfied
            updateStatus(.error(error))
            return
        }

        let backend = backendFactory()
        self.backend = backend
        let recordingFormat = backend.inputFormat

        // Recordings are written locally only; no network transmission.
        // Create audio file
        let url = recordingManager.getNewRecordingURL()
        do {
            audioFile = try audioFileFactory(url, recordingFormat.settings)
        } catch {
            updateStatus(.error(.audioFileCreationFailed))
            backend = nil
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

    func stopRecording() {
        guard isRecording else { return }
        stopRecordingInternal(statusOverride: .idle)
    }

    private func stopRecordingInternal(statusOverride: AudioCaptureStatus) {
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

    private func updateStatus(_ newStatus: AudioCaptureStatus) {
        if Thread.isMainThread {
            status = newStatus
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.status = newStatus
            }
        }
    }
}
