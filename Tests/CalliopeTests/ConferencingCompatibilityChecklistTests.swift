//
//  ConferencingCompatibilityChecklistTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class ConferencingCompatibilityChecklistTests: XCTestCase {
    func testChecklistCoversPrimaryApps() {
        let sections = ConferencingCompatibilityChecklist.sections

        XCTAssertTrue(sections.contains { $0.title.localizedCaseInsensitiveContains("zoom") })
        XCTAssertTrue(sections.contains { $0.title.localizedCaseInsensitiveContains("google meet") })
        XCTAssertTrue(sections.contains { $0.title.localizedCaseInsensitiveContains("teams") })
        XCTAssertFalse(sections.isEmpty)
        XCTAssertTrue(sections.allSatisfy { !$0.items.isEmpty })
    }

    func testChecklistMentionsMicSelectionAndTroubleshooting() {
        let sections = ConferencingCompatibilityChecklist.sections
        let items = sections.flatMap(\.items)

        XCTAssertTrue(items.contains { $0.localizedCaseInsensitiveContains("same microphone") })
        XCTAssertTrue(
            items.contains {
                $0.localizedCaseInsensitiveContains("clipped")
                    || $0.localizedCaseInsensitiveContains("muffled")
                    || $0.localizedCaseInsensitiveContains("over-processed")
            }
        )
    }
}
