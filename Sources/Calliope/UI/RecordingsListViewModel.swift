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
    func cleanupOrphanedMetadata(for recordings: [URL])
    func backfillMetadataIfNeeded(for recordings: [URL])
    func deleteRecording(at url: URL) throws
    func deleteAllRecordings() throws
    func deleteRecordings(olderThan cutoff: Date) -> Int
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
    let integrityReport: RecordingIntegrityReport?
    let metadata: RecordingMetadata?

    var id: URL { url }
    var displayName: String {
        RecordingMetadataDisplayFormatter.displayName(
            for: url,
            metadata: metadata,
            modifiedAt: modifiedAt
        )
    }
    var sessionDate: Date {
        let now = Date()
        let inferredCreatedAt = RecordingMetadata.inferredCreatedAt(from: url)
        return RecordingMetadata.resolvedCreatedAt(
            createdAt: metadata?.createdAt,
            inferred: inferredCreatedAt,
            modifiedAt: modifiedAt,
            now: now
        ) ?? modifiedAt
    }
    var detailText: String {
        metadataDetailText()
    }
    var summaryText: String? {
        guard let summary else { return nil }
        let pace = Int(summary.pace.averageWPM.rounded())
        let averagePause = RecordingItem.formatSeconds(summary.pauses.averageDurationSeconds)
        let durationSeconds = summary.durationSeconds > 0 ? summary.durationSeconds : duration
        let pausesPerMinute = RecordingItem.formatPausesPerMinute(
            count: summary.pauses.count,
            durationSeconds: durationSeconds
        )
        let latencyText = RecordingItem.formatLatencySummary(
            averageMs: summary.processing.latencyAverageMs,
            peakMs: summary.processing.latencyPeakMs
        )
        let utilizationText = RecordingItem.formatUtilizationSummary(
            average: summary.processing.utilizationAverage,
            peak: summary.processing.utilizationPeak
        )
        let speakingText = speakingSummaryText
        let pieces = [
            "Avg \(pace) WPM",
            "Pauses \(summary.pauses.count)",
            pausesPerMinute.map { "Pauses/min \($0)" },
            "Avg Pause \(averagePause)",
            "Crutch \(summary.crutchWords.totalCount)",
            speakingText,
            latencyText,
            utilizationText
        ].compactMap { $0 }
        return pieces.joined(separator: " • ")
    }

    var speakingDetailLines: [String] {
        guard let summary else { return [] }
        let speakingSeconds = summary.speaking.timeSeconds
        let turnCount = summary.speaking.turnCount
        guard speakingSeconds > 0 || turnCount > 0 else { return [] }
        var lines: [String] = []
        if let speakingText = RecordingItem.formatDuration(speakingSeconds) {
            lines.append("Speaking time: \(speakingText)")
        }
        if turnCount > 0 {
            lines.append("Speaking turns: \(turnCount)")
        }
        let sessionDuration = summary.durationSeconds > 0 ? summary.durationSeconds : (duration ?? 0)
        if let percentText = RecordingItem.formatSpeakingPercent(
            speakingSeconds: speakingSeconds,
            durationSeconds: sessionDuration
        ) {
            lines.append("Speaking %: \(percentText)")
        }
        return lines
    }

    var integrityWarningText: String? {
        guard let integrityReport else { return nil }
        guard !integrityReport.issues.isEmpty else { return nil }
        let hasAudioIssue = integrityReport.issues.contains(.missingAudioFile)
        let hasSummaryIssue = integrityReport.issues.contains(.missingSummary)
        switch (hasAudioIssue, hasSummaryIssue) {
        case (true, true):
            return "Audio and analysis summary are missing. Try recording again to capture a complete session."
        case (true, false):
            return "Audio file is missing. Try recording again to capture a complete session."
        case (false, true):
            return "Analysis summary is missing. Try recording again to capture full insights."
        case (false, false):
            return nil
        }
    }

    var title: String? {
        guard let title = metadata?.title else { return nil }
        return RecordingMetadata.normalizedTitle(title)
    }

    var detailMetadataText: String {
        metadataDetailText()
    }

    var coachingProfileText: String? {
        guard let name = metadata?.coachingProfileName,
              !name.isEmpty else { return nil }
        return "Profile: \(name)"
    }

    var paceDetailLines: [String] {
        guard let summary else { return [] }
        let average = Int(summary.pace.averageWPM.rounded())
        let minWPM = Int(summary.pace.minWPM.rounded())
        let maxWPM = Int(summary.pace.maxWPM.rounded())
        return [
            "Average: \(average) WPM",
            "Range: \(minWPM)-\(maxWPM) WPM",
            "Total words: \(summary.pace.totalWords)"
        ]
    }

    var pauseDetailLines: [String] {
        guard let summary else { return [] }
        let averagePause = RecordingItem.formatSeconds(summary.pauses.averageDurationSeconds)
        let threshold = RecordingItem.formatSeconds(summary.pauses.thresholdSeconds)
        let durationSeconds = summary.durationSeconds > 0 ? summary.durationSeconds : duration
        let pausesPerMinute = RecordingItem.formatPausesPerMinute(
            count: summary.pauses.count,
            durationSeconds: durationSeconds
        )
        var lines = [
            "Pause count: \(summary.pauses.count)",
            "Avg pause: \(averagePause)",
            "Pause threshold: \(threshold)"
        ]
        if let pausesPerMinute {
            lines.append("Pauses/min: \(pausesPerMinute)")
        }
        return lines
    }

    var processingDetailLines: [String] {
        guard let summary else { return [] }
        var lines: [String] = []
        let latencyAverage = summary.processing.latencyAverageMs
        let latencyPeak = summary.processing.latencyPeakMs
        if latencyAverage > 0 || latencyPeak > 0 {
            lines.append(
                String(
                    format: "Latency avg/peak: %.0f/%.0f ms",
                    latencyAverage,
                    latencyPeak
                )
            )
        }
        let utilizationAverage = summary.processing.utilizationAverage * 100
        let utilizationPeak = summary.processing.utilizationPeak * 100
        if utilizationAverage > 0 || utilizationPeak > 0 {
            lines.append(
                String(
                    format: "Util avg/peak: %.0f/%.0f%%",
                    utilizationAverage,
                    utilizationPeak
                )
            )
        }
        return lines
    }

    var crutchBreakdown: [(word: String, count: Int)] {
        guard let summary else { return [] }
        return summary.crutchWords.counts
            .filter { !$0.key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.value > 0 }
            .sorted { lhs, rhs in
                if lhs.value != rhs.value {
                    return lhs.value > rhs.value
                }
                return lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
            }
            .map { (word: $0.key, count: $0.value) }
    }

    init(
        url: URL,
        modifiedAt: Date,
        duration: TimeInterval?,
        fileSizeBytes: Int?,
        summary: AnalysisSummary?,
        integrityReport: RecordingIntegrityReport?,
        metadata: RecordingMetadata? = nil
    ) {
        self.url = url
        self.modifiedAt = modifiedAt
        self.duration = duration
        self.fileSizeBytes = fileSizeBytes
        self.summary = summary
        self.integrityReport = integrityReport
        self.metadata = metadata
    }

    static func displayName(
        for url: URL,
        metadata: RecordingMetadata? = nil,
        modifiedAt: Date? = nil
    ) -> String {
        RecordingMetadataDisplayFormatter.displayName(
            for: url,
            metadata: metadata,
            modifiedAt: modifiedAt
        )
    }

    static func defaultSessionTitle(for date: Date) -> String {
        RecordingMetadata.defaultSessionTitle(for: date)
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private static let durationWithHoursFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad, .dropLeading]
        return formatter
    }()

    private static let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    static func formatDuration(_ duration: TimeInterval?) -> String? {
        guard let duration, duration > 0 else {
            return nil
        }
        if duration >= 3600 {
            guard let formatted = durationWithHoursFormatter.string(from: duration) else {
                return nil
            }
            if formatted.hasPrefix("0") && formatted.count > 1 {
                return String(formatted.dropFirst())
            }
            return formatted
        }
        return durationFormatter.string(from: duration)
    }

    private static func formatFileSize(_ bytes: Int?) -> String? {
        guard let bytes, bytes > 0 else {
            return nil
        }
        return sizeFormatter.string(fromByteCount: Int64(bytes))
    }

    private static func formatSeconds(_ seconds: TimeInterval) -> String {
        String(format: "%.1fs", seconds)
    }

    private static func formatPausesPerMinute(count: Int, durationSeconds: TimeInterval?) -> String? {
        guard let durationSeconds, durationSeconds > 0 else {
            return nil
        }
        let safeDuration = max(durationSeconds, 1)
        let minutes = safeDuration / 60
        let rate = Double(count) / minutes
        return String(format: "%.1f", rate)
    }

    private static func formatSpeakingPercent(
        speakingSeconds: TimeInterval,
        durationSeconds: TimeInterval
    ) -> String? {
        guard speakingSeconds > 0, durationSeconds > 0 else { return nil }
        let rawRatio = speakingSeconds / durationSeconds
        let clampedRatio = min(max(rawRatio, 0), 1)
        return String(format: "%.0f%%", clampedRatio * 100)
    }

    private static func formatLatencySummary(averageMs: Double, peakMs: Double) -> String? {
        guard averageMs > 0 || peakMs > 0 else {
            return nil
        }
        let averageText = String(format: "%.0f", averageMs)
        let peakText = String(format: "%.0f", peakMs)
        return "Latency \(averageText)/\(peakText)ms"
    }

    private static func formatUtilizationSummary(average: Double, peak: Double) -> String? {
        guard average > 0 || peak > 0 else {
            return nil
        }
        let averagePercent = average * 100
        let peakPercent = peak * 100
        return String(format: "Util %.0f/%.0f%%", averagePercent, peakPercent)
    }

    private var speakingSummaryText: String? {
        guard let summary else { return nil }
        let speakingSeconds = summary.speaking.timeSeconds
        let turnCount = summary.speaking.turnCount
        guard speakingSeconds > 0 || turnCount > 0 else { return nil }
        var parts: [String] = []
        if let timeText = RecordingItem.formatDuration(speakingSeconds) {
            parts.append("Speaking \(timeText)")
        }
        if turnCount > 0 {
            parts.append("Turns \(turnCount)")
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " • ")
    }

    var speakingPercentValue: Double? {
        guard let summary else { return nil }
        let speakingSeconds = summary.speaking.timeSeconds
        let sessionDuration = summary.durationSeconds > 0 ? summary.durationSeconds : (duration ?? 0)
        guard speakingSeconds > 0, sessionDuration > 0 else { return nil }
        let ratio = speakingSeconds / sessionDuration
        return min(max(ratio, 0), 1)
    }

    private func metadataDetailText() -> String {
        let dateText = RecordingMetadataDisplayFormatter.dateTimeText(for: sessionDate)
        let details = [
            RecordingItem.formatDuration(duration),
            RecordingItem.formatFileSize(fileSizeBytes)
        ].compactMap { $0 }
        guard !details.isEmpty else {
            return dateText
        }
        return ([dateText] + details).joined(separator: " • ")
    }
}

enum RecordingDeleteRequest: Identifiable, Equatable {
    case single(RecordingItem)
    case all

    var id: String {
        switch self {
        case .single(let item):
            return "single-\(item.url.absoluteString)"
        case .all:
            return "all"
        }
    }
}

enum RecordingSortOption: String, CaseIterable, Identifiable {
    case dateNewest
    case dateOldest
    case durationLongest
    case durationShortest
    case speakingPercentHighest
    case speakingPercentLowest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dateNewest:
            return "Date (Newest)"
        case .dateOldest:
            return "Date (Oldest)"
        case .durationLongest:
            return "Duration (Longest)"
        case .durationShortest:
            return "Duration (Shortest)"
        case .speakingPercentHighest:
            return "Speaking % (Highest)"
        case .speakingPercentLowest:
            return "Speaking % (Lowest)"
        }
    }
}

@MainActor
final class RecordingListViewModel: ObservableObject {
    static let deleteWhileRecordingMessage = "Stop recording before deleting recordings."

    @Published private(set) var recordings: [RecordingItem] = []
    @Published var searchText: String = "" {
        didSet {
            applyFiltersAndSort()
        }
    }
    @Published var sortOption: RecordingSortOption = .dateNewest {
        didSet {
            applyFiltersAndSort()
        }
    }
    @Published var pendingDelete: RecordingDeleteRequest?
    @Published var detailItem: RecordingItem?
    @Published var deleteErrorMessage: String?
    @Published private(set) var activePlaybackURL: URL?
    @Published private(set) var isPlaybackPaused = false
    @Published private(set) var isRecording = false

    private struct SummaryAggregate {
        let totalDurationSeconds: TimeInterval
        let totalWords: Int
        let totalCrutch: Int
        let totalPauses: Int

        var averageWPM: Int {
            guard totalDurationSeconds > 0 else { return 0 }
            return Int(round(Double(totalWords) / (totalDurationSeconds / 60)))
        }
    }

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
        let totalSizeBytes = recordings
            .compactMap(\.fileSizeBytes)
            .filter { $0 > 0 }
            .reduce(0, +)
        var parts = [countText]
        if totalDuration > 0, let durationText = Self.formatTotalDuration(totalDuration) {
            parts.append("\(durationText) total")
        }
        if totalSizeBytes > 0 {
            let sizeText = Self.totalSizeFormatter.string(fromByteCount: Int64(totalSizeBytes))
            parts.append(sizeText)
        }
        return parts.joined(separator: " • ")
    }

    var recentSummaryText: String? {
        guard !recordings.isEmpty else { return nil }
        let cutoff = RecordingListViewModel.recentSummaryCalendar.date(
            byAdding: .day,
            value: -7,
            to: now()
        ) ?? now()
        let recentSummaries = recordings
            .filter { $0.modifiedAt >= cutoff }
            .compactMap { item -> (summary: AnalysisSummary, durationSeconds: TimeInterval)? in
                guard let summary = item.summary else { return nil }
                let durationSeconds = summary.durationSeconds > 0
                    ? summary.durationSeconds
                    : (item.duration ?? 0)
                return (summary, durationSeconds)
            }
        guard !recentSummaries.isEmpty else { return nil }
        let totalDurationSeconds = recentSummaries
            .map(\.durationSeconds)
            .filter { $0 > 0 }
            .reduce(0, +)
        guard totalDurationSeconds > 0 else { return nil }
        let totalWords = recentSummaries.map { $0.summary.pace.totalWords }.reduce(0, +)
        let averageWPM = Int(round(Double(totalWords) / (totalDurationSeconds / 60)))
        let totalCrutch = recentSummaries.map { $0.summary.crutchWords.totalCount }.reduce(0, +)
        let totalPauses = recentSummaries.map { $0.summary.pauses.count }.reduce(0, +)
        let pausesPerMinute = RecordingListViewModel.formatPausesPerMinute(
            count: totalPauses,
            durationSeconds: totalDurationSeconds
        )
        var parts = ["Last 7 days: Avg \(averageWPM) WPM", "Crutch \(totalCrutch)"]
        if let pausesPerMinute {
            parts.append("Pauses/min \(pausesPerMinute)")
        }
        return parts.joined(separator: " • ")
    }

    var trendSummaryText: String? {
        guard !recordings.isEmpty else { return nil }
        let now = now()
        let recentStart = RecordingListViewModel.recentSummaryCalendar.date(
            byAdding: .day,
            value: -7,
            to: now
        ) ?? now
        let previousStart = RecordingListViewModel.recentSummaryCalendar.date(
            byAdding: .day,
            value: -14,
            to: now
        ) ?? now
        guard let recent = aggregateSummaries(from: recentStart, to: now),
              let previous = aggregateSummaries(from: previousStart, to: recentStart) else {
            return nil
        }

        let paceDelta = recent.averageWPM - previous.averageWPM
        let crutchDelta = recent.totalCrutch - previous.totalCrutch
        guard let recentPauses = RecordingListViewModel.pausesPerMinute(
            count: recent.totalPauses,
            durationSeconds: recent.totalDurationSeconds
        ),
        let previousPauses = RecordingListViewModel.pausesPerMinute(
            count: previous.totalPauses,
            durationSeconds: previous.totalDurationSeconds
        ) else {
            return nil
        }
        let pauseDelta = recentPauses - previousPauses

        let parts = [
            "Pace \(RecordingListViewModel.formatSigned(paceDelta)) WPM",
            "Crutch \(RecordingListViewModel.formatSigned(crutchDelta))",
            "Pauses/min \(RecordingListViewModel.formatSigned(pauseDelta))"
        ]
        return "Trend (7d vs prior): \(parts.joined(separator: " • "))"
    }

    var mostRecentRecordingText: String? {
        guard let mostRecentDate = recordings.map(\.modifiedAt).max() else {
            return nil
        }
        return "Most recent: \(mostRecentDateTextProvider(mostRecentDate))"
    }

    var recordingsPath: String {
        PathDisplayFormatter.displayPath(manager.recordingsDirectoryURL())
    }

    private let manager: RecordingManaging
    private let workspace: WorkspaceOpening
    private let recordingPreferencesStore: RecordingRetentionPreferencesStore
    private let now: () -> Date
    private let modificationDateProvider: @MainActor (URL) -> Date
    private let durationProvider: @MainActor (URL) -> TimeInterval?
    private let fileSizeProvider: @MainActor (URL) -> Int?
    private let summaryProvider: @MainActor (URL) -> AnalysisSummary?
    private let integrityReportProvider: @MainActor (URL) -> RecordingIntegrityReport?
    private let metadataProvider: @MainActor (URL) -> RecordingMetadata?
    private let mostRecentDateTextProvider: @MainActor (Date) -> String
    private let audioPlayerFactory: (URL) throws -> AudioPlaying
    private var audioPlayer: AudioPlaying?
    private var cancellables = Set<AnyCancellable>()
    private var allRecordings: [RecordingItem] = []

    private static let totalDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private static let totalDurationLongFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad, .dropLeading]
        return formatter
    }()

    private static let totalSizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    private static let mostRecentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let recentSummaryCalendar = Calendar(identifier: .gregorian)

    private static func formatTotalDuration(_ duration: TimeInterval) -> String? {
        if duration >= 3600 {
            guard let formatted = totalDurationLongFormatter.string(from: duration) else {
                return nil
            }
            if formatted.hasPrefix("0") && formatted.count > 1 {
                return String(formatted.dropFirst())
            }
            return formatted
        }
        return totalDurationFormatter.string(from: duration)
    }

    private static func defaultMostRecentDateText(_ date: Date) -> String {
        mostRecentDateFormatter.string(from: date)
    }

    private static func formatPausesPerMinute(count: Int, durationSeconds: TimeInterval) -> String? {
        guard durationSeconds > 0 else { return nil }
        let safeDuration = max(durationSeconds, 1)
        let minutes = safeDuration / 60
        let rate = Double(count) / minutes
        return String(format: "%.1f", rate)
    }

    private static func pausesPerMinute(count: Int, durationSeconds: TimeInterval) -> Double? {
        guard durationSeconds > 0 else { return nil }
        let safeDuration = max(durationSeconds, 1)
        let minutes = safeDuration / 60
        return Double(count) / minutes
    }

    private static func formatSigned(_ value: Int) -> String {
        if value > 0 {
            return "+\(value)"
        }
        if value < 0 {
            return "\(value)"
        }
        return "0"
    }

    private static func formatSigned(_ value: Double) -> String {
        let formatted = String(format: "%.1f", abs(value))
        if value > 0 {
            return "+\(formatted)"
        }
        if value < 0 {
            return "-\(formatted)"
        }
        return "0.0"
    }

    private func aggregateSummaries(from start: Date, to end: Date) -> SummaryAggregate? {
        let summaries = recordings
            .filter { $0.modifiedAt >= start && $0.modifiedAt < end }
            .compactMap { item -> (summary: AnalysisSummary, durationSeconds: TimeInterval)? in
                guard let summary = item.summary else { return nil }
                let durationSeconds = summary.durationSeconds > 0
                    ? summary.durationSeconds
                    : (item.duration ?? 0)
                return (summary, durationSeconds)
            }
        guard !summaries.isEmpty else { return nil }
        let totalDurationSeconds = summaries
            .map(\.durationSeconds)
            .filter { $0 > 0 }
            .reduce(0, +)
        guard totalDurationSeconds > 0 else { return nil }
        let totalWords = summaries.map { $0.summary.pace.totalWords }.reduce(0, +)
        let totalCrutch = summaries.map { $0.summary.crutchWords.totalCount }.reduce(0, +)
        let totalPauses = summaries.map { $0.summary.pauses.count }.reduce(0, +)
        return SummaryAggregate(
            totalDurationSeconds: totalDurationSeconds,
            totalWords: totalWords,
            totalCrutch: totalCrutch,
            totalPauses: totalPauses
        )
    }

    private func applyFiltersAndSort() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered: [RecordingItem]
        if query.isEmpty {
            filtered = allRecordings
        } else {
            filtered = allRecordings.filter { item in
                item.displayName.localizedCaseInsensitiveContains(query)
            }
        }
        recordings = sortRecordings(filtered)
    }

    private func sortRecordings(_ items: [RecordingItem]) -> [RecordingItem] {
        items.sorted { left, right in
            switch sortOption {
            case .dateNewest:
                if left.sessionDate != right.sessionDate {
                    return left.sessionDate > right.sessionDate
                }
            case .dateOldest:
                if left.sessionDate != right.sessionDate {
                    return left.sessionDate < right.sessionDate
                }
            case .durationLongest:
                let leftDuration = left.duration ?? -1
                let rightDuration = right.duration ?? -1
                if leftDuration != rightDuration {
                    return leftDuration > rightDuration
                }
            case .durationShortest:
                let leftDuration = left.duration ?? Double.greatestFiniteMagnitude
                let rightDuration = right.duration ?? Double.greatestFiniteMagnitude
                if leftDuration != rightDuration {
                    return leftDuration < rightDuration
                }
            case .speakingPercentHighest:
                let leftPercent = left.speakingPercentValue ?? -1
                let rightPercent = right.speakingPercentValue ?? -1
                if leftPercent != rightPercent {
                    return leftPercent > rightPercent
                }
            case .speakingPercentLowest:
                let leftPercent = left.speakingPercentValue ?? Double.greatestFiniteMagnitude
                let rightPercent = right.speakingPercentValue ?? Double.greatestFiniteMagnitude
                if leftPercent != rightPercent {
                    return leftPercent < rightPercent
                }
            }
            let nameComparison = left.displayName.localizedCaseInsensitiveCompare(right.displayName)
            if nameComparison != .orderedSame {
                return nameComparison == .orderedAscending
            }
            return left.url.absoluteString < right.url.absoluteString
        }
    }

    init(
        manager: RecordingManaging = RecordingManager.shared,
        workspace: WorkspaceOpening = NSWorkspace.shared,
        modificationDateProvider: @escaping @MainActor (URL) -> Date = RecordingListViewModel.defaultModificationDate,
        durationProvider: @escaping @MainActor (URL) -> TimeInterval? = RecordingListViewModel.defaultDuration,
        fileSizeProvider: @escaping @MainActor (URL) -> Int? = RecordingListViewModel.defaultFileSize,
        summaryProvider: @escaping @MainActor (URL) -> AnalysisSummary? = RecordingListViewModel.defaultSummary,
        integrityReportProvider: @escaping @MainActor (URL) -> RecordingIntegrityReport? = RecordingListViewModel.defaultIntegrityReport,
        metadataProvider: @escaping @MainActor (URL) -> RecordingMetadata? = RecordingListViewModel.defaultMetadata,
        mostRecentDateTextProvider: @escaping @MainActor (Date) -> String = RecordingListViewModel.defaultMostRecentDateText,
        recordingPreferencesStore: RecordingRetentionPreferencesStore = RecordingRetentionPreferencesStore(),
        now: @escaping () -> Date = Date.init,
        audioPlayerFactory: @escaping (URL) throws -> AudioPlaying = { url in
            try SystemAudioPlayer(url: url)
        }
    ) {
        self.manager = manager
        self.workspace = workspace
        self.recordingPreferencesStore = recordingPreferencesStore
        self.now = now
        self.modificationDateProvider = modificationDateProvider
        self.durationProvider = durationProvider
        self.fileSizeProvider = fileSizeProvider
        self.summaryProvider = summaryProvider
        self.integrityReportProvider = integrityReportProvider
        self.metadataProvider = metadataProvider
        self.mostRecentDateTextProvider = mostRecentDateTextProvider
        self.audioPlayerFactory = audioPlayerFactory
    }

    func loadRecordings() {
        let urls = manager.getAllRecordings()
        loadRecordings(from: urls)
    }

    private func loadRecordings(from urls: [URL]) {
        pendingDelete = nil
        deleteErrorMessage = nil
        let items = urls.map { url in
            RecordingItem(
                url: url,
                modifiedAt: modificationDateProvider(url),
                duration: durationProvider(url),
                fileSizeBytes: fileSizeProvider(url),
                summary: summaryProvider(url),
                integrityReport: integrityReportProvider(url),
                metadata: metadataProvider(url)
            )
        }
        if let activePlaybackURL,
           !items.contains(where: { $0.url == activePlaybackURL }) {
            stopPlayback()
        }
        allRecordings = items
        applyFiltersAndSort()
    }

    func refreshRecordings() {
        guard !isRecording else { return }
        autoCleanIfNeeded()
        let urls = manager.getAllRecordings()
        manager.cleanupOrphanedMetadata(for: urls)
        manager.backfillMetadataIfNeeded(for: urls)
        loadRecordings(from: urls)
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
                    self.autoCleanIfNeeded()
                    let urls = self.manager.getAllRecordings()
                    self.manager.cleanupOrphanedMetadata(for: urls)
                    self.manager.backfillMetadataIfNeeded(for: urls)
                    self.loadRecordings(from: urls)
                }
            }
            .store(in: &cancellables)
    }

    func item(for url: URL) -> RecordingItem {
        RecordingItem(
            url: url,
            modifiedAt: modificationDateProvider(url),
            duration: durationProvider(url),
            fileSizeBytes: fileSizeProvider(url),
            summary: summaryProvider(url),
            integrityReport: integrityReportProvider(url),
            metadata: metadataProvider(url)
        )
    }

    func reveal(_ item: RecordingItem) {
        workspace.activateFileViewerSelecting([item.url])
    }

    func openRecordingsFolder() {
        workspace.activateFileViewerSelecting([manager.recordingsDirectoryURL()])
    }

    func requestDelete(_ item: RecordingItem) {
        deleteErrorMessage = nil
        guard !isRecording else {
            deleteErrorMessage = Self.deleteWhileRecordingMessage
            return
        }
        pendingDelete = .single(item)
    }

    func requestDeleteAll() {
        deleteErrorMessage = nil
        guard !isRecording else {
            deleteErrorMessage = Self.deleteWhileRecordingMessage
            return
        }
        pendingDelete = .all
    }

    func confirmDelete(_ item: RecordingItem) {
        pendingDelete = nil
        deleteErrorMessage = nil
        guard !isRecording else {
            deleteErrorMessage = Self.deleteWhileRecordingMessage
            return
        }
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

    func confirmDeleteAll() {
        pendingDelete = nil
        deleteErrorMessage = nil
        guard !isRecording else {
            deleteErrorMessage = Self.deleteWhileRecordingMessage
            return
        }
        stopPlayback()
        do {
            try manager.deleteAllRecordings()
        } catch {
            deleteErrorMessage = "Unable to delete recordings. Please try again."
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

    private func autoCleanIfNeeded() {
        guard !isRecording else { return }
        guard recordingPreferencesStore.autoCleanEnabled else { return }
        let retentionDays = recordingPreferencesStore.retentionOption.days
        let cutoff = now().addingTimeInterval(-TimeInterval(retentionDays) * 24 * 60 * 60)
        _ = manager.deleteRecordings(olderThan: cutoff)
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
        RecordingManager.shared.readSummary(for: url)
    }

    private static func defaultIntegrityReport(_ url: URL) -> RecordingIntegrityReport? {
        RecordingManager.shared.readIntegrityReport(for: url)
    }

    private static func defaultMetadata(_ url: URL) -> RecordingMetadata? {
        RecordingManager.shared.readMetadata(for: url)
    }
}
