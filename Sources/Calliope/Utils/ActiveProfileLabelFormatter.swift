//
//  ActiveProfileLabelFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct ActiveProfileLabelFormatter {
    static func labelText(isRecording: Bool, profile: PerAppFeedbackProfile?) -> String? {
        guard isRecording else {
            return nil
        }
        if let profile {
            return "Profile: \(profile.appIdentifier)"
        }
        return "Profile: Default"
    }
}
