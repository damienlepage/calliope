//
//  AppCommands.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct ToggleRecordingActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct RefreshRecordingsActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct OpenRecordingsFolderActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var toggleRecording: (() -> Void)? {
        get { self[ToggleRecordingActionKey.self] }
        set { self[ToggleRecordingActionKey.self] = newValue }
    }

    var refreshRecordings: (() -> Void)? {
        get { self[RefreshRecordingsActionKey.self] }
        set { self[RefreshRecordingsActionKey.self] = newValue }
    }

    var openRecordingsFolder: (() -> Void)? {
        get { self[OpenRecordingsFolderActionKey.self] }
        set { self[OpenRecordingsFolderActionKey.self] = newValue }
    }
}

struct AppNavigationCommands: Commands {
    @ObservedObject var navigationState: AppNavigationState

    var body: some Commands {
        CommandMenu("View") {
            ForEach(AppSection.allCases) { section in
                Button(section.title) {
                    navigationState.selection = section
                }
                .keyboardShortcut(section.shortcutKey, modifiers: .command)
                .help(section.shortcutLabel)
            }
        }
    }
}

struct RecordingCommands: Commands {
    @FocusedValue(\.toggleRecording) private var toggleRecording

    var body: some Commands {
        CommandMenu("Session") {
            Button("Start/Stop Recording") {
                toggleRecording?()
            }
            .keyboardShortcut("r", modifiers: .command)
            .help("Cmd+R")
            .disabled(toggleRecording == nil)
        }
    }
}

struct RecordingsCommands: Commands {
    @FocusedValue(\.refreshRecordings) private var refreshRecordings
    @FocusedValue(\.openRecordingsFolder) private var openRecordingsFolder

    var body: some Commands {
        CommandMenu("Recordings") {
            Button("Refresh Recordings") {
                refreshRecordings?()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .help("Cmd+Shift+R")
            .disabled(refreshRecordings == nil)

            Button("Open Recordings Folder") {
                openRecordingsFolder?()
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
            .help("Cmd+Shift+O")
            .disabled(openRecordingsFolder == nil)
        }
    }
}
