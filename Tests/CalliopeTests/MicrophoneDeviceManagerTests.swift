import AVFoundation
import XCTest
@testable import Calliope

final class MicrophoneDeviceManagerTests: XCTestCase {
    private final class MockMicrophoneDeviceProvider: MicrophoneDeviceProviding {
        var devices: [String]

        init(devices: [String]) {
            self.devices = devices
        }

        func availableMicrophoneNames() -> [String] {
            devices
        }
    }

    func testReportsUnavailableWhenNoDevices() {
        let notificationCenter = NotificationCenter()
        let provider = MockMicrophoneDeviceProvider(devices: [])

        let manager = MicrophoneDeviceManager(
            provider: provider,
            notificationCenter: notificationCenter
        )

        XCTAssertFalse(manager.hasMicrophoneInput)
    }

    func testUpdatesWhenDevicesChange() {
        let notificationCenter = NotificationCenter()
        let provider = MockMicrophoneDeviceProvider(devices: [])

        let manager = MicrophoneDeviceManager(
            provider: provider,
            notificationCenter: notificationCenter
        )

        let connected = expectation(description: "Reports available after device connects")
        provider.devices = ["Built-in Microphone"]
        notificationCenter.post(name: .AVCaptureDeviceWasConnected, object: nil)
        DispatchQueue.main.async {
            XCTAssertTrue(manager.hasMicrophoneInput)
            connected.fulfill()
        }
        wait(for: [connected], timeout: 1.0)

        let disconnected = expectation(description: "Reports unavailable after device disconnects")
        provider.devices = []
        notificationCenter.post(name: .AVCaptureDeviceWasDisconnected, object: nil)
        DispatchQueue.main.async {
            XCTAssertFalse(manager.hasMicrophoneInput)
            disconnected.fulfill()
        }
        wait(for: [disconnected], timeout: 1.0)
    }
}
