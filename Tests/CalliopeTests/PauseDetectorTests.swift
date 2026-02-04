#if canImport(XCTest) && canImport(AVFoundation)
import AVFoundation
import XCTest
@testable import Calliope

final class PauseDetectorTests: XCTestCase {
    func testDetectsPauseAfterSilenceThreshold() {
        var now = Date(timeIntervalSince1970: 0)
        let detector = PauseDetector(
            pauseThreshold: 1.0,
            speechThreshold: 0.02,
            now: { now }
        )

        let speechBuffer = makeBuffer(amplitude: 0.1)
        let silenceBuffer = makeBuffer(amplitude: 0.0)

        XCTAssertFalse(detector.detectPause(in: speechBuffer))

        now = Date(timeIntervalSince1970: 0.5)
        XCTAssertFalse(detector.detectPause(in: silenceBuffer))

        now = Date(timeIntervalSince1970: 1.1)
        XCTAssertTrue(detector.detectPause(in: silenceBuffer))
        XCTAssertEqual(detector.getPauseCount(), 1)

        now = Date(timeIntervalSince1970: 1.6)
        XCTAssertFalse(detector.detectPause(in: silenceBuffer))
        XCTAssertEqual(detector.getPauseCount(), 1)

        now = Date(timeIntervalSince1970: 2.0)
        XCTAssertFalse(detector.detectPause(in: speechBuffer))

        now = Date(timeIntervalSince1970: 3.2)
        XCTAssertTrue(detector.detectPause(in: silenceBuffer))
        XCTAssertEqual(detector.getPauseCount(), 2)
    }

    private func makeBuffer(amplitude: Float, frames: AVAudioFrameCount = 128) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!

        buffer.frameLength = frames
        let samples = buffer.floatChannelData?.pointee
        for index in 0..<Int(frames) {
            samples?[index] = amplitude
        }
        return buffer
    }
}
#endif
