//
//  RecordingManager.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

class RecordingManager {
    static let shared = RecordingManager()
    
    private let recordingsDirectory: URL
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingsDirectory = documentsPath.appendingPathComponent("CalliopeRecordings", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: recordingsDirectory.path) {
            try? FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }
    }
    
    func getNewRecordingURL() -> URL {
        let timestamp = Date().timeIntervalSince1970
        let filename = "recording_\(Int(timestamp)).m4a"
        return recordingsDirectory.appendingPathComponent(filename)
    }
    
    func getAllRecordings() -> [URL] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files.filter { $0.pathExtension == "m4a" || $0.pathExtension == "wav" }
    }
    
    func deleteRecording(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
