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
        let rms = audioBuffer.rmsAmplitude()
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
        buffer.rmsAmplitude()
    }
}
