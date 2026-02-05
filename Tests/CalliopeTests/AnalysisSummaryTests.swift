import AVFoundation
import XCTest
@testable import Calliope

final class AnalysisSummaryTests: XCTestCase {
    func testSummaryWrittenWhenRecordingStops() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let manager = RecordingManager(baseDirectory: tempDir)
        let suiteName = "AnalysisSummaryTests.AudioCapture.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AudioCapturePreferencesStore(defaults: defaults)
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
        let defaults = UserDefaults(suiteName: "AnalysisSummaryTests")!
        defaults.removePersistentDomain(forName: "AnalysisSummaryTests")
        let preferences = AnalysisPreferencesStore(defaults: defaults)

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
                thresholdSeconds: 1.5
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 3,
                counts: ["um": 2, "you know": 1]
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
                thresholdSeconds: 1.0
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 1,
                counts: ["um": 1]
            )
        )

        try manager.writeSummary(summary, for: recordingURL)

        let summaryURL = manager.summaryURL(for: recordingURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: summaryURL.path))

        try manager.deleteRecording(at: recordingURL)

        XCTAssertFalse(FileManager.default.fileExists(atPath: summaryURL.path))
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
    var onTranscription: ((String) -> Void)?

    func startTranscription() {}

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {}

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

    func start() throws {}

    func stop() {}
}

private final class FakeAudioFileWriter: AudioFileWritable {
    func write(from buffer: AVAudioPCMBuffer) throws {}
}
