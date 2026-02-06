import XCTest
@testable import Calliope

final class PerformanceValidationChecklistTests: XCTestCase {
    func testSectionsHaveContent() {
        let sections = PerformanceValidationChecklist.sections

        XCTAssertFalse(sections.isEmpty)
        for section in sections {
            XCTAssertFalse(section.title.isEmpty)
            XCTAssertFalse(section.items.isEmpty)
        }
    }

    func testTargetsIncludeKeyRanges() {
        let targets = PerformanceValidationChecklist.sections.first { $0.title == "Targets" }

        XCTAssertNotNil(targets)
        let items = targets?.items.joined(separator: " ") ?? ""
        XCTAssertTrue(items.contains("3-8%"))
        XCTAssertTrue(items.contains("5-12%"))
        XCTAssertTrue(items.contains("<=15%"))
        XCTAssertTrue(items.contains("<=20%"))
        XCTAssertTrue(items.localizedCaseInsensitiveContains("Energy Impact"))
        XCTAssertTrue(items.localizedCaseInsensitiveContains("Memory"))
        XCTAssertTrue(items.localizedCaseInsensitiveContains("Latency"))
    }

    func testValidationStepsIncludeKeyChecks() {
        let steps = PerformanceValidationChecklist.sections.first { $0.title == "Validation Steps" }

        XCTAssertNotNil(steps)
        let items = steps?.items.joined(separator: " ") ?? ""
        XCTAssertTrue(items.localizedCaseInsensitiveContains("Idle baseline"))
        XCTAssertTrue(items.localizedCaseInsensitiveContains("Steady-state"))
        XCTAssertTrue(items.localizedCaseInsensitiveContains("Stress burst"))
        XCTAssertTrue(items.localizedCaseInsensitiveContains("Memory drift"))
        XCTAssertTrue(items.localizedCaseInsensitiveContains("Instruments"))
    }
}
