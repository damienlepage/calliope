//
//  OverlayVisibility.swift
//  Calliope
//
//  Created on [Date]
//

enum OverlayVisibility {
    static func shouldShowCompactOverlay(
        isEnabled: Bool,
        isRecording: Bool,
        isSessionVisible: Bool
    ) -> Bool {
        isEnabled && isRecording && !isSessionVisible
    }
}
