import AVFoundation
import XCTest
@testable import Calliope

final class AudioCaptureSmokeTests: XCTestCase {
    func testSystemBackendUsesMicrophoneInput() {
        let backend = SystemAudioCaptureBackend()
        XCTAssertEqual(backend.inputSource, .microphone)
    }

    func testCaptureSmokeTestWithBundledWavInputWritesRecording() throws {
        let resourceURL = try XCTUnwrap(Bundle.module.url(forResource: "mono_test", withExtension: "wav"))
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let recordingURL = tempDirectory.appendingPathComponent("smoke_recording.wav")
        let manager = RecordingManager(baseDirectory: tempDirectory)
        let backend = TestAudioFileInputBackend(fileURL: resourceURL)

        let capture = AudioCapture(
            recordingManager: manager,
            backendFactory: { backend },
            audioFileFactory: { _, settings in
                try SystemAudioFileWriter(url: recordingURL, settings: settings)
            }
        )

        let privacyState = PrivacyGuardrails.State(hasAcceptedDisclosure: true)
        capture.startRecording(privacyState: privacyState, microphonePermission: .authorized)
        capture.stopRecording()

        XCTAssertTrue(FileManager.default.fileExists(atPath: recordingURL.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: recordingURL.path)
        let fileSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
        XCTAssertGreaterThan(fileSize, 0)
    }
}

private final class TestAudioFileInputBackend: AudioCaptureBackend {
    let inputSource: AudioInputSource = .microphone
    let inputFormat: AVAudioFormat
    let inputDeviceName: String = "Test Microphone"

    private let fileURL: URL
    private var tapHandler: ((AVAudioPCMBuffer) -> Void)?
    private var configurationChangeHandler: (() -> Void)?
    private var tapBufferSize: AVAudioFrameCount = 1024

    init(fileURL: URL) {
        self.fileURL = fileURL
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

    func start() throws {
        guard let tapHandler else { return }
        let file = try AVAudioFile(forReading: fileURL)

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
        }
    }

    func stop() {
        return
    }
}
