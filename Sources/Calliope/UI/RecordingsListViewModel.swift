//
//  RecordingsListViewModel.swift
//  Calliope
//
//  Created on [Date]
//

import AppKit
import Foundation

protocol RecordingManaging {
    func getAllRecordings() -> [URL]
    func deleteRecording(at url: URL) throws
}

extension RecordingManager: RecordingManaging {}

protocol WorkspaceOpening {
    func activateFileViewerSelecting(_ fileURLs: [URL])
}

extension NSWorkspace: WorkspaceOpening {}

struct RecordingItem: Identifiable, Equatable {
    let url: URL
    let modifiedAt: Date

    var id: URL { url }
    var displayName: String { url.lastPathComponent }
}

@MainActor
final class RecordingListViewModel: ObservableObject {
    @Published private(set) var recordings: [RecordingItem] = []

    private let manager: RecordingManaging
    private let workspace: WorkspaceOpening
    private let modificationDateProvider: (URL) -> Date

    init(
        manager: RecordingManaging = RecordingManager.shared,
        workspace: WorkspaceOpening = NSWorkspace.shared,
        modificationDateProvider: @escaping (URL) -> Date = RecordingListViewModel.defaultModificationDate
    ) {
        self.manager = manager
        self.workspace = workspace
        self.modificationDateProvider = modificationDateProvider
    }

    func loadRecordings() {
        let urls = manager.getAllRecordings()
        recordings = urls.map { url in
            RecordingItem(url: url, modifiedAt: modificationDateProvider(url))
        }
    }

    func reveal(_ item: RecordingItem) {
        workspace.activateFileViewerSelecting([item.url])
    }

    func delete(_ item: RecordingItem) {
        do {
            try manager.deleteRecording(at: item.url)
        } catch {
            return
        }
        loadRecordings()
    }

    private static func defaultModificationDate(_ url: URL) -> Date {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate ?? .distantPast
    }
}
