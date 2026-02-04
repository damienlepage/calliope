//
//  PaceAnalyzer.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

class PaceAnalyzer {
    private let now: () -> Date
    private var wordCount: Int = 0
    private var startTime: Date?
    private let targetPace: Double = 150.0 // words per minute

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }
    
    func start() {
        startTime = now()
        wordCount = 0
    }
    
    func updateWordCount(_ count: Int) {
        wordCount = count
    }
    
    func calculatePace() -> Double {
        guard let startTime = startTime else { return 0.0 }
        let elapsedMinutes = now().timeIntervalSince(startTime) / 60.0
        guard elapsedMinutes > 0 else { return 0.0 }
        return Double(wordCount) / elapsedMinutes
    }
    
    func reset() {
        startTime = nil
        wordCount = 0
    }
}
