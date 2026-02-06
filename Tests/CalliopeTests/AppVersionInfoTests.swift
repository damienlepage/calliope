import XCTest
@testable import Calliope

final class AppVersionInfoTests: XCTestCase {
    func testDisplayTextWithShortAndBuild() {
        let info = AppVersionInfo(infoDictionary: [
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "45"
        ])

        XCTAssertEqual(info.displayText, "Version 1.2.3 (Build 45)")
    }

    func testDisplayTextWithShortOnly() {
        let info = AppVersionInfo(infoDictionary: [
            "CFBundleShortVersionString": "2.0.1"
        ])

        XCTAssertEqual(info.displayText, "Version 2.0.1")
    }

    func testDisplayTextWithBuildOnly() {
        let info = AppVersionInfo(infoDictionary: [
            "CFBundleVersion": "108"
        ])

        XCTAssertEqual(info.displayText, "Build 108")
    }

    func testDisplayTextWithEmptyValues() {
        let info = AppVersionInfo(infoDictionary: [
            "CFBundleShortVersionString": "  ",
            "CFBundleVersion": ""
        ])

        XCTAssertEqual(info.displayText, "Version unavailable")
    }
}
