//
//  CaptureStatusFormatter.swift
//  Calliope
//
//  Created on [Date]
//

struct CaptureStatusFormatter {
    static func statusText(
        inputDeviceName: String,
        backendStatus: AudioCaptureBackendStatus,
        isRecording: Bool
    ) -> String? {
        guard isRecording else {
            return nil
        }

        let trimmedDeviceName = inputDeviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let backendText = backendStatus.message
        guard !trimmedDeviceName.isEmpty else {
            return backendText
        }
        return "Input: \(trimmedDeviceName) · \(backendText)"
    }
}
