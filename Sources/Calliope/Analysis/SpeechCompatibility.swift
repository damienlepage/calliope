//
//  SpeechCompatibility.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

#if os(macOS)
let SFSpeechRecognizerErrorDomain = "SFSpeechRecognizerErrorDomain"

enum SFSpeechRecognizerErrorCode: Int {
    case noSpeech = 1
    case canceled = 2
}
#endif
