import XCTest
@testable import Calliope

final class PrivacyDisclosureStoreTests: XCTestCase {
    func testAcceptancePersistsInDefaults() {
        let suiteName = "PrivacyDisclosureStoreTests"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var store = PrivacyDisclosureStore(defaults: defaults)
        XCTAssertFalse(store.hasAcceptedDisclosure)

        store.hasAcceptedDisclosure = true
        let reloaded = PrivacyDisclosureStore(defaults: defaults)
        XCTAssertTrue(reloaded.hasAcceptedDisclosure)
    }
}
