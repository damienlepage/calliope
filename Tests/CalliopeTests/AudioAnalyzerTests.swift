import XCTest
@testable import Calliope

final class AudioAnalyzerTests: XCTestCase {
    func testWordCountHandlesPunctuationAndCase() {
        let analyzer = AudioAnalyzer()
        let count = analyzer.wordCount(in: "Hello, WORLD!")

        XCTAssertEqual(count, 2)
    }

    func testWordCountIncludesNumbers() {
        let analyzer = AudioAnalyzer()
        let count = analyzer.wordCount(in: "Uh... 42")

        XCTAssertEqual(count, 2)
    }

    func testWordCountSplitsOnHyphens() {
        let analyzer = AudioAnalyzer()
        let count = analyzer.wordCount(in: "you-know")

        XCTAssertEqual(count, 2)
    }

    func testWordCountHandlesEmptyInput() {
        let analyzer = AudioAnalyzer()
        let count = analyzer.wordCount(in: "   ")

        XCTAssertEqual(count, 0)
    }

    func testApplyPreferencesWiresDetectors() {
        let analyzer = AudioAnalyzer()
        let preferences = AnalysisPreferences(
            paceMin: 110,
            paceMax: 170,
            pauseThreshold: 2.2,
            crutchWords: ["alpha", "you know"]
        )

        analyzer.applyPreferences(preferences)

        XCTAssertEqual(analyzer.crutchWordDetector?.analyze("alpha"), 1)
        XCTAssertEqual(analyzer.crutchWordDetector?.analyze("you know"), 1)
        XCTAssertEqual(analyzer.pauseDetector?.pauseThreshold, 2.2)
    }
}
