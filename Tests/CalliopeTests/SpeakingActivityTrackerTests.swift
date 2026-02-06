import AVFoundation
import XCTest
@testable import Calliope

final class SpeakingActivityTrackerTests: XCTestCase {
    func testTracksSpeakingTimeAndTurns() {
        let tracker = SpeakingActivityTracker(speechThreshold: 0.02)
        let speechBuffer = makeBuffer(amplitude: 0.1, sampleRate: 1000, frames: 1000)
        let silenceBuffer = makeBuffer(amplitude: 0.0, sampleRate: 1000, frames: 1000)

        tracker.process(speechBuffer)
        tracker.process(speechBuffer)
        tracker.process(silenceBuffer)
        tracker.process(silenceBuffer)
        tracker.process(speechBuffer)

        let summary = tracker.summary()
        XCTAssertEqual(summary.timeSeconds, 3, accuracy: 0.001)
        XCTAssertEqual(summary.turnCount, 2)
    }

    func testResetClearsSpeakingActivity() {
        let tracker = SpeakingActivityTracker(speechThreshold: 0.02)
        let speechBuffer = makeBuffer(amplitude: 0.1, sampleRate: 1000, frames: 500)

        tracker.process(speechBuffer)
        XCTAssertEqual(tracker.summary().timeSeconds, 0.5, accuracy: 0.001)
        XCTAssertEqual(tracker.summary().turnCount, 1)

        tracker.reset()
        XCTAssertEqual(tracker.summary().timeSeconds, 0, accuracy: 0.001)
        XCTAssertEqual(tracker.summary().turnCount, 0)
    }

    private func makeBuffer(
        amplitude: Float,
        sampleRate: Double,
        frames: AVAudioFrameCount
    ) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!

        buffer.frameLength = frames
        let samples = buffer.floatChannelData?.pointee
        for index in 0..<Int(frames) {
            samples?[index] = amplitude
        }
        return buffer
    }
}
