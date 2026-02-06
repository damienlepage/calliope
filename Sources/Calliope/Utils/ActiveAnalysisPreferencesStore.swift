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
    private let perAppProfileStore: PerAppFeedbackProfileStore
    private var cancellables = Set<AnyCancellable>()

    init(
        basePreferencesStore: AnalysisPreferencesStore,
        perAppProfileStore: PerAppFeedbackProfileStore,
        frontmostAppPublisher: AnyPublisher<String?, Never>,
        recordingPublisher: AnyPublisher<Bool, Never>
    ) {
        self.basePreferencesStore = basePreferencesStore
        self.perAppProfileStore = perAppProfileStore
        activePreferences = basePreferencesStore.current
        activeAppIdentifier = nil
        activeProfile = nil

        let normalizedFrontmostPublisher = frontmostAppPublisher
            .map { PerAppFeedbackProfileStore.normalizeAppIdentifier($0) }
            .removeDuplicates()

        Publishers.CombineLatest4(
            basePreferencesStore.preferencesPublisher,
            perAppProfileStore.$profiles,
            normalizedFrontmostPublisher,
            recordingPublisher
        )
        .map { basePreferences, profiles, frontmostApp, isRecording in
            let resolvedAppIdentifier = isRecording ? frontmostApp : nil
            let resolvedProfile = resolvedAppIdentifier.flatMap { appIdentifier in
                profiles.first { $0.appIdentifier == appIdentifier }
            }
            let resolvedPreferences = resolvedProfile.map { profile in
                AnalysisPreferences(
                    paceMin: profile.paceMin,
                    paceMax: profile.paceMax,
                    pauseThreshold: profile.pauseThreshold,
                    crutchWords: profile.crutchWords
                )
            } ?? basePreferences
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
