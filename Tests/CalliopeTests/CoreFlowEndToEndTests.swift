import AVFoundation
import Combine
import XCTest
@testable import Calliope

@MainActor
final class CoreFlowEndToEndTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testCoreFlowPersistsSettingsAndSupportsRecordingPlayback() throws {
        let resourceURL = try XCTUnwrap(Bundle.module.url(forResource: "mono_test", withExtension: "wav"))
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let recordingManager = TestRecordingManager(baseDirectory: tempDirectory)
        let backend = TestSessionAudioFileInputBackend(fileURL: resourceURL, silenceDuration: 0.05)
        let suiteName = "CoreFlowEndToEndTests.AudioCapture.\(UUID().uuidString)"
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

        let analysisSuite = "CoreFlowEndToEndTests.Analysis.\(UUID().uuidString)"
        let analysisDefaults = UserDefaults(suiteName: analysisSuite)!
        analysisDefaults.removePersistentDomain(forName: analysisSuite)

        let basePreferences = AnalysisPreferencesStore(defaults: analysisDefaults)
        basePreferences.paceMin = 140
        basePreferences.paceMax = 175
        basePreferences.pauseThreshold = 0.05
        basePreferences.crutchWords = ["um"]
        basePreferences.speakingTimeTargetPercent = 40

        let reloadedPreferences = AnalysisPreferencesStore(defaults: analysisDefaults)
        XCTAssertEqual(reloadedPreferences.current, basePreferences.current)

        let transcriber = TestSessionSpeechTranscriber()
        let analyzer = AudioAnalyzer(
            summaryWriter: recordingManager,
            speechTranscriberFactory: { transcriber },
            checkpointInterval: 0.2
        )
        analyzer.setup(audioCapture: capture, preferencesStore: reloadedPreferences)

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
        let recordingDeadline = Date().addingTimeInterval(2.0)
        var recordingWritten = false
        while Date() < recordingDeadline {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: recordingURL.path),
               let size = attributes[.size] as? NSNumber,
               size.int64Value > 0 {
                recordingWritten = true
                break
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        XCTAssertTrue(recordingWritten)

        let summaryDeadline = Date().addingTimeInterval(2.0)
        var summaryWritten = false
        while Date() < summaryDeadline {
            if recordingManager.readSummary(for: recordingURL) != nil {
                summaryWritten = true
                break
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        XCTAssertTrue(summaryWritten)

        let summary = try XCTUnwrap(recordingManager.readSummary(for: recordingURL))
        XCTAssertGreaterThan(summary.pace.totalWords, 0)
        XCTAssertGreaterThan(summary.crutchWords.totalCount, 0)
        XCTAssertGreaterThan(summary.speaking.timeSeconds, 0)

        let playbackStore = TestAudioPlayerStore()
        let viewModel = RecordingListViewModel(
            manager: recordingManager,
            workspace: SpyWorkspace(),
            summaryProvider: { recordingManager.readSummary(for: $0) },
            audioPlayerFactory: { url in
                playbackStore.player(for: url)
            }
        )

        viewModel.refreshRecordings()
        let normalizedRecordingURL = recordingURL.resolvingSymlinksInPath()
        let item = try XCTUnwrap(
            viewModel.recordings.first(where: { $0.url.resolvingSymlinksInPath() == normalizedRecordingURL })
        )

        let availability = viewModel.actionAvailability(for: item)
        XCTAssertTrue(availability.canPlay)
        XCTAssertTrue(availability.canReveal)
        XCTAssertTrue(availability.canDelete)

        viewModel.togglePlayPause(item)

        XCTAssertEqual(
            viewModel.activePlaybackURL?.resolvingSymlinksInPath(),
            recordingURL.resolvingSymlinksInPath()
        )
        XCTAssertFalse(viewModel.isPlaybackPaused)
        XCTAssertEqual(playbackStore.players[item.url]?.playCount, 1)
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
                let samples = floatChannelData[channel]
                for frame in 0..<Int(frameCount) {
                    samples[frame] = amplitude
                }
            }
        }

        return buffer
    }
}

private final class SpyWorkspace: WorkspaceOpening {
    func activateFileViewerSelecting(_ fileURLs: [URL]) {}
}

private final class TestAudioPlayerStore {
    private(set) var players: [URL: TestAudioPlayer] = [:]

    func player(for url: URL) -> TestAudioPlayer {
        if let existing = players[url] {
            return existing
        }
        let player = TestAudioPlayer()
        players[url] = player
        return player
    }
}

private final class TestAudioPlayer: AudioPlaying {
    var isPlaying: Bool = false
    var onPlaybackEnded: (() -> Void)?
    var playCount = 0
    var pauseCount = 0
    var stopCount = 0

    func play() -> Bool {
        playCount += 1
        isPlaying = true
        return true
    }

    func pause() {
        pauseCount += 1
        isPlaying = false
    }

    func stop() {
        stopCount += 1
        isPlaying = false
    }
}
