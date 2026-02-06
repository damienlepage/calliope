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
    let preferredMicrophoneName: String?

    static let `default` = AudioCapturePreferences(
        voiceIsolationEnabled: true,
        preferredMicrophoneName: nil
    )
}

final class AudioCapturePreferencesStore: ObservableObject {
    @Published var voiceIsolationEnabled: Bool
    @Published var preferredMicrophoneName: String?

    private let defaults: UserDefaults
    private let voiceIsolationEnabledKey = "audioCapturePreferences.voiceIsolationEnabled"
    private let preferredMicrophoneNameKey = "audioCapturePreferences.preferredMicrophoneName"
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedValue = defaults.object(forKey: voiceIsolationEnabledKey) as? Bool
        voiceIsolationEnabled = storedValue ?? AudioCapturePreferences.default.voiceIsolationEnabled
        preferredMicrophoneName = defaults.string(forKey: preferredMicrophoneNameKey)

        $voiceIsolationEnabled
            .dropFirst()
            .sink { [weak self] voiceIsolationEnabled in
                self?.persist(voiceIsolationEnabled: voiceIsolationEnabled)
            }
            .store(in: &cancellables)

        $preferredMicrophoneName
            .dropFirst()
            .sink { [weak self] preferredMicrophoneName in
                self?.persist(preferredMicrophoneName: preferredMicrophoneName)
            }
            .store(in: &cancellables)
    }

    var current: AudioCapturePreferences {
        AudioCapturePreferences(
            voiceIsolationEnabled: voiceIsolationEnabled,
            preferredMicrophoneName: preferredMicrophoneName
        )
    }

    private func persist(voiceIsolationEnabled: Bool) {
        defaults.set(voiceIsolationEnabled, forKey: voiceIsolationEnabledKey)
    }

    private func persist(preferredMicrophoneName: String?) {
        guard let preferredMicrophoneName, !preferredMicrophoneName.isEmpty else {
            defaults.removeObject(forKey: preferredMicrophoneNameKey)
            return
        }
        defaults.set(preferredMicrophoneName, forKey: preferredMicrophoneNameKey)
    }
}
