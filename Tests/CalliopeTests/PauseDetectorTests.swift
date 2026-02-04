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

    func testDetectsPauseWithInt16Buffer() {
        var now = Date(timeIntervalSince1970: 0)
        let detector = PauseDetector(
            pauseThreshold: 1.0,
            speechThreshold: 0.02,
            now: { now }
        )

        let speechBuffer = makeInt16Buffer(sampleValue: 3276)
        let silenceBuffer = makeInt16Buffer(sampleValue: 0)

        XCTAssertFalse(detector.detectPause(in: speechBuffer))

        now = Date(timeIntervalSince1970: 0.6)
        XCTAssertFalse(detector.detectPause(in: silenceBuffer))

        now = Date(timeIntervalSince1970: 1.3)
        XCTAssertTrue(detector.detectPause(in: silenceBuffer))
        XCTAssertEqual(detector.getPauseCount(), 1)

        now = Date(timeIntervalSince1970: 2.2)
        XCTAssertFalse(detector.detectPause(in: speechBuffer))
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

    private func makeInt16Buffer(sampleValue: Int16, frames: AVAudioFrameCount = 128) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 44_100,
            channels: 1,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!

        buffer.frameLength = frames
        let samples = buffer.int16ChannelData?.pointee
        for index in 0..<Int(frames) {
            samples?[index] = sampleValue
        }
        return buffer
    }
}
#endif
