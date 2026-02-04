//
//  AudioAnalyzer.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Combine

class AudioAnalyzer: ObservableObject {
    @Published var currentPace: Double = 0.0 // words per minute
    @Published var crutchWordCount: Int = 0
    @Published var pauseCount: Int = 0

    private var speechTranscriber: SpeechTranscriber?
    private var crutchWordDetector: CrutchWordDetector?
    private var paceAnalyzer: PaceAnalyzer?
    private var pauseDetector: PauseDetector?
    private var cancellables = Set<AnyCancellable>()

    func setup(audioCapture: AudioCapture) {
        speechTranscriber = SpeechTranscriber()
        crutchWordDetector = CrutchWordDetector()
        paceAnalyzer = PaceAnalyzer()
        pauseDetector = PauseDetector()

        speechTranscriber?.onTranscription = { [weak self] transcript in
            guard let self = self else { return }
            let totalWords = self.wordCount(in: transcript)
            self.paceAnalyzer?.updateWordCount(totalWords)
            let pace = self.paceAnalyzer?.calculatePace() ?? 0.0
            DispatchQueue.main.async {
                self.currentPace = pace
            }
        }

        audioCapture.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                guard let self = self else { return }
                if isRecording {
                    self.paceAnalyzer?.start()
                    self.speechTranscriber?.startTranscription()
                } else {
                    self.speechTranscriber?.stopTranscription()
                    self.paceAnalyzer?.reset()
                    self.currentPace = 0.0
                }
            }
            .store(in: &cancellables)

        audioCapture.audioBufferPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] buffer in
                self?.processAudioBuffer(buffer)
            }
            .store(in: &cancellables)
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Process audio buffer for real-time analysis
        // This will be called continuously during recording
        speechTranscriber?.appendAudioBuffer(buffer)
        _ = buffer
    }

    private func wordCount(in text: String) -> Int {
        let tokens = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return tokens.count
    }
}
