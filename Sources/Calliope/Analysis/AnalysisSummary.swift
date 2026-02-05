//
//  AnalysisSummary.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct AnalysisSummary: Codable, Equatable {
    struct PaceStats: Codable, Equatable {
        let averageWPM: Double
        let minWPM: Double
        let maxWPM: Double
        let totalWords: Int
    }

    struct PauseStats: Codable, Equatable {
        let count: Int
        let thresholdSeconds: Double
    }

    struct CrutchWordStats: Codable, Equatable {
        let totalCount: Int
        let counts: [String: Int]
    }

    let version: Int
    let createdAt: Date
    let durationSeconds: Double
    let pace: PaceStats
    let pauses: PauseStats
    let crutchWords: CrutchWordStats
}
