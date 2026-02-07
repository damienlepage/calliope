import XCTest

final class ReleaseQATemplateTests: XCTestCase {
    func testReleaseQATemplateExistsAndIncludesKeySections() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let templateURL = repositoryRoot.appendingPathComponent("RELEASE_QA_TEMPLATE.md")

        XCTAssertTrue(FileManager.default.fileExists(atPath: templateURL.path))

        let contents = try String(contentsOf: templateURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("Build & Run"))
        XCTAssertTrue(contents.contains("Permissions Flow"))
        XCTAssertTrue(contents.contains("Session Lifecycle"))
        XCTAssertTrue(contents.contains("Live Feedback"))
        XCTAssertTrue(contents.contains("Recordings & Playback"))
        XCTAssertTrue(contents.contains("Diagnostics Export"))
        XCTAssertTrue(contents.contains("Packaging & Artifacts"))
        XCTAssertTrue(contents.contains("Notarization"))
        XCTAssertTrue(contents.contains("Performance Validation"))
        XCTAssertTrue(contents.contains("Privacy Confirmation"))
        XCTAssertTrue(contents.contains("User-Facing Release Notes"))
        XCTAssertTrue(contents.localizedCaseInsensitiveContains("No audio"))
    }
}
