//
//  ConferencingCompatibilityLogTemplateTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class ConferencingCompatibilityLogTemplateTests: XCTestCase {
    func testTemplateIncludesExpectedSectionsAndDate() {
        let date = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2024,
            month: 2,
            day: 6
        ).date!
        let template = ConferencingCompatibilityLogTemplate.make(date: date)

        XCTAssertTrue(template.contains("## Compatibility Check - 2024-02-06"))
        XCTAssertTrue(template.contains("### Zoom"))
        XCTAssertTrue(template.contains("### Google Meet (Chrome)"))
        XCTAssertTrue(template.contains("### Microsoft Teams"))
        XCTAssertTrue(template.contains("- macOS version:"))
        XCTAssertTrue(template.contains("- Calliope version/build:"))
    }
}
