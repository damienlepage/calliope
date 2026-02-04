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

    func testCopyPreservesInt16Samples() {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                         sampleRate: 44_100,
                                         channels: 1,
                                         interleaved: false) else {
            XCTFail("Missing int16 format")
            return
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4) else {
            XCTFail("Missing int16 buffer")
            return
        }

        buffer.frameLength = 4
        buffer.int16ChannelData?.pointee[0] = 100
        buffer.int16ChannelData?.pointee[1] = -200
        buffer.int16ChannelData?.pointee[2] = 300
        buffer.int16ChannelData?.pointee[3] = -400

        guard let copied = AudioBufferCopy.copy(buffer) else {
            XCTFail("Copy failed")
            return
        }

        XCTAssertEqual(copied.frameLength, buffer.frameLength)
        XCTAssertEqual(copied.frameCapacity, buffer.frameCapacity)
        XCTAssertEqual(copied.int16ChannelData?.pointee[0], 100)
        XCTAssertEqual(copied.int16ChannelData?.pointee[1], -200)
        XCTAssertEqual(copied.int16ChannelData?.pointee[2], 300)
        XCTAssertEqual(copied.int16ChannelData?.pointee[3], -400)
    }

    func testCopyPreservesInt32Samples() {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatInt32,
                                         sampleRate: 44_100,
                                         channels: 1,
                                         interleaved: false) else {
            XCTFail("Missing int32 format")
            return
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4) else {
            XCTFail("Missing int32 buffer")
            return
        }

        buffer.frameLength = 4
        buffer.int32ChannelData?.pointee[0] = 1000
        buffer.int32ChannelData?.pointee[1] = -2000
        buffer.int32ChannelData?.pointee[2] = 3000
        buffer.int32ChannelData?.pointee[3] = -4000

        guard let copied = AudioBufferCopy.copy(buffer) else {
            XCTFail("Copy failed")
            return
        }

        XCTAssertEqual(copied.frameLength, buffer.frameLength)
        XCTAssertEqual(copied.frameCapacity, buffer.frameCapacity)
        XCTAssertEqual(copied.int32ChannelData?.pointee[0], 1000)
        XCTAssertEqual(copied.int32ChannelData?.pointee[1], -2000)
        XCTAssertEqual(copied.int32ChannelData?.pointee[2], 3000)
        XCTAssertEqual(copied.int32ChannelData?.pointee[3], -4000)
    }

    func testCopyReturnsNilForUnsupportedFormat() {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat64,
                                         sampleRate: 44_100,
                                         channels: 1,
                                         interleaved: false) else {
            XCTFail("Missing float64 format")
            return
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1) else {
            XCTFail("Missing float64 buffer")
            return
        }

        buffer.frameLength = 1

        XCTAssertNil(AudioBufferCopy.copy(buffer))
    }
}
#endif
