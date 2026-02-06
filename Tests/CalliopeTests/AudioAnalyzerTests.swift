import XCTest
@testable import Calliope
#if canImport(AVFoundation)
import AVFoundation
#endif

final class AudioAnalyzerTests: XCTestCase {
    func testWordCountHandlesPunctuationAndCase() {
        let analyzer = AudioAnalyzer()
        let count = analyzer.wordCount(in: "Hello, WORLD!")

        XCTAssertEqual(count, 2)
    }

    func testWordCountIncludesNumbers() {
        let analyzer = AudioAnalyzer()
        let count = analyzer.wordCount(in: "Uh... 42")

        XCTAssertEqual(count, 2)
    }

    func testWordCountSplitsOnHyphens() {
        let analyzer = AudioAnalyzer()
        let count = analyzer.wordCount(in: "you-know")

        XCTAssertEqual(count, 2)
    }

    func testWordCountHandlesEmptyInput() {
        let analyzer = AudioAnalyzer()
        let count = analyzer.wordCount(in: "   ")

        XCTAssertEqual(count, 0)
    }

    func testApplyPreferencesWiresDetectors() {
        let analyzer = AudioAnalyzer()
        let preferences = AnalysisPreferences(
            paceMin: 110,
            paceMax: 170,
            pauseThreshold: 2.2,
            crutchWords: ["alpha", "you know"]
        )

        analyzer.applyPreferences(preferences)

        XCTAssertEqual(analyzer.crutchWordDetector?.analyze("alpha"), 1)
        XCTAssertEqual(analyzer.crutchWordDetector?.analyze("you know"), 1)
        XCTAssertEqual(analyzer.pauseDetector?.pauseThreshold, 2.2)
    }

    func testTranscriptionIgnoredWhenNotRecording() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let manager = RecordingManager(baseDirectory: tempDir)
        let suiteName = "AudioAnalyzerTests.AudioCapture.\(UUID().uuidString)"
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
        let analysisSuiteName = "AudioAnalyzerTests.Analysis.\(UUID().uuidString)"
        let analysisDefaults = UserDefaults(suiteName: analysisSuiteName)!
        analysisDefaults.removePersistentDomain(forName: analysisSuiteName)
        let analysisPreferences = AnalysisPreferencesStore(defaults: analysisDefaults)
        let analyzer = AudioAnalyzer(
            summaryWriter: manager,
            speechTranscriberFactory: { FakeSpeechTranscriber() }
        )

        analyzer.setup(audioCapture: audioCapture, preferencesStore: analysisPreferences)

        analyzer.handleTranscription("um hello world")

        let expectation = expectation(description: "Allow main queue to process")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(analyzer.crutchWordCount, 0)
        XCTAssertEqual(analyzer.currentPace, 0)
    }

    #if canImport(AVFoundation)
    func testAudioBufferIgnoredWhenNotRecording() {
        let analyzer = AudioAnalyzer()
        analyzer.applyPreferences(
            AnalysisPreferences(
                paceMin: 110,
                paceMax: 170,
                pauseThreshold: 1.0,
                crutchWords: ["uh"]
            )
        )

        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4) else {
            XCTFail("Failed to create test audio buffer.")
            return
        }
        buffer.frameLength = 4
        if let channelData = buffer.floatChannelData {
            channelData[0][0] = 1.0
            channelData[0][1] = 1.0
            channelData[0][2] = 1.0
            channelData[0][3] = 1.0
        }

        analyzer.processAudioBuffer(buffer)

        XCTAssertEqual(analyzer.inputLevel, 0.0)
        XCTAssertEqual(analyzer.pauseCount, 0)
        XCTAssertEqual(analyzer.pauseAverageDuration, 0)
    }
    #endif
}

private final class FakeSpeechTranscriber: SpeechTranscribing {
    var onTranscription: ((String) -> Void)?

    func startTranscription() {}

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {}

    func stopTranscription() {}
}

private final class FakeAudioCaptureBackend: AudioCaptureBackend {
    let inputFormat: AVAudioFormat
    let inputSource: AudioInputSource = .microphone
    let inputDeviceName: String = "Test Microphone"
    private var configurationHandler: (() -> Void)?

    init() {
        inputFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    func installTap(bufferSize: AVAudioFrameCount, handler: @escaping (AVAudioPCMBuffer) -> Void) {}

    func removeTap() {}

    func setConfigurationChangeHandler(_ handler: @escaping () -> Void) {
        configurationHandler = handler
    }

    func clearConfigurationChangeHandler() {
        configurationHandler = nil
    }

    func selectInputDevice(named preferredName: String?) -> AudioInputDeviceSelectionResult {
        return preferredName == nil ? .notRequested : .selected
    }

    func start() throws {}

    func stop() {}
}

private final class FakeAudioFileWriter: AudioFileWritable {
    func write(from buffer: AVAudioPCMBuffer) throws {}
}
