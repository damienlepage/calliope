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

    var id: String { appIdentifier }

    static func `default`(for appIdentifier: String) -> PerAppFeedbackProfile {
        PerAppFeedbackProfile(
            appIdentifier: appIdentifier,
            paceMin: Constants.targetPaceMin,
            paceMax: Constants.targetPaceMax,
            pauseThreshold: Constants.pauseThreshold,
            crutchWords: Constants.crutchWords
        )
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
        let normalizedProfiles = loadedProfiles.map(Self.normalize)
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
        profiles.first { $0.appIdentifier == appIdentifier }
    }

    func setProfile(_ profile: PerAppFeedbackProfile) {
        let normalized = Self.normalize(profile)
        if let index = profiles.firstIndex(where: { $0.appIdentifier == normalized.appIdentifier }) {
            profiles[index] = normalized
        } else {
            profiles.append(normalized)
        }
    }

    func removeProfile(appIdentifier: String) {
        profiles.removeAll { $0.appIdentifier == appIdentifier }
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

        return PerAppFeedbackProfile(
            appIdentifier: profile.appIdentifier,
            paceMin: paceMin,
            paceMax: paceMax,
            pauseThreshold: pauseThreshold,
            crutchWords: normalizedCrutchWords
        )
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
