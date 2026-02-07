//
//  CrutchWordFeedback.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum CrutchWordFeedbackLevel {
    case calm
    case caution
}

struct CrutchWordFeedback {
    static let cautionThreshold = 5

    static func level(for count: Int) -> CrutchWordFeedbackLevel {
        count > cautionThreshold ? .caution : .calm
    }
}
