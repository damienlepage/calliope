//
//  RepeatingTimer.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

protocol RepeatingTimer {
    func schedule(interval: TimeInterval, handler: @escaping () -> Void)
    func cancel()
}

final class DispatchRepeatingTimer: RepeatingTimer {
    private let queue: DispatchQueue
    private var timer: DispatchSourceTimer?

    init(queue: DispatchQueue = DispatchQueue.global(qos: .utility)) {
        self.queue = queue
    }

    func schedule(interval: TimeInterval, handler: @escaping () -> Void) {
        cancel()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler(handler: handler)
        self.timer = timer
        timer.resume()
    }

    func cancel() {
        timer?.cancel()
        timer = nil
    }
}
