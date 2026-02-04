//
//  Constants.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum Constants {
    // Audio settings
    static let sampleRate: Double = 44100.0
    static let bufferSize: Int = 1024
    
    // Analysis thresholds
    static let targetPaceMin: Double = 120.0 // words per minute
    static let targetPaceMax: Double = 180.0 // words per minute
    static let pauseThreshold: TimeInterval = 1.0 // seconds
    static let speechAmplitudeThreshold: Float = 0.02 // RMS amplitude threshold for speech
    
    // Crutch words
    static let crutchWords: [String] = [
        "uh", "um", "ah", "er", "hmm",
        "so", "like", "you know", "well",
        "actually", "basically", "literally"
    ]
}
