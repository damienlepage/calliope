//
//  SessionTitlePromptSheet.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct SessionTitlePromptSheet: View {
    let defaultTitle: String
    @Binding var draft: String
    let onSave: () -> Void
    let onSkip: () -> Void

    var body: some View {
        let state = SessionTitlePromptState(draft: draft, defaultTitle: defaultTitle)
        let helperColor: Color = state.helperTone == .warning ? .orange : .secondary

        VStack(alignment: .leading, spacing: 12) {
            Text("Add a session title?")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(defaultTitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            TextField("Title (optional)", text: $draft)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Session title")
                .accessibilityHint("Enter an optional title for this session.")
            Text(state.helperText)
                .font(.footnote)
                .foregroundColor(helperColor)
            HStack(spacing: 12) {
                Button("Save", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .disabled(!state.isValid)
                Button("Skip", action: onSkip)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(minWidth: 360)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Session title prompt")
    }
}

#Preview {
    SessionTitlePromptSheet(
        defaultTitle: "Session Feb 8 at 9:00am",
        draft: .constant("1:1 with Alex"),
        onSave: {},
        onSkip: {}
    )
}
