import XCTest
@testable import Calliope

final class CrutchWordDetectorTests: XCTestCase {
    func testCountsSingleWordCrutchesWithPunctuation() {
        let detector = CrutchWordDetector()
        let text = "Uh, well... like, so?"

        let count = detector.analyze(text)

        XCTAssertEqual(count, 4)
    }

    func testCountsMultiWordPhrases() {
        let detector = CrutchWordDetector()
        let text = "You know, I think you know?"

        let count = detector.analyze(text)

        XCTAssertEqual(count, 2)
    }

    func testDoesNotCountSubstrings() {
        let detector = CrutchWordDetector()
        let text = "Album basics are basic."

        let count = detector.analyze(text)

        XCTAssertEqual(count, 0)
    }

    func testCustomCrutchWordsAreParsed() {
        let detector = CrutchWordDetector(crutchWords: ["next level", "rad"])
        let text = "That was rad, next level."

        let count = detector.analyze(text)

        XCTAssertEqual(count, 2)
    }
}
