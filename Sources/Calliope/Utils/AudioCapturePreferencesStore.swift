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
    let maxSegmentDuration: TimeInterval

    static let `default` = AudioCapturePreferences(
        voiceIsolationEnabled: true,
        preferredMicrophoneName: nil,
        maxSegmentDuration: Constants.maxRecordingSegmentDuration
    )
}

final class AudioCapturePreferencesStore: ObservableObject {
    @Published var voiceIsolationEnabled: Bool
    @Published var preferredMicrophoneName: String?
    @Published var maxSegmentDuration: TimeInterval

    private let defaults: UserDefaults
    private let voiceIsolationEnabledKey = "audioCapturePreferences.voiceIsolationEnabled"
    private let preferredMicrophoneNameKey = "audioCapturePreferences.preferredMicrophoneName"
    private let maxSegmentDurationKey = "audioCapturePreferences.maxSegmentDurationSeconds"
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedValue = defaults.object(forKey: voiceIsolationEnabledKey) as? Bool
        voiceIsolationEnabled = storedValue ?? AudioCapturePreferences.default.voiceIsolationEnabled
        preferredMicrophoneName = defaults.string(forKey: preferredMicrophoneNameKey)
        let storedSegmentDuration = defaults.object(forKey: maxSegmentDurationKey) as? Double
        maxSegmentDuration = storedSegmentDuration ?? AudioCapturePreferences.default.maxSegmentDuration

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

        $maxSegmentDuration
            .dropFirst()
            .sink { [weak self] maxSegmentDuration in
                self?.persist(maxSegmentDuration: maxSegmentDuration)
            }
            .store(in: &cancellables)
    }

    var current: AudioCapturePreferences {
        AudioCapturePreferences(
            voiceIsolationEnabled: voiceIsolationEnabled,
            preferredMicrophoneName: preferredMicrophoneName,
            maxSegmentDuration: maxSegmentDuration
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

    private func persist(maxSegmentDuration: TimeInterval) {
        defaults.set(maxSegmentDuration, forKey: maxSegmentDurationKey)
    }
}
