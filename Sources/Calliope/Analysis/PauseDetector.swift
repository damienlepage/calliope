//
//  PauseDetector.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation
import AVFoundation

class PauseDetector {
    private(set) var pauseThreshold: TimeInterval
    private let speechThreshold: Float
    private let now: () -> Date
    private var lastSpeechTime: Date?
    private var pauseStartTime: Date?
    private var pauseCount: Int = 0
    private var totalPauseDuration: TimeInterval = 0
    private var isInPause: Bool = false
    
    init(
        pauseThreshold: TimeInterval = Constants.pauseThreshold,
        speechThreshold: Float = Constants.speechAmplitudeThreshold,
        now: @escaping () -> Date = Date.init
    ) {
        self.pauseThreshold = pauseThreshold
        self.speechThreshold = speechThreshold
        self.now = now
    }

    func detectPause(in audioBuffer: AVAudioPCMBuffer) -> Bool {
        let currentTime = now()
        let rms = rmsAmplitude(in: audioBuffer)
        let isSpeech = rms >= speechThreshold

        if isSpeech {
            if isInPause, let pauseStartTime {
                totalPauseDuration += currentTime.timeIntervalSince(pauseStartTime)
                self.pauseStartTime = nil
            }
            lastSpeechTime = currentTime
            if isInPause {
                isInPause = false
            }
            return false
        }

        guard let lastSpeechTime else { return false }
        let timeSinceLastSpeech = currentTime.timeIntervalSince(lastSpeechTime)
        if !isInPause && timeSinceLastSpeech >= pauseThreshold {
            pauseCount += 1
            isInPause = true
            pauseStartTime = lastSpeechTime
            return true
        }

        return false
    }
    
    func getPauseCount() -> Int {
        return pauseCount
    }

    func averagePauseDuration(currentTime: Date? = nil) -> TimeInterval {
        guard pauseCount > 0 else { return 0 }
        let timestamp = currentTime ?? now()
        var total = totalPauseDuration
        if isInPause, let pauseStartTime {
            total += timestamp.timeIntervalSince(pauseStartTime)
        }
        return total / Double(pauseCount)
    }
    
    func reset() {
        pauseCount = 0
        lastSpeechTime = nil
        pauseStartTime = nil
        totalPauseDuration = 0
        isInPause = false
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
