import AVFoundation
import Combine
import XCTest
@testable import Calliope

final class SessionFlowSmokeTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testSessionFlowWritesSummaryAndRecapMatches() throws {
        let resourceURL = try XCTUnwrap(Bundle.module.url(forResource: "mono_test", withExtension: "wav"))
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let recordingManager = TestRecordingManager(baseDirectory: tempDirectory)
        let backend = TestSessionAudioFileInputBackend(fileURL: resourceURL, silenceDuration: 0.05)
        let suiteName = "SessionFlowSmokeTests.AudioCapture.\(UUID().uuidString)"
        let captureDefaults = UserDefaults(suiteName: suiteName)!
        captureDefaults.removePersistentDomain(forName: suiteName)
        let capturePreferencesStore = AudioCapturePreferencesStore(defaults: captureDefaults)

        let capture = AudioCapture(
            recordingManager: recordingManager,
            capturePreferencesStore: capturePreferencesStore,
            backendSelector: { _ in
                AudioCaptureBackendSelection(backend: backend, status: .standard)
            },
            recordingStartTimeout: 0.5,
            recordingStartTimeoutQueue: .main,
            recordingStartConfirmation: { true },
            captureStartValidationTimeout: 0.5,
            captureStartValidationQueue: .main,
            captureStartValidationThreshold: 0.01
        )

        let analysisDefaults = UserDefaults(suiteName: "SessionFlowSmokeTests.Analysis.\(UUID().uuidString)")!
        analysisDefaults.removePersistentDomain(forName: "SessionFlowSmokeTests.Analysis")
        let preferences = AnalysisPreferencesStore(defaults: analysisDefaults)
        preferences.pauseThreshold = 0.05
        preferences.crutchWords = ["um"]

        let transcriber = TestSessionSpeechTranscriber()
        let analyzer = AudioAnalyzer(
            summaryWriter: recordingManager,
            speechTranscriberFactory: { transcriber },
            checkpointInterval: 0.2
        )
        analyzer.setup(audioCapture: capture, preferencesStore: preferences)

        let transcriptionExpectation = expectation(description: "Receives transcription")
        var didFulfillTranscription = false
        transcriber.onEmit = {
            guard !didFulfillTranscription else { return }
            didFulfillTranscription = true
            transcriptionExpectation.fulfill()
        }

        let completedExpectation = expectation(description: "Completed session")
        var completedSession: CompletedRecordingSession?
        capture.$completedRecordingSession
            .compactMap { $0 }
            .sink { session in
                completedSession = session
                completedExpectation.fulfill()
            }
            .store(in: &cancellables)

        let privacyState = PrivacyGuardrails.State(hasAcceptedDisclosure: true)
        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)

        wait(for: [transcriptionExpectation], timeout: 2.0)
        capture.stopRecording()
        wait(for: [completedExpectation], timeout: 2.0)

        let session = try XCTUnwrap(completedSession)
        XCTAssertFalse(session.recordingURLs.isEmpty)

        let recordingURL = session.recordingURLs[0]
        let recordingExpectation = expectation(description: "Recording written")
        DispatchQueue.global(qos: .utility).async {
            let deadline = Date().addingTimeInterval(2.0)
            while Date() < deadline {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: recordingURL.path),
                   let size = attributes[.size] as? NSNumber,
                   size.int64Value > 0 {
                    recordingExpectation.fulfill()
                    return
                }
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        wait(for: [recordingExpectation], timeout: 2.5)

        let recordingsExpectation = expectation(description: "Recording appears in list")
        let expectedURL = recordingURL.resolvingSymlinksInPath()
        DispatchQueue.global(qos: .utility).async {
            let deadline = Date().addingTimeInterval(4.0)
            while Date() < deadline {
                let normalized = recordingManager.getAllRecordings().map { $0.resolvingSymlinksInPath() }
                if normalized.contains(expectedURL) {
                    recordingsExpectation.fulfill()
                    return
                }
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        wait(for: [recordingsExpectation], timeout: 4.5)

        let summaryExpectation = expectation(description: "Summary written")
        DispatchQueue.global(qos: .utility).async {
            let deadline = Date().addingTimeInterval(2.0)
            while Date() < deadline {
                if recordingManager.readSummary(for: recordingURL) != nil {
                    summaryExpectation.fulfill()
                    return
                }
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        wait(for: [summaryExpectation], timeout: 2.5)

        let summary = try XCTUnwrap(recordingManager.readSummary(for: recordingURL))
        XCTAssertGreaterThan(summary.durationSeconds, 0)
        XCTAssertGreaterThan(summary.pace.totalWords, 0)
        XCTAssertGreaterThan(summary.crutchWords.totalCount, 0)
        XCTAssertGreaterThan(summary.speaking.timeSeconds, 0)
        XCTAssertGreaterThan(summary.speaking.turnCount, 0)

        let review = try XCTUnwrap(PostSessionReview(session: session))
        XCTAssertEqual(review.summary, SessionTitleSummary(summary: summary))
    }
}

private final class TestRecordingManager: RecordingManager {
    override func getNewRecordingURL(sessionID: String? = nil, segmentIndex: Int? = nil) -> URL {
        let baseURL = super.getNewRecordingURL(sessionID: sessionID, segmentIndex: segmentIndex)
        return baseURL.deletingPathExtension().appendingPathExtension("wav")
    }
}

private final class TestSessionSpeechTranscriber: SpeechTranscribing {
    var onTranscription: ((String) -> Void)?
    var onEmit: (() -> Void)?
    private var hasEmitted = false

    func startTranscription() {
        hasEmitted = false
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard !hasEmitted else { return }
        hasEmitted = true
        emit("um hello world")
        emit("um hello world again")
    }

    func stopTranscription() {}

    private func emit(_ text: String) {
        onTranscription?(text)
        onEmit?()
    }
}

private final class TestSessionAudioFileInputBackend: AudioCaptureBackend {
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

        return nil
    }
}
