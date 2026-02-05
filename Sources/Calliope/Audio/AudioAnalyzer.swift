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
    @Published var inputLevel: Double = 0.0

    var feedbackPublisher: AnyPublisher<FeedbackState, Never> {
        Publishers.CombineLatest3($currentPace, $crutchWordCount, $pauseCount)
            .map { FeedbackState(pace: $0, crutchWords: $1, pauseCount: $2) }
            .eraseToAnyPublisher()
    }

    private var speechTranscriber: SpeechTranscriber?
    private(set) var crutchWordDetector: CrutchWordDetector?
    private var paceAnalyzer: PaceAnalyzer?
    private(set) var pauseDetector: PauseDetector?
    private var cancellables = Set<AnyCancellable>()

    func setup(audioCapture: AudioCapture, preferencesStore: AnalysisPreferencesStore) {
        speechTranscriber = SpeechTranscriber()
        paceAnalyzer = PaceAnalyzer()
        applyPreferences(preferencesStore.current)

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

        preferencesStore.preferencesPublisher
            .removeDuplicates()
            .sink { [weak self] preferences in
                self?.applyPreferences(preferences)
            }
            .store(in: &cancellables)

        audioCapture.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                guard let self = self else { return }
                if isRecording {
                    self.paceAnalyzer?.start()
                    self.pauseDetector?.reset()
                    self.pauseCount = 0
                    self.inputLevel = 0.0
                    self.speechTranscriber?.startTranscription()
                } else {
                    self.speechTranscriber?.stopTranscription()
                    self.paceAnalyzer?.reset()
                    self.crutchWordDetector?.reset()
                    self.pauseDetector?.reset()
                    self.currentPace = 0.0
                    self.crutchWordCount = 0
                    self.pauseCount = 0
                    self.inputLevel = 0.0
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

    func applyPreferences(_ preferences: AnalysisPreferences) {
        crutchWordDetector = CrutchWordDetector(crutchWords: preferences.crutchWords)
        pauseDetector = PauseDetector(pauseThreshold: preferences.pauseThreshold)
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Process audio buffer for real-time analysis
        // This will be called continuously during recording
        speechTranscriber?.appendAudioBuffer(buffer)
        updateInputLevel(from: buffer)
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

    private func updateInputLevel(from buffer: AVAudioPCMBuffer) {
        let rms = rmsAmplitude(in: buffer)
        let scaled = min(max(Double(rms) * 8.0, 0.0), 1.0)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.inputLevel = (self.inputLevel * 0.7) + (scaled * 0.3)
        }
    }

    private func rmsAmplitude(in buffer: AVAudioPCMBuffer) -> Float {
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        if let floatChannelData = buffer.floatChannelData {
            let samples = floatChannelData[0]
            var sum: Float = 0
            for index in 0..<frameLength {
                let sample = samples[index]
                sum += sample * sample
            }
            return sqrt(sum / Float(frameLength))
        }

        if let int16ChannelData = buffer.int16ChannelData {
            let samples = int16ChannelData[0]
            var sum: Float = 0
            let scale = 1.0 as Float / Float(Int16.max)
            for index in 0..<frameLength {
                let sample = Float(samples[index]) * scale
                sum += sample * sample
            }
            return sqrt(sum / Float(frameLength))
        }

        if let int32ChannelData = buffer.int32ChannelData {
            let samples = int32ChannelData[0]
            var sum: Float = 0
            let scale = 1.0 as Float / Float(Int32.max)
            for index in 0..<frameLength {
                let sample = Float(samples[index]) * scale
                sum += sample * sample
            }
            return sqrt(sum / Float(frameLength))
        }

        return 0
    }

    func wordCount(in text: String) -> Int {
        let tokens = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return tokens.count
    }
}
