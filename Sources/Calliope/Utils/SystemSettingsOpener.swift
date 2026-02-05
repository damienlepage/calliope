//
//  SystemSettingsOpener.swift
//  Calliope
//
//  Created on [Date]
//

import AppKit
import Foundation

protocol SystemSettingsOpening {
    func openMicrophonePrivacy()
    func openSoundInput()
}

struct SystemSettingsOpener: SystemSettingsOpening {
    func openMicrophonePrivacy() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func openSoundInput() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.sound?input"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

struct MicrophoneSettingsActionModel {
    private let opener: SystemSettingsOpening

    init(opener: SystemSettingsOpening = SystemSettingsOpener()) {
        self.opener = opener
    }

    func shouldShow(for blockingReasons: [RecordingEligibility.Reason]) -> Bool {
        blockingReasons.contains(.microphonePermissionDenied)
            || blockingReasons.contains(.microphonePermissionRestricted)
    }

    func openSystemSettings() {
        opener.openMicrophonePrivacy()
    }
}

struct SoundSettingsActionModel {
    private let opener: SystemSettingsOpening

    init(opener: SystemSettingsOpening = SystemSettingsOpener()) {
        self.opener = opener
    }

    func shouldShow(for blockingReasons: [RecordingEligibility.Reason]) -> Bool {
        guard blockingReasons.contains(.microphoneUnavailable) else {
            return false
        }
        return blockingReasons.allSatisfy { $0 == .microphoneUnavailable }
    }

    func openSoundSettings() {
        opener.openSoundInput()
    }
}
