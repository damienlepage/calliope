//
//  ActiveAnalysisPreferencesStore.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import Foundation

protocol AnalysisPreferencesProviding: AnyObject {
    var current: AnalysisPreferences { get }
    var preferencesPublisher: AnyPublisher<AnalysisPreferences, Never> { get }
}

extension AnalysisPreferencesStore: AnalysisPreferencesProviding {}

final class ActiveAnalysisPreferencesStore: ObservableObject, AnalysisPreferencesProviding {
    @Published private(set) var activePreferences: AnalysisPreferences
    @Published private(set) var activeAppIdentifier: String?
    @Published private(set) var activeProfile: PerAppFeedbackProfile?

    private let basePreferencesStore: AnalysisPreferencesStore
    private let coachingProfileStore: CoachingProfileStore
    private let perAppProfileStore: PerAppFeedbackProfileStore
    private var cancellables = Set<AnyCancellable>()

    init(
        basePreferencesStore: AnalysisPreferencesStore,
        coachingProfileStore: CoachingProfileStore,
        perAppProfileStore: PerAppFeedbackProfileStore,
        frontmostAppPublisher: AnyPublisher<String?, Never>,
        recordingPublisher: AnyPublisher<Bool, Never>
    ) {
        self.basePreferencesStore = basePreferencesStore
        self.coachingProfileStore = coachingProfileStore
        self.perAppProfileStore = perAppProfileStore
        activePreferences = basePreferencesStore.current
        activeAppIdentifier = nil
        activeProfile = nil

        let normalizedFrontmostPublisher = frontmostAppPublisher
            .map { PerAppFeedbackProfileStore.normalizeAppIdentifier($0) }
            .removeDuplicates()

        let coachingProfilePublisher = Publishers.CombineLatest(
            coachingProfileStore.$profiles,
            coachingProfileStore.$selectedProfileID
        )
        .map { profiles, selectedID in
            profiles.first { $0.id == selectedID } ?? profiles.first
        }
        .removeDuplicates()

        Publishers.CombineLatest(
            Publishers.CombineLatest4(
                basePreferencesStore.preferencesPublisher,
                coachingProfilePublisher,
                perAppProfileStore.$profiles,
                normalizedFrontmostPublisher
            ),
            recordingPublisher
        )
        .map { combined, isRecording in
            let (basePreferences, coachingProfile, profiles, frontmostApp) = combined
            let resolvedBase = isRecording ? coachingProfile?.preferences ?? basePreferences : basePreferences
            let resolvedAppIdentifier = isRecording ? frontmostApp : nil
            let resolvedProfile = resolvedAppIdentifier.flatMap { appIdentifier in
                profiles.first { $0.appIdentifier == appIdentifier }
            }
            let resolvedPreferences = resolvedProfile.map { profile in
                AnalysisPreferences(
                    paceMin: profile.paceMin,
                    paceMax: profile.paceMax,
                    pauseThreshold: profile.pauseThreshold,
                    crutchWords: profile.crutchWords,
                    speakingTimeTargetPercent: profile.speakingTimeTargetPercent
                )
            } ?? resolvedBase
            return ActiveState(
                preferences: resolvedPreferences,
                appIdentifier: resolvedAppIdentifier,
                profile: resolvedProfile
            )
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] state in
            self?.activePreferences = state.preferences
            self?.activeAppIdentifier = state.appIdentifier
            self?.activeProfile = state.profile
        }
        .store(in: &cancellables)
    }

    var current: AnalysisPreferences {
        activePreferences
    }

    var preferencesPublisher: AnyPublisher<AnalysisPreferences, Never> {
        $activePreferences
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private struct ActiveState: Equatable {
        let preferences: AnalysisPreferences
        let appIdentifier: String?
        let profile: PerAppFeedbackProfile?
    }
}
