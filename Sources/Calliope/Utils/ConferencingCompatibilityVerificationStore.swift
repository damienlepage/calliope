//
//  ConferencingCompatibilityVerificationStore.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import Foundation

enum ConferencingPlatform: String, CaseIterable, Identifiable {
    case zoom
    case googleMeet
    case microsoftTeams

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zoom:
            return "Zoom"
        case .googleMeet:
            return "Google Meet"
        case .microsoftTeams:
            return "Microsoft Teams"
        }
    }
}

final class ConferencingCompatibilityVerificationStore: ObservableObject {
    @Published private(set) var verificationDates: [ConferencingPlatform: Date]

    private let defaults: UserDefaults
    private let nowProvider: () -> Date
    private let verificationKey = "conferencingCompatibility.verificationDates"

    init(defaults: UserDefaults = .standard, nowProvider: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.nowProvider = nowProvider
        let stored = defaults.dictionary(forKey: verificationKey) as? [String: TimeInterval] ?? [:]
        var loaded: [ConferencingPlatform: Date] = [:]
        for (key, value) in stored {
            guard let platform = ConferencingPlatform(rawValue: key) else { continue }
            loaded[platform] = Date(timeIntervalSince1970: value)
        }
        verificationDates = loaded
    }

    func isVerified(_ platform: ConferencingPlatform) -> Bool {
        verificationDates[platform] != nil
    }

    func verificationDate(for platform: ConferencingPlatform) -> Date? {
        verificationDates[platform]
    }

    func setVerified(_ platform: ConferencingPlatform, isVerified: Bool) {
        if isVerified {
            markVerified(platform)
        } else {
            clearVerification(platform)
        }
    }

    func markVerified(_ platform: ConferencingPlatform) {
        verificationDates[platform] = nowProvider()
        persist()
    }

    func clearVerification(_ platform: ConferencingPlatform) {
        verificationDates.removeValue(forKey: platform)
        persist()
    }

    private func persist() {
        var payload: [String: TimeInterval] = [:]
        for (platform, date) in verificationDates {
            payload[platform.rawValue] = date.timeIntervalSince1970
        }
        defaults.set(payload, forKey: verificationKey)
    }
}
