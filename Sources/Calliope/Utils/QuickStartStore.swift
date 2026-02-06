//
//  QuickStartStore.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct QuickStartStore {
    private let defaults: UserDefaults
    private let quickStartSeenKey = "quickStartSeen"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasSeenQuickStart: Bool {
        get { defaults.bool(forKey: quickStartSeenKey) }
        set { defaults.set(newValue, forKey: quickStartSeenKey) }
    }
}
