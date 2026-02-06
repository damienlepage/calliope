import XCTest

final class CoverageScriptTests: XCTestCase {
    func testCoverageScriptIncludesThresholdGate() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/coverage.sh")

        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: scriptURL.path))

        let contents = try String(contentsOf: scriptURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("COVERAGE_THRESHOLD"))
        XCTAssertTrue(contents.contains("Line coverage:"))
        XCTAssertTrue(contents.contains("llvm-cov report"))
    }
}
