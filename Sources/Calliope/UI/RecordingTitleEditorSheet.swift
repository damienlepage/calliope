//
//  RecordingTitleEditorSheet.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct RecordingTitleEditorSheet: View {
    let recordingName: String
    let defaultTitle: String
    @Binding var draft: String
    let onSave: () -> Void
    let onCancel: () -> Void
    let onReset: () -> Void

    var body: some View {
        let state = RecordingTitleEditState(draft: draft, defaultTitle: defaultTitle)
        let helperColor: Color = state.helperTone == .warning ? .orange : .secondary
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit recording title")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(recordingName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            TextField("Title", text: $draft)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Recording title")
                .accessibilityHint("Enter a title for this recording.")
            Text(state.helperText)
                .font(.footnote)
                .foregroundColor(helperColor)
            HStack(spacing: 12) {
                Button("Save", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .disabled(!state.isValid)
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                Button("Reset to Default", action: onReset)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(minWidth: 360)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Edit recording title")
    }
}

#Preview {
    RecordingTitleEditorSheet(
        recordingName: "Jan 1 at 9:00am - 12min - Team Sync",
        defaultTitle: "Session Jan 1 at 9:00am",
        draft: .constant("Team Sync"),
        onSave: {},
        onCancel: {},
        onReset: {}
    )
}
