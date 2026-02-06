//
//  AppNavigationState.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

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

    var shortcutKey: KeyEquivalent {
        switch self {
        case .session:
            return "1"
        case .recordings:
            return "2"
        case .settings:
            return "3"
        }
    }

    var shortcutLabel: String {
        switch self {
        case .session:
            return "Cmd+1"
        case .recordings:
            return "Cmd+2"
        case .settings:
            return "Cmd+3"
        }
    }
}

final class AppNavigationState: ObservableObject {
    @Published var selection: AppSection = .session
}
