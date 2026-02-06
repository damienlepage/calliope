//
//  ElapsedTimeFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct ElapsedTimeFormatter {
    static func labelText(_ sessionDurationText: String?) -> String? {
        guard let sessionDurationText, !sessionDurationText.isEmpty else {
            return nil
        }
        return "Elapsed \(sessionDurationText)"
    }
}
