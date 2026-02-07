//
//  RecordingsView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct RecordingsView: View {
    @ObservedObject var viewModel: RecordingListViewModel
    let onExportDiagnostics: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Recordings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                RecordingsListView(
                    viewModel: viewModel,
                    onExportDiagnostics: onExportDiagnostics
                )
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RecordingsView(viewModel: RecordingListViewModel()) {}
}
