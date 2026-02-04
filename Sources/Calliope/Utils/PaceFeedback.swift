//
//  PaceFeedback.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum PaceFeedbackLevel {
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
        if pace < minPace {
            return .slow
        }
        if pace > maxPace {
            return .fast
        }
        return .target
    }
}
