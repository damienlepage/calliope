//
//  AudioCapturePreferencesStore.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import Foundation

struct AudioCapturePreferences: Equatable {
    let voiceIsolationEnabled: Bool

    static let `default` = AudioCapturePreferences(
        voiceIsolationEnabled: true
    )
}

final class AudioCapturePreferencesStore: ObservableObject {
    @Published var voiceIsolationEnabled: Bool

    private let defaults: UserDefaults
    private let voiceIsolationEnabledKey = "audioCapturePreferences.voiceIsolationEnabled"
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedValue = defaults.object(forKey: voiceIsolationEnabledKey) as? Bool
        voiceIsolationEnabled = storedValue ?? AudioCapturePreferences.default.voiceIsolationEnabled

        $voiceIsolationEnabled
            .dropFirst()
            .sink { [weak self] voiceIsolationEnabled in
                self?.persist(voiceIsolationEnabled: voiceIsolationEnabled)
            }
            .store(in: &cancellables)
    }

    var current: AudioCapturePreferences {
        AudioCapturePreferences(
            voiceIsolationEnabled: voiceIsolationEnabled
        )
    }

    private func persist(voiceIsolationEnabled: Bool) {
        defaults.set(voiceIsolationEnabled, forKey: voiceIsolationEnabledKey)
    }
}
