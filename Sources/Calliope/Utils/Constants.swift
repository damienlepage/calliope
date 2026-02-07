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

    // Performance guardrails
    static let processingLatencyWindowSize: Int = 30
    static let processingLatencyHighThreshold: TimeInterval = 0.03 // seconds
    static let processingLatencyCriticalThreshold: TimeInterval = 0.06 // seconds
    static let processingUtilizationWindowSize: Int = 30
    static let processingUtilizationHighThreshold: Double = 0.75
    static let processingUtilizationCriticalThreshold: Double = 1.0

    // Long-session guardrails
    static let analysisCheckpointInterval: TimeInterval = 300 // seconds
    static let maxRecordingSegmentDuration: TimeInterval = 2 * 60 * 60 // seconds

    // Live captions
    static let captionMaxCharacters: Int = 240
    
    // Crutch words
    static let crutchWords: [String] = [
        "uh", "um", "ah", "er", "hmm",
        "so", "like", "you know", "well",
        "actually", "basically", "literally"
    ]
}
