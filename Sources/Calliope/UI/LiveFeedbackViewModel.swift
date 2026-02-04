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

    private var cancellables = Set<AnyCancellable>()

    init(initialState: FeedbackState = .zero) {
        self.state = initialState
    }

    func bind(
        feedbackPublisher: AnyPublisher<FeedbackState, Never>,
        recordingPublisher: AnyPublisher<Bool, Never>,
        receiveOn queue: DispatchQueue = .main,
        throttleInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(200)
    ) {
        cancellables.removeAll()

        let recordingState = recordingPublisher
            .removeDuplicates()
            .share()

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
            }
            .store(in: &cancellables)
    }
}
