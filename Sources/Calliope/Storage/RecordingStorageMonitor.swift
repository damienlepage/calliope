//
//  RecordingStorageMonitor.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum RecordingStorageStatus: Equatable {
    case ok
    case warning(remainingSeconds: TimeInterval)
}

struct RecordingStorageWarningFormatter {
    static func warningText(status: RecordingStorageStatus) -> String? {
        guard case .warning(let remainingSeconds) = status else {
            return nil
        }
        return "Low storage: ~\(remainingTimeText(remainingSeconds)) left"
    }

    private static func remainingTimeText(_ remainingSeconds: TimeInterval) -> String {
        let clampedSeconds = max(0, Int(remainingSeconds.rounded(.down)))
        let totalMinutes = max(1, clampedSeconds / 60)
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return "\(hours) hr"
        }
        return "\(hours) hr \(minutes) min"
    }
}

struct RecordingStorageSample: Equatable {
    let timestamp: Date
    let fileSizeBytes: Int
}

final class RecordingStorageMonitor {
    private let warningThresholdSeconds: TimeInterval
    private let fallbackBytesPerSecond: Double
    private let now: () -> Date
    private let fileSizeProvider: (URL) -> Int
    private let availableBytesProvider: (URL) -> Int64?
    private var previousSample: RecordingStorageSample?

    init(
        warningThresholdSeconds: TimeInterval = 30 * 60,
        fallbackBytesPerSecond: Double = 128_000 / 8,
        now: @escaping () -> Date = Date.init,
        fileSizeProvider: @escaping (URL) -> Int = { url in
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            return values?.fileSize ?? 0
        },
        availableBytesProvider: @escaping (URL) -> Int64? = RecordingStorageMonitor.defaultAvailableBytesProvider
    ) {
        self.warningThresholdSeconds = warningThresholdSeconds
        self.fallbackBytesPerSecond = fallbackBytesPerSecond
        self.now = now
        self.fileSizeProvider = fileSizeProvider
        self.availableBytesProvider = availableBytesProvider
    }

    func reset() {
        previousSample = nil
    }

    func evaluate(recordingURL: URL, inputFormat: AudioInputFormatSnapshot?) -> RecordingStorageStatus {
        guard let availableBytes = availableBytesProvider(recordingURL) else {
            previousSample = RecordingStorageSample(timestamp: now(), fileSizeBytes: fileSizeProvider(recordingURL))
            return .ok
        }
        let sample = RecordingStorageSample(
            timestamp: now(),
            fileSizeBytes: fileSizeProvider(recordingURL)
        )
        let bytesPerSecond = estimateBytesPerSecond(
            currentSample: sample,
            previousSample: previousSample,
            inputFormat: inputFormat
        )
        previousSample = sample

        guard let bytesPerSecond, bytesPerSecond > 0 else {
            return .ok
        }

        let remainingSeconds = Double(max(0, availableBytes)) / bytesPerSecond
        if remainingSeconds <= warningThresholdSeconds {
            return .warning(remainingSeconds: remainingSeconds)
        }
        return .ok
    }

    private func estimateBytesPerSecond(
        currentSample: RecordingStorageSample,
        previousSample: RecordingStorageSample?,
        inputFormat: AudioInputFormatSnapshot?
    ) -> Double? {
        if let previousSample {
            let deltaBytes = currentSample.fileSizeBytes - previousSample.fileSizeBytes
            let deltaTime = currentSample.timestamp.timeIntervalSince(previousSample.timestamp)
            if deltaBytes > 0, deltaTime > 0 {
                return Double(deltaBytes) / deltaTime
            }
        }

        if let inputFormat, inputFormat.sampleRate > 0, inputFormat.channelCount > 0 {
            let bytesPerSample = 2.0
            return inputFormat.sampleRate * Double(inputFormat.channelCount) * bytesPerSample
        }

        return fallbackBytesPerSecond
    }

    private static func defaultAvailableBytesProvider(url: URL) -> Int64? {
        let keys: Set<URLResourceKey> = [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]
        let values = try? url.resourceValues(forKeys: keys)
        if let capacity = values?.volumeAvailableCapacityForImportantUsage {
            return capacity
        }
        if let capacity = values?.volumeAvailableCapacity {
            return Int64(capacity)
        }
        return nil
    }
}
