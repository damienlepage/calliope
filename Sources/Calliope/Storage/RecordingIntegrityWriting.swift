//
//  RecordingIntegrityWriting.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

protocol RecordingIntegrityWriting {
    func integrityReportURL(for recordingURL: URL) -> URL
    func writeIntegrityReport(_ report: RecordingIntegrityReport, for recordingURL: URL) throws
    func deleteIntegrityReport(for recordingURL: URL) throws
    func readIntegrityReport(for recordingURL: URL) -> RecordingIntegrityReport?
}
