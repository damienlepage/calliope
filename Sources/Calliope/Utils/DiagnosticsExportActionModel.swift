//
//  DiagnosticsExportActionModel.swift
//  Calliope
//
//  Created on [Date]
//

import AppKit
import Foundation

struct DiagnosticsExportActionModel {
    private let manager: RecordingManaging
    private let workspace: WorkspaceOpening
    private let writerFactory: (URL) -> DiagnosticsReportWriting

    init(
        manager: RecordingManaging = RecordingManager.shared,
        workspace: WorkspaceOpening = NSWorkspace.shared,
        writerFactory: @escaping (URL) -> DiagnosticsReportWriting = { DiagnosticsReportWriter(recordingsDirectory: $0) }
    ) {
        self.manager = manager
        self.workspace = workspace
        self.writerFactory = writerFactory
    }

    func export(report: DiagnosticsReport) {
        do {
            let writer = writerFactory(manager.recordingsDirectoryURL())
            let reportURL = try writer.writeReport(report)
            workspace.activateFileViewerSelecting([reportURL])
        } catch {
            return
        }
    }
}
