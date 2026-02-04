//
//  CrutchWordDetector.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

class CrutchWordDetector {
    private let crutchWords: Set<String> = [
        "uh", "um", "ah", "er", "hmm",
        "so", "like", "you know", "well",
        "actually", "basically", "literally"
    ]
    
    private var wordCount: Int = 0
    
    func analyze(_ text: String) -> Int {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let crutchCount = words.filter { crutchWords.contains($0) }.count
        wordCount += words.count
        
        return crutchCount
    }
    
    func reset() {
        wordCount = 0
    }
}
