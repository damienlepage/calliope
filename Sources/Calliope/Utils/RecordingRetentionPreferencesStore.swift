//
//  RecordingRetentionPreferencesStore.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import Foundation

enum RecordingRetentionOption: Int, CaseIterable, Identifiable {
    case days30 = 30
    case days60 = 60
    case days90 = 90

    var id: Int { rawValue }

    var days: Int { rawValue }

    var label: String {
        "Keep \(rawValue) days"
    }
}

struct RecordingRetentionPreferences: Equatable {
    let autoCleanEnabled: Bool
    let retentionOption: RecordingRetentionOption

    static let `default` = RecordingRetentionPreferences(
        autoCleanEnabled: false,
        retentionOption: .days30
    )
}

final class RecordingRetentionPreferencesStore: ObservableObject {
    @Published var autoCleanEnabled: Bool
    @Published var retentionOption: RecordingRetentionOption

    private let defaults: UserDefaults
    private let autoCleanEnabledKey = "recordingRetention.autoCleanEnabled"
    private let retentionDaysKey = "recordingRetention.retentionDays"
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedAutoClean = defaults.object(forKey: autoCleanEnabledKey) as? Bool
        autoCleanEnabled = storedAutoClean ?? RecordingRetentionPreferences.default.autoCleanEnabled
        let storedDays = defaults.object(forKey: retentionDaysKey) as? Int
            ?? (defaults.object(forKey: retentionDaysKey) as? Double).map(Int.init)
        if let storedDays, let option = RecordingRetentionOption(rawValue: storedDays) {
            retentionOption = option
        } else {
            retentionOption = RecordingRetentionPreferences.default.retentionOption
        }

        $autoCleanEnabled
            .dropFirst()
            .sink { [weak self] value in
                self?.persist(autoCleanEnabled: value)
            }
            .store(in: &cancellables)

        $retentionOption
            .dropFirst()
            .sink { [weak self] value in
                self?.persist(retentionOption: value)
            }
            .store(in: &cancellables)
    }

    var current: RecordingRetentionPreferences {
        RecordingRetentionPreferences(
            autoCleanEnabled: autoCleanEnabled,
            retentionOption: retentionOption
        )
    }

    private func persist(autoCleanEnabled: Bool) {
        defaults.set(autoCleanEnabled, forKey: autoCleanEnabledKey)
    }

    private func persist(retentionOption: RecordingRetentionOption) {
        defaults.set(retentionOption.rawValue, forKey: retentionDaysKey)
    }
}
