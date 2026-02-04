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
        receiveOn queue: DispatchQueue = .main
    ) {
        feedbackPublisher
            .receive(on: queue)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)

        recordingPublisher
            .removeDuplicates()
            .filter { !$0 }
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.state = .zero
            }
            .store(in: &cancellables)
    }
}
