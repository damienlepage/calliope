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
        _ = buffer
    }
}
