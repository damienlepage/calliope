//
//  InputLevelMeter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct InputLevelMeter {
    static let scaleFactor: Double = 8.0
    static let smoothingFactor: Double = 0.7
    static let meaningfulThreshold: Double = 0.05

    static func scaledLevel(for rms: Float) -> Double {
        let scaled = Double(rms) * scaleFactor
        return min(max(scaled, 0.0), 1.0)
    }

    static func smoothedLevel(previous: Double, target: Double) -> Double {
        (previous * smoothingFactor) + (target * (1.0 - smoothingFactor))
    }
}
