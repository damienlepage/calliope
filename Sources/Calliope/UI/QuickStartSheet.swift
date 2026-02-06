//
//  QuickStartSheet.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct QuickStartSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Start")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Before your first session, dial in your setup for the cleanest feedback.")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Call Readiness")
                    .font(.headline)
                ForEach(CallReadinessTips.items, id: \.self) { tip in
                    Text("• \(tip)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Privacy Guardrails")
                    .font(.headline)
                Text(PrivacyGuardrails.disclosureBody)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ForEach(PrivacyGuardrails.settingsStatements, id: \.self) { statement in
                    Text(statement)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Got It") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 440, minHeight: 360)
        .onDisappear {
            onDismiss()
        }
    }
}

#if DEBUG
struct QuickStartSheet_Previews: PreviewProvider {
    static var previews: some View {
        QuickStartSheet {}
    }
}
#endif
