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
    @ObservedObject var audioCapture: AudioCapture
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
    let onOpenRecordingsFolder: () -> Void
    let onRunMicTest: () -> Void

    var body: some View {
        let canRunMicTest = MicTestEligibility.canRun(
            microphonePermission: microphonePermission.state,
            hasMicrophoneInput: microphoneDevices.hasMicrophoneInput
        )
        let availableDevices = microphoneDevices.availableMicrophoneDevices
        let selectedInputLabel = CaptureDiagnosticsFormatter.selectedInputLabel(
            preferredName: audioCapturePreferencesStore.preferredMicrophoneName,
            availableNames: microphoneDevices.availableMicrophoneNames,
            defaultName: microphoneDevices.defaultMicrophoneName
        )
        let inputFormatLabel = audioCapture.inputFormatSnapshot.map {
            CaptureDiagnosticsFormatter.inputFormatLabel(
                sampleRate: $0.sampleRate,
                channelCount: $0.channelCount
            )
        } ?? "Unknown"
        let preferredName = audioCapturePreferencesStore.preferredMicrophoneName
        let segmentHoursBinding = Binding(
            get: { audioCapturePreferencesStore.maxSegmentDuration / 3600 },
            set: { audioCapturePreferencesStore.maxSegmentDuration = $0 * 3600 }
        )
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
                            if let message = audioCapture.deviceSelectionMessage {
                                Text(message)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
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
                    Text("Recordings are stored locally at \(recordingsPath)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    HStack {
                        Text("Max Segment Length")
                            .font(.subheadline)
                        Spacer()
                        Stepper(
                            value: segmentHoursBinding,
                            in: 0.5...6.0,
                            step: 0.5
                        ) {
                            Text(segmentDurationLabel(hours: segmentHoursBinding.wrappedValue))
                                .font(.subheadline)
                        }
                    }
                    Text("Long recordings are split into parts at this interval.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button("Open Recordings Folder") {
                        onOpenRecordingsFolder()
                    }
                    .buttonStyle(.bordered)
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
                    }
                    Button("Reset to Defaults") {
                        preferencesStore.resetToDefaults()
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
                    Text("Capture")
                        .font(.headline)
                    Toggle(
                        "Enable voice isolation (if supported)",
                        isOn: $audioCapturePreferencesStore.voiceIsolationEnabled
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Capture Diagnostics")
                            .font(.subheadline)
                        Text("Backend: \(audioCapture.backendStatus.message)")
                        Text("Selected Input: \(selectedInputLabel)")
                        Text("Format: \(inputFormatLabel)")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    Button("Test Mic") {
                        onRunMicTest()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canRunMicTest || audioCapture.isRecording || audioCapture.isTestingMic)
                    if let statusText = audioCapture.micTestStatusText {
                        Text(statusText)
                            .font(.footnote)
                            .foregroundColor(micTestStatusColor(for: audioCapture.micTestStatus))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            audioCapture.refreshDiagnostics()
        }
        .onChange(of: audioCapturePreferencesStore.voiceIsolationEnabled) { _ in
            audioCapture.refreshDiagnostics()
        }
        .onChange(of: audioCapturePreferencesStore.preferredMicrophoneName) { _ in
            audioCapture.refreshDiagnostics()
        }
        .onChange(of: microphoneDevices.availableMicrophoneNames) { _ in
            audioCapture.refreshDiagnostics()
        }
        .onChange(of: audioCapture.isRecording) { _ in
            audioCapture.refreshDiagnostics()
        }
        .onChange(of: audioCapture.isTestingMic) { _ in
            audioCapture.refreshDiagnostics()
        }
    }

    private func crutchWordsBinding() -> Binding<String> {
        Binding(
            get: { AnalysisPreferencesStore.formatCrutchWords(preferencesStore.crutchWords) },
            set: { preferencesStore.crutchWords = AnalysisPreferencesStore.parseCrutchWords(from: $0) }
        )
    }

    private func micTestStatusColor(for status: MicTestStatus) -> Color {
        switch status {
        case .idle:
            return .secondary
        case .running:
            return .secondary
        case .success:
            return .green
        case .failure:
            return .orange
        }
    }

    private func segmentDurationLabel(hours: Double) -> String {
        let rounded = (hours * 10).rounded() / 10
        if abs(rounded - rounded.rounded()) < 0.01 {
            let value = Int(rounded.rounded())
            return value == 1 ? "1 hr" : "\(value) hr"
        }
        return String(format: "%.1f hr", rounded)
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
        audioCapture: AudioCapture(capturePreferencesStore: AudioCapturePreferencesStore()),
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
        onOpenRecordingsFolder: {},
        onRunMicTest: {}
    )
}
