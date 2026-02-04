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

    static let zero = FeedbackState(pace: 0.0, crutchWords: 0, pauseCount: 0)
}
