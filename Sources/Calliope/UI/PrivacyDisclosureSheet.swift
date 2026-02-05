//
//  PrivacyDisclosureSheet.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct PrivacyDisclosureSheet: View {
    let recordingsPath: String
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(PrivacyGuardrails.disclosureTitle)
                .font(.title2)
                .fontWeight(.semibold)

            Text(PrivacyGuardrails.disclosureBody)
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(PrivacyGuardrails.settingsStatements, id: \.self) { statement in
                    Text(statement)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text("Recordings are stored locally at \(recordingsPath)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                Spacer()
                Button("I Accept") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 320)
    }
}

#if DEBUG
struct PrivacyDisclosureSheet_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyDisclosureSheet(recordingsPath: "/Users/example/Calliope/Recordings") {}
    }
}
#endif
