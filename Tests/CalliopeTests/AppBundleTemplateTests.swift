import XCTest

final class AppBundleTemplateTests: XCTestCase {
    func testInfoPlistTemplateContainsRequiredKeys() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let plistURL = repositoryRoot.appendingPathComponent("scripts/app/Info.plist")

        let data = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let dict = plist as? [String: Any] else {
            XCTFail("Info.plist template is not a dictionary")
            return
        }

        XCTAssertEqual(dict["CFBundleExecutable"] as? String, "Calliope")
        XCTAssertEqual(dict["CFBundlePackageType"] as? String, "APPL")

        let identifier = dict["CFBundleIdentifier"] as? String
        XCTAssertNotNil(identifier)
        XCTAssertFalse(identifier?.isEmpty ?? true)

        let shortVersion = dict["CFBundleShortVersionString"] as? String
        XCTAssertNotNil(shortVersion)
        XCTAssertFalse(shortVersion?.isEmpty ?? true)

        let micUsage = dict["NSMicrophoneUsageDescription"] as? String
        XCTAssertNotNil(micUsage)
        XCTAssertFalse(micUsage?.isEmpty ?? true)
    }
}
