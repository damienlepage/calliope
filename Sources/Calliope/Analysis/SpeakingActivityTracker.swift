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
        let rms = rmsAmplitude(in: buffer)
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
}
