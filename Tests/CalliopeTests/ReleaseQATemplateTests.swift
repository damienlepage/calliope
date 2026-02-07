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

    func testReleaseQAReportScaffoldingExists() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let scriptURL = repositoryRoot.appendingPathComponent("scripts/new-release-qa-report.sh")
        let releaseReadmeURL = repositoryRoot.appendingPathComponent("release/README.md")
        let readmeURL = repositoryRoot.appendingPathComponent("README.md")

        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: releaseReadmeURL.path))

        let releaseReadmeContents = try String(contentsOf: releaseReadmeURL, encoding: .utf8)
        XCTAssertTrue(releaseReadmeContents.contains("QA-YYYY-MM-DD.md"))
        XCTAssertTrue(releaseReadmeContents.contains("new-release-qa-report.sh"))

        let readmeContents = try String(contentsOf: readmeURL, encoding: .utf8)
        XCTAssertTrue(readmeContents.contains("new-release-qa-report.sh"))
        XCTAssertTrue(readmeContents.contains("release/"))
    }
}
