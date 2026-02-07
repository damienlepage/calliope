//
//  PostSessionReviewCoordinator.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct PostSessionReviewCoordinator: Equatable {
    var pendingSessionForTitle: CompletedRecordingSession?
    var lastCompletedSession: CompletedRecordingSession?
    var postSessionReview: PostSessionReview?
    var sessionTitleDraft: String = ""

    mutating func handleCompletedSession(
        _ session: CompletedRecordingSession,
        reviewLoader: (CompletedRecordingSession) -> PostSessionReview?
    ) {
        pendingSessionForTitle = session
        lastCompletedSession = session
        postSessionReview = reviewLoader(session)
        sessionTitleDraft = ""
    }

    mutating func handleTitleSaved() {
        pendingSessionForTitle = nil
        sessionTitleDraft = ""
    }

    mutating func handleTitleSkipped() {
        pendingSessionForTitle = nil
        sessionTitleDraft = ""
    }

    mutating func handleRecordingStarted() {
        pendingSessionForTitle = nil
        lastCompletedSession = nil
        postSessionReview = nil
        sessionTitleDraft = ""
    }

    mutating func handleEditTitle() {
        guard pendingSessionForTitle == nil else { return }
        guard let lastCompletedSession else { return }
        pendingSessionForTitle = lastCompletedSession
    }
}
