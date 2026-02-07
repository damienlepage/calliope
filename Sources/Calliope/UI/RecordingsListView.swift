//
//  RecordingsListView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct RecordingsListView: View {
    @ObservedObject var viewModel: RecordingListViewModel
    let onExportDiagnostics: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    summaryBlock
                    Spacer()
                    controlsExpanded
                }
                VStack(alignment: .leading, spacing: 12) {
                    summaryBlock
                    controlsCompact
                }
            }
            if viewModel.recordings.isEmpty {
                Text("No recordings yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("No recordings yet")
                    .accessibilityHint("Start a session to create a recording.")
            } else {
                if RecordingsListLayout.usesAccessibilityLayout(dynamicTypeSize: dynamicTypeSize) {
                    accessibleList
                } else {
                    tableList
                }
            }
            if let deleteErrorMessage = viewModel.deleteErrorMessage {
                Label {
                    Text(deleteErrorMessage)
                        .font(.footnote)
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
                .accessibilityLabel("Warning")
                .accessibilityValue(deleteErrorMessage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            viewModel.loadRecordings()
        }
        .sheet(item: $viewModel.detailItem) { item in
            RecordingDetailView(item: item) {
                viewModel.requestEditTitle(item)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { viewModel.titleEditItem != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.cancelTitleEdit()
                    }
                }
            )
        ) {
            if let item = viewModel.titleEditItem {
                RecordingTitleEditorSheet(
                    recordingName: item.displayName,
                    defaultTitle: viewModel.titleEditDefaultTitle,
                    draft: $viewModel.titleEditDraft,
                    onSave: viewModel.saveTitleEdit,
                    onCancel: viewModel.cancelTitleEdit,
                    onReset: viewModel.resetTitleEdit
                )
            }
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

private extension RecordingsListView {
    var summaryBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Recordings")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
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
        .accessibilityLabel("Recordings summary")
        .accessibilityValue(summaryAccessibilityValue)
    }

    var controlsExpanded: some View {
        HStack(alignment: .center, spacing: 8) {
            searchField
            sortPicker
            refreshButton
            openFolderButton
            exportDiagnosticsButton
            deleteAllButton
        }
    }

    var controlsCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                searchField
                sortPicker
            }
            HStack(spacing: 8) {
                refreshButton
                openFolderButton
                exportDiagnosticsButton
                deleteAllButton
            }
        }
    }

    var searchField: some View {
        TextField("Search recordings", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
            .frame(minWidth: 200, idealWidth: 240, maxWidth: 320)
            .layoutPriority(1)
            .accessibilityLabel("Search recordings")
            .accessibilityHint("Filters recordings by name.")
    }

    var sortPicker: some View {
        Picker("Sort recordings", selection: $viewModel.sortOption) {
            ForEach(RecordingSortOption.allCases) { option in
                Text(option.label).tag(option)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Sort recordings")
        .accessibilityHint("Choose a sort order for the recordings list.")
    }

    var refreshButton: some View {
        Button("Refresh") {
            viewModel.refreshRecordings()
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.isRecording)
        .accessibilityLabel("Refresh recordings")
        .accessibilityHint("Reload the recordings list.")
    }

    var openFolderButton: some View {
        Button("Open Folder") {
            viewModel.openRecordingsFolder()
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Open recordings folder")
        .accessibilityHint("Open the recordings folder in Finder.")
    }

    var exportDiagnosticsButton: some View {
        Button("Export Diagnostics") {
            onExportDiagnostics()
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Export diagnostics")
        .accessibilityHint("Create a diagnostics report for support.")
    }

    var deleteAllButton: some View {
        Button("Delete All") {
            viewModel.requestDeleteAll()
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .disabled(viewModel.isRecording || viewModel.recordings.isEmpty)
        .accessibilityLabel("Delete all recordings")
        .accessibilityHint("Deletes every recording in the list.")
    }
}

private extension RecordingsListView {
    var summaryAccessibilityValue: String {
        var lines: [String] = []
        if let summaryText = viewModel.recordingsSummaryText {
            lines.append(summaryText)
        }
        if let recentSummaryText = viewModel.recentSummaryText {
            lines.append(recentSummaryText)
        }
        if let trendSummaryText = viewModel.trendSummaryText {
            lines.append(trendSummaryText)
        }
        if let mostRecentText = viewModel.mostRecentRecordingText {
            lines.append(mostRecentText)
        }
        lines.append("Stored in \(viewModel.recordingsPath)")
        return AccessibilityFormatting.detailLinesValue(lines)
    }

    var tableList: some View {
        let isRecording = viewModel.isRecording
        return Table(viewModel.recordings) {
            TableColumn("Recording") { item in
                Text(item.displayName)
                    .font(.subheadline)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)
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
                recordingStatusLabel(for: item)
            }
            .width(
                min: Layout.statusColumnMin,
                ideal: Layout.statusColumnIdeal,
                max: Layout.statusColumnMax
            )
            TableColumn("Actions") { item in
                recordingActions(for: item, isRecording: isRecording)
            }
            .width(
                min: Layout.actionsColumnMin,
                ideal: Layout.actionsColumnIdeal,
                max: Layout.actionsColumnMax
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Recordings list")
        .accessibilityHint("Shows recording name, date, duration, speaking percentage, status, and actions.")
    }

    var accessibleList: some View {
        let isRecording = viewModel.isRecording
        return LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.recordings) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.displayName)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date: \(item.dateText)")
                        Text("Duration: \(item.durationText)")
                        Text("Speaking: \(item.speakingPercentText)")
                        Text("Status: \(item.integrityStatusText ?? "OK")")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    recordingActions(for: item, isRecording: isRecording)
                }
                .padding(12)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.12))
                )
                .cornerRadius(10)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(item.displayName)
                .accessibilityValue(
                    AccessibilityFormatting.detailLinesValue([
                        "Date: \(item.dateText)",
                        "Duration: \(item.durationText)",
                        "Speaking: \(item.speakingPercentText)",
                        "Status: \(item.integrityStatusText ?? "OK")"
                    ])
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Recordings list")
        .accessibilityHint("Shows recording details and actions in a stacked layout.")
    }

    @ViewBuilder
    func recordingStatusLabel(for item: RecordingItem) -> some View {
        if let integrityText = item.integrityStatusText {
            Label {
                Text(integrityText)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
            .help(integrityText)
            .accessibilityLabel("Recording status")
            .accessibilityValue(integrityText)
            .accessibilityHint("Status for \(item.displayName).")
        } else {
            Label {
                Text("OK")
                    .font(.footnote)
                    .foregroundColor(.primary)
            } icon: {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Recording status")
            .accessibilityValue("No issues detected")
            .accessibilityHint("Status for \(item.displayName).")
        }
    }

    @ViewBuilder
    func recordingActions(for item: RecordingItem, isRecording: Bool) -> some View {
        let isActive = viewModel.activePlaybackURL == item.url
        let isPlaying = isActive && !viewModel.isPlaybackPaused
        let availability = viewModel.actionAvailability(for: item)
        HStack(spacing: 8) {
            Button {
                viewModel.togglePlayPause(item)
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.bordered)
            .disabled(!availability.canPlay)
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
                .disabled(!availability.canReveal)
                Button("Edit Title") {
                    viewModel.requestEditTitle(item)
                }
                .disabled(isRecording)
                Button("Details") {
                    viewModel.detailItem = item
                }
                Button("Delete", role: .destructive) {
                    viewModel.requestDelete(item)
                }
                .disabled(!availability.canDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderedButton)
            .accessibilityLabel("Recording actions")
            .accessibilityHint("Show actions for \(item.displayName).")
        }
    }
}

enum RecordingsListLayout {
    static func usesAccessibilityLayout(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }
}

#Preview {
    RecordingsListView(viewModel: RecordingListViewModel()) {}
        .padding()
}
