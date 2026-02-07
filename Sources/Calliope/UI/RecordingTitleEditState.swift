//
//  RecordingTitleEditState.swift
//  Calliope
//
//  Created on [Date]
//

struct RecordingTitleEditState: Equatable {
    enum HelperTone: Equatable {
        case standard
        case warning
    }

    let isValid: Bool
    let helperText: String
    let helperTone: HelperTone
    let wasTruncated: Bool

    init(draft: String, defaultTitle: String) {
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
            helperText = "Enter a title to save. Default title is \"\(defaultTitle)\"."
            helperTone = .warning
        }
    }
}
