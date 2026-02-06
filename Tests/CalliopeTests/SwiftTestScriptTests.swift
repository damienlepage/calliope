import XCTest

final class SwiftTestScriptTests: XCTestCase {
    func testSwiftTestScriptUsesLocalCaches() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/swift-test.sh")

        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: scriptURL.path))

        let contents = try String(contentsOf: scriptURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("SWIFTPM_CACHE_PATH"))
        XCTAssertTrue(contents.contains("module-cache-path"))
        XCTAssertTrue(contents.contains("fmodules-cache-path"))
    }
}
