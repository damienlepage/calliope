//
//  PaceRangeBarLayout.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct PaceRangeBarLayout: Equatable {
    let targetStart: Double
    let targetWidth: Double
    let pacePosition: Double

    static func compute(
        pace: Double,
        minPace: Double,
        maxPace: Double,
        padding: Double = 40
    ) -> PaceRangeBarLayout {
        let lower = max(0, minPace - padding)
        let upper = max(maxPace + padding, lower + 1)
        let total = max(upper - lower, 1)
        let targetStart = (minPace - lower) / total
        let targetWidth = (maxPace - minPace) / total
        let clampedPace = min(max(pace, lower), upper)
        let pacePosition = (clampedPace - lower) / total
        return PaceRangeBarLayout(
            targetStart: targetStart,
            targetWidth: targetWidth,
            pacePosition: pacePosition
        )
    }
}
