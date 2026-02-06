import AVFoundation
import XCTest
@testable import Calliope

final class MicrophoneDeviceManagerTests: XCTestCase {
    private final class MockMicrophoneDeviceProvider: MicrophoneDeviceProviding {
        var devices: [String]
        var defaultDevice: String?

        init(devices: [String], defaultDevice: String? = nil) {
            self.devices = devices
            self.defaultDevice = defaultDevice
        }

        func availableMicrophoneNames() -> [String] {
            devices
        }

        func defaultMicrophoneName() -> String? {
            defaultDevice
        }
    }

    func testReportsUnavailableWhenNoDevices() {
        let notificationCenter = NotificationCenter()
        let provider = MockMicrophoneDeviceProvider(devices: [], defaultDevice: nil)

        let manager = MicrophoneDeviceManager(
            provider: provider,
            notificationCenter: notificationCenter
        )

        XCTAssertFalse(manager.hasMicrophoneInput)
        XCTAssertTrue(manager.availableMicrophoneNames.isEmpty)
        XCTAssertNil(manager.defaultMicrophoneName)
    }

    func testProvidesDeviceNamesAndDefault() {
        let notificationCenter = NotificationCenter()
        let provider = MockMicrophoneDeviceProvider(
            devices: ["Built-in Microphone", "USB Mic"],
            defaultDevice: "USB Mic"
        )

        let manager = MicrophoneDeviceManager(
            provider: provider,
            notificationCenter: notificationCenter
        )

        XCTAssertEqual(manager.availableMicrophoneNames, ["Built-in Microphone", "USB Mic"])
        XCTAssertEqual(manager.defaultMicrophoneName, "USB Mic")
    }

    func testUpdatesWhenDevicesChange() {
        let notificationCenter = NotificationCenter()
        let provider = MockMicrophoneDeviceProvider(devices: [], defaultDevice: nil)

        let manager = MicrophoneDeviceManager(
            provider: provider,
            notificationCenter: notificationCenter
        )

        let connected = expectation(description: "Reports available after device connects")
        provider.devices = ["Built-in Microphone"]
        provider.defaultDevice = "Built-in Microphone"
        notificationCenter.post(name: .AVCaptureDeviceWasConnected, object: nil)
        DispatchQueue.main.async {
            XCTAssertTrue(manager.hasMicrophoneInput)
            XCTAssertEqual(manager.availableMicrophoneNames, ["Built-in Microphone"])
            XCTAssertEqual(manager.defaultMicrophoneName, "Built-in Microphone")
            connected.fulfill()
        }
        wait(for: [connected], timeout: 1.0)

        let disconnected = expectation(description: "Reports unavailable after device disconnects")
        provider.devices = []
        provider.defaultDevice = nil
        notificationCenter.post(name: .AVCaptureDeviceWasDisconnected, object: nil)
        DispatchQueue.main.async {
            XCTAssertFalse(manager.hasMicrophoneInput)
            XCTAssertTrue(manager.availableMicrophoneNames.isEmpty)
            XCTAssertNil(manager.defaultMicrophoneName)
            disconnected.fulfill()
        }
        wait(for: [disconnected], timeout: 1.0)
    }
}
