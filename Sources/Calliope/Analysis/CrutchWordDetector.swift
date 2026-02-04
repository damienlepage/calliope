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
        let tokens = tokenize(text)

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
        return
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
