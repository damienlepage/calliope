//
//  PauseDetector.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation
import AVFoundation

class PauseDetector {
    private let pauseThreshold: TimeInterval = 1.0 // seconds
    private var lastSpeechTime: Date?
    private var pauseCount: Int = 0
    
    func detectPause(in audioBuffer: AVAudioPCMBuffer) -> Bool {
        // Analyze audio buffer for silence
        // This is a simplified version - real implementation would analyze amplitude
        let currentTime = Date()
        
        if let lastTime = lastSpeechTime {
            let timeSinceLastSpeech = currentTime.timeIntervalSince(lastTime)
            if timeSinceLastSpeech > pauseThreshold {
                pauseCount += 1
                lastSpeechTime = currentTime
                return true
            }
        } else {
            lastSpeechTime = currentTime
        }
        
        return false
    }
    
    func getPauseCount() -> Int {
        return pauseCount
    }
    
    func reset() {
        pauseCount = 0
        lastSpeechTime = nil
    }
}
