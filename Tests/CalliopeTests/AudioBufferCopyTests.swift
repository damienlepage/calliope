#if canImport(XCTest) && canImport(AVFoundation)
import AVFoundation
import XCTest
@testable import Calliope

final class AudioBufferCopyTests: XCTestCase {
    func testCopyPreservesFramesAndSamples() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        guard let format else {
            XCTFail("Missing audio format")
            return
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4) else {
            XCTFail("Missing audio buffer")
            return
        }

        buffer.frameLength = 4
        buffer.floatChannelData?.pointee[0] = 0.1
        buffer.floatChannelData?.pointee[1] = 0.2
        buffer.floatChannelData?.pointee[2] = 0.3
        buffer.floatChannelData?.pointee[3] = 0.4

        guard let copied = AudioBufferCopy.copy(buffer) else {
            XCTFail("Copy failed")
            return
        }

        XCTAssertEqual(copied.frameLength, buffer.frameLength)
        XCTAssertEqual(copied.frameCapacity, buffer.frameCapacity)
        XCTAssertEqual(copied.floatChannelData?.pointee[0], 0.1, accuracy: 0.0001)
        XCTAssertEqual(copied.floatChannelData?.pointee[1], 0.2, accuracy: 0.0001)
        XCTAssertEqual(copied.floatChannelData?.pointee[2], 0.3, accuracy: 0.0001)
        XCTAssertEqual(copied.floatChannelData?.pointee[3], 0.4, accuracy: 0.0001)
    }
}
#endif
