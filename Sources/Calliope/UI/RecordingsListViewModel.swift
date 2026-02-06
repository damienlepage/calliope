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

protocol AudioPlaying: AnyObject {
    var isPlaying: Bool { get }
    var onPlaybackEnded: (() -> Void)? { get set }
    func play() -> Bool
    func pause()
    func stop()
}

final class SystemAudioPlayer: NSObject, AudioPlaying, AVAudioPlayerDelegate {
    private let player: AVAudioPlayer
    var onPlaybackEnded: (() -> Void)?

    init(url: URL) throws {
        player = try AVAudioPlayer(contentsOf: url)
        super.init()
        player.delegate = self
        player.prepareToPlay()
    }

    var isPlaying: Bool {
        player.isPlaying
    }

    func play() -> Bool {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.stop()
        player.currentTime = 0
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onPlaybackEnded?()
    }
}

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
    @Published var pendingDelete: RecordingItem?
    @Published var deleteErrorMessage: String?
    @Published private(set) var activePlaybackURL: URL?
    @Published private(set) var isPlaybackPaused = false
    @Published private(set) var isRecording = false

    var recordingsSummaryText: String? {
        let count = recordings.count
        guard count > 0 else {
            return nil
        }
        let countText = count == 1 ? "1 recording" : "\(count) recordings"
        let totalDuration = recordings
            .compactMap(\.duration)
            .filter { $0 > 0 }
            .reduce(0, +)
        guard totalDuration > 0,
              let durationText = Self.totalDurationFormatter.string(from: totalDuration) else {
            return countText
        }
        return "\(countText) • \(durationText) total"
    }

    private let manager: RecordingManaging
    private let workspace: WorkspaceOpening
    private let modificationDateProvider: @MainActor (URL) -> Date
    private let durationProvider: @MainActor (URL) -> TimeInterval?
    private let fileSizeProvider: @MainActor (URL) -> Int?
    private let summaryProvider: @MainActor (URL) -> AnalysisSummary?
    private let audioPlayerFactory: (URL) throws -> AudioPlaying
    private var audioPlayer: AudioPlaying?
    private var cancellables = Set<AnyCancellable>()

    private static let totalDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    init(
        manager: RecordingManaging = RecordingManager.shared,
        workspace: WorkspaceOpening = NSWorkspace.shared,
        modificationDateProvider: @escaping @MainActor (URL) -> Date = RecordingListViewModel.defaultModificationDate,
        durationProvider: @escaping @MainActor (URL) -> TimeInterval? = RecordingListViewModel.defaultDuration,
        fileSizeProvider: @escaping @MainActor (URL) -> Int? = RecordingListViewModel.defaultFileSize,
        summaryProvider: @escaping @MainActor (URL) -> AnalysisSummary? = RecordingListViewModel.defaultSummary,
        audioPlayerFactory: @escaping (URL) throws -> AudioPlaying = { url in
            try SystemAudioPlayer(url: url)
        }
    ) {
        self.manager = manager
        self.workspace = workspace
        self.modificationDateProvider = modificationDateProvider
        self.durationProvider = durationProvider
        self.fileSizeProvider = fileSizeProvider
        self.summaryProvider = summaryProvider
        self.audioPlayerFactory = audioPlayerFactory
    }

    func loadRecordings() {
        deleteErrorMessage = nil
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
            .sink { [weak self] isRecording in
                guard let self else { return }
                self.isRecording = isRecording
                if isRecording {
                    self.stopPlayback()
                } else {
                    self.loadRecordings()
                }
            }
            .store(in: &cancellables)
    }

    func reveal(_ item: RecordingItem) {
        workspace.activateFileViewerSelecting([item.url])
    }

    func openRecordingsFolder() {
        workspace.activateFileViewerSelecting([manager.recordingsDirectoryURL()])
    }

    func requestDelete(_ item: RecordingItem) {
        pendingDelete = item
    }

    func confirmDelete(_ item: RecordingItem) {
        pendingDelete = nil
        deleteErrorMessage = nil
        if item.url == activePlaybackURL {
            stopPlayback()
        }
        do {
            try manager.deleteRecording(at: item.url)
        } catch {
            deleteErrorMessage = "Unable to delete recording. Please try again."
            return
        }
        loadRecordings()
    }

    func cancelDelete() {
        pendingDelete = nil
    }

    func togglePlayPause(_ item: RecordingItem) {
        if activePlaybackURL == item.url, let audioPlayer {
            if audioPlayer.isPlaying {
                audioPlayer.pause()
                isPlaybackPaused = true
                return
            }
            if audioPlayer.play() {
                isPlaybackPaused = false
                return
            }
        }
        startPlayback(item)
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        activePlaybackURL = nil
        isPlaybackPaused = false
    }

    private func startPlayback(_ item: RecordingItem) {
        if activePlaybackURL != nil {
            stopPlayback()
        }
        do {
            let player = try audioPlayerFactory(item.url)
            player.onPlaybackEnded = { [weak self] in
                self?.stopPlayback()
            }
            audioPlayer = player
            activePlaybackURL = item.url
            if player.play() {
                isPlaybackPaused = false
            } else {
                stopPlayback()
            }
        } catch {
            stopPlayback()
        }
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
