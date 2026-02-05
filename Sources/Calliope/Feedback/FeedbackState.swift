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
    let inputLevel: Double
    let showSilenceWarning: Bool

    init(
        pace: Double,
        crutchWords: Int,
        pauseCount: Int,
        inputLevel: Double = 0.0,
        showSilenceWarning: Bool = false
    ) {
        self.pace = pace
        self.crutchWords = crutchWords
        self.pauseCount = pauseCount
        self.inputLevel = inputLevel
        self.showSilenceWarning = showSilenceWarning
    }

    static let zero = FeedbackState(
        pace: 0.0,
        crutchWords: 0,
        pauseCount: 0,
        inputLevel: 0.0,
        showSilenceWarning: false
    )
}
