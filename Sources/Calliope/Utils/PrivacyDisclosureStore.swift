//
//  PrivacyDisclosureStore.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct PrivacyDisclosureStore {
    private let defaults: UserDefaults
    private let disclosureKey = "privacyDisclosureAccepted"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasAcceptedDisclosure: Bool {
        get { defaults.bool(forKey: disclosureKey) }
        set { defaults.set(newValue, forKey: disclosureKey) }
    }
}
