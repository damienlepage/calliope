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
    @Published private(set) var showWaitingForSpeech: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var staleFeedbackWorkItem: DispatchWorkItem?
    private var isRecording = false

    init(initialState: FeedbackState = .zero) {
        self.state = initialState
    }

    func bind(
        feedbackPublisher: AnyPublisher<FeedbackState, Never>,
        recordingPublisher: AnyPublisher<Bool, Never>,
        receiveOn queue: DispatchQueue = .main,
        throttleInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(200),
        staleFeedbackDelay: DispatchQueue.SchedulerTimeType.Stride = .seconds(3),
        now: @escaping () -> Date = Date.init,
        timerPublisherFactory: @escaping () -> AnyPublisher<Date, Never> = {
            Timer.publish(every: 1.0, on: .main, in: .common)
                .autoconnect()
                .eraseToAnyPublisher()
        }
    ) {
        cancellables.removeAll()
        staleFeedbackWorkItem?.cancel()
        staleFeedbackWorkItem = nil
        isRecording = false
        let queueKey = DispatchSpecificKey<Void>()
        queue.setSpecific(key: queueKey, value: ())

        let recordingState = recordingPublisher
            .removeDuplicates()

        recordingState
            .filter { $0 }
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self, self.state != .zero else { return }
                self.state = .zero
            }
            .store(in: &cancellables)

        feedbackPublisher
            .throttle(for: throttleInterval, scheduler: queue, latest: true)
            .receive(on: queue)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)

        let feedbackEvents = feedbackPublisher
            .filter { $0.inputLevel >= InputLevelMeter.meaningfulThreshold }
            .map { _ in () }

        let performOnQueue: (@escaping () -> Void) -> Void = { block in
            if DispatchQueue.getSpecific(key: queueKey) != nil {
                block()
            } else {
                queue.async(execute: block)
            }
        }

        let resetWaitingForSpeechTimer = { [weak self] in
            guard let self, self.isRecording else { return }
            performOnQueue {
                self.showWaitingForSpeech = false
                self.staleFeedbackWorkItem?.cancel()

                let workItem = DispatchWorkItem { [weak self] in
                    self?.showWaitingForSpeech = true
                }
                self.staleFeedbackWorkItem = workItem
                queue.asyncAfter(deadline: .now() + staleFeedbackDelay.timeInterval, execute: workItem)
            }
        }

        recordingState
            .sink { [weak self] isRecording in
                guard let self else { return }
                self.isRecording = isRecording

                performOnQueue {
                    if isRecording {
                        resetWaitingForSpeechTimer()
                    } else {
                        self.staleFeedbackWorkItem?.cancel()
                        self.staleFeedbackWorkItem = nil
                        self.showWaitingForSpeech = false
                    }
                }
            }
            .store(in: &cancellables)

        feedbackEvents
            .sink { _ in
                resetWaitingForSpeechTimer()
            }
            .store(in: &cancellables)

        recordingState
            .filter { !$0 }
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self else { return }
                self.state = .zero
                self.sessionDurationSeconds = nil
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
