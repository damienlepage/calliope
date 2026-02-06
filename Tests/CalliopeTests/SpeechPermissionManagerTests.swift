import XCTest
@testable import Calliope

final class SpeechPermissionManagerTests: XCTestCase {
    private final class TestProvider: SpeechPermissionProviding {
        var state: SpeechPermissionState
        var requestedState: SpeechPermissionState

        init(state: SpeechPermissionState, requestedState: SpeechPermissionState) {
            self.state = state
            self.requestedState = requestedState
        }

        func authorizationState() -> SpeechPermissionState {
            state
        }

        func requestAccess(_ completion: @escaping (SpeechPermissionState) -> Void) {
            completion(requestedState)
        }
    }

    func testManagerInitializesFromProvider() {
        let provider = TestProvider(state: .denied, requestedState: .authorized)
        let manager = SpeechPermissionManager(
            provider: provider,
            notificationCenter: NotificationCenter(),
            appActivationNotification: Notification.Name("TestAppActive")
        )
        XCTAssertEqual(manager.state, .denied)
    }

    func testRefreshUpdatesState() {
        let provider = TestProvider(state: .denied, requestedState: .authorized)
        let manager = SpeechPermissionManager(
            provider: provider,
            notificationCenter: NotificationCenter(),
            appActivationNotification: Notification.Name("TestAppActive")
        )

        provider.state = .authorized
        manager.refresh()

        XCTAssertEqual(manager.state, .authorized)
    }

    func testRequestAccessUpdatesState() {
        let provider = TestProvider(state: .notDetermined, requestedState: .authorized)
        let manager = SpeechPermissionManager(
            provider: provider,
            notificationCenter: NotificationCenter(),
            appActivationNotification: Notification.Name("TestAppActive")
        )
        let expectation = expectation(description: "Updates state on request")

        manager.requestAccess()

        DispatchQueue.main.async {
            XCTAssertEqual(manager.state, .authorized)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testRefreshesOnAppActivationNotification() {
        let notificationCenter = NotificationCenter()
        let provider = TestProvider(state: .denied, requestedState: .authorized)
        let manager = SpeechPermissionManager(
            provider: provider,
            notificationCenter: notificationCenter,
            appActivationNotification: Notification.Name("TestAppActive")
        )

        provider.state = .authorized
        let expectation = expectation(description: "Refreshes when app becomes active")

        notificationCenter.post(name: Notification.Name("TestAppActive"), object: nil)
        DispatchQueue.main.async {
            XCTAssertEqual(manager.state, .authorized)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
