import XCTest
@testable import Calliope

final class ConferencingCompatibilityVerificationStoreTests: XCTestCase {
    func testDefaultsStartEmpty() {
        let suiteName = "ConferencingCompatibilityVerificationStoreTests.defaults"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ConferencingCompatibilityVerificationStore(defaults: defaults)

        XCTAssertFalse(store.isVerified(.zoom))
        XCTAssertFalse(store.isVerified(.googleMeet))
        XCTAssertFalse(store.isVerified(.microsoftTeams))
    }

    func testMarkVerifiedPersistsAcrossInstances() {
        let suiteName = "ConferencingCompatibilityVerificationStoreTests.persistence"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let expectedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let store = ConferencingCompatibilityVerificationStore(
            defaults: defaults,
            nowProvider: { expectedDate }
        )
        store.markVerified(.zoom)

        let reloaded = ConferencingCompatibilityVerificationStore(defaults: defaults)
        XCTAssertEqual(reloaded.verificationDate(for: .zoom), expectedDate)
        XCTAssertTrue(reloaded.isVerified(.zoom))
    }

    func testClearVerificationRemovesDate() {
        let suiteName = "ConferencingCompatibilityVerificationStoreTests.clear"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ConferencingCompatibilityVerificationStore(
            defaults: defaults,
            nowProvider: { Date(timeIntervalSince1970: 1_700_000_100) }
        )
        store.markVerified(.googleMeet)
        store.clearVerification(.googleMeet)

        XCTAssertFalse(store.isVerified(.googleMeet))
        XCTAssertNil(store.verificationDate(for: .googleMeet))
    }
}
