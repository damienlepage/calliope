//
//  SpeakingActivityTracker.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Foundation

final class SpeakingActivityTracker {
    private let speechThreshold: Float
    private var isSpeaking: Bool = false
    private var speakingTimeSeconds: TimeInterval = 0
    private var speakingTurnCount: Int = 0

    init(speechThreshold: Float = Constants.speechAmplitudeThreshold) {
        self.speechThreshold = speechThreshold
    }

    func process(_ buffer: AVAudioPCMBuffer) {
        let rms = buffer.rmsAmplitude()
        let isSpeech = rms >= speechThreshold
        let duration = bufferDuration(for: buffer)
        if isSpeech {
            speakingTimeSeconds += duration
            if !isSpeaking {
                speakingTurnCount += 1
            }
        }
        isSpeaking = isSpeech
    }

    func reset() {
        isSpeaking = false
        speakingTimeSeconds = 0
        speakingTurnCount = 0
    }

    func summary() -> AnalysisSummary.SpeakingStats {
        AnalysisSummary.SpeakingStats(timeSeconds: speakingTimeSeconds, turnCount: speakingTurnCount)
    }

    private func bufferDuration(for buffer: AVAudioPCMBuffer) -> TimeInterval {
        let frameLength = Double(buffer.frameLength)
        let sampleRate = buffer.format.sampleRate
        guard frameLength > 0, sampleRate > 0 else { return 0 }
        return frameLength / sampleRate
    }

    private func rmsAmplitude(in buffer: AVAudioPCMBuffer) -> Float {
        buffer.rmsAmplitude()
    }
}
