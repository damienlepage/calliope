//
//  AnalysisSummaryWriting.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

protocol AnalysisSummaryWriting {
    func summaryURL(for recordingURL: URL) -> URL
    func writeSummary(_ summary: AnalysisSummary, for recordingURL: URL) throws
    func deleteSummary(for recordingURL: URL) throws
}
