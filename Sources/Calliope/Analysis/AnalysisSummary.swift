//
//  AnalysisSummary.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct AnalysisSummary: Codable, Equatable {
    struct ProcessingStats: Codable, Equatable {
        let latencyAverageMs: Double
        let latencyPeakMs: Double
        let utilizationAverage: Double
        let utilizationPeak: Double

        init(
            latencyAverageMs: Double = 0,
            latencyPeakMs: Double = 0,
            utilizationAverage: Double = 0,
            utilizationPeak: Double = 0
        ) {
            self.latencyAverageMs = latencyAverageMs
            self.latencyPeakMs = latencyPeakMs
            self.utilizationAverage = utilizationAverage
            self.utilizationPeak = utilizationPeak
        }

        private enum CodingKeys: String, CodingKey {
            case latencyAverageMs
            case latencyPeakMs
            case utilizationAverage
            case utilizationPeak
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            latencyAverageMs = try container.decodeIfPresent(Double.self, forKey: .latencyAverageMs) ?? 0
            latencyPeakMs = try container.decodeIfPresent(Double.self, forKey: .latencyPeakMs) ?? 0
            utilizationAverage = try container.decodeIfPresent(Double.self, forKey: .utilizationAverage) ?? 0
            utilizationPeak = try container.decodeIfPresent(Double.self, forKey: .utilizationPeak) ?? 0
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(latencyAverageMs, forKey: .latencyAverageMs)
            try container.encode(latencyPeakMs, forKey: .latencyPeakMs)
            try container.encode(utilizationAverage, forKey: .utilizationAverage)
            try container.encode(utilizationPeak, forKey: .utilizationPeak)
        }
    }

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
    let processing: ProcessingStats

    init(
        version: Int,
        createdAt: Date,
        durationSeconds: Double,
        pace: PaceStats,
        pauses: PauseStats,
        crutchWords: CrutchWordStats,
        processing: ProcessingStats = ProcessingStats()
    ) {
        self.version = version
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.pace = pace
        self.pauses = pauses
        self.crutchWords = crutchWords
        self.processing = processing
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case createdAt
        case durationSeconds
        case pace
        case pauses
        case crutchWords
        case processing
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        durationSeconds = try container.decode(Double.self, forKey: .durationSeconds)
        pace = try container.decode(PaceStats.self, forKey: .pace)
        pauses = try container.decode(PauseStats.self, forKey: .pauses)
        crutchWords = try container.decode(CrutchWordStats.self, forKey: .crutchWords)
        processing = try container.decodeIfPresent(ProcessingStats.self, forKey: .processing) ?? ProcessingStats()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(pace, forKey: .pace)
        try container.encode(pauses, forKey: .pauses)
        try container.encode(crutchWords, forKey: .crutchWords)
        try container.encode(processing, forKey: .processing)
    }
}
