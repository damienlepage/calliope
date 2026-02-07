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
    private var pauseThreshold: TimeInterval
    private var isSpeaking: Bool = false
    private var speakingTimeSeconds: TimeInterval = 0
    private var speakingTurnCount: Int = 0
    private var silenceDurationSinceSpeech: TimeInterval?

    init(
        speechThreshold: Float = Constants.speechAmplitudeThreshold,
        pauseThreshold: TimeInterval = Constants.pauseThreshold
    ) {
        self.speechThreshold = speechThreshold
        self.pauseThreshold = max(0, pauseThreshold)
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
            isSpeaking = true
            silenceDurationSinceSpeech = 0
            return
        }

        guard isSpeaking else { return }
        let accumulatedSilence = (silenceDurationSinceSpeech ?? 0) + duration
        if accumulatedSilence <= pauseThreshold {
            speakingTimeSeconds += duration
            silenceDurationSinceSpeech = accumulatedSilence
            return
        }

        let remaining = pauseThreshold - (silenceDurationSinceSpeech ?? 0)
        if remaining > 0 {
            speakingTimeSeconds += remaining
        }
        isSpeaking = false
        silenceDurationSinceSpeech = nil
    }

    func reset() {
        isSpeaking = false
        speakingTimeSeconds = 0
        speakingTurnCount = 0
        silenceDurationSinceSpeech = nil
    }

    func updatePauseThreshold(_ pauseThreshold: TimeInterval) {
        self.pauseThreshold = max(0, pauseThreshold)
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
