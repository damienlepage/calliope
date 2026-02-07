//
//  SettingsView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var microphonePermission: MicrophonePermissionManager
    @ObservedObject var speechPermission: SpeechPermissionManager
    @ObservedObject var microphoneDevices: MicrophoneDeviceManager
    @ObservedObject var preferencesStore: AnalysisPreferencesStore
    @ObservedObject var overlayPreferencesStore: OverlayPreferencesStore
    @ObservedObject var audioCapturePreferencesStore: AudioCapturePreferencesStore
    @ObservedObject var coachingProfileStore: CoachingProfileStore
    let hasAcceptedDisclosure: Bool
    let recordingsPath: String
    let showOpenSettingsAction: Bool
    let showOpenSoundSettingsAction: Bool
    let showOpenSpeechSettingsAction: Bool
    let onRequestMicAccess: () -> Void
    let onRequestSpeechAccess: () -> Void
    let onOpenSystemSettings: () -> Void
    let onOpenSoundSettings: () -> Void
    let onOpenSpeechSettings: () -> Void
    @State private var isCoachingProfilesPresented = false

    var body: some View {
        let availableDevices = microphoneDevices.availableMicrophoneDevices
        let preferredName = audioCapturePreferencesStore.preferredMicrophoneName
        let appVersionText = AppVersionInfo().displayText
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Microphone Access")
                        .font(.headline)
                    Text(microphonePermission.state.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if microphonePermission.state.shouldShowGrantAccess {
                        Button("Grant Microphone Access") {
                            onRequestMicAccess()
                        }
                        .buttonStyle(.bordered)
                    }
                    if showOpenSettingsAction {
                        Button("Open System Settings") {
                            onOpenSystemSettings()
                        }
                        .buttonStyle(.bordered)
                    }
                    if showOpenSoundSettingsAction {
                        Button("Open Sound Settings") {
                            onOpenSoundSettings()
                        }
                        .buttonStyle(.bordered)
                    }
                    if !microphoneDevices.hasMicrophoneInput {
                        Text("No microphone input device detected.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Preferred Input")
                                .font(.subheadline)
                            Picker(
                                "Preferred Input",
                                selection: $audioCapturePreferencesStore.preferredMicrophoneName
                            ) {
                                Text("System Default")
                                    .tag(String?.none)
                                if let preferredName, !availableDevices.map(\.name).contains(preferredName) {
                                    Text("\(preferredName) (Unavailable)")
                                        .tag(Optional(preferredName))
                                }
                                ForEach(availableDevices, id: \.id) { device in
                                    Text(device.name)
                                        .tag(Optional(device.name))
                                }
                            }
                            .pickerStyle(.menu)
                            Text("Available Inputs")
                                .font(.subheadline)
                            ForEach(microphoneDevices.availableMicrophoneNames, id: \.self) { name in
                                HStack(spacing: 8) {
                                    Text(name)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    if name == microphoneDevices.defaultMicrophoneName {
                                        Text("Default")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Speech Recognition")
                        .font(.headline)
                    Text(speechPermission.state.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if speechPermission.state.shouldShowGrantAccess {
                        Button("Grant Speech Access") {
                            onRequestSpeechAccess()
                        }
                        .buttonStyle(.bordered)
                    }
                    if showOpenSpeechSettingsAction {
                        Button("Open System Settings") {
                            onOpenSpeechSettings()
                        }
                        .buttonStyle(.bordered)
                    }
                    Text("Speech recognition runs on-device and never leaves your Mac.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text(PrivacyGuardrails.disclosureTitle)
                        .font(.headline)
                    Text(PrivacyGuardrails.disclosureBody)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    ForEach(PrivacyGuardrails.settingsStatements, id: \.self) { statement in
                        Text(statement)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Text("Recordings are stored locally at \(recordingsPath).")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text(
                        hasAcceptedDisclosure
                            ? "Disclosure accepted."
                            : "Disclosure required before starting a session."
                    )
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Sensitivity Preferences")
                        .font(.headline)
                    HStack {
                        Text("Pace Min")
                            .font(.subheadline)
                        Spacer()
                        Stepper(
                            value: $preferencesStore.paceMin,
                            in: 60...220,
                            step: 5
                        ) {
                            Text("\(Int(preferencesStore.paceMin)) WPM")
                                .font(.subheadline)
                        }
                    }
                    HStack {
                        Text("Pace Max")
                            .font(.subheadline)
                        Spacer()
                        Stepper(
                            value: $preferencesStore.paceMax,
                            in: 80...260,
                            step: 5
                        ) {
                            Text("\(Int(preferencesStore.paceMax)) WPM")
                                .font(.subheadline)
                        }
                    }
                    HStack {
                        Text("Pause Threshold")
                            .font(.subheadline)
                        Spacer()
                        Stepper(
                            value: $preferencesStore.pauseThreshold,
                            in: 0.5...5.0,
                            step: 0.1
                        ) {
                            Text(String(format: "%.1f s", preferencesStore.pauseThreshold))
                                .font(.subheadline)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Crutch Words (comma or newline separated)")
                            .font(.subheadline)
                        TextField("uh, um, you know", text: crutchWordsBinding())
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Text("Presets")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Menu("Choose") {
                                ForEach(AnalysisPreferencesStore.crutchWordPresets) { preset in
                                    Button {
                                        preferencesStore.applyCrutchWordPreset(preset)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(preset.name)
                                            Text(preset.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        Text("Current preset: \(AnalysisPreferencesStore.crutchWordPresetLabel(for: preferencesStore.crutchWords))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        if let description = AnalysisPreferencesStore.crutchWordPresetDescription(for: preferencesStore.crutchWords) {
                            Text(description)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Text("Selecting a preset replaces the current list.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("Tip: multi-word phrases are supported (for example, \"you know\" or \"kind of\").")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Button("Reset to Defaults") {
                        preferencesStore.resetToDefaults()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Coaching Profiles")
                        .font(.headline)
                    Text("Create named profiles for different coaching targets per session.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    if coachingProfileStore.profiles.isEmpty {
                        Text("No profiles yet. Add one to customize coaching targets.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(coachingProfileStore.profiles.sorted(
                            by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                        )) { profile in
                            Text(profile.name)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    Button("Manage Profiles") {
                        isCoachingProfilesPresented = true
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Overlay")
                        .font(.headline)
                    Toggle("Show compact overlay", isOn: $overlayPreferencesStore.showCompactOverlay)
                    Toggle("Always on top", isOn: $overlayPreferencesStore.alwaysOnTop)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                    Text(appVersionText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isCoachingProfilesPresented) {
            CoachingProfilesSheet(coachingProfileStore: coachingProfileStore)
        }
    }

    private func crutchWordsBinding() -> Binding<String> {
        Binding(
            get: { AnalysisPreferencesStore.formatCrutchWords(preferencesStore.crutchWords) },
            set: { preferencesStore.crutchWords = AnalysisPreferencesStore.parseCrutchWords(from: $0) }
        )
    }

}

#Preview {
    SettingsView(
        microphonePermission: MicrophonePermissionManager(),
        speechPermission: SpeechPermissionManager(),
        microphoneDevices: MicrophoneDeviceManager(),
        preferencesStore: AnalysisPreferencesStore(),
        overlayPreferencesStore: OverlayPreferencesStore(),
        audioCapturePreferencesStore: AudioCapturePreferencesStore(),
        coachingProfileStore: CoachingProfileStore(),
        hasAcceptedDisclosure: true,
        recordingsPath: "/Users/you/Recordings",
        showOpenSettingsAction: false,
        showOpenSoundSettingsAction: false,
        showOpenSpeechSettingsAction: false,
        onRequestMicAccess: {},
        onRequestSpeechAccess: {},
        onOpenSystemSettings: {},
        onOpenSoundSettings: {},
        onOpenSpeechSettings: {},
    )
}
