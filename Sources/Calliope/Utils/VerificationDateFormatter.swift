//
//  VerificationDateFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum VerificationDateFormatter {
    static func format(_ date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
