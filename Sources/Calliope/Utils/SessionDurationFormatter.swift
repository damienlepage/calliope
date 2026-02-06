//
//  SessionDurationFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum SessionDurationFormatter {
    static func format(seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let remainder = clamped % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remainder)
        }
        return String(format: "%02d:%02d", minutes, remainder)
    }
}
