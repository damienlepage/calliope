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
    let description: String
    let words: [String]

    var id: String { name }
}

struct AnalysisPreferences: Equatable, Codable {
    var paceMin: Double
    var paceMax: Double
    var pauseThreshold: TimeInterval
    var crutchWords: [String]
    var speakingTimeTargetPercent: Double

    static let `default` = AnalysisPreferences(
        paceMin: Constants.targetPaceMin,
        paceMax: Constants.targetPaceMax,
        pauseThreshold: Constants.pauseThreshold,
        crutchWords: Constants.crutchWords,
        speakingTimeTargetPercent: Constants.speakingTimeTargetPercent
    )

    enum CodingKeys: String, CodingKey {
        case paceMin
        case paceMax
        case pauseThreshold
        case crutchWords
        case speakingTimeTargetPercent
    }

    init(
        paceMin: Double,
        paceMax: Double,
        pauseThreshold: TimeInterval,
        crutchWords: [String],
        speakingTimeTargetPercent: Double
    ) {
        self.paceMin = paceMin
        self.paceMax = paceMax
        self.pauseThreshold = pauseThreshold
        self.crutchWords = crutchWords
        self.speakingTimeTargetPercent = speakingTimeTargetPercent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        paceMin = try container.decode(Double.self, forKey: .paceMin)
        paceMax = try container.decode(Double.self, forKey: .paceMax)
        pauseThreshold = try container.decode(TimeInterval.self, forKey: .pauseThreshold)
        crutchWords = try container.decode([String].self, forKey: .crutchWords)
        speakingTimeTargetPercent = try container.decodeIfPresent(
            Double.self,
            forKey: .speakingTimeTargetPercent
        ) ?? Constants.speakingTimeTargetPercent
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paceMin, forKey: .paceMin)
        try container.encode(paceMax, forKey: .paceMax)
        try container.encode(pauseThreshold, forKey: .pauseThreshold)
        try container.encode(crutchWords, forKey: .crutchWords)
        try container.encode(speakingTimeTargetPercent, forKey: .speakingTimeTargetPercent)
    }
}

final class AnalysisPreferencesStore: ObservableObject {
    static let crutchWordPresets: [CrutchWordPreset] = {
        let defaultPreset = CrutchWordPreset(
            name: "Default",
            description: "A balanced list of common filler words for everyday calls.",
            words: normalizeCrutchWords(Constants.crutchWords)
        )
        let focusedPreset = CrutchWordPreset(
            name: "Focused",
            description: "A short core set for tighter, more disciplined feedback.",
            words: normalizeCrutchWords(["uh", "um", "ah", "er", "hmm"])
        )
        let extendedPreset = CrutchWordPreset(
            name: "Extended",
            description: "A broader list that includes softer phrases like \"kind of\" and \"i mean\".",
            words: normalizeCrutchWords(Constants.crutchWords + ["kind of", "sort of", "i mean", "right", "okay"])
        )
        return [defaultPreset, focusedPreset, extendedPreset]
    }()

    @Published var paceMin: Double
    @Published var paceMax: Double
    @Published var pauseThreshold: TimeInterval
    @Published var crutchWords: [String]
    @Published var speakingTimeTargetPercent: Double

    private let defaults: UserDefaults
    private let paceMinKey = "analysisPreferences.paceMin"
    private let paceMaxKey = "analysisPreferences.paceMax"
    private let pauseThresholdKey = "analysisPreferences.pauseThreshold"
    private let crutchWordsKey = "analysisPreferences.crutchWords"
    private let speakingTimeTargetKey = "analysisPreferences.speakingTimeTargetPercent"
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let defaultsPreferences = AnalysisPreferences.default
        let storedPaceMin = defaults.object(forKey: paceMinKey) as? Double ?? defaultsPreferences.paceMin
        let storedPaceMax = defaults.object(forKey: paceMaxKey) as? Double ?? defaultsPreferences.paceMax
        let storedPauseThreshold = defaults.object(forKey: pauseThresholdKey) as? Double ?? defaultsPreferences.pauseThreshold
        let storedCrutchWords = defaults.array(forKey: crutchWordsKey) as? [String] ?? defaultsPreferences.crutchWords
        let storedSpeakingTimeTarget = defaults.object(forKey: speakingTimeTargetKey) as? Double
            ?? defaultsPreferences.speakingTimeTargetPercent

        let normalized = Self.normalize(
            paceMin: storedPaceMin,
            paceMax: storedPaceMax,
            pauseThreshold: storedPauseThreshold,
            crutchWords: storedCrutchWords,
            speakingTimeTargetPercent: storedSpeakingTimeTarget
        )

        paceMin = normalized.paceMin
        paceMax = normalized.paceMax
        pauseThreshold = normalized.pauseThreshold
        crutchWords = normalized.crutchWords
        speakingTimeTargetPercent = normalized.speakingTimeTargetPercent

        let shouldPersist = normalized.paceMin != storedPaceMin
            || normalized.paceMax != storedPaceMax
            || normalized.pauseThreshold != storedPauseThreshold
            || normalized.crutchWords != storedCrutchWords
            || normalized.speakingTimeTargetPercent != storedSpeakingTimeTarget
        if shouldPersist {
            persist(
                paceMin: normalized.paceMin,
                paceMax: normalized.paceMax,
                pauseThreshold: normalized.pauseThreshold,
                crutchWords: normalized.crutchWords,
                speakingTimeTargetPercent: normalized.speakingTimeTargetPercent
            )
        }

        Publishers.CombineLatest4(
            $paceMin,
            $paceMax,
            $pauseThreshold,
            $crutchWords
        )
        .combineLatest($speakingTimeTargetPercent)
            .dropFirst()
            .sink { [weak self] combined, speakingTimeTargetPercent in
                guard let self = self else { return }
                let (paceMin, paceMax, pauseThreshold, crutchWords) = combined
                let normalized = Self.normalize(
                    paceMin: paceMin,
                    paceMax: paceMax,
                    pauseThreshold: pauseThreshold,
                    crutchWords: crutchWords,
                    speakingTimeTargetPercent: speakingTimeTargetPercent
                )
                if normalized.paceMin != paceMin
                    || normalized.paceMax != paceMax
                    || normalized.pauseThreshold != pauseThreshold
                    || normalized.crutchWords != crutchWords
                    || normalized.speakingTimeTargetPercent != speakingTimeTargetPercent {
                    self.paceMin = normalized.paceMin
                    self.paceMax = normalized.paceMax
                    self.pauseThreshold = normalized.pauseThreshold
                    self.crutchWords = normalized.crutchWords
                    self.speakingTimeTargetPercent = normalized.speakingTimeTargetPercent
                    return
                }
                self.persist(
                    paceMin: normalized.paceMin,
                    paceMax: normalized.paceMax,
                    pauseThreshold: normalized.pauseThreshold,
                    crutchWords: normalized.crutchWords,
                    speakingTimeTargetPercent: normalized.speakingTimeTargetPercent
                )
            }
            .store(in: &cancellables)
    }

    var current: AnalysisPreferences {
        AnalysisPreferences(
            paceMin: paceMin,
            paceMax: paceMax,
            pauseThreshold: pauseThreshold,
            crutchWords: crutchWords,
            speakingTimeTargetPercent: speakingTimeTargetPercent
        )
    }

    var preferencesPublisher: AnyPublisher<AnalysisPreferences, Never> {
        Publishers.CombineLatest4(
            $paceMin,
            $paceMax,
            $pauseThreshold,
            $crutchWords
        )
            .combineLatest($speakingTimeTargetPercent)
            .map { combined, speakingTimeTargetPercent in
                let (paceMin, paceMax, pauseThreshold, crutchWords) = combined
                return AnalysisPreferences(
                    paceMin: paceMin,
                    paceMax: paceMax,
                    pauseThreshold: pauseThreshold,
                    crutchWords: crutchWords,
                    speakingTimeTargetPercent: speakingTimeTargetPercent
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
        speakingTimeTargetPercent = defaultsPreferences.speakingTimeTargetPercent
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

    static func crutchWordPresetDescription(for words: [String]) -> String? {
        matchingCrutchWordPreset(for: words)?.description
    }

    private static func normalize(
        paceMin: Double,
        paceMax: Double,
        pauseThreshold: TimeInterval,
        crutchWords: [String],
        speakingTimeTargetPercent: Double
    ) -> AnalysisPreferences {
        var normalizedMin = paceMin
        var normalizedMax = paceMax
        if normalizedMin > normalizedMax {
            swap(&normalizedMin, &normalizedMax)
        }

        let normalizedPauseThreshold = pauseThreshold > 0 ? pauseThreshold : Constants.pauseThreshold

        let normalizedCrutchWords = normalizeCrutchWords(crutchWords)
        let normalizedSpeakingTimeTarget = normalizeSpeakingTimeTarget(speakingTimeTargetPercent)

        return AnalysisPreferences(
            paceMin: normalizedMin,
            paceMax: normalizedMax,
            pauseThreshold: normalizedPauseThreshold,
            crutchWords: normalizedCrutchWords,
            speakingTimeTargetPercent: normalizedSpeakingTimeTarget
        )
    }

    private func persist(
        paceMin: Double,
        paceMax: Double,
        pauseThreshold: TimeInterval,
        crutchWords: [String],
        speakingTimeTargetPercent: Double
    ) {
        defaults.set(paceMin, forKey: paceMinKey)
        defaults.set(paceMax, forKey: paceMaxKey)
        defaults.set(pauseThreshold, forKey: pauseThresholdKey)
        defaults.set(crutchWords, forKey: crutchWordsKey)
        defaults.set(speakingTimeTargetPercent, forKey: speakingTimeTargetKey)
    }

    static func normalizeSpeakingTimeTarget(_ target: Double) -> Double {
        guard target.isFinite else {
            return Constants.speakingTimeTargetPercent
        }
        let minTarget = Constants.speakingTimeTargetMinPercent
        let maxTarget = Constants.speakingTimeTargetMaxPercent
        if target < minTarget || target > maxTarget {
            return Constants.speakingTimeTargetPercent
        }
        return target
    }
}
