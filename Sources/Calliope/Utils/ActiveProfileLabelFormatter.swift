//
//  ActiveProfileLabelFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct ActiveProfileLabelFormatter {
    static func labelText(
        isRecording: Bool,
        coachingProfileName: String?,
        perAppProfile: PerAppFeedbackProfile?
    ) -> String? {
        guard isRecording else {
            return nil
        }
        let trimmedName = coachingProfileName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCoachingName = (trimmedName?.isEmpty == false) ? trimmedName! : "Default"
        let appLabel = perAppProfile?.appIdentifier ?? "Default"
        return "Profile: \(resolvedCoachingName) (App: \(appLabel))"
    }
}
