import AVFoundation
import XCTest
@testable import Calliope

final class MicrophoneDeviceManagerTests: XCTestCase {
    private final class MockMicrophoneDeviceProvider: MicrophoneDeviceProviding {
        var devices: [AudioInputDevice]
        var defaultDevice: AudioInputDevice?

        init(devices: [AudioInputDevice], defaultDevice: AudioInputDevice? = nil) {
            self.devices = devices
            self.defaultDevice = defaultDevice
        }

        func availableMicrophones() -> [AudioInputDevice] {
            devices
        }

        func defaultMicrophone() -> AudioInputDevice? {
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
        let builtIn = AudioInputDevice(id: 1, name: "Built-in Microphone")
        let usb = AudioInputDevice(id: 2, name: "USB Mic")
        let provider = MockMicrophoneDeviceProvider(
            devices: [builtIn, usb],
            defaultDevice: usb
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
        let builtIn = AudioInputDevice(id: 1, name: "Built-in Microphone")
        provider.devices = [builtIn]
        provider.defaultDevice = builtIn
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
