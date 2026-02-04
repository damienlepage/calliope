//
//  Recording.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct Recording: Identifiable, Codable {
    let id: UUID
    let url: URL
    let date: Date
    let duration: TimeInterval
    let pace: Double
    let crutchWordCount: Int
    let pauseCount: Int
    
    init(url: URL, date: Date = Date(), duration: TimeInterval, pace: Double, crutchWordCount: Int, pauseCount: Int) {
        self.id = UUID()
        self.url = url
        self.date = date
        self.duration = duration
        self.pace = pace
        self.crutchWordCount = crutchWordCount
        self.pauseCount = pauseCount
    }
}
