//
//  AppVersionInfo.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct AppVersionInfo: Equatable {
    let shortVersion: String?
    let buildVersion: String?

    init(bundle: Bundle = .main) {
        self.init(infoDictionary: bundle.infoDictionary)
    }

    init(infoDictionary: [String: Any]?) {
        shortVersion = AppVersionInfo.trimmedVersion(
            infoDictionary?["CFBundleShortVersionString"] as? String
        )
        buildVersion = AppVersionInfo.trimmedVersion(
            infoDictionary?["CFBundleVersion"] as? String
        )
    }

    var displayText: String {
        switch (shortVersion, buildVersion) {
        case let (short?, build?):
            return "Version \(short) (Build \(build))"
        case let (short?, nil):
            return "Version \(short)"
        case let (nil, build?):
            return "Build \(build)"
        case (nil, nil):
            return "Version unavailable"
        }
    }

    private static func trimmedVersion(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
