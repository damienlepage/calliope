//
//  AudioCapture.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Combine

class AudioCapture: NSObject, ObservableObject {
    @Published var isRecording = false

    private let bufferSubject = PassthroughSubject<AVAudioPCMBuffer, Never>()
    var audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> {
        bufferSubject.eraseToAnyPublisher()
    }

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var tapFrameCounter: UInt = 0
    private let recordingManager = RecordingManager.shared

    override init() {
        super.init()
        // macOS doesn't use AVAudioSession - AVAudioEngine handles this directly
    }

    func startRecording(privacyState: PrivacyGuardrails.State) {
        guard !isRecording else { return }
        guard PrivacyGuardrails.canStartRecording(state: privacyState) else {
            print("Privacy guardrails not satisfied. Recording blocked.")
            return
        }

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }

        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Recordings are written locally only; no network transmission.
        // Create audio file
        let url = recordingManager.getNewRecordingURL()
        do {
            audioFile = try AVAudioFile(forWriting: url, settings: recordingFormat.settings)
        } catch {
            print("Failed to create audio file: \(error)")
            return
        }

        tapFrameCounter = 0

        // Install tap to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, let audioFile = self.audioFile else { return }

            if let copiedBuffer = AudioBufferCopy.copy(buffer) {
                self.bufferSubject.send(copiedBuffer)
            }

            do {
                try audioFile.write(from: buffer)
            } catch {
                print("Failed to write audio buffer: \(error)")
            }

            self.tapFrameCounter += 1
            if self.tapFrameCounter % 50 == 0 {
                print("AudioCapture received \(self.tapFrameCounter) buffers")
            }
        }

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioFile = nil
        audioEngine = nil
        inputNode = nil

        isRecording = false
    }
}
