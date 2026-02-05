//
//  LiveFeedbackViewModel.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import Foundation

final class LiveFeedbackViewModel: ObservableObject {
    @Published private(set) var state: FeedbackState
    @Published private(set) var sessionDurationSeconds: Int? = nil

    private var cancellables = Set<AnyCancellable>()

    init(initialState: FeedbackState = .zero) {
        self.state = initialState
    }

    func bind(
        feedbackPublisher: AnyPublisher<FeedbackState, Never>,
        recordingPublisher: AnyPublisher<Bool, Never>,
        receiveOn queue: DispatchQueue = .main,
        throttleInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(200),
        now: @escaping () -> Date = Date.init,
        timerPublisherFactory: @escaping () -> AnyPublisher<Date, Never> = {
            Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .eraseToAnyPublisher()
        }
    ) {
        cancellables.removeAll()

        let recordingState = recordingPublisher
            .removeDuplicates()
            .share()

        recordingState
            .filter { $0 }
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.state = .zero
                self?.sessionDurationSeconds = 0
            }
            .store(in: &cancellables)

        recordingState
            .map { isRecording in
                isRecording ? feedbackPublisher : Empty().eraseToAnyPublisher()
            }
            .switchToLatest()
            .throttle(for: throttleInterval, scheduler: queue, latest: true)
            .receive(on: queue)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)

        recordingState
            .filter { !$0 }
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.state = .zero
                self?.sessionDurationSeconds = nil
            }
            .store(in: &cancellables)

        recordingState
            .map { isRecording -> AnyPublisher<Int?, Never> in
                guard isRecording else {
                    return Just<Int?>(nil).eraseToAnyPublisher()
                }
                let start = now()
                return timerPublisherFactory()
                    .map { date in
                        max(0, Int(date.timeIntervalSince(start)))
                    }
                    .prepend(0)
                    .map(Optional.init)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .removeDuplicates()
            .receive(on: queue)
            .sink { [weak self] seconds in
                self?.sessionDurationSeconds = seconds
            }
            .store(in: &cancellables)
    }
}
