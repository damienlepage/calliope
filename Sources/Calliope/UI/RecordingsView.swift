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
        VStack(alignment: .leading, spacing: 16) {
            RecordingsListView(
                viewModel: viewModel,
                onExportDiagnostics: onExportDiagnostics
            )
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    RecordingsView(viewModel: RecordingListViewModel()) {}
}
