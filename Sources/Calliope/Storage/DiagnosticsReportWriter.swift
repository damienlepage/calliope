//
//  DiagnosticsReportWriter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

protocol DiagnosticsReportWriting {
    func writeReport(_ report: DiagnosticsReport) throws -> URL
}

struct DiagnosticsReportWriter: DiagnosticsReportWriting {
    private let recordingsDirectory: URL
    private let fileManager: FileManager

    init(
        recordingsDirectory: URL,
        fileManager: FileManager = .default
    ) {
        self.recordingsDirectory = recordingsDirectory
        self.fileManager = fileManager
    }

    func writeReport(_ report: DiagnosticsReport) throws -> URL {
        let diagnosticsDirectory = recordingsDirectory.appendingPathComponent("Diagnostics", isDirectory: true)
        try fileManager.createDirectory(at: diagnosticsDirectory, withIntermediateDirectories: true)
        let filename = DiagnosticsReport.filename(for: report.createdAt)
        let reportURL = diagnosticsDirectory.appendingPathComponent(filename)
        let data = try DiagnosticsReportWriter.encoder.encode(report)
        try data.write(to: reportURL, options: .atomic)
        return reportURL
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
