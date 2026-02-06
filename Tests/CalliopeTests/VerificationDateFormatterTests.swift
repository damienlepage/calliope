import XCTest
@testable import Calliope

final class VerificationDateFormatterTests: XCTestCase {
    func testFormatsMediumDateWithInjectedLocaleAndTimeZone() {
        let locale = Locale(identifier: "en_US_POSIX")
        let timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = Date(timeIntervalSince1970: 1_736_899_200) // 2025-01-15 00:00:00 UTC

        let formatted = VerificationDateFormatter.format(date, locale: locale, timeZone: timeZone)

        XCTAssertEqual(formatted, "Jan 15, 2025")
    }
}
