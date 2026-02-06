import XCTest
@testable import Calliope

final class CaptureStatusFormatterTests: XCTestCase {
    func testReturnsNilWhenNotRecording() {
        let result = CaptureStatusFormatter.statusText(
            inputDeviceName: "Built-in Microphone",
            backendStatus: .standard,
            isRecording: false
        )

        XCTAssertNil(result)
    }

    func testIncludesDeviceAndBackendWhenRecording() {
        let result = CaptureStatusFormatter.statusText(
            inputDeviceName: "Built-in Microphone",
            backendStatus: .standard,
            isRecording: true
        )

        XCTAssertEqual(result, "Input: Built-in Microphone · Capture: Standard mic")
    }

    func testFallsBackToBackendWhenDeviceNameEmpty() {
        let result = CaptureStatusFormatter.statusText(
            inputDeviceName: "   ",
            backendStatus: .voiceIsolation,
            isRecording: true
        )

        XCTAssertEqual(result, "Capture: Voice Isolation enabled")
    }

    func testOverlayIncludesDeviceAndBackend() {
        let result = CaptureStatusFormatter.overlayStatusText(
            inputDeviceName: "External Mic",
            backendStatus: .voiceIsolation
        )

        XCTAssertEqual(result, "Input: External Mic · Capture: Voice Isolation enabled")
    }

    func testOverlayFallsBackToBackendWhenDeviceNameEmpty() {
        let result = CaptureStatusFormatter.overlayStatusText(
            inputDeviceName: "  ",
            backendStatus: .standard
        )

        XCTAssertEqual(result, "Capture: Standard mic")
    }
}
