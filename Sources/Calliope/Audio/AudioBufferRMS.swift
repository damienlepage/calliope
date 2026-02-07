//
//  AudioBufferRMS.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation

extension AVAudioPCMBuffer {
    func rmsAmplitude() -> Float {
        let frameCount = Int(frameLength)
        guard frameCount > 0 else { return 0 }
        let channelCount = Int(format.channelCount)
        guard channelCount > 0 else { return 0 }

        if format.isInterleaved {
            return rmsInterleaved(frameCount: frameCount, channelCount: channelCount)
        }

        if let floatChannelData {
            return rmsNonInterleavedFloat(
                channelCount: channelCount,
                frameCount: frameCount,
                sampleProvider: { channel in floatChannelData[channel] }
            )
        }

        if let int16ChannelData {
            return rmsNonInterleavedInt16(
                channelCount: channelCount,
                frameCount: frameCount,
                sampleProvider: { channel in int16ChannelData[channel] }
            )
        }

        if let int32ChannelData {
            return rmsNonInterleavedInt32(
                channelCount: channelCount,
                frameCount: frameCount,
                sampleProvider: { channel in int32ChannelData[channel] }
            )
        }

        return 0
    }

    private func rmsInterleaved(frameCount: Int, channelCount: Int) -> Float {
        guard let data = audioBufferList.pointee.mBuffers.mData else { return 0 }

        switch format.commonFormat {
        case .pcmFormatFloat32:
            let samples = data.assumingMemoryBound(to: Float.self)
            return rmsInterleavedSamples(samples, frameCount: frameCount, channelCount: channelCount) { $0 }
        case .pcmFormatInt16:
            let samples = data.assumingMemoryBound(to: Int16.self)
            let scale = 1.0 as Float / Float(Int16.max)
            return rmsInterleavedSamples(samples, frameCount: frameCount, channelCount: channelCount) { Float($0) * scale }
        case .pcmFormatInt32:
            let samples = data.assumingMemoryBound(to: Int32.self)
            let scale = 1.0 as Float / Float(Int32.max)
            return rmsInterleavedSamples(samples, frameCount: frameCount, channelCount: channelCount) { Float($0) * scale }
        default:
            return 0
        }
    }

    private func rmsNonInterleavedFloat(
        channelCount: Int,
        frameCount: Int,
        sampleProvider: (Int) -> UnsafeMutablePointer<Float>
    ) -> Float {
        var maxRms: Float = 0
        for channel in 0..<channelCount {
            let samples = sampleProvider(channel)
            var sum: Float = 0
            for index in 0..<frameCount {
                let sample = samples[index]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameCount))
            maxRms = max(maxRms, rms)
        }
        return maxRms
    }

    private func rmsNonInterleavedInt16(
        channelCount: Int,
        frameCount: Int,
        sampleProvider: (Int) -> UnsafeMutablePointer<Int16>
    ) -> Float {
        var maxRms: Float = 0
        let scale = 1.0 as Float / Float(Int16.max)
        for channel in 0..<channelCount {
            let samples = sampleProvider(channel)
            var sum: Float = 0
            for index in 0..<frameCount {
                let sample = Float(samples[index]) * scale
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameCount))
            maxRms = max(maxRms, rms)
        }
        return maxRms
    }

    private func rmsNonInterleavedInt32(
        channelCount: Int,
        frameCount: Int,
        sampleProvider: (Int) -> UnsafeMutablePointer<Int32>
    ) -> Float {
        var maxRms: Float = 0
        let scale = 1.0 as Float / Float(Int32.max)
        for channel in 0..<channelCount {
            let samples = sampleProvider(channel)
            var sum: Float = 0
            for index in 0..<frameCount {
                let sample = Float(samples[index]) * scale
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameCount))
            maxRms = max(maxRms, rms)
        }
        return maxRms
    }

    private func rmsInterleavedSamples<T>(
        _ samples: UnsafePointer<T>,
        frameCount: Int,
        channelCount: Int,
        transformer: (T) -> Float
    ) -> Float {
        var sums = Array(repeating: Float(0), count: channelCount)
        for frameIndex in 0..<frameCount {
            let baseIndex = frameIndex * channelCount
            for channel in 0..<channelCount {
                let sample = transformer(samples[baseIndex + channel])
                sums[channel] += sample * sample
            }
        }
        var maxRms: Float = 0
        for channel in 0..<channelCount {
            let rms = sqrt(sums[channel] / Float(frameCount))
            maxRms = max(maxRms, rms)
        }
        return maxRms
    }
}
