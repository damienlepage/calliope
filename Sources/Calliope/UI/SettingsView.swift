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
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Microphone Access")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Text(microphonePermission.state.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Microphone access status")
                        .accessibilityValue(microphonePermission.state.description)
                    if microphonePermission.state.shouldShowGrantAccess {
                        Button("Grant Microphone Access") {
                            onRequestMicAccess()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Request microphone permission for Calliope.")
                    }
                    if showOpenSettingsAction {
                        Button("Open System Settings") {
                            onOpenSystemSettings()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Open macOS privacy settings.")
                    }
                    if showOpenSoundSettingsAction {
                        Button("Open Sound Settings") {
                            onOpenSoundSettings()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Open macOS sound input settings.")
                    }
                    if !microphoneDevices.hasMicrophoneInput {
                        Label {
                            Text("No microphone input device detected.")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                        .accessibilityLabel("No microphone input device detected")
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
                            .accessibilityLabel("Preferred microphone input")
                            .accessibilityHint("Choose which microphone Calliope uses.")
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
                                            .accessibilityLabel("Default input")
                                    }
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(
                                    name == microphoneDevices.defaultMicrophoneName
                                        ? "\(name), Default input"
                                        : name
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Speech Recognition")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Text(speechPermission.state.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Speech recognition status")
                        .accessibilityValue(speechPermission.state.description)
                    if speechPermission.state.shouldShowGrantAccess {
                        Button("Grant Speech Access") {
                            onRequestSpeechAccess()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Request speech recognition permission.")
                    }
                    if showOpenSpeechSettingsAction {
                        Button("Open System Settings") {
                            onOpenSpeechSettings()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Open macOS speech recognition settings.")
                    }
                    Text("Speech recognition runs on-device and never leaves your Mac.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text(PrivacyGuardrails.disclosureTitle)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
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
                    .accessibilityLabel("Privacy disclosure status")
                    .accessibilityValue(
                        hasAcceptedDisclosure
                            ? "Accepted"
                            : "Required before starting a session"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Sensitivity Preferences")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    ViewThatFits(in: .horizontal) {
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
                            .accessibilityLabel("Pace minimum")
                            .accessibilityValue("\(Int(preferencesStore.paceMin)) words per minute")
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pace Min")
                                .font(.subheadline)
                            Stepper(
                                value: $preferencesStore.paceMin,
                                in: 60...220,
                                step: 5
                            ) {
                                Text("\(Int(preferencesStore.paceMin)) WPM")
                                    .font(.subheadline)
                            }
                            .accessibilityLabel("Pace minimum")
                            .accessibilityValue("\(Int(preferencesStore.paceMin)) words per minute")
                        }
                    }
                    ViewThatFits(in: .horizontal) {
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
                            .accessibilityLabel("Pace maximum")
                            .accessibilityValue("\(Int(preferencesStore.paceMax)) words per minute")
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pace Max")
                                .font(.subheadline)
                            Stepper(
                                value: $preferencesStore.paceMax,
                                in: 80...260,
                                step: 5
                            ) {
                                Text("\(Int(preferencesStore.paceMax)) WPM")
                                    .font(.subheadline)
                            }
                            .accessibilityLabel("Pace maximum")
                            .accessibilityValue("\(Int(preferencesStore.paceMax)) words per minute")
                        }
                    }
                    ViewThatFits(in: .horizontal) {
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
                            .accessibilityLabel("Pause threshold")
                            .accessibilityValue(String(format: "%.1f seconds", preferencesStore.pauseThreshold))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pause Threshold")
                                .font(.subheadline)
                            Stepper(
                                value: $preferencesStore.pauseThreshold,
                                in: 0.5...5.0,
                                step: 0.1
                            ) {
                                Text(String(format: "%.1f s", preferencesStore.pauseThreshold))
                                    .font(.subheadline)
                            }
                            .accessibilityLabel("Pause threshold")
                            .accessibilityValue(String(format: "%.1f seconds", preferencesStore.pauseThreshold))
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Crutch Words (comma or newline separated)")
                            .font(.subheadline)
                        TextField("uh, um, you know", text: crutchWordsBinding())
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Crutch words list")
                            .accessibilityHint("Enter crutch words separated by commas or new lines.")
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
                            .accessibilityLabel("Crutch word presets")
                            .accessibilityHint("Choose a preset list of crutch words.")
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
                    .accessibilityHint("Reset pace, pause, and crutch word settings.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Coaching Profiles")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
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
                    .accessibilityHint("Open the coaching profile manager.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Overlay")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Toggle("Show compact overlay", isOn: $overlayPreferencesStore.showCompactOverlay)
                        .accessibilityHint("Show a smaller live feedback overlay while recording.")
                    Toggle("Always on top", isOn: $overlayPreferencesStore.alwaysOnTop)
                        .accessibilityHint("Keep the overlay above other windows.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
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
