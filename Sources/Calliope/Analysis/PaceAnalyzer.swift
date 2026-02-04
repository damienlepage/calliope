//
//  PaceAnalyzer.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

class PaceAnalyzer {
    private var wordCount: Int = 0
    private var startTime: Date?
    private let targetPace: Double = 150.0 // words per minute
    
    func start() {
        startTime = Date()
        wordCount = 0
    }
    
    func updateWordCount(_ count: Int) {
        wordCount = count
    }
    
    func calculatePace() -> Double {
        guard let startTime = startTime else { return 0.0 }
        let elapsedMinutes = Date().timeIntervalSince(startTime) / 60.0
        guard elapsedMinutes > 0 else { return 0.0 }
        return Double(wordCount) / elapsedMinutes
    }
    
    func reset() {
        startTime = nil
        wordCount = 0
    }
}
