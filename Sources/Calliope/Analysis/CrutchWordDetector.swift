//
//  CrutchWordDetector.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

class CrutchWordDetector {
    private let singleWordCrutches: Set<String>
    private let multiWordCrutches: [[String]]

    init(crutchWords: [String] = Constants.crutchWords) {
        var singleWordCrutches = Set<String>()
        var multiWordCrutches = [[String]]()

        for crutch in crutchWords {
            let tokens = crutch
                .lowercased()
                .split(separator: " ")
                .map(String.init)
            guard !tokens.isEmpty else { continue }
            if tokens.count == 1, let token = tokens.first {
                singleWordCrutches.insert(token)
            } else {
                multiWordCrutches.append(tokens)
            }
        }

        self.singleWordCrutches = singleWordCrutches
        self.multiWordCrutches = multiWordCrutches
    }
    
    func analyze(_ text: String) -> Int {
        let counts = analyzeCounts(text)
        return counts.values.reduce(0, +)
    }

    func analyzeCounts(_ text: String) -> [String: Int] {
        let tokens = tokenize(text)

        var counts: [String: Int] = [:]
        var index = 0
        while index < tokens.count {
            if let match = matchPhrase(tokens, at: index) {
                counts[match.phrase, default: 0] += 1
                index += match.length
                continue
            }

            let token = tokens[index]
            if singleWordCrutches.contains(token) {
                counts[token, default: 0] += 1
            }
            index += 1
        }

        return counts
    }
    
    func reset() {
        return
    }

    private func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func matchPhrase(_ tokens: [String], at index: Int) -> (phrase: String, length: Int)? {
        for phrase in multiWordCrutches {
            guard index + phrase.count <= tokens.count else { continue }
            let slice = tokens[index..<(index + phrase.count)]
            if Array(slice) == phrase {
                return (phrase.joined(separator: " "), phrase.count)
            }
        }
        return nil
    }
}
