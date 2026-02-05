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
    let showCompactOverlay: Bool

    static let `default` = OverlayPreferences(
        alwaysOnTop: false,
        showCompactOverlay: false
    )
}

final class OverlayPreferencesStore: ObservableObject {
    @Published var alwaysOnTop: Bool
    @Published var showCompactOverlay: Bool

    private let defaults: UserDefaults
    private let alwaysOnTopKey = "overlayPreferences.alwaysOnTop"
    private let showCompactOverlayKey = "overlayPreferences.showCompactOverlay"
    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedAlwaysOnTop = defaults.object(forKey: alwaysOnTopKey) as? Bool
        let storedShowCompactOverlay = defaults.object(forKey: showCompactOverlayKey) as? Bool
        alwaysOnTop = storedAlwaysOnTop ?? OverlayPreferences.default.alwaysOnTop
        showCompactOverlay = storedShowCompactOverlay ?? OverlayPreferences.default.showCompactOverlay

        $alwaysOnTop
            .dropFirst()
            .sink { [weak self] alwaysOnTop in
                self?.persist(alwaysOnTop: alwaysOnTop)
            }
            .store(in: &cancellables)

        $showCompactOverlay
            .dropFirst()
            .sink { [weak self] showCompactOverlay in
                self?.persist(showCompactOverlay: showCompactOverlay)
            }
            .store(in: &cancellables)
    }

    var current: OverlayPreferences {
        OverlayPreferences(
            alwaysOnTop: alwaysOnTop,
            showCompactOverlay: showCompactOverlay
        )
    }

    private func persist(alwaysOnTop: Bool) {
        defaults.set(alwaysOnTop, forKey: alwaysOnTopKey)
    }

    private func persist(showCompactOverlay: Bool) {
        defaults.set(showCompactOverlay, forKey: showCompactOverlayKey)
    }
}
