import AVFoundation
import XCTest
@testable import Calliope

final class AudioFixtureAnalysisTests: XCTestCase {
    func test203WpmFixtureAnalysisMatchesExpectedMetrics() throws {
        let resourceURL = try XCTUnwrap(Bundle.module.url(forResource: "sample-203wpm", withExtension: "wav"))
        let file = try AVAudioFile(forReading: resourceURL)
        let expectedDuration = Double(file.length) / file.processingFormat.sampleRate
        let targetWpm = 203.0
        let expectedWordCount = Int((targetWpm * expectedDuration / 60.0).rounded())

        let clock = AdvancingClock(start: Date(timeIntervalSince1970: 0))
        let backend = FixtureAudioFileBackend(fileURL: resourceURL, clock: clock)
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let recordingManager = RecordingManager(baseDirectory: tempDirectory)

        let captureSuite = "AudioFixtureAnalysisTests.AudioCapture.\(UUID().uuidString)"
        let captureDefaults = UserDefaults(suiteName: captureSuite)!
        captureDefaults.removePersistentDomain(forName: captureSuite)
        let capturePreferences = AudioCapturePreferencesStore(defaults: captureDefaults)

        let audioCapture = AudioCapture(
            recordingManager: recordingManager,
            capturePreferencesStore: capturePreferences,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, _ in FakeAudioFileWriter() },
            recordingStartConfirmation: { true },
            now: clock.now,
            captureStartValidationTimeout: 5.0,
            captureStartValidationQueue: .main,
            captureStartValidationThreshold: 0.0,
            inputLevelProvider: { _ in 1.0 },
            fileSizeProvider: { _ in 1 }
        )

        let analysisSuite = "AudioFixtureAnalysisTests.Analysis.\(UUID().uuidString)"
        let analysisDefaults = UserDefaults(suiteName: analysisSuite)!
        analysisDefaults.removePersistentDomain(forName: analysisSuite)
        let preferences = AnalysisPreferencesStore(defaults: analysisDefaults)
        preferences.crutchWords = ["um", "uh", "like"]
        preferences.pauseThreshold = 10.0

        let summaryWriter = CapturingSummaryWriter()
        let analyzer = AudioAnalyzer(
            summaryWriter: summaryWriter,
            now: clock.now,
            speechTranscriberFactory: { FixtureSpeechTranscriber() },
            checkpointInterval: 0
        )
        analyzer.setup(audioCapture: audioCapture, preferencesStore: preferences)

        audioCapture.startRecording(
            privacyState: PrivacyGuardrails.State(hasAcceptedDisclosure: true),
            microphonePermission: .authorized,
            hasMicrophoneInput: true
        )

        let startHandled = expectation(description: "start handled")
        DispatchQueue.main.async { startHandled.fulfill() }
        wait(for: [startHandled], timeout: 1.0)

        analyzer.handleTranscription(makeTranscript(wordCount: expectedWordCount))

        audioCapture.stopRecording()

        let stopHandled = expectation(description: "stop handled")
        DispatchQueue.main.async { stopHandled.fulfill() }
        wait(for: [stopHandled], timeout: 1.0)

        guard let summary = summaryWriter.lastSummary else {
            XCTFail("Expected summary to be written")
            return
        }

        let durationTolerance = expectedDuration * 0.1
        XCTAssertEqual(summary.durationSeconds, expectedDuration, accuracy: durationTolerance)
        XCTAssertEqual(summary.pace.averageWPM, targetWpm, accuracy: targetWpm * 0.1)
        XCTAssertEqual(summary.pace.totalWords, expectedWordCount)
        XCTAssertEqual(summary.pauses.count, 0)
        XCTAssertEqual(summary.crutchWords.totalCount, 0)
        XCTAssertEqual(summary.speaking.timeSeconds, expectedDuration, accuracy: durationTolerance)
    }
}

private func makeTranscript(wordCount: Int) -> String {
    guard wordCount > 0 else { return "" }
    return Array(repeating: "word", count: wordCount).joined(separator: " ")
}

private final class AdvancingClock {
    private var current: Date

    init(start: Date) {
        current = start
    }

    func now() -> Date {
        current
    }

    func advance(by duration: TimeInterval) {
        current = current.addingTimeInterval(duration)
    }
}

private final class FixtureSpeechTranscriber: SpeechTranscribing {
    var onTranscription: ((String) -> Void)?

    func startTranscription() {}

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {}

    func stopTranscription() {}
}

private final class FixtureAudioFileBackend: AudioCaptureBackend {
    let inputSource: AudioInputSource = .microphone
    let inputFormat: AVAudioFormat
    let inputDeviceName: String = "Fixture Microphone"

    private let fileURL: URL
    private let clock: AdvancingClock
    private var tapHandler: ((AVAudioPCMBuffer) -> Void)?
    private var tapBufferSize: AVAudioFrameCount = 1024
    private var configurationChangeHandler: (() -> Void)?

    init(fileURL: URL, clock: AdvancingClock) {
        self.fileURL = fileURL
        self.clock = clock
        let file = try? AVAudioFile(forReading: fileURL)
        self.inputFormat = file?.processingFormat ?? AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void) {
        tapBufferSize = bufferSize
        tapHandler = handler
    }

    func removeTap() {
        tapHandler = nil
    }

    func setConfigurationChangeHandler(_ handler: @escaping () -> Void) {
        configurationChangeHandler = handler
    }

    func clearConfigurationChangeHandler() {
        configurationChangeHandler = nil
    }

    func selectInputDevice(named preferredName: String?) -> AudioInputDeviceSelectionResult {
        .notRequested
    }

    func start() throws {
        guard let tapHandler else { return }
        let file = try AVAudioFile(forReading: fileURL)
        var totalDuration: TimeInterval = 0

        while file.framePosition < file.length {
            let remaining = file.length - file.framePosition
            let frameCount = min(AVAudioFrameCount(remaining), tapBufferSize)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount) else {
                break
            }
            try file.read(into: buffer, frameCount: frameCount)
            if buffer.frameLength == 0 {
                break
            }
            tapHandler(buffer)
            let bufferDuration = Double(buffer.frameLength) / file.processingFormat.sampleRate
            totalDuration += bufferDuration
        }

        clock.advance(by: totalDuration)
    }

    func stop() {
        return
    }
}

private final class FakeAudioFileWriter: AudioFileWritable {
    func write(from buffer: AVAudioPCMBuffer) throws {}
}

private final class CapturingSummaryWriter: AnalysisSummaryWriting {
    private(set) var lastSummary: AnalysisSummary?

    func summaryURL(for recordingURL: URL) -> URL {
        recordingURL
    }

    func writeSummary(_ summary: AnalysisSummary, for recordingURL: URL) throws {
        lastSummary = summary
    }

    func deleteSummary(for recordingURL: URL) throws {}
}
