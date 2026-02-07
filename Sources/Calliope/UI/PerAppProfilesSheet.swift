//
//  PerAppProfilesSheet.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct PerAppProfilesSheet: View {
    @ObservedObject var perAppProfileStore: PerAppFeedbackProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIdentifier: String?
    @State private var newIdentifier: String = ""

    var body: some View {
        let profiles = perAppProfileStore.profiles.sorted { $0.appIdentifier < $1.appIdentifier }
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Manage Per-App Profiles")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Profiles")
                        .font(.headline)
                    List(selection: $selectedIdentifier) {
                        ForEach(profiles) { profile in
                            Text(profile.appIdentifier)
                                .tag(profile.appIdentifier as String?)
                        }
                    }
                    .frame(minWidth: 220, minHeight: 260)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Profile")
                            .font(.headline)
                        TextField("Bundle identifier", text: $newIdentifier)
                            .textFieldStyle(.roundedBorder)
                        Text("Examples: us.zoom.xos, com.microsoft.teams, com.google.Chrome")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Add Profile") {
                            if let created = perAppProfileStore.addProfile(appIdentifier: newIdentifier) {
                                selectedIdentifier = created.appIdentifier
                                newIdentifier = ""
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(newIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Profile Details")
                        .font(.headline)
                    Text("Use the app bundle identifier shown in Activity Monitor or System Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let selectedIdentifier,
                       let profile = perAppProfileStore.profile(for: selectedIdentifier) {
                        PerAppProfileEditor(
                            profile: binding(for: selectedIdentifier),
                            onDelete: {
                                perAppProfileStore.removeProfile(appIdentifier: selectedIdentifier)
                                if let next = perAppProfileStore.profiles.sorted(
                                    by: { $0.appIdentifier < $1.appIdentifier }
                                ).first {
                                    self.selectedIdentifier = next.appIdentifier
                                } else {
                                    self.selectedIdentifier = nil
                                }
                            }
                        )
                        .id(profile.appIdentifier)
                    } else {
                        Text("Select a profile to edit pace, pauses, and crutch words.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(minWidth: 740, minHeight: 420)
        .onAppear {
            if selectedIdentifier == nil {
                selectedIdentifier = profiles.first?.appIdentifier
            }
        }
        .onChange(of: profiles.map(\.appIdentifier)) { identifiers in
            if let selectedIdentifier, !identifiers.contains(selectedIdentifier) {
                self.selectedIdentifier = identifiers.first
            } else if selectedIdentifier == nil {
                self.selectedIdentifier = identifiers.first
            }
        }
    }

    private func binding(for appIdentifier: String) -> Binding<PerAppFeedbackProfile> {
        Binding(
            get: {
                perAppProfileStore.profile(for: appIdentifier)
                    ?? PerAppFeedbackProfile.default(for: appIdentifier)
            },
            set: { updated in
                perAppProfileStore.setProfile(updated)
            }
        )
    }
}

private struct PerAppProfileEditor: View {
    @Binding var profile: PerAppFeedbackProfile
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(profile.appIdentifier)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Delete Profile", role: .destructive) {
                    onDelete()
                }
            }
            HStack {
                Text("Pace Min")
                    .font(.subheadline)
                Spacer()
                Stepper(value: paceMinBinding, in: 60...220, step: 5) {
                    Text("\(Int(profile.paceMin)) WPM")
                        .font(.subheadline)
                }
            }
            HStack {
                Text("Pace Max")
                    .font(.subheadline)
                Spacer()
                Stepper(value: paceMaxBinding, in: 80...260, step: 5) {
                    Text("\(Int(profile.paceMax)) WPM")
                        .font(.subheadline)
                }
            }
            HStack {
                Text("Pause Threshold")
                    .font(.subheadline)
                Spacer()
                Stepper(value: pauseThresholdBinding, in: 0.5...5.0, step: 0.1) {
                    Text(String(format: "%.1f s", profile.pauseThreshold))
                        .font(.subheadline)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Crutch Words (comma or newline separated)")
                    .font(.subheadline)
                TextField("uh, um, you know", text: crutchWordsBinding)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Text("Presets")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Menu("Choose") {
                        ForEach(AnalysisPreferencesStore.crutchWordPresets) { preset in
                            Button(preset.name) {
                                profile.crutchWords = preset.words
                            }
                        }
                    }
                }
                Text("Selecting a preset replaces the current list.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var paceMinBinding: Binding<Double> {
        Binding(
            get: { profile.paceMin },
            set: { newValue in
                profile.paceMin = newValue
                if profile.paceMin > profile.paceMax {
                    profile.paceMax = profile.paceMin
                }
            }
        )
    }

    private var paceMaxBinding: Binding<Double> {
        Binding(
            get: { profile.paceMax },
            set: { newValue in
                profile.paceMax = newValue
                if profile.paceMax < profile.paceMin {
                    profile.paceMin = profile.paceMax
                }
            }
        )
    }

    private var pauseThresholdBinding: Binding<Double> {
        Binding(
            get: { profile.pauseThreshold },
            set: { newValue in
                profile.pauseThreshold = newValue
            }
        )
    }

    private var crutchWordsBinding: Binding<String> {
        Binding(
            get: { AnalysisPreferencesStore.formatCrutchWords(profile.crutchWords) },
            set: { newValue in
                profile.crutchWords = AnalysisPreferencesStore.parseCrutchWords(from: newValue)
            }
        )
    }
}

#Preview {
    PerAppProfilesSheet(perAppProfileStore: PerAppFeedbackProfileStore())
}
