import XCTest
@testable import Calliope

final class PrivacyDisclosureGateTests: XCTestCase {
    func testRequiresDisclosureWhenNotAccepted() {
        XCTAssertTrue(PrivacyDisclosureGate.requiresDisclosure(hasAcceptedDisclosure: false))
    }

    func testDoesNotRequireDisclosureAfterAcceptance() {
        XCTAssertFalse(PrivacyDisclosureGate.requiresDisclosure(hasAcceptedDisclosure: true))
    }
}
