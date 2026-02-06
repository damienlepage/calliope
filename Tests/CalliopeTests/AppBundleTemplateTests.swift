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

        let iconName = dict["CFBundleIconFile"] as? String
        XCTAssertEqual(iconName, "AppIcon")

        let shortVersion = dict["CFBundleShortVersionString"] as? String
        XCTAssertNotNil(shortVersion)
        XCTAssertFalse(shortVersion?.isEmpty ?? true)

        let category = dict["LSApplicationCategoryType"] as? String
        XCTAssertNotNil(category)
        XCTAssertFalse(category?.isEmpty ?? true)

        let micUsage = dict["NSMicrophoneUsageDescription"] as? String
        XCTAssertNotNil(micUsage)
        XCTAssertFalse(micUsage?.isEmpty ?? true)

        let speechUsage = dict["NSSpeechRecognitionUsageDescription"] as? String
        XCTAssertNotNil(speechUsage)
        XCTAssertFalse(speechUsage?.isEmpty ?? true)
    }

    func testBundleTemplatesArePresentAndUsedByBuildScript() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let pkgInfoURL = repositoryRoot.appendingPathComponent("scripts/app/PkgInfo")
        let iconURL = repositoryRoot.appendingPathComponent("scripts/app/AppIcon.icns")
        let buildScriptURL = repositoryRoot.appendingPathComponent("scripts/build-app.sh")

        XCTAssertTrue(FileManager.default.fileExists(atPath: pkgInfoURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: iconURL.path))

        let contents = try String(contentsOf: pkgInfoURL, encoding: .utf8)
        XCTAssertEqual(contents.trimmingCharacters(in: .whitespacesAndNewlines), "APPL????")

        let buildScript = try String(contentsOf: buildScriptURL, encoding: .utf8)
        XCTAssertTrue(buildScript.contains("PkgInfo"))
        XCTAssertTrue(buildScript.contains("AppIcon.icns"))
    }
}
