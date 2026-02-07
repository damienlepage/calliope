//
//  InputLevelMeterView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct InputLevelMeterView: View {
    let level: Double

    var body: some View {
        let statusText = level < InputLevelMeter.meaningfulThreshold ? "Low signal" : "Active"
        ProgressView(value: level)
            .progressViewStyle(.linear)
            .frame(height: 6)
            .tint(level > 0.6 ? .green : .accentColor)
            .accessibilityLabel("Input level")
            .accessibilityValue(
                AccessibilityFormatting.inputLevelValue(level: level, statusText: statusText)
            )
            .accessibilityHint("Microphone signal strength.")
    }
}
