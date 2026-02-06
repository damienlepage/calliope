//
//  CaptureDiagnosticsFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct AudioInputFormatSnapshot: Equatable {
    let sampleRate: Double
    let channelCount: Int
}

struct CaptureDiagnosticsFormatter {
    static func inputFormatLabel(sampleRate: Double, channelCount: Int) -> String {
        let rateText = formatSampleRate(sampleRate)
        let channelText = formatChannelCount(channelCount)
        return "\(rateText) · \(channelText)"
    }

    static func selectedInputLabel(
        preferredName: String?,
        availableNames: [String],
        defaultName: String?
    ) -> String {
        if let preferredName, !preferredName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if availableNames.contains(preferredName) {
                return preferredName
            }
            return "\(preferredName) (Unavailable)"
        }

        if let defaultName, !defaultName.isEmpty {
            return "System Default (\(defaultName))"
        }

        return "System Default"
    }

    private static func formatSampleRate(_ sampleRate: Double) -> String {
        let kHz = (sampleRate / 1000.0 * 10).rounded() / 10
        if kHz.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f kHz", kHz)
        }
        return String(format: "%.1f kHz", kHz)
    }

    private static func formatChannelCount(_ channelCount: Int) -> String {
        "\(channelCount) ch"
    }
}
