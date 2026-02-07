//
//  RecordingsListView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct RecordingsListView: View {
    @ObservedObject var viewModel: RecordingListViewModel
    private enum Layout {
        static let recordingColumnMin: CGFloat = 180
        static let recordingColumnIdeal: CGFloat = 240
        static let recordingColumnMax: CGFloat = 320
        static let dateColumnMin: CGFloat = 110
        static let dateColumnIdeal: CGFloat = 130
        static let dateColumnMax: CGFloat = 160
        static let durationColumnMin: CGFloat = 80
        static let durationColumnIdeal: CGFloat = 90
        static let durationColumnMax: CGFloat = 110
        static let speakingColumnMin: CGFloat = 90
        static let speakingColumnIdeal: CGFloat = 100
        static let speakingColumnMax: CGFloat = 120
        static let statusColumnMin: CGFloat = 70
        static let statusColumnIdeal: CGFloat = 90
        static let statusColumnMax: CGFloat = 110
        static let actionsColumnMin: CGFloat = 80
        static let actionsColumnIdeal: CGFloat = 100
        static let actionsColumnMax: CGFloat = 120
    }

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
                    if let trendSummaryText = viewModel.trendSummaryText {
                        Text(trendSummaryText)
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
                .accessibilityElement(children: .combine)
                Spacer()
                TextField("Search recordings", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                    .accessibilityLabel("Search recordings")
                    .accessibilityHint("Filters recordings by name.")
                Picker("Sort recordings", selection: $viewModel.sortOption) {
                    ForEach(RecordingSortOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Sort recordings")
                .accessibilityHint("Choose a sort order for the recordings list.")
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
                Table(viewModel.recordings) {
                    TableColumn("Recording") { item in
                        Text(item.displayName)
                            .font(.subheadline)
                            .lineLimit(1)
                            .accessibilityLabel("Recording name")
                            .accessibilityValue(item.displayName)
                    }
                    .width(
                        min: Layout.recordingColumnMin,
                        ideal: Layout.recordingColumnIdeal,
                        max: Layout.recordingColumnMax
                    )
                    TableColumn("Date") { item in
                        Text(item.dateText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Recording date")
                            .accessibilityValue(item.dateText)
                    }
                    .width(
                        min: Layout.dateColumnMin,
                        ideal: Layout.dateColumnIdeal,
                        max: Layout.dateColumnMax
                    )
                    TableColumn("Duration") { item in
                        Text(item.durationText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Recording duration")
                            .accessibilityValue(item.durationText)
                    }
                    .width(
                        min: Layout.durationColumnMin,
                        ideal: Layout.durationColumnIdeal,
                        max: Layout.durationColumnMax
                    )
                    TableColumn("Speaking %") { item in
                        Text(item.speakingPercentText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Speaking time percentage")
                            .accessibilityValue(item.speakingPercentText)
                    }
                    .width(
                        min: Layout.speakingColumnMin,
                        ideal: Layout.speakingColumnIdeal,
                        max: Layout.speakingColumnMax
                    )
                    TableColumn("Status") { item in
                        if let integrityText = item.integrityStatusText {
                            Label("Issue", systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundColor(.orange)
                                .help(integrityText)
                                .accessibilityLabel("Recording status")
                                .accessibilityValue(integrityText)
                        } else {
                            Label("OK", systemImage: "checkmark.circle")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Recording status")
                                .accessibilityValue("No issues detected")
                        }
                    }
                    .width(
                        min: Layout.statusColumnMin,
                        ideal: Layout.statusColumnIdeal,
                        max: Layout.statusColumnMax
                    )
                    TableColumn("Actions") { item in
                        let isActive = viewModel.activePlaybackURL == item.url
                        let isPlaying = isActive && !viewModel.isPlaybackPaused
                        HStack(spacing: 8) {
                            Button {
                                viewModel.togglePlayPause(item)
                            } label: {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            }
                            .buttonStyle(.bordered)
                            .disabled(isRecording)
                            .accessibilityLabel(isPlaying ? "Pause playback" : "Play recording")
                            .accessibilityHint("Controls playback for \(item.displayName).")

                            Menu {
                                Button("Stop") {
                                    viewModel.stopPlayback()
                                }
                                .disabled(!isActive || isRecording)
                                Button("Reveal") {
                                    viewModel.reveal(item)
                                }
                                Button("Details") {
                                    viewModel.detailItem = item
                                }
                                Button("Delete", role: .destructive) {
                                    viewModel.requestDelete(item)
                                }
                                .disabled(isRecording)
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .menuStyle(.borderedButton)
                            .accessibilityLabel("Recording actions")
                            .accessibilityHint("Show actions for \(item.displayName).")
                        }
                    }
                    .width(
                        min: Layout.actionsColumnMin,
                        ideal: Layout.actionsColumnIdeal,
                        max: Layout.actionsColumnMax
                    )
                }
            }
            if let deleteErrorMessage = viewModel.deleteErrorMessage {
                Text(deleteErrorMessage)
                    .font(.footnote)
                    .foregroundColor(.orange)
                    .accessibilityLabel("Warning")
                    .accessibilityValue(deleteErrorMessage)
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
