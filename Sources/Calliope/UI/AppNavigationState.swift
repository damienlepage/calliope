//
//  AppNavigationState.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case session
    case recordings
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .session:
            return "Session"
        case .recordings:
            return "Recordings"
        case .settings:
            return "Settings"
        }
    }
}

final class AppNavigationState: ObservableObject {
    @Published var selection: AppSection = .session
}
