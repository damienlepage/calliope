//
//  AssetDurationLoader.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Foundation

enum AssetDurationLoader {
    static func loadSeconds(for url: URL) -> TimeInterval? {
        let asset = AVURLAsset(url: url)
        guard let duration = loadDuration(for: asset), duration.isNumeric else {
            return nil
        }
        let seconds = CMTimeGetSeconds(duration)
        return seconds > 0 ? seconds : nil
    }

    private static func loadDuration(for asset: AVURLAsset) -> CMTime? {
        let semaphore = DispatchSemaphore(value: 0)
        let resultPointer = UnsafeMutablePointer<CMTime?>.allocate(capacity: 1)
        resultPointer.initialize(to: nil)
        Task.detached {
            let duration = try? await asset.load(.duration)
            resultPointer.pointee = duration
            semaphore.signal()
        }
        semaphore.wait()
        let duration = resultPointer.pointee
        resultPointer.deinitialize(count: 1)
        resultPointer.deallocate()
        return duration
    }
}
