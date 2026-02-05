//
//  OverlayPreferencesStore.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import Foundation

struct OverlayPreferences: Equatable {
    let alwaysOnTop: Bool

    static let `default` = OverlayPreferences(alwaysOnTop: false)
}

final class OverlayPreferencesStore: ObservableObject {
    @Published var alwaysOnTop: Bool

    private let defaults: UserDefaults
    private let alwaysOnTopKey = "overlayPreferences.alwaysOnTop"
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedAlwaysOnTop = defaults.object(forKey: alwaysOnTopKey) as? Bool
        alwaysOnTop = storedAlwaysOnTop ?? OverlayPreferences.default.alwaysOnTop

        $alwaysOnTop
            .dropFirst()
            .sink { [weak self] alwaysOnTop in
                self?.persist(alwaysOnTop: alwaysOnTop)
            }
            .store(in: &cancellables)
    }

    var current: OverlayPreferences {
        OverlayPreferences(alwaysOnTop: alwaysOnTop)
    }

    private func persist(alwaysOnTop: Bool) {
        defaults.set(alwaysOnTop, forKey: alwaysOnTopKey)
    }
}
