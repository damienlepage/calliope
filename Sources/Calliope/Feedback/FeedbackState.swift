//
//  FeedbackState.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct FeedbackState: Equatable {
    let pace: Double
    let crutchWords: Int
    let pauseCount: Int
    let pauseAverageDuration: TimeInterval
    let inputLevel: Double
    let showSilenceWarning: Bool
    let processingLatencyStatus: ProcessingLatencyStatus
    let processingLatencyAverage: TimeInterval

    init(
        pace: Double,
        crutchWords: Int,
        pauseCount: Int,
        pauseAverageDuration: TimeInterval = 0,
        inputLevel: Double = 0.0,
        showSilenceWarning: Bool = false,
        processingLatencyStatus: ProcessingLatencyStatus = .ok,
        processingLatencyAverage: TimeInterval = 0
    ) {
        self.pace = pace
        self.crutchWords = crutchWords
        self.pauseCount = pauseCount
        self.pauseAverageDuration = pauseAverageDuration
        self.inputLevel = inputLevel
        self.showSilenceWarning = showSilenceWarning
        self.processingLatencyStatus = processingLatencyStatus
        self.processingLatencyAverage = processingLatencyAverage
    }

    static let zero = FeedbackState(
        pace: 0.0,
        crutchWords: 0,
        pauseCount: 0,
        pauseAverageDuration: 0,
        inputLevel: 0.0,
        showSilenceWarning: false,
        processingLatencyStatus: .ok,
        processingLatencyAverage: 0
    )
}
