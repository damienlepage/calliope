#if canImport(XCTest)
//
//  RecordingManagerTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import Foundation
import XCTest
@testable import Calliope

final class RecordingManagerTests: XCTestCase {
    func testNewRecordingURLUsesLocalDirectoryAndM4AExtension() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)

        let url = manager.getNewRecordingURL()
        let expectedDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)

        XCTAssertEqual(url.pathExtension, "m4a")
        XCTAssertEqual(url.deletingLastPathComponent(), expectedDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedDirectory.path))
    }

    func testNewRecordingURLIsUniqueAcrossCalls() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        var uuidSeed = 0
        let manager = RecordingManager(
            baseDirectory: tempDir,
            now: { Date(timeIntervalSince1970: 1000) },
            uuid: {
                uuidSeed += 1
                return UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", uuidSeed))!
            }
        )

        let first = manager.getNewRecordingURL()
        let second = manager.getNewRecordingURL()

        XCTAssertNotEqual(first.lastPathComponent, second.lastPathComponent)
        XCTAssertTrue(first.lastPathComponent.contains("recording_"))
        XCTAssertTrue(second.lastPathComponent.contains("recording_"))
    }

    func testGetAllRecordingsFiltersByExtension() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingsDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)

        let m4aURL = recordingsDirectory.appendingPathComponent("sample.m4a")
        let wavURL = recordingsDirectory.appendingPathComponent("sample.wav")
        let txtURL = recordingsDirectory.appendingPathComponent("sample.txt")

        FileManager.default.createFile(atPath: m4aURL.path, contents: Data())
        FileManager.default.createFile(atPath: wavURL.path, contents: Data())
        FileManager.default.createFile(atPath: txtURL.path, contents: Data())

        let recordings = manager.getAllRecordings()
        let normalized = Set(recordings.map { $0.standardizedFileURL })

        XCTAssertTrue(normalized.contains(m4aURL.standardizedFileURL))
        XCTAssertTrue(normalized.contains(wavURL.standardizedFileURL))
        XCTAssertFalse(normalized.contains(txtURL.standardizedFileURL))
    }

    func testDeleteRecordingRemovesFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingsDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)
        let fileURL = recordingsDirectory.appendingPathComponent("remove.m4a")

        FileManager.default.createFile(atPath: fileURL.path, contents: Data())
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        try manager.deleteRecording(at: fileURL)

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testGetAllRecordingsRecreatesMissingDirectory() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingsDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)

        try? FileManager.default.removeItem(at: recordingsDirectory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: recordingsDirectory.path))

        let recordings = manager.getAllRecordings()

        XCTAssertTrue(recordings.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: recordingsDirectory.path))
    }

    func testGetNewRecordingURLRecreatesMissingDirectory() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingsDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)

        try? FileManager.default.removeItem(at: recordingsDirectory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: recordingsDirectory.path))

        let url = manager.getNewRecordingURL()

        XCTAssertTrue(FileManager.default.fileExists(atPath: recordingsDirectory.path))
        XCTAssertEqual(url.deletingLastPathComponent(), recordingsDirectory)
    }
}
#endif
