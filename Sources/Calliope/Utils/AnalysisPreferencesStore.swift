//
//  AnalysisPreferencesStore.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import Foundation

struct CrutchWordPreset: Identifiable, Equatable {
    let name: String
    let words: [String]

    var id: String { name }
}

struct AnalysisPreferences: Equatable, Codable {
    var paceMin: Double
    var paceMax: Double
    var pauseThreshold: TimeInterval
    var crutchWords: [String]

    static let `default` = AnalysisPreferences(
        paceMin: Constants.targetPaceMin,
        paceMax: Constants.targetPaceMax,
        pauseThreshold: Constants.pauseThreshold,
        crutchWords: Constants.crutchWords
    )
}

final class AnalysisPreferencesStore: ObservableObject {
    static let crutchWordPresets: [CrutchWordPreset] = {
        let defaultPreset = CrutchWordPreset(
            name: "Default",
            words: normalizeCrutchWords(Constants.crutchWords)
        )
        let focusedPreset = CrutchWordPreset(
            name: "Focused",
            words: normalizeCrutchWords(["uh", "um", "ah", "er", "hmm"])
        )
        let extendedPreset = CrutchWordPreset(
            name: "Extended",
            words: normalizeCrutchWords(Constants.crutchWords + ["kind of", "sort of", "i mean", "right", "okay"])
        )
        return [defaultPreset, focusedPreset, extendedPreset]
    }()

    @Published var paceMin: Double
    @Published var paceMax: Double
    @Published var pauseThreshold: TimeInterval
    @Published var crutchWords: [String]

    private let defaults: UserDefaults
    private let paceMinKey = "analysisPreferences.paceMin"
    private let paceMaxKey = "analysisPreferences.paceMax"
    private let pauseThresholdKey = "analysisPreferences.pauseThreshold"
    private let crutchWordsKey = "analysisPreferences.crutchWords"
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let defaultsPreferences = AnalysisPreferences.default
        let storedPaceMin = defaults.object(forKey: paceMinKey) as? Double ?? defaultsPreferences.paceMin
        let storedPaceMax = defaults.object(forKey: paceMaxKey) as? Double ?? defaultsPreferences.paceMax
        let storedPauseThreshold = defaults.object(forKey: pauseThresholdKey) as? Double ?? defaultsPreferences.pauseThreshold
        let storedCrutchWords = defaults.array(forKey: crutchWordsKey) as? [String] ?? defaultsPreferences.crutchWords

        let normalized = Self.normalize(
            paceMin: storedPaceMin,
            paceMax: storedPaceMax,
            pauseThreshold: storedPauseThreshold,
            crutchWords: storedCrutchWords
        )

        paceMin = normalized.paceMin
        paceMax = normalized.paceMax
        pauseThreshold = normalized.pauseThreshold
        crutchWords = normalized.crutchWords

        if normalized.paceMin != storedPaceMin
            || normalized.paceMax != storedPaceMax
            || normalized.pauseThreshold != storedPauseThreshold
            || normalized.crutchWords != storedCrutchWords {
            persist(
                paceMin: normalized.paceMin,
                paceMax: normalized.paceMax,
                pauseThreshold: normalized.pauseThreshold,
                crutchWords: normalized.crutchWords
            )
        }

        Publishers.CombineLatest4($paceMin, $paceMax, $pauseThreshold, $crutchWords)
            .dropFirst()
            .sink { [weak self] paceMin, paceMax, pauseThreshold, crutchWords in
                guard let self = self else { return }
                let normalized = Self.normalize(
                    paceMin: paceMin,
                    paceMax: paceMax,
                    pauseThreshold: pauseThreshold,
                    crutchWords: crutchWords
                )
                if normalized.paceMin != paceMin
                    || normalized.paceMax != paceMax
                    || normalized.pauseThreshold != pauseThreshold
                    || normalized.crutchWords != crutchWords {
                    self.paceMin = normalized.paceMin
                    self.paceMax = normalized.paceMax
                    self.pauseThreshold = normalized.pauseThreshold
                    self.crutchWords = normalized.crutchWords
                    return
                }
                self.persist(
                    paceMin: normalized.paceMin,
                    paceMax: normalized.paceMax,
                    pauseThreshold: normalized.pauseThreshold,
                    crutchWords: normalized.crutchWords
                )
            }
            .store(in: &cancellables)
    }

    var current: AnalysisPreferences {
        AnalysisPreferences(
            paceMin: paceMin,
            paceMax: paceMax,
            pauseThreshold: pauseThreshold,
            crutchWords: crutchWords
        )
    }

    var preferencesPublisher: AnyPublisher<AnalysisPreferences, Never> {
        Publishers.CombineLatest4($paceMin, $paceMax, $pauseThreshold, $crutchWords)
            .map { paceMin, paceMax, pauseThreshold, crutchWords in
                AnalysisPreferences(
                    paceMin: paceMin,
                    paceMax: paceMax,
                    pauseThreshold: pauseThreshold,
                    crutchWords: crutchWords
                )
            }
            .eraseToAnyPublisher()
    }

    func resetToDefaults() {
        let defaultsPreferences = AnalysisPreferences.default
        paceMin = defaultsPreferences.paceMin
        paceMax = defaultsPreferences.paceMax
        pauseThreshold = defaultsPreferences.pauseThreshold
        crutchWords = defaultsPreferences.crutchWords
    }

    func applyCrutchWordPreset(_ preset: CrutchWordPreset) {
        crutchWords = preset.words
    }

    static func parseCrutchWords(from text: String) -> [String] {
        var seen = Set<String>()
        return text.split(whereSeparator: { $0 == "," || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .filter { word in
                if seen.contains(word) {
                    return false
                }
                seen.insert(word)
                return true
            }
    }

    static func formatCrutchWords(_ words: [String]) -> String {
        words.joined(separator: ", ")
    }

    static func normalizeCrutchWords(_ words: [String]) -> [String] {
        var seen = Set<String>()
        return words
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .filter { word in
                if seen.contains(word) {
                    return false
                }
                seen.insert(word)
                return true
            }
    }

    static func matchingCrutchWordPreset(for words: [String]) -> CrutchWordPreset? {
        let normalized = normalizeCrutchWords(words).sorted()
        return crutchWordPresets.first { preset in
            preset.words.sorted() == normalized
        }
    }

    static func crutchWordPresetLabel(for words: [String]) -> String {
        matchingCrutchWordPreset(for: words)?.name ?? "Custom list"
    }

    private static func normalize(
        paceMin: Double,
        paceMax: Double,
        pauseThreshold: TimeInterval,
        crutchWords: [String]
    ) -> AnalysisPreferences {
        var normalizedMin = paceMin
        var normalizedMax = paceMax
        if normalizedMin > normalizedMax {
            swap(&normalizedMin, &normalizedMax)
        }

        let normalizedPauseThreshold = pauseThreshold > 0 ? pauseThreshold : Constants.pauseThreshold

        let normalizedCrutchWords = normalizeCrutchWords(crutchWords)

        return AnalysisPreferences(
            paceMin: normalizedMin,
            paceMax: normalizedMax,
            pauseThreshold: normalizedPauseThreshold,
            crutchWords: normalizedCrutchWords
        )
    }

    private func persist(
        paceMin: Double,
        paceMax: Double,
        pauseThreshold: TimeInterval,
        crutchWords: [String]
    ) {
        defaults.set(paceMin, forKey: paceMinKey)
        defaults.set(paceMax, forKey: paceMaxKey)
        defaults.set(pauseThreshold, forKey: pauseThresholdKey)
        defaults.set(crutchWords, forKey: crutchWordsKey)
    }
}
