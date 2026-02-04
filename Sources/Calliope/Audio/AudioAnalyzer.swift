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

    var feedbackPublisher: AnyPublisher<FeedbackState, Never> {
        Publishers.CombineLatest3($currentPace, $crutchWordCount, $pauseCount)
            .map { FeedbackState(pace: $0, crutchWords: $1, pauseCount: $2) }
            .eraseToAnyPublisher()
    }

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
            let crutchCount = self.crutchWordDetector?.analyze(transcript) ?? 0
            DispatchQueue.main.async {
                self.currentPace = pace
                self.crutchWordCount = crutchCount
            }
        }

        audioCapture.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                guard let self = self else { return }
                if isRecording {
                    self.paceAnalyzer?.start()
                    self.pauseDetector?.reset()
                    self.pauseCount = 0
                    self.speechTranscriber?.startTranscription()
                } else {
                    self.speechTranscriber?.stopTranscription()
                    self.paceAnalyzer?.reset()
                    self.crutchWordDetector?.reset()
                    self.pauseDetector?.reset()
                    self.currentPace = 0.0
                    self.crutchWordCount = 0
                    self.pauseCount = 0
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
        if let pauseDetector = pauseDetector {
            let didDetectPause = pauseDetector.detectPause(in: buffer)
            if didDetectPause {
                let updatedCount = pauseDetector.getPauseCount()
                DispatchQueue.main.async { [weak self] in
                    self?.pauseCount = updatedCount
                }
            }
        }
    }

    private func wordCount(in text: String) -> Int {
        let tokens = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return tokens.count
    }
}
