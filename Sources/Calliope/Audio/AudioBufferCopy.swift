//
//  AudioBufferCopy.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation

enum AudioBufferCopy {
    static func copy(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: buffer.format.commonFormat,
                                          sampleRate: buffer.format.sampleRate,
                                          channels: buffer.format.channelCount,
                                          interleaved: buffer.format.isInterleaved) else {
            return nil
        }

        guard let newBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else {
            return nil
        }

        newBuffer.frameLength = buffer.frameLength

        if format.commonFormat == .pcmFormatFloat32, let source = buffer.floatChannelData, let destination = newBuffer.floatChannelData {
            let frames = Int(buffer.frameLength)
            let channels = Int(buffer.format.channelCount)
            for channel in 0..<channels {
                destination[channel].update(from: source[channel], count: frames)
            }
            return newBuffer
        }

        if format.commonFormat == .pcmFormatInt16, let source = buffer.int16ChannelData, let destination = newBuffer.int16ChannelData {
            let frames = Int(buffer.frameLength)
            let channels = Int(buffer.format.channelCount)
            for channel in 0..<channels {
                destination[channel].update(from: source[channel], count: frames)
            }
            return newBuffer
        }

        if format.commonFormat == .pcmFormatInt32, let source = buffer.int32ChannelData, let destination = newBuffer.int32ChannelData {
            let frames = Int(buffer.frameLength)
            let channels = Int(buffer.format.channelCount)
            for channel in 0..<channels {
                destination[channel].update(from: source[channel], count: frames)
            }
            return newBuffer
        }

        return nil
    }
}
