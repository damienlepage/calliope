import XCTest
@testable import Calliope

final class PathDisplayFormatterTests: XCTestCase {
    func testFormatsHomeDirectoryPathWithTilde() {
        let home = URL(fileURLWithPath: "/Users/tester")
        let path = "/Users/tester/CalliopeRecordings"

        let display = PathDisplayFormatter.displayPath(path, homeDirectory: home)

        XCTAssertEqual(display, "~/CalliopeRecordings")
    }

    func testFormatsHomeDirectoryRootAsTilde() {
        let home = URL(fileURLWithPath: "/Users/tester")

        let display = PathDisplayFormatter.displayPath("/Users/tester", homeDirectory: home)

        XCTAssertEqual(display, "~")
    }

    func testLeavesNonHomePathsUntouched() {
        let home = URL(fileURLWithPath: "/Users/tester")
        let path = "/Volumes/External/Recordings"

        let display = PathDisplayFormatter.displayPath(path, homeDirectory: home)

        XCTAssertEqual(display, path)
    }
}
