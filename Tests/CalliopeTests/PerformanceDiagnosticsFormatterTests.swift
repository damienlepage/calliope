//
//  PerformanceDiagnosticsFormatterTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class PerformanceDiagnosticsFormatterTests: XCTestCase {
    func testUtilizationSummaryFormatsPercentages() {
        let result = PerformanceDiagnosticsFormatter.utilizationSummary(
            average: 0.423,
            peak: 0.755
        )

        XCTAssertEqual(result, "Utilization avg/peak: 42% / 76%")
    }

    func testUtilizationSummaryClampsNegativeValues() {
        let result = PerformanceDiagnosticsFormatter.utilizationSummary(
            average: -0.2,
            peak: -1.0
        )

        XCTAssertEqual(result, "Utilization avg/peak: 0% / 0%")
    }

    func testUtilizationSummaryHandlesNonFiniteValues() {
        let result = PerformanceDiagnosticsFormatter.utilizationSummary(
            average: .nan,
            peak: .infinity
        )

        XCTAssertEqual(result, "Utilization avg/peak: -- / --")
    }
}
