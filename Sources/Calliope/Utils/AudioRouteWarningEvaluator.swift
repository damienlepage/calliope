//
//  AudioRouteWarningEvaluator.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum AudioRouteWarningState: Equatable {
    case ok
    case warning(message: String)
}

struct AudioRouteWarningEvaluator {
    static func warningState(
        inputDeviceName: String,
        outputDeviceName: String,
        backendStatus: AudioCaptureBackendStatus
    ) -> AudioRouteWarningState {
        let trimmedInput = inputDeviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOutput = outputDeviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty, !trimmedOutput.isEmpty else {
            return .ok
        }

        let normalizedInput = trimmedInput.lowercased()
        let normalizedOutput = trimmedOutput.lowercased()

        if isHeadphones(output: normalizedOutput) {
            return .ok
        }

        let outputIsSpeaker = isSpeaker(output: normalizedOutput)
        let inputIsBuiltIn = isBuiltInMic(input: normalizedInput)

        if outputIsSpeaker, inputIsBuiltIn {
            let message = backendStatus == .voiceIsolation
                ? "Built-in speakers and mic detected. Voice Isolation helps, but a headset reduces bleed."
                : "Built-in speakers and mic detected. Use a headset or external mic to reduce bleed."
            return .warning(message: message)
        }

        if outputIsSpeaker, backendStatus != .voiceIsolation {
            return .warning(message: "Speaker output may feed into the mic. Consider a headset for best isolation.")
        }

        return .ok
    }

    static func warningText(
        inputDeviceName: String,
        outputDeviceName: String,
        backendStatus: AudioCaptureBackendStatus
    ) -> String? {
        switch warningState(
            inputDeviceName: inputDeviceName,
            outputDeviceName: outputDeviceName,
            backendStatus: backendStatus
        ) {
        case .ok:
            return nil
        case .warning(let message):
            return message
        }
    }

    private static func isHeadphones(output: String) -> Bool {
        output.contains("headphone")
            || output.contains("headphones")
            || output.contains("earbud")
            || output.contains("earbuds")
            || output.contains("earpods")
            || output.contains("airpods")
            || output.contains("headset")
    }

    private static func isSpeaker(output: String) -> Bool {
        output.contains("speaker")
            || output.contains("speakers")
            || output.contains("built-in output")
            || output.contains("internal")
    }

    private static func isBuiltInMic(input: String) -> Bool {
        input.contains("built-in")
            || input.contains("internal")
            || input.contains("macbook")
            || input.contains("imac")
            || input.contains("mac mini")
            || input.contains("mac studio")
            || input.contains("mac pro")
            || input.contains("studio display")
    }
}
