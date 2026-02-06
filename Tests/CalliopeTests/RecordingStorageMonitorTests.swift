//
//  RecordingStorageMonitorTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class RecordingStorageMonitorTests: XCTestCase {
    func testWarnsWhenRemainingBelowThresholdUsingGrowth() {
        let url = URL(fileURLWithPath: "/tmp/recording.m4a")
        var now = Date()
        var fileSize = 0
        let monitor = RecordingStorageMonitor(
            warningThresholdSeconds: 30,
            now: { now },
            fileSizeProvider: { _ in fileSize },
            availableBytesProvider: { _ in 1_000 }
        )

        fileSize = 1_000
        _ = monitor.evaluate(recordingURL: url, inputFormat: nil)

        now = now.addingTimeInterval(10)
        fileSize = 2_000
        let status = monitor.evaluate(recordingURL: url, inputFormat: nil)

        guard case .warning(let remainingSeconds) = status else {
            return XCTFail("Expected warning status when storage is below threshold.")
        }
        XCTAssertLessThanOrEqual(remainingSeconds, 30)
    }

    func testWarnsWhenRemainingBelowThresholdUsingInputFormatEstimate() {
        let url = URL(fileURLWithPath: "/tmp/recording.m4a")
        let monitor = RecordingStorageMonitor(
            warningThresholdSeconds: 30,
            now: Date.init,
            fileSizeProvider: { _ in 0 },
            availableBytesProvider: { _ in 1_920_000 }
        )
        let inputFormat = AudioInputFormatSnapshot(sampleRate: 48_000, channelCount: 1)

        let status = monitor.evaluate(recordingURL: url, inputFormat: inputFormat)

        guard case .warning(let remainingSeconds) = status else {
            return XCTFail("Expected warning status when estimated remaining time is below threshold.")
        }
        XCTAssertLessThanOrEqual(remainingSeconds, 30)
    }

    func testDoesNotWarnWhenRemainingAboveThreshold() {
        let url = URL(fileURLWithPath: "/tmp/recording.m4a")
        let monitor = RecordingStorageMonitor(
            warningThresholdSeconds: 60,
            now: Date.init,
            fileSizeProvider: { _ in 0 },
            availableBytesProvider: { _ in 6_720_000 }
        )
        let inputFormat = AudioInputFormatSnapshot(sampleRate: 48_000, channelCount: 1)

        let status = monitor.evaluate(recordingURL: url, inputFormat: inputFormat)

        XCTAssertEqual(status, .ok)
    }
}
