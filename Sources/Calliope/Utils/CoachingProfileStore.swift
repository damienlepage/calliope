//
//  CoachingProfileStore.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import Foundation

struct CoachingProfile: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var preferences: AnalysisPreferences

    static func `default`(name: String = "Default") -> CoachingProfile {
        CoachingProfile(
            id: UUID(),
            name: name,
            preferences: AnalysisPreferences.default
        )
    }
}

final class CoachingProfileStore: ObservableObject {
    @Published private(set) var profiles: [CoachingProfile]
    @Published var selectedProfileID: UUID?

    private let defaults: UserDefaults
    private let profilesKey = "coachingProfiles"
    private let selectedKey = "coachingProfiles.selectedId"
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let loadedProfiles = Self.loadProfiles(from: defaults, key: profilesKey)
        let normalizedProfiles = loadedProfiles.compactMap(Self.normalize)
        if normalizedProfiles.isEmpty {
            profiles = Self.defaultProfiles()
        } else {
            profiles = normalizedProfiles
        }

        let storedSelectedID = defaults.string(forKey: selectedKey).flatMap(UUID.init)
        let resolvedSelectedID = Self.resolveSelectedID(
            storedSelectedID,
            profiles: profiles
        )
        selectedProfileID = resolvedSelectedID

        if profiles != loadedProfiles {
            persistProfiles(profiles)
        }
        if storedSelectedID != resolvedSelectedID {
            persistSelectedID(resolvedSelectedID)
        }

        $profiles
            .dropFirst()
            .sink { [weak self] profiles in
                guard let self = self else { return }
                self.persistProfiles(profiles)
                let resolved = Self.resolveSelectedID(self.selectedProfileID, profiles: profiles)
                if resolved != self.selectedProfileID {
                    self.selectedProfileID = resolved
                }
            }
            .store(in: &cancellables)

        $selectedProfileID
            .dropFirst()
            .sink { [weak self] selectedID in
                guard let self = self else { return }
                let resolved = Self.resolveSelectedID(selectedID, profiles: self.profiles)
                if resolved != selectedID {
                    self.selectedProfileID = resolved
                    return
                }
                self.persistSelectedID(resolved)
            }
            .store(in: &cancellables)
    }

    var selectedProfile: CoachingProfile? {
        guard let selectedProfileID else {
            return nil
        }
        return profiles.first { $0.id == selectedProfileID }
    }

    @discardableResult
    func addProfile(name: String, preferences: AnalysisPreferences = .default) -> CoachingProfile? {
        let profile = CoachingProfile(id: UUID(), name: name, preferences: preferences)
        guard let normalized = Self.normalize(profile) else {
            return nil
        }
        profiles.append(normalized)
        return normalized
    }

    func setProfile(_ profile: CoachingProfile) {
        guard let normalized = Self.normalize(profile) else {
            return
        }
        if let index = profiles.firstIndex(where: { $0.id == normalized.id }) {
            profiles[index] = normalized
        } else {
            profiles.append(normalized)
        }
    }

    func removeProfile(id: UUID) {
        profiles.removeAll { $0.id == id }
    }

    func selectProfile(id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else {
            selectedProfileID = profiles.first?.id
            return
        }
        selectedProfileID = id
    }

    private static func loadProfiles(from defaults: UserDefaults, key: String) -> [CoachingProfile] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }
        do {
            return try JSONDecoder().decode([CoachingProfile].self, from: data)
        } catch {
            return []
        }
    }

    private static func normalize(_ profile: CoachingProfile) -> CoachingProfile? {
        let normalizedName = normalizeName(profile.name)
        guard !normalizedName.isEmpty else {
            return nil
        }
        let normalizedPreferences = normalizePreferences(profile.preferences)
        return CoachingProfile(
            id: profile.id,
            name: normalizedName,
            preferences: normalizedPreferences
        )
    }

    private static func normalizeName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func defaultProfiles() -> [CoachingProfile] {
        let defaultProfile = CoachingProfile.default()
        let focused = CoachingProfile(
            id: UUID(),
            name: "Focused",
            preferences: AnalysisPreferences(
                paceMin: 130,
                paceMax: 170,
                pauseThreshold: 0.8,
                crutchWords: Constants.crutchWords,
                speakingTimeTargetPercent: Constants.speakingTimeTargetPercent
            )
        )
        let conversational = CoachingProfile(
            id: UUID(),
            name: "Conversational",
            preferences: AnalysisPreferences(
                paceMin: 110,
                paceMax: 175,
                pauseThreshold: 1.4,
                crutchWords: Constants.crutchWords,
                speakingTimeTargetPercent: Constants.speakingTimeTargetPercent
            )
        )
        return [defaultProfile, focused, conversational].compactMap(Self.normalize)
    }

    private static func normalizePreferences(_ preferences: AnalysisPreferences) -> AnalysisPreferences {
        var paceMin = preferences.paceMin
        var paceMax = preferences.paceMax
        if paceMin > paceMax {
            swap(&paceMin, &paceMax)
        }

        let pauseThreshold = preferences.pauseThreshold > 0
            ? preferences.pauseThreshold
            : Constants.pauseThreshold

        var seen = Set<String>()
        let normalizedCrutchWords = preferences.crutchWords
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
            preferences.speakingTimeTargetPercent
        )

        return AnalysisPreferences(
            paceMin: paceMin,
            paceMax: paceMax,
            pauseThreshold: pauseThreshold,
            crutchWords: normalizedCrutchWords,
            speakingTimeTargetPercent: normalizedSpeakingTarget
        )
    }

    private static func resolveSelectedID(_ selectedID: UUID?, profiles: [CoachingProfile]) -> UUID? {
        guard let selectedID else {
            return profiles.first?.id
        }
        return profiles.contains(where: { $0.id == selectedID })
            ? selectedID
            : profiles.first?.id
    }

    private func persistProfiles(_ profiles: [CoachingProfile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            defaults.set(data, forKey: profilesKey)
        } catch {
            defaults.removeObject(forKey: profilesKey)
        }
    }

    private func persistSelectedID(_ selectedID: UUID?) {
        guard let selectedID else {
            defaults.removeObject(forKey: selectedKey)
            return
        }
        defaults.set(selectedID.uuidString, forKey: selectedKey)
    }
}
