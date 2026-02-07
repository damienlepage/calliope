//
//  PerAppFeedbackProfileStore.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import Foundation

/// A lightweight per-app feedback profile keyed by the conferencing app bundle identifier.
/// Stores pace targets, pause threshold, and crutch words for that app.
struct PerAppFeedbackProfile: Codable, Equatable, Identifiable {
    let appIdentifier: String
    var paceMin: Double
    var paceMax: Double
    var pauseThreshold: TimeInterval
    var crutchWords: [String]
    var speakingTimeTargetPercent: Double

    var id: String { appIdentifier }

    static func `default`(for appIdentifier: String) -> PerAppFeedbackProfile {
        PerAppFeedbackProfile(
            appIdentifier: appIdentifier,
            paceMin: Constants.targetPaceMin,
            paceMax: Constants.targetPaceMax,
            pauseThreshold: Constants.pauseThreshold,
            crutchWords: Constants.crutchWords,
            speakingTimeTargetPercent: Constants.speakingTimeTargetPercent
        )
    }

    enum CodingKeys: String, CodingKey {
        case appIdentifier
        case paceMin
        case paceMax
        case pauseThreshold
        case crutchWords
        case speakingTimeTargetPercent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appIdentifier = try container.decode(String.self, forKey: .appIdentifier)
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
        try container.encode(appIdentifier, forKey: .appIdentifier)
        try container.encode(paceMin, forKey: .paceMin)
        try container.encode(paceMax, forKey: .paceMax)
        try container.encode(pauseThreshold, forKey: .pauseThreshold)
        try container.encode(crutchWords, forKey: .crutchWords)
        try container.encode(speakingTimeTargetPercent, forKey: .speakingTimeTargetPercent)
    }
}

final class PerAppFeedbackProfileStore: ObservableObject {
    @Published private(set) var profiles: [PerAppFeedbackProfile]

    private let defaults: UserDefaults
    private let profilesKey = "perAppFeedbackProfiles"
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let loadedProfiles = Self.loadProfiles(from: defaults, key: profilesKey)
        let normalizedProfiles = loadedProfiles
            .map(Self.normalize)
            .filter { !$0.appIdentifier.isEmpty }
        profiles = normalizedProfiles
        if loadedProfiles != normalizedProfiles {
            persist(normalizedProfiles)
        }

        $profiles
            .dropFirst()
            .sink { [weak self] profiles in
                self?.persist(profiles)
            }
            .store(in: &cancellables)
    }

    func profile(for appIdentifier: String) -> PerAppFeedbackProfile? {
        let normalizedIdentifier = Self.normalizeAppIdentifier(appIdentifier)
        return profiles.first { $0.appIdentifier == normalizedIdentifier }
    }

    func setProfile(_ profile: PerAppFeedbackProfile) {
        let normalized = Self.normalize(profile)
        guard !normalized.appIdentifier.isEmpty else {
            return
        }
        if let index = profiles.firstIndex(where: { $0.appIdentifier == normalized.appIdentifier }) {
            profiles[index] = normalized
        } else {
            profiles.append(normalized)
        }
    }

    @discardableResult
    func addProfile(appIdentifier: String) -> PerAppFeedbackProfile? {
        let normalizedIdentifier = Self.normalizeAppIdentifier(appIdentifier)
        guard !normalizedIdentifier.isEmpty else {
            return nil
        }
        let profile = PerAppFeedbackProfile.default(for: normalizedIdentifier)
        setProfile(profile)
        return profile
    }

    func removeProfile(appIdentifier: String) {
        let normalizedIdentifier = Self.normalizeAppIdentifier(appIdentifier)
        profiles.removeAll { $0.appIdentifier == normalizedIdentifier }
    }

    private static func loadProfiles(from defaults: UserDefaults, key: String) -> [PerAppFeedbackProfile] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }
        do {
            return try JSONDecoder().decode([PerAppFeedbackProfile].self, from: data)
        } catch {
            return []
        }
    }

    private static func normalize(_ profile: PerAppFeedbackProfile) -> PerAppFeedbackProfile {
        let appIdentifier = normalizeAppIdentifier(profile.appIdentifier)
        var paceMin = profile.paceMin
        var paceMax = profile.paceMax
        if paceMin > paceMax {
            swap(&paceMin, &paceMax)
        }

        let pauseThreshold = profile.pauseThreshold > 0
            ? profile.pauseThreshold
            : Constants.pauseThreshold

        var seen = Set<String>()
        let normalizedCrutchWords = profile.crutchWords
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .filter { word in
                if seen.contains(word) {
                    return false
                }
                seen.insert(word)
                return true
            }

        let normalizedSpeakingTarget = AnalysisPreferencesStore.normalizeSpeakingTimeTarget(
            profile.speakingTimeTargetPercent
        )

        return PerAppFeedbackProfile(
            appIdentifier: appIdentifier,
            paceMin: paceMin,
            paceMax: paceMax,
            pauseThreshold: pauseThreshold,
            crutchWords: normalizedCrutchWords,
            speakingTimeTargetPercent: normalizedSpeakingTarget
        )
    }

    static func normalizeAppIdentifier(_ appIdentifier: String) -> String {
        appIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    static func normalizeAppIdentifier(_ appIdentifier: String?) -> String? {
        guard let appIdentifier else {
            return nil
        }
        let normalized = normalizeAppIdentifier(appIdentifier)
        return normalized.isEmpty ? nil : normalized
    }

    private func persist(_ profiles: [PerAppFeedbackProfile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            defaults.set(data, forKey: profilesKey)
        } catch {
            defaults.removeObject(forKey: profilesKey)
        }
    }
}
