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
            HStack {
                Text("Recordings")
                    .font(.headline)
                Spacer()
                Button("Open Folder") {
                    viewModel.openRecordingsFolder()
                }
                .buttonStyle(.bordered)
            }
            if viewModel.recordings.isEmpty {
                Text("No recordings yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.recordings) { item in
                    let isActive = viewModel.activePlaybackURL == item.url
                    let isPaused = isActive && viewModel.isPlaybackPaused
                    let isPlaying = isActive && !viewModel.isPlaybackPaused
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.displayName)
                                .font(.subheadline)
                            Text(item.detailText)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            if let summaryText = item.summaryText {
                                Text(summaryText)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            if isPlaying {
                                Text("Playing")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            } else if isPaused {
                                Text("Paused")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button(isPlaying ? "Pause" : "Play") {
                            viewModel.togglePlayPause(item)
                        }
                        .buttonStyle(.bordered)
                        Button("Stop") {
                            viewModel.stopPlayback()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!isActive)
                        Button("Reveal") {
                            viewModel.reveal(item)
                        }
                        .buttonStyle(.bordered)
                        Button("Delete") {
                            viewModel.requestDelete(item)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }
            if let deleteErrorMessage = viewModel.deleteErrorMessage {
                Text(deleteErrorMessage)
                    .font(.footnote)
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            viewModel.loadRecordings()
        }
        .alert(item: $viewModel.pendingDelete) { item in
            Alert(
                title: Text("Delete recording?"),
                message: Text("This will remove the recording and its analysis summary."),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.confirmDelete(item)
                },
                secondaryButton: .cancel {
                    viewModel.cancelDelete()
                }
            )
        }
    }
}

#Preview {
    RecordingsListView(viewModel: RecordingListViewModel())
        .padding()
}
