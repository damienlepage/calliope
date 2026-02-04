//
//  CrutchWordDetector.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

class CrutchWordDetector {
    private let singleWordCrutches: Set<String> = [
        "uh", "um", "ah", "er", "hmm",
        "so", "like", "well",
        "actually", "basically", "literally"
    ]
    private let multiWordCrutches: [[String]] = [
        ["you", "know"]
    ]

    private var wordCount: Int = 0
    
    func analyze(_ text: String) -> Int {
        let tokens = tokenize(text)
        wordCount += tokens.count

        var count = 0
        var index = 0
        while index < tokens.count {
            if let phraseLength = matchPhrase(tokens, at: index) {
                count += 1
                index += phraseLength
                continue
            }

            if singleWordCrutches.contains(tokens[index]) {
                count += 1
            }
            index += 1
        }

        return count
    }
    
    func reset() {
        wordCount = 0
    }

    private func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func matchPhrase(_ tokens: [String], at index: Int) -> Int? {
        for phrase in multiWordCrutches {
            guard index + phrase.count <= tokens.count else { continue }
            let slice = tokens[index..<(index + phrase.count)]
            if Array(slice) == phrase {
                return phrase.count
            }
        }
        return nil
    }
}
