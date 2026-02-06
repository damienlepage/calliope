//
//  ConferencingCompatibilityLogTemplate.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum ConferencingCompatibilityLogTemplate {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func make(date: Date = Date()) -> String {
        let dateString = dateFormatter.string(from: date)
        return """
## Compatibility Check - \(dateString)

- macOS version:
- Calliope version/build:
- Device model:
- Audio input device:
- Notes:

### Zoom

- Call audio unchanged:
- Calliope tracks only local speaker:
- Pace/crutch/pause updates while speaking:
- Observations:

### Google Meet (Chrome)

- Call audio unchanged:
- Calliope tracks only local speaker:
- Pace/crutch/pause updates while speaking:
- Observations:

### Microsoft Teams

- Call audio unchanged:
- Calliope tracks only local speaker:
- Pace/crutch/pause updates while speaking:
- Observations:
"""
    }
}
