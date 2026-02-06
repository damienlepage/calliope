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
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recordings")
                        .font(.headline)
                    if let summaryText = viewModel.recordingsSummaryText {
                        Text(summaryText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let recentSummaryText = viewModel.recentSummaryText {
                        Text(recentSummaryText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if let mostRecentText = viewModel.mostRecentRecordingText {
                        Text(mostRecentText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Text("Stored in \(viewModel.recordingsPath)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Refresh") {
                    viewModel.refreshRecordings()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isRecording)
                .accessibilityLabel("Refresh recordings")
                .accessibilityHint("Reload the recordings list.")
                Button("Open Folder") {
                    viewModel.openRecordingsFolder()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Open recordings folder")
                .accessibilityHint("Open the recordings folder in Finder.")
                Button("Delete All") {
                    viewModel.requestDeleteAll()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(viewModel.isRecording || viewModel.recordings.isEmpty)
                .accessibilityLabel("Delete all recordings")
                .accessibilityHint("Deletes every recording in the list.")
            }
            if viewModel.recordings.isEmpty {
                Text("No recordings yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                let isRecording = viewModel.isRecording
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
                            if let warningText = item.integrityWarningText {
                                Text(warningText)
                                    .font(.footnote)
                                    .foregroundColor(.orange)
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
                        .disabled(isRecording)
                        .accessibilityLabel(isPlaying ? "Pause playback" : "Play recording")
                        .accessibilityHint("Controls playback for \(item.displayName).")
                        Button("Stop") {
                            viewModel.stopPlayback()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!isActive || isRecording)
                        .accessibilityLabel("Stop playback")
                        .accessibilityHint("Stops playback for \(item.displayName).")
                        Button("Reveal") {
                            viewModel.reveal(item)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Reveal recording in Finder")
                        .accessibilityHint("Shows \(item.displayName) in Finder.")
                        Button("Details") {
                            viewModel.detailItem = item
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Show recording details")
                        .accessibilityHint("Opens details for \(item.displayName).")
                        Button("Delete") {
                            viewModel.requestDelete(item)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isRecording)
                        .accessibilityLabel("Delete recording")
                        .accessibilityHint("Deletes \(item.displayName).")
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
        .sheet(item: $viewModel.detailItem) { item in
            RecordingDetailView(item: item)
        }
        .alert(item: $viewModel.pendingDelete) { request in
            switch request {
            case .single(let item):
                return Alert(
                    title: Text("Delete recording?"),
                    message: Text("This will remove the recording and its analysis summary."),
                    primaryButton: .destructive(Text("Delete")) {
                        viewModel.confirmDelete(item)
                    },
                    secondaryButton: .cancel {
                        viewModel.cancelDelete()
                    }
                )
            case .all:
                return Alert(
                    title: Text("Delete all recordings?"),
                    message: Text("This will remove all recordings and their analysis summaries."),
                    primaryButton: .destructive(Text("Delete All")) {
                        viewModel.confirmDeleteAll()
                    },
                    secondaryButton: .cancel {
                        viewModel.cancelDelete()
                    }
                )
            }
        }
    }
}

#Preview {
    RecordingsListView(viewModel: RecordingListViewModel())
        .padding()
}
