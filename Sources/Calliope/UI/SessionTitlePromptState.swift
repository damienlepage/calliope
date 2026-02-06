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

    init(draft: String) {
        if let titleInfo = RecordingMetadata.normalizedTitleInfo(draft) {
            isValid = true
            wasTruncated = titleInfo.wasTruncated
            if titleInfo.wasTruncated {
                helperText = "Titles longer than \(RecordingMetadata.maxTitleLength) characters will be shortened."
                helperTone = .warning
            } else {
                helperText = "Max \(RecordingMetadata.maxTitleLength) characters."
                helperTone = .standard
            }
        } else {
            isValid = false
            wasTruncated = false
            helperText = "Enter a title or choose Skip."
            helperTone = .warning
        }
    }
}
