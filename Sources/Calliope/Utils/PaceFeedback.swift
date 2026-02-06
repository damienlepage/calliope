//
//  PaceFeedback.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum PaceFeedbackLevel {
    case idle
    case slow
    case target
    case fast
}

enum PaceFeedback {
    static func level(
        for pace: Double,
        minPace: Double = Constants.targetPaceMin,
        maxPace: Double = Constants.targetPaceMax
    ) -> PaceFeedbackLevel {
        if pace <= 0 {
            return .idle
        }
        if pace < minPace {
            return .slow
        }
        if pace > maxPace {
            return .fast
        }
        return .target
    }

    static func label(
        for pace: Double,
        minPace: Double = Constants.targetPaceMin,
        maxPace: Double = Constants.targetPaceMax
    ) -> String {
        switch level(for: pace, minPace: minPace, maxPace: maxPace) {
        case .idle:
            return "Listening"
        case .slow:
            return "Slow"
        case .target:
            return "On Target"
        case .fast:
            return "Fast"
        }
    }

    static func targetRangeText(
        minPace: Double = Constants.targetPaceMin,
        maxPace: Double = Constants.targetPaceMax
    ) -> String {
        let lower = min(minPace, maxPace)
        let upper = max(minPace, maxPace)
        return "\(Int(lower))-\(Int(upper)) WPM"
    }
}
