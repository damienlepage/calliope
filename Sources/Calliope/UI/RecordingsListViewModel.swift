//
//  RecordingsListViewModel.swift
//  Calliope
//
//  Created on [Date]
//

import AppKit
import AVFoundation
import Combine
import Foundation

protocol RecordingManaging {
    func getAllRecordings() -> [URL]
    func deleteRecording(at url: URL) throws
    func recordingsDirectoryURL() -> URL
}

extension RecordingManager: RecordingManaging {}

protocol WorkspaceOpening {
    func activateFileViewerSelecting(_ fileURLs: [URL])
}

extension NSWorkspace: WorkspaceOpening {}

struct RecordingItem: Identifiable, Equatable {
    let url: URL
    let modifiedAt: Date
    let duration: TimeInterval?
    let fileSizeBytes: Int?
    let summary: AnalysisSummary?

    var id: URL { url }
    var displayName: String { url.lastPathComponent }
    var detailText: String {
        let dateText = modifiedAt.formatted(date: .abbreviated, time: .shortened)
        let details = [
            RecordingItem.formatDuration(duration),
            RecordingItem.formatFileSize(fileSizeBytes)
        ].compactMap { $0 }
        guard !details.isEmpty else {
            return dateText
        }
        return ([dateText] + details).joined(separator: " • ")
    }
    var summaryText: String? {
        guard let summary else { return nil }
        let pace = Int(summary.pace.averageWPM.rounded())
        let pieces = [
            "Avg \(pace) WPM",
            "Pauses \(summary.pauses.count)",
            "Crutch \(summary.crutchWords.totalCount)"
        ]
        return pieces.joined(separator: " • ")
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    private static func formatDuration(_ duration: TimeInterval?) -> String? {
        guard let duration, duration > 0 else {
            return nil
        }
        return durationFormatter.string(from: duration)
    }

    private static func formatFileSize(_ bytes: Int?) -> String? {
        guard let bytes, bytes > 0 else {
            return nil
        }
        return sizeFormatter.string(fromByteCount: Int64(bytes))
    }
}

@MainActor
final class RecordingListViewModel: ObservableObject {
    @Published private(set) var recordings: [RecordingItem] = []

    private let manager: RecordingManaging
    private let workspace: WorkspaceOpening
    private let modificationDateProvider: (URL) -> Date
    private let durationProvider: (URL) -> TimeInterval?
    private let fileSizeProvider: (URL) -> Int?
    private let summaryProvider: (URL) -> AnalysisSummary?
    private var cancellables = Set<AnyCancellable>()

    init(
        manager: RecordingManaging = RecordingManager.shared,
        workspace: WorkspaceOpening = NSWorkspace.shared,
        modificationDateProvider: @escaping (URL) -> Date = RecordingListViewModel.defaultModificationDate,
        durationProvider: @escaping (URL) -> TimeInterval? = RecordingListViewModel.defaultDuration,
        fileSizeProvider: @escaping (URL) -> Int? = RecordingListViewModel.defaultFileSize,
        summaryProvider: @escaping (URL) -> AnalysisSummary? = RecordingListViewModel.defaultSummary
    ) {
        self.manager = manager
        self.workspace = workspace
        self.modificationDateProvider = modificationDateProvider
        self.durationProvider = durationProvider
        self.fileSizeProvider = fileSizeProvider
        self.summaryProvider = summaryProvider
    }

    func loadRecordings() {
        let urls = manager.getAllRecordings()
        recordings = urls.map { url in
            RecordingItem(
                url: url,
                modifiedAt: modificationDateProvider(url),
                duration: durationProvider(url),
                fileSizeBytes: fileSizeProvider(url),
                summary: summaryProvider(url)
            )
        }
    }

    func bind(recordingPublisher: AnyPublisher<Bool, Never>) {
        recordingPublisher
            .removeDuplicates()
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.loadRecordings()
            }
            .store(in: &cancellables)
    }

    func reveal(_ item: RecordingItem) {
        workspace.activateFileViewerSelecting([item.url])
    }

    func openRecordingsFolder() {
        workspace.activateFileViewerSelecting([manager.recordingsDirectoryURL()])
    }

    func delete(_ item: RecordingItem) {
        do {
            try manager.deleteRecording(at: item.url)
        } catch {
            return
        }
        loadRecordings()
    }

    private static func defaultModificationDate(_ url: URL) -> Date {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate ?? .distantPast
    }

    private static func defaultDuration(_ url: URL) -> TimeInterval? {
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        guard duration.isNumeric else {
            return nil
        }
        let seconds = CMTimeGetSeconds(duration)
        return seconds > 0 ? seconds : nil
    }

    private static func defaultFileSize(_ url: URL) -> Int? {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return values?.fileSize
    }

    private static func defaultSummary(_ url: URL) -> AnalysisSummary? {
        let summaryURL = url
            .deletingPathExtension()
            .appendingPathExtension("summary.json")
        guard let data = try? Data(contentsOf: summaryURL) else {
            return nil
        }
        return try? JSONDecoder().decode(AnalysisSummary.self, from: data)
    }
}
