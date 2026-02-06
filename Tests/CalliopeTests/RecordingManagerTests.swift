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

        FileManager.default.createFile(atPath: m4aURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: wavURL.path, contents: Data([0x1]))
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

    func testRecordingsDirectoryURLRecreatesMissingDirectory() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingsDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)

        try? FileManager.default.removeItem(at: recordingsDirectory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: recordingsDirectory.path))

        let directoryURL = manager.recordingsDirectoryURL()

        XCTAssertEqual(directoryURL, recordingsDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: recordingsDirectory.path))
    }

    func testGetAllRecordingsSortsNewestFirstAndIgnoresDirectories() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingsDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)

        let olderURL = recordingsDirectory.appendingPathComponent("older.m4a")
        let newerURL = recordingsDirectory.appendingPathComponent("newer.wav")
        let directoryURL = recordingsDirectory.appendingPathComponent("archive.m4a", isDirectory: true)

        FileManager.default.createFile(atPath: olderURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: newerURL.path, contents: Data([0x1]))
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false)

        let now = Date()
        try FileManager.default.setAttributes(
            [.modificationDate: now.addingTimeInterval(-120)],
            ofItemAtPath: olderURL.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: now],
            ofItemAtPath: newerURL.path
        )

        let recordings = manager.getAllRecordings()

        XCTAssertEqual(recordings.count, 2)
        XCTAssertEqual(recordings.first?.standardizedFileURL, newerURL.standardizedFileURL)
        XCTAssertEqual(recordings.last?.standardizedFileURL, olderURL.standardizedFileURL)
        XCTAssertFalse(recordings.contains { $0.standardizedFileURL == directoryURL.standardizedFileURL })
    }

    func testGetAllRecordingsIgnoresZeroByteFiles() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingsDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)

        let emptyURL = recordingsDirectory.appendingPathComponent("empty.m4a")
        let validURL = recordingsDirectory.appendingPathComponent("valid.m4a")

        FileManager.default.createFile(atPath: emptyURL.path, contents: Data())
        FileManager.default.createFile(atPath: validURL.path, contents: Data([0x1]))

        let recordings = manager.getAllRecordings()
        let normalized = Set(recordings.map { $0.standardizedFileURL })

        XCTAssertFalse(normalized.contains(emptyURL.standardizedFileURL))
        XCTAssertTrue(normalized.contains(validURL.standardizedFileURL))
    }

    func testDeleteAllRecordingsRemovesAudioAndMetadataFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingsDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)

        let audioURL = recordingsDirectory.appendingPathComponent("recording_1.m4a")
        let wavURL = recordingsDirectory.appendingPathComponent("recording_2.wav")
        let summaryURL = recordingsDirectory.appendingPathComponent("recording_1.summary.json")
        let integrityURL = recordingsDirectory.appendingPathComponent("recording_1.integrity.json")
        let metadataURL = recordingsDirectory.appendingPathComponent("recording_1.metadata.json")
        let keepURL = recordingsDirectory.appendingPathComponent("notes.txt")

        FileManager.default.createFile(atPath: audioURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: wavURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: summaryURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: integrityURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: metadataURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: keepURL.path, contents: Data([0x1]))

        try manager.deleteAllRecordings()

        XCTAssertFalse(FileManager.default.fileExists(atPath: audioURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: wavURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: summaryURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: integrityURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: metadataURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: keepURL.path))
    }

    func testDeleteRecordingsOlderThanRemovesAudioAndMetadata() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingsDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)

        let oldURL = recordingsDirectory.appendingPathComponent("old.m4a")
        let newURL = recordingsDirectory.appendingPathComponent("new.m4a")
        let oldSummaryURL = oldURL.deletingPathExtension().appendingPathExtension("summary.json")
        let oldIntegrityURL = oldURL.deletingPathExtension().appendingPathExtension("integrity.json")
        let oldMetadataURL = oldURL.deletingPathExtension().appendingPathExtension("metadata.json")

        FileManager.default.createFile(atPath: oldURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: newURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: oldSummaryURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: oldIntegrityURL.path, contents: Data([0x1]))
        FileManager.default.createFile(atPath: oldMetadataURL.path, contents: Data([0x1]))

        let now = Date()
        try FileManager.default.setAttributes(
            [.modificationDate: now.addingTimeInterval(-10 * 24 * 60 * 60)],
            ofItemAtPath: oldURL.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: now],
            ofItemAtPath: newURL.path
        )

        let deletedCount = manager.deleteRecordings(
            olderThan: now.addingTimeInterval(-5 * 24 * 60 * 60)
        )

        XCTAssertEqual(deletedCount, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldSummaryURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldIntegrityURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldMetadataURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: newURL.path))
    }

    func testWriteAndReadMetadata() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let manager = RecordingManager(baseDirectory: tempDir)
        let recordingsDirectory = tempDir.appendingPathComponent("CalliopeRecordings", isDirectory: true)
        let recordingURL = recordingsDirectory.appendingPathComponent("session.m4a")

        FileManager.default.createFile(atPath: recordingURL.path, contents: Data([0x1]))
        let metadata = RecordingMetadata(title: "Weekly Sync")

        try manager.writeMetadata(metadata, for: recordingURL)

        let readBack = manager.readMetadata(for: recordingURL)
        XCTAssertEqual(readBack, metadata)
    }
}
