//
//  SessionTitlePromptState.swift
//  Calliope
//
//  Created on [Date]
//

struct SessionTitlePromptState: Equatable {
    enum HelperTone: Equatable {
        case standard
        case warning
    }

    let isValid: Bool
    let helperText: String
    let helperTone: HelperTone
    let wasTruncated: Bool

    init(draft: String, defaultTitle: String? = nil) {
        if let titleInfo = RecordingMetadata.normalizedTitleInfo(draft) {
            isValid = true
            wasTruncated = titleInfo.wasTruncated
            if titleInfo.wasTruncated {
                helperText = "Will save as \"\(titleInfo.normalized)\". Titles longer than \(RecordingMetadata.maxTitleLength) characters will be shortened."
                helperTone = .warning
            } else {
                helperText = "Will save as \"\(titleInfo.normalized)\"."
                helperTone = .standard
            }
        } else {
            isValid = false
            wasTruncated = false
            if let defaultTitle, !defaultTitle.isEmpty {
                helperText = "Will save as \"\(defaultTitle)\". Enter a title or choose Skip."
                helperTone = .standard
            } else {
                helperText = "Enter a title or choose Skip."
                helperTone = .warning
            }
        }
    }
}
