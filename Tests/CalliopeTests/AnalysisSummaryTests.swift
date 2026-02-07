import AVFoundation
import XCTest
@testable import Calliope

private func makeTranscript(word: String = "word", count: Int) -> String {
    guard count > 0 else { return "" }
    return Array(repeating: word, count: count).joined(separator: " ")
}

final class AnalysisSummaryTests: XCTestCase {
    func testSummaryWrittenWhenRecordingStops() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let manager = RecordingManager(baseDirectory: tempDir)
        let suiteName = "AnalysisSummaryTests.AudioCapture.\(UUID().uuidString)"
        let captureDefaults = UserDefaults(suiteName: suiteName)!
        captureDefaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AudioCapturePreferencesStore(defaults: captureDefaults)
        let audioCapture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: FakeAudioCaptureBackend(), status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )
        let writer = MockSummaryWriter()
        let start = Date(timeIntervalSince1970: 1_000)
        let clock = TestClock([
            start,
            start,
            start.addingTimeInterval(60),
            start.addingTimeInterval(120),
            start.addingTimeInterval(120)
        ])
        let analyzer = AudioAnalyzer(
            summaryWriter: writer,
            now: clock.now,
            speechTranscriberFactory: { FakeSpeechTranscriber() }
        )
        let analysisDefaults = UserDefaults(suiteName: "AnalysisSummaryTests")!
        analysisDefaults.removePersistentDomain(forName: "AnalysisSummaryTests")
        let preferences = AnalysisPreferencesStore(defaults: analysisDefaults)

        analyzer.setup(audioCapture: audioCapture, preferencesStore: preferences)

        let recordingURL = manager.getNewRecordingURL()
        audioCapture.setRecordingURLForTesting(recordingURL)

        audioCapture.isRecording = true
        let startHandled = expectation(description: "start handled")
        DispatchQueue.main.async { startHandled.fulfill() }
        wait(for: [startHandled], timeout: 1.0)

        analyzer.handleTranscription("um hello world")

        audioCapture.isRecording = false
        let stopHandled = expectation(description: "stop handled")
        DispatchQueue.main.async { stopHandled.fulfill() }
        wait(for: [stopHandled], timeout: 1.0)

        XCTAssertEqual(
            writer.lastRecordingURL?.standardizedFileURL,
            recordingURL.standardizedFileURL
        )
        XCTAssertEqual(writer.lastSummary?.crutchWords.totalCount, 1)
        XCTAssertEqual(writer.lastSummary?.crutchWords.counts["um"], 1)
        XCTAssertEqual(writer.lastSummary?.speaking.timeSeconds, 0)
        XCTAssertEqual(writer.lastSummary?.speaking.turnCount, 0)
        XCTAssertEqual(writer.lastSummary?.processing.latencyAverageMs, 0)
        XCTAssertEqual(writer.lastSummary?.processing.latencyPeakMs, 0)
        XCTAssertEqual(writer.lastSummary?.processing.utilizationAverage, 0)
        XCTAssertEqual(writer.lastSummary?.processing.utilizationPeak, 0)
    }

    func testSummaryPaceStatsMatchTranscriptAndElapsedTime() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let manager = RecordingManager(baseDirectory: tempDir)
        let suiteName = "AnalysisSummaryTests.AudioCapture.\(UUID().uuidString)"
        let captureDefaults = UserDefaults(suiteName: suiteName)!
        captureDefaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AudioCapturePreferencesStore(defaults: captureDefaults)
        let audioCapture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: FakeAudioCaptureBackend(), status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )
        let writer = MockSummaryWriter()
        let start = Date(timeIntervalSince1970: 1_000)
        let clock = TestClock([
            start,
            start,
            start.addingTimeInterval(30),
            start.addingTimeInterval(60)
        ])
        let analyzer = AudioAnalyzer(
            summaryWriter: writer,
            now: clock.now,
            speechTranscriberFactory: { FakeSpeechTranscriber() }
        )
        let analysisDefaults = UserDefaults(suiteName: "AnalysisSummaryTests.Pace")!
        analysisDefaults.removePersistentDomain(forName: "AnalysisSummaryTests.Pace")
        let preferences = AnalysisPreferencesStore(defaults: analysisDefaults)

        analyzer.setup(audioCapture: audioCapture, preferencesStore: preferences)

        let recordingURL = manager.getNewRecordingURL()
        audioCapture.setRecordingURLForTesting(recordingURL)

        audioCapture.isRecording = true
        let startHandled = expectation(description: "start handled")
        DispatchQueue.main.async { startHandled.fulfill() }
        wait(for: [startHandled], timeout: 1.0)

        analyzer.handleTranscription(makeTranscript(count: 30))
        analyzer.handleTranscription(makeTranscript(count: 120))

        audioCapture.isRecording = false
        let stopHandled = expectation(description: "stop handled")
        DispatchQueue.main.async { stopHandled.fulfill() }
        wait(for: [stopHandled], timeout: 1.0)

        guard let summary = writer.lastSummary else {
            XCTFail("Expected summary to be written")
            return
        }

        XCTAssertEqual(summary.pace.totalWords, 120)
        XCTAssertEqual(summary.pace.minWPM, 60, accuracy: 0.001)
        XCTAssertEqual(summary.pace.maxWPM, 120, accuracy: 0.001)
        XCTAssertEqual(summary.pace.averageWPM, 90, accuracy: 0.001)
    }

    func testRecordingManagerWritesSummaryJSON() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingURL = manager.getNewRecordingURL()
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(timeIntervalSince1970: 2_000),
            durationSeconds: 42,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 150,
                minWPM: 140,
                maxWPM: 160,
                totalWords: 300
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 2,
                thresholdSeconds: 1.5,
                averageDurationSeconds: 1.2
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 3,
                counts: ["um": 2, "you know": 1]
            ),
            speaking: AnalysisSummary.SpeakingStats(
                timeSeconds: 18,
                turnCount: 4
            ),
            processing: AnalysisSummary.ProcessingStats(
                latencyAverageMs: 12,
                latencyPeakMs: 28,
                utilizationAverage: 0.42,
                utilizationPeak: 0.88
            )
        )

        try manager.writeSummary(summary, for: recordingURL)

        let summaryURL = manager.summaryURL(for: recordingURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: summaryURL.path))
        let data = try Data(contentsOf: summaryURL)
        let decoded = try JSONDecoder().decode(AnalysisSummary.self, from: data)
        XCTAssertEqual(decoded, summary)
    }

    func testDeleteRecordingRemovesSummary() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingURL = manager.getNewRecordingURL()
        FileManager.default.createFile(atPath: recordingURL.path, contents: Data())
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(timeIntervalSince1970: 3_000),
            durationSeconds: 10,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 120,
                minWPM: 110,
                maxWPM: 130,
                totalWords: 120
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 1,
                thresholdSeconds: 1.0,
                averageDurationSeconds: 0.8
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 1,
                counts: ["um": 1]
            ),
            speaking: AnalysisSummary.SpeakingStats(
                timeSeconds: 4,
                turnCount: 2
            ),
            processing: AnalysisSummary.ProcessingStats(
                latencyAverageMs: 5,
                latencyPeakMs: 12,
                utilizationAverage: 0.2,
                utilizationPeak: 0.5
            )
        )

        try manager.writeSummary(summary, for: recordingURL)

        let summaryURL = manager.summaryURL(for: recordingURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: summaryURL.path))

        try manager.deleteRecording(at: recordingURL)

        XCTAssertFalse(FileManager.default.fileExists(atPath: summaryURL.path))
    }

    func testSummaryDefaultsProcessingStatsWhenMissing() throws {
        let json = """
        {
          "version": 1,
          "createdAt": 1700000000,
          "durationSeconds": 30,
          "pace": {
            "averageWPM": 120,
            "minWPM": 100,
            "maxWPM": 140,
            "totalWords": 60
          },
          "pauses": {
            "count": 2,
            "thresholdSeconds": 1.2,
            "averageDurationSeconds": 0.8
          },
          "crutchWords": {
            "totalCount": 1,
            "counts": {
              "um": 1
            }
          }
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(AnalysisSummary.self, from: data)
        XCTAssertEqual(decoded.processing.latencyAverageMs, 0)
        XCTAssertEqual(decoded.processing.latencyPeakMs, 0)
        XCTAssertEqual(decoded.processing.utilizationAverage, 0)
        XCTAssertEqual(decoded.processing.utilizationPeak, 0)
    }

    func testSummaryDefaultsSpeakingStatsWhenMissing() throws {
        let json = """
        {
          "version": 1,
          "createdAt": 1700000000,
          "durationSeconds": 30,
          "pace": {
            "averageWPM": 120,
            "minWPM": 100,
            "maxWPM": 140,
            "totalWords": 60
          },
          "pauses": {
            "count": 2,
            "thresholdSeconds": 1.2,
            "averageDurationSeconds": 0.8
          },
          "crutchWords": {
            "totalCount": 1,
            "counts": {
              "um": 1
            }
          }
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(AnalysisSummary.self, from: data)
        XCTAssertEqual(decoded.speaking.timeSeconds, 0)
        XCTAssertEqual(decoded.speaking.turnCount, 0)
    }

    func testSummaryIncludesProcessingMetricsWhenBuffersProcessed() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let manager = RecordingManager(baseDirectory: tempDir)
        let suiteName = "AnalysisSummaryTests.Processing.\(UUID().uuidString)"
        let captureDefaults = UserDefaults(suiteName: suiteName)!
        captureDefaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AudioCapturePreferencesStore(defaults: captureDefaults)
        let audioCapture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: FakeAudioCaptureBackend(), status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )
        let writer = MockSummaryWriter()
        let start = Date(timeIntervalSince1970: 1_000)
        let clock = TestClock([
            start,
            start,
            start.addingTimeInterval(5),
            start.addingTimeInterval(10),
            start.addingTimeInterval(10)
        ])
        let analyzer = AudioAnalyzer(
            summaryWriter: writer,
            now: clock.now,
            speechTranscriberFactory: { FakeSpeechTranscriber(delaySeconds: 0.005) }
        )
        let analysisDefaults = UserDefaults(suiteName: "AnalysisSummaryTests.Processing.Analysis")!
        analysisDefaults.removePersistentDomain(forName: "AnalysisSummaryTests.Processing.Analysis")
        let preferences = AnalysisPreferencesStore(defaults: analysisDefaults)

        analyzer.setup(audioCapture: audioCapture, preferencesStore: preferences)

        let recordingURL = manager.getNewRecordingURL()
        audioCapture.setRecordingURLForTesting(recordingURL)

        audioCapture.isRecording = true
        let startHandled = expectation(description: "start handled")
        DispatchQueue.main.async { startHandled.fulfill() }
        wait(for: [startHandled], timeout: 1.0)

        let format = AVAudioFormat(standardFormatWithSampleRate: 1000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1000)!
        buffer.frameLength = 1000
        analyzer.processAudioBuffer(buffer)

        audioCapture.isRecording = false
        let stopHandled = expectation(description: "stop handled")
        DispatchQueue.main.async { stopHandled.fulfill() }
        wait(for: [stopHandled], timeout: 1.0)

        XCTAssertNotNil(writer.lastSummary)
        XCTAssertGreaterThan(writer.lastSummary?.processing.latencyAverageMs ?? 0, 0)
        XCTAssertGreaterThan(writer.lastSummary?.processing.latencyPeakMs ?? 0, 0)
        XCTAssertGreaterThan(writer.lastSummary?.processing.utilizationAverage ?? 0, 0)
        XCTAssertGreaterThan(writer.lastSummary?.processing.utilizationPeak ?? 0, 0)
    }

    func testCheckpointSummaryWritesWhileRecording() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let manager = RecordingManager(baseDirectory: tempDir)
        let suiteName = "AnalysisSummaryTests.Checkpoints.\(UUID().uuidString)"
        let captureDefaults = UserDefaults(suiteName: suiteName)!
        captureDefaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AudioCapturePreferencesStore(defaults: captureDefaults)
        let audioCapture = AudioCapture(
            recordingManager: manager,
            capturePreferencesStore: preferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: FakeAudioCaptureBackend(), status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() }
        )
        let writer = CountingSummaryWriter()
        let start = Date(timeIntervalSince1970: 2_000)
        let clock = TestClock([
            start,
            start.addingTimeInterval(300),
            start.addingTimeInterval(300),
            start.addingTimeInterval(300),
            start.addingTimeInterval(600),
            start.addingTimeInterval(600),
            start.addingTimeInterval(600)
        ])
        let timer = TestRepeatingTimer()
        let analyzer = AudioAnalyzer(
            summaryWriter: writer,
            now: clock.now,
            speechTranscriberFactory: { FakeSpeechTranscriber() },
            checkpointInterval: 300,
            checkpointTimerFactory: { timer }
        )
        let analysisDefaults = UserDefaults(suiteName: "AnalysisSummaryTests.Checkpoints.Analysis")!
        analysisDefaults.removePersistentDomain(forName: "AnalysisSummaryTests.Checkpoints.Analysis")
        let preferences = AnalysisPreferencesStore(defaults: analysisDefaults)

        analyzer.setup(audioCapture: audioCapture, preferencesStore: preferences)

        let recordingURL = manager.getNewRecordingURL()
        audioCapture.setRecordingURLForTesting(recordingURL)

        audioCapture.isRecording = true
        let startHandled = expectation(description: "start handled")
        DispatchQueue.main.async { startHandled.fulfill() }
        wait(for: [startHandled], timeout: 1.0)

        XCTAssertEqual(timer.scheduledInterval, 300)
        timer.fire()
        XCTAssertEqual(writer.writeCount, 1)

        audioCapture.isRecording = false
        let stopHandled = expectation(description: "stop handled")
        DispatchQueue.main.async { stopHandled.fulfill() }
        wait(for: [stopHandled], timeout: 1.0)

        XCTAssertEqual(writer.writeCount, 2)

        timer.fire()
        XCTAssertEqual(writer.writeCount, 2)
    }
}

private final class TestClock {
    private var dates: [Date]

    init(_ dates: [Date]) {
        self.dates = dates
    }

    func now() -> Date {
        guard !dates.isEmpty else { return Date() }
        if dates.count == 1 {
            return dates[0]
        }
        return dates.removeFirst()
    }
}

private final class FakeSpeechTranscriber: SpeechTranscribing {
    private let delaySeconds: TimeInterval
    var onTranscription: ((String) -> Void)?

    init(delaySeconds: TimeInterval = 0) {
        self.delaySeconds = delaySeconds
    }

    func startTranscription() {}

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        if delaySeconds > 0 {
            usleep(useconds_t(delaySeconds * 1_000_000))
        }
    }

    func stopTranscription() {}
}

private final class MockSummaryWriter: AnalysisSummaryWriting {
    var lastSummary: AnalysisSummary?
    var lastRecordingURL: URL?

    func summaryURL(for recordingURL: URL) -> URL {
        recordingURL
    }

    func writeSummary(_ summary: AnalysisSummary, for recordingURL: URL) throws {
        lastSummary = summary
        lastRecordingURL = recordingURL
    }

    func deleteSummary(for recordingURL: URL) throws {
        return
    }
}

private final class CountingSummaryWriter: AnalysisSummaryWriting {
    private(set) var writeCount: Int = 0

    func summaryURL(for recordingURL: URL) -> URL {
        recordingURL
    }

    func writeSummary(_ summary: AnalysisSummary, for recordingURL: URL) throws {
        writeCount += 1
    }

    func deleteSummary(for recordingURL: URL) throws {
        return
    }
}

private final class TestRepeatingTimer: RepeatingTimer {
    private(set) var scheduledInterval: TimeInterval?
    private var handler: (() -> Void)?

    func schedule(interval: TimeInterval, handler: @escaping () -> Void) {
        scheduledInterval = interval
        self.handler = handler
    }

    func cancel() {
        handler = nil
    }

    func fire() {
        handler?()
    }
}

private final class FakeAudioCaptureBackend: AudioCaptureBackend {
    let inputFormat: AVAudioFormat
    let inputSource: AudioInputSource = .microphone
    let inputDeviceName: String = "Test Microphone"

    init() {
        self.inputFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void) {}

    func removeTap() {}

    func setConfigurationChangeHandler(_ handler: @escaping () -> Void) {}

    func clearConfigurationChangeHandler() {}

    func selectInputDevice(named preferredName: String?) -> AudioInputDeviceSelectionResult {
        .notRequested
    }

    func start() throws {}

    func stop() {}
}

private final class FakeAudioFileWriter: AudioFileWritable {
    func write(from buffer: AVAudioPCMBuffer) throws {}
}
