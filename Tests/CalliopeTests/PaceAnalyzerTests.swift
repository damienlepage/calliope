#if canImport(XCTest)
import XCTest
@testable import Calliope

final class PaceAnalyzerTests: XCTestCase {
    func testCalculatePaceUsesElapsedTime() {
        var now = Date(timeIntervalSince1970: 0)
        let analyzer = PaceAnalyzer(now: { now })

        analyzer.start()
        analyzer.updateWordCount(300)

        now = Date(timeIntervalSince1970: 120)
        let pace = analyzer.calculatePace()

        XCTAssertEqual(pace, 150.0, accuracy: 0.001)
    }

    func testResetClearsState() {
        var now = Date(timeIntervalSince1970: 0)
        let analyzer = PaceAnalyzer(now: { now })

        analyzer.start()
        analyzer.updateWordCount(120)
        now = Date(timeIntervalSince1970: 60)
        _ = analyzer.calculatePace()

        analyzer.reset()

        XCTAssertEqual(analyzer.calculatePace(), 0.0, accuracy: 0.001)
    }
}
#endif
