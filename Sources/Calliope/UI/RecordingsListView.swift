//
//  RecordingsListView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct RecordingsListView: View {
    @ObservedObject var viewModel: RecordingListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recordings")
                .font(.headline)
            if viewModel.recordings.isEmpty {
                Text("No recordings yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.recordings) { item in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.displayName)
                                .font(.subheadline)
                            Text(item.detailText)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Reveal") {
                            viewModel.reveal(item)
                        }
                        .buttonStyle(.bordered)
                        Button("Delete") {
                            viewModel.delete(item)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            viewModel.loadRecordings()
        }
    }
}

#Preview {
    RecordingsListView(viewModel: RecordingListViewModel())
        .padding()
}
