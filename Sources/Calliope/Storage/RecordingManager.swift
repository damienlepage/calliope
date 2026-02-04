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
    private let fileManager: FileManager
    
    init(baseDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let documentsPath = baseDirectory ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingsDirectory = documentsPath.appendingPathComponent("CalliopeRecordings", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }
    }
    
    func getNewRecordingURL() -> URL {
        let timestamp = Date().timeIntervalSince1970
        let filename = "recording_\(Int(timestamp)).m4a"
        return recordingsDirectory.appendingPathComponent(filename)
    }
    
    func getAllRecordings() -> [URL] {
        guard let files = try? fileManager.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files.filter { $0.pathExtension == "m4a" || $0.pathExtension == "wav" }
    }
    
    func deleteRecording(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
}
