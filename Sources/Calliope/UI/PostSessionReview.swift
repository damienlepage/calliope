//
//  PostSessionReview.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Foundation

struct PostSessionReview: Equatable {
    static let summaryFallbackText = "Summary is still processing. You can review stats in Recordings."

    let recordingURL: URL
    let summary: SessionTitleSummary?

    var paceText: String? { summary?.paceText }
    var crutchText: String? { summary?.crutchText }
    var pauseText: String? { summary?.pauseText }
    var pauseRateText: String? { summary?.pauseRateText }
    var speakingText: String? { summary?.speakingText }
    var durationText: String? { summary?.durationText }
    var turnsText: String? { summary?.turnsText }

    var summaryLines: [String] {
        guard let summary else {
            return [Self.summaryFallbackText]
        }
        return [
            summary.durationText,
            summary.speakingText,
            summary.turnsText,
            summary.paceText,
            summary.crutchText,
            summary.pauseRateText
        ]
    }

    init?(
        session: CompletedRecordingSession,
        summaryProvider: (URL) -> AnalysisSummary? = { RecordingManager.shared.readSummary(for: $0) },
        durationProvider: (URL) -> TimeInterval? = PostSessionReview.defaultDuration
    ) {
        guard !session.recordingURLs.isEmpty else {
            return nil
        }

        struct Candidate {
            let url: URL
            let summary: AnalysisSummary?
            let duration: TimeInterval
        }

        let candidates = session.recordingURLs.map { url -> Candidate in
            let summary = summaryProvider(url)
            let summaryDuration = summary?.durationSeconds ?? 0
            let fallbackDuration = durationProvider(url) ?? 0
            let duration = summaryDuration > 0 ? summaryDuration : fallbackDuration
            return Candidate(url: url, summary: summary, duration: duration)
        }

        var best = candidates[0]
        for candidate in candidates.dropFirst() {
            if candidate.duration > best.duration {
                best = candidate
            } else if candidate.duration == best.duration {
                if best.summary == nil, candidate.summary != nil {
                    best = candidate
                }
            }
        }

        recordingURL = best.url
        summary = best.summary.map(SessionTitleSummary.init)
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
}
