//
//  RecordingsFolderActionModel.swift
//  Calliope
//
//  Created on [Date]
//

import AppKit
import Foundation

struct RecordingsFolderActionModel {
    private let manager: RecordingManaging
    private let workspace: WorkspaceOpening

    init(
        manager: RecordingManaging = RecordingManager.shared,
        workspace: WorkspaceOpening = NSWorkspace.shared
    ) {
        self.manager = manager
        self.workspace = workspace
    }

    func openRecordingsFolder() {
        workspace.activateFileViewerSelecting([manager.recordingsDirectoryURL()])
    }
}
