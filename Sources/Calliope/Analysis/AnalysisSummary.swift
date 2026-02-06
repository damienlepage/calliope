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
        let averageDurationSeconds: Double

        init(count: Int, thresholdSeconds: Double, averageDurationSeconds: Double = 0) {
            self.count = count
            self.thresholdSeconds = thresholdSeconds
            self.averageDurationSeconds = averageDurationSeconds
        }

        private enum CodingKeys: String, CodingKey {
            case count
            case thresholdSeconds
            case averageDurationSeconds
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            count = try container.decode(Int.self, forKey: .count)
            thresholdSeconds = try container.decode(Double.self, forKey: .thresholdSeconds)
            averageDurationSeconds = try container.decodeIfPresent(Double.self, forKey: .averageDurationSeconds) ?? 0
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(count, forKey: .count)
            try container.encode(thresholdSeconds, forKey: .thresholdSeconds)
            try container.encode(averageDurationSeconds, forKey: .averageDurationSeconds)
        }
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
