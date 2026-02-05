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
        let minutes = clamped / 60
        let remainder = clamped % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}
