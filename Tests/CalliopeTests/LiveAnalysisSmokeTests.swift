import AVFoundation
import Combine
import XCTest
@testable import Calliope

final class LiveAnalysisSmokeTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testLiveAnalysisPipelineWithBundledWavUpdatesFeedbackViewModel() throws {
        let resourceURL = try XCTUnwrap(Bundle.module.url(forResource: "mono_test", withExtension: "wav"))
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let recordingURL = tempDirectory.appendingPathComponent("analysis_smoke_recording.wav")
        let recordingManager = RecordingManager(baseDirectory: tempDirectory)
        let backend = TestAnalysisAudioFileInputBackend(fileURL: resourceURL, silenceDuration: 0.06)
        let suiteName = "LiveAnalysisSmokeTests.AudioCapture.\(UUID().uuidString)"
        let captureDefaults = UserDefaults(suiteName: suiteName)!
        captureDefaults.removePersistentDomain(forName: suiteName)
        let capturePreferencesStore = AudioCapturePreferencesStore(defaults: captureDefaults)

        XCTAssertEqual(backend.inputSource, .microphone)

        let capture = AudioCapture(
            recordingManager: recordingManager,
            capturePreferencesStore: capturePreferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            audioFileFactory: { _, settings in
                try SystemAudioFileWriter(url: recordingURL, settings: settings)
            }
        )

        let analysisDefaults = UserDefaults(suiteName: "LiveAnalysisSmokeTests")!
        analysisDefaults.removePersistentDomain(forName: "LiveAnalysisSmokeTests")
        let preferences = AnalysisPreferencesStore(defaults: analysisDefaults)
        preferences.pauseThreshold = 0.05
        preferences.crutchWords = ["um"]

        let transcriber = TestSpeechTranscriber()
        let analyzer = AudioAnalyzer(speechTranscriberFactory: { transcriber })
        analyzer.setup(audioCapture: capture, preferencesStore: preferences)

        let viewModel = LiveFeedbackViewModel()
        viewModel.bind(
            feedbackPublisher: analyzer.feedbackPublisher,
            recordingPublisher: capture.$isRecording.eraseToAnyPublisher(),
            receiveOn: .main,
            throttleInterval: .milliseconds(200)
        )

        var updateCount = 0
        var feedbackUpdateCount = 0
        var observedState: FeedbackState?
        let updateExpectation = expectation(description: "Receives throttled feedback update")

        viewModel.$state
            .dropFirst()
            .sink { state in
                updateCount += 1
                observedState = state
                if state.pace > 0, state.crutchWords > 0, state.pauseCount > 0 {
                    feedbackUpdateCount += 1
                    updateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let privacyState = PrivacyGuardrails.State(hasAcceptedDisclosure: true)
        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        wait(for: [updateExpectation], timeout: 2.0)

        let throttleWindow = expectation(description: "Throttle window")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            throttleWindow.fulfill()
        }
        wait(for: [throttleWindow], timeout: 1.0)

        capture.stopRecording()

        XCTAssertEqual(feedbackUpdateCount, 1)
        XCTAssertGreaterThan(transcriber.transcriptionCount, 1)

        let state = try XCTUnwrap(observedState)
        XCTAssertGreaterThan(state.pace, 0)
        XCTAssertGreaterThan(state.crutchWords, 0)
        XCTAssertGreaterThan(state.pauseCount, 0)
    }
}

private final class TestSpeechTranscriber: SpeechTranscribing {
    var onTranscription: ((String) -> Void)?
    private(set) var transcriptionCount: Int = 0
    private var hasEmitted = false

    func startTranscription() {
        hasEmitted = false
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard !hasEmitted else { return }
        hasEmitted = true
        Thread.sleep(forTimeInterval: 0.05)
        emit("um hello world")
        emit("um hello world again")
        emit("um hello world again today")
    }

    func stopTranscription() {}

    private func emit(_ text: String) {
        transcriptionCount += 1
        onTranscription?(text)
    }
}

private final class TestAnalysisAudioFileInputBackend: AudioCaptureBackend {
    let inputSource: AudioInputSource = .microphone
    let inputFormat: AVAudioFormat
    let inputDeviceName: String = "Test Microphone"

    private let fileURL: URL
    private let silenceDuration: TimeInterval
    private var tapHandler: ((AVAudioPCMBuffer) -> Void)?
    private var configurationChangeHandler: (() -> Void)?
    private var tapBufferSize: AVAudioFrameCount = 1024

    init(fileURL: URL, silenceDuration: TimeInterval) {
        self.fileURL = fileURL
        self.silenceDuration = silenceDuration
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
        var sentBuffers = 0

        while file.framePosition < file.length && sentBuffers < 6 {
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
            sentBuffers += 1
        }

        if let speechBuffer = makeConstantBuffer(amplitude: 0.1, frameCount: tapBufferSize, format: file.processingFormat) {
            tapHandler(speechBuffer)
        }

        Thread.sleep(forTimeInterval: silenceDuration)

        if let silenceBuffer = makeConstantBuffer(amplitude: 0.0, frameCount: tapBufferSize, format: file.processingFormat) {
            tapHandler(silenceBuffer)
        }
    }

    func stop() {
        return
    }

    private func makeConstantBuffer(
        amplitude: Float,
        frameCount: AVAudioFrameCount,
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        if let floatChannelData = buffer.floatChannelData {
            let channels = Int(format.channelCount)
            for channel in 0..<channels {
                let pointer = floatChannelData[channel]
                for index in 0..<Int(frameCount) {
                    pointer[index] = amplitude
                }
            }
            return buffer
        }

        if let int16ChannelData = buffer.int16ChannelData {
            let channels = Int(format.channelCount)
            let value = Int16(amplitude * Float(Int16.max))
            for channel in 0..<channels {
                let pointer = int16ChannelData[channel]
                for index in 0..<Int(frameCount) {
                    pointer[index] = value
                }
            }
            return buffer
        }

        if let int32ChannelData = buffer.int32ChannelData {
            let channels = Int(format.channelCount)
            let value = Int32(amplitude * Float(Int32.max))
            for channel in 0..<channels {
                let pointer = int32ChannelData[channel]
                for index in 0..<Int(frameCount) {
                    pointer[index] = value
                }
            }
            return buffer
        }

        return buffer
    }
}
