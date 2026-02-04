//
//  LiveFeedbackViewModelTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import Combine
import XCTest
@testable import Calliope

final class LiveFeedbackViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testUpdatesStateFromFeedbackPublisher() {
        let feedbackSubject = PassthroughSubject<FeedbackState, Never>()
        let recordingSubject = CurrentValueSubject<Bool, Never>(true)
        let viewModel = LiveFeedbackViewModel()

        viewModel.bind(
            feedbackPublisher: feedbackSubject.eraseToAnyPublisher(),
            recordingPublisher: recordingSubject.eraseToAnyPublisher(),
            receiveOn: .main
        )

        let expected = FeedbackState(pace: 155, crutchWords: 2, pauseCount: 1)
        let expectation = expectation(description: "Receives feedback update")

        viewModel.$state
            .dropFirst()
            .sink { state in
                if state == expected {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        feedbackSubject.send(expected)

        wait(for: [expectation], timeout: 1.0)
    }

    func testResetsWhenRecordingStops() {
        let feedbackSubject = PassthroughSubject<FeedbackState, Never>()
        let recordingSubject = CurrentValueSubject<Bool, Never>(true)
        let viewModel = LiveFeedbackViewModel()

        viewModel.bind(
            feedbackPublisher: feedbackSubject.eraseToAnyPublisher(),
            recordingPublisher: recordingSubject.eraseToAnyPublisher(),
            receiveOn: .main
        )

        let expectation = expectation(description: "Resets on stop")

        viewModel.$state
            .dropFirst()
            .sink { state in
                if state == .zero {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        feedbackSubject.send(FeedbackState(pace: 140, crutchWords: 3, pauseCount: 2))
        recordingSubject.send(false)

        wait(for: [expectation], timeout: 1.0)
    }

    func testBindClearsPreviousSubscriptions() {
        let feedbackSubject = PassthroughSubject<FeedbackState, Never>()
        let recordingSubject = CurrentValueSubject<Bool, Never>(true)
        let viewModel = LiveFeedbackViewModel()

        viewModel.bind(
            feedbackPublisher: feedbackSubject.eraseToAnyPublisher(),
            recordingPublisher: recordingSubject.eraseToAnyPublisher(),
            receiveOn: .main
        )

        viewModel.bind(
            feedbackPublisher: feedbackSubject.eraseToAnyPublisher(),
            recordingPublisher: recordingSubject.eraseToAnyPublisher(),
            receiveOn: .main
        )

        let expectation = expectation(description: "Receives a single update after rebind")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        viewModel.$state
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        feedbackSubject.send(FeedbackState(pace: 120, crutchWords: 1, pauseCount: 0))

        wait(for: [expectation], timeout: 1.0)
    }

    func testThrottlesFeedbackUpdates() {
        let feedbackSubject = PassthroughSubject<FeedbackState, Never>()
        let recordingSubject = CurrentValueSubject<Bool, Never>(true)
        let viewModel = LiveFeedbackViewModel()

        viewModel.bind(
            feedbackPublisher: feedbackSubject.eraseToAnyPublisher(),
            recordingPublisher: recordingSubject.eraseToAnyPublisher(),
            receiveOn: .main,
            throttleInterval: .milliseconds(200)
        )

        let expected = FeedbackState(pace: 190, crutchWords: 4, pauseCount: 2)
        let expectation = expectation(description: "Receives throttled update")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        viewModel.$state
            .dropFirst()
            .sink { state in
                XCTAssertEqual(state, expected)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        feedbackSubject.send(FeedbackState(pace: 120, crutchWords: 1, pauseCount: 0))
        feedbackSubject.send(expected)

        wait(for: [expectation], timeout: 1.0)
    }
}
