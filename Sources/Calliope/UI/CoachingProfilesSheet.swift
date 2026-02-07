//
//  CoachingProfilesSheet.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct CoachingProfilesSheet: View {
    @ObservedObject var coachingProfileStore: CoachingProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProfileID: UUID?
    @State private var newName: String = ""

    var body: some View {
        let profiles = coachingProfileStore.profiles.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Manage Coaching Profiles")
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
                    List(selection: $selectedProfileID) {
                        ForEach(profiles) { profile in
                            Text(profile.name)
                                .tag(profile.id as UUID?)
                        }
                    }
                    .frame(minWidth: 220, minHeight: 260)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Profile")
                            .font(.headline)
                        TextField("Profile name", text: $newName)
                            .textFieldStyle(.roundedBorder)
                        Button("Add Profile") {
                            if let created = coachingProfileStore.addProfile(name: newName) {
                                selectedProfileID = created.id
                                newName = ""
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Profile Details")
                        .font(.headline)
                    Text("Set pace, pause, and crutch-word targets for each profile.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let selectedProfileID,
                       let profile = coachingProfileStore.profiles.first(where: { $0.id == selectedProfileID }) {
                        CoachingProfileEditor(
                            profile: binding(for: selectedProfileID),
                            canDelete: coachingProfileStore.profiles.count > 1,
                            onDelete: {
                                coachingProfileStore.removeProfile(id: selectedProfileID)
                                if let next = coachingProfileStore.profiles.sorted(
                                    by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                                ).first {
                                    self.selectedProfileID = next.id
                                } else {
                                    self.selectedProfileID = nil
                                }
                            }
                        )
                        .id(profile.id)
                    } else {
                        Text("Select a profile to edit its name and preferences.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(minWidth: 740, minHeight: 440)
        .onAppear {
            if selectedProfileID == nil {
                selectedProfileID = profiles.first?.id
            }
        }
        .onChange(of: profiles.map(\.id)) { identifiers in
            if let selectedProfileID, !identifiers.contains(selectedProfileID) {
                self.selectedProfileID = identifiers.first
            } else if selectedProfileID == nil {
                self.selectedProfileID = identifiers.first
            }
        }
    }

    private func binding(for profileID: UUID) -> Binding<CoachingProfile> {
        Binding(
            get: {
                coachingProfileStore.profiles.first(where: { $0.id == profileID })
                    ?? CoachingProfile.default()
            },
            set: { updated in
                coachingProfileStore.setProfile(updated)
            }
        )
    }
}

private struct CoachingProfileEditor: View {
    @Binding var profile: CoachingProfile
    let canDelete: Bool
    let onDelete: () -> Void
    @State private var isDeleteConfirmationPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Profile name", text: nameBinding)
                    .textFieldStyle(.roundedBorder)
                Button("Delete Profile", role: .destructive) {
                    isDeleteConfirmationPresented = true
                }
                .disabled(!canDelete)
                .confirmationDialog(
                    "Delete this coaching profile?",
                    isPresented: $isDeleteConfirmationPresented
                ) {
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This cannot be undone.")
                }
            }
            if !canDelete {
                Text("At least one profile is required.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("Pace Min")
                    .font(.subheadline)
                Spacer()
                Stepper(value: paceMinBinding, in: 60...220, step: 5) {
                    Text("\(Int(profile.preferences.paceMin)) WPM")
                        .font(.subheadline)
                }
            }
            HStack {
                Text("Pace Max")
                    .font(.subheadline)
                Spacer()
                Stepper(value: paceMaxBinding, in: 80...260, step: 5) {
                    Text("\(Int(profile.preferences.paceMax)) WPM")
                        .font(.subheadline)
                }
            }
            HStack {
                Text("Pause Threshold")
                    .font(.subheadline)
                Spacer()
                Stepper(value: pauseThresholdBinding, in: 0.5...5.0, step: 0.1) {
                    Text(String(format: "%.1f s", profile.preferences.pauseThreshold))
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
                                profile.preferences.crutchWords = preset.words
                            }
                        }
                    }
                }
                Text("Current preset: \(AnalysisPreferencesStore.crutchWordPresetLabel(for: profile.preferences.crutchWords))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text("Selecting a preset replaces the current list.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text("Tip: multi-word phrases are supported (for example, \"you know\" or \"kind of\").")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { profile.name },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return
                }
                profile.name = newValue
            }
        )
    }

    private var paceMinBinding: Binding<Double> {
        Binding(
            get: { profile.preferences.paceMin },
            set: { newValue in
                profile.preferences.paceMin = newValue
                if profile.preferences.paceMin > profile.preferences.paceMax {
                    profile.preferences.paceMax = profile.preferences.paceMin
                }
            }
        )
    }

    private var paceMaxBinding: Binding<Double> {
        Binding(
            get: { profile.preferences.paceMax },
            set: { newValue in
                profile.preferences.paceMax = newValue
                if profile.preferences.paceMax < profile.preferences.paceMin {
                    profile.preferences.paceMin = profile.preferences.paceMax
                }
            }
        )
    }

    private var pauseThresholdBinding: Binding<Double> {
        Binding(
            get: { profile.preferences.pauseThreshold },
            set: { newValue in
                profile.preferences.pauseThreshold = newValue
            }
        )
    }

    private var crutchWordsBinding: Binding<String> {
        Binding(
            get: { AnalysisPreferencesStore.formatCrutchWords(profile.preferences.crutchWords) },
            set: { newValue in
                profile.preferences.crutchWords = AnalysisPreferencesStore.parseCrutchWords(from: newValue)
            }
        )
    }
}

#Preview {
    CoachingProfilesSheet(coachingProfileStore: CoachingProfileStore())
}
