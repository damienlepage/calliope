import XCTest

final class ReleasePackagingScriptTests: XCTestCase {
    func testReleasePackagingScriptUsesBuildAppAndTemplates() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/package-release.sh")

        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: scriptURL.path))

        let contents = try String(contentsOf: scriptURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("build-app.sh"))
        XCTAssertTrue(contents.contains("Info.plist"))
        XCTAssertTrue(contents.contains("Calliope"))
    }
}
