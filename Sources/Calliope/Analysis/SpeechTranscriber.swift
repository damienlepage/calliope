//
//  SpeechTranscriber.swift
//  Calliope
//
//  Created on [Date]
//

import Speech
import AVFoundation

enum SpeechTranscriberState: Equatable {
    case idle
    case listening
    case stopped
    case error
}

class SpeechTranscriber {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private(set) var state: SpeechTranscriberState = .idle
    
    var onTranscription: ((String) -> Void)?
    var onStateChange: ((SpeechTranscriberState) -> Void)?
    
    func startTranscription() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            updateState(.error)
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true
        if #available(macOS 10.15, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                self?.onTranscription?(result.bestTranscription.formattedString)
            }
            
            if let error = error {
                self?.handleRecognitionError(error)
            }
        }

        updateState(.listening)
    }
    
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }
    
    func stopTranscription() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        updateState(.stopped)
    }

    func handleRecognitionError(_ error: Error) {
        if isBenignRecognitionError(error) {
            updateState(.stopped)
            return
        }

        updateState(.error)
        print("Recognition error: \(error)")
    }

    func isBenignRecognitionError(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == SFSpeechRecognizerErrorDomain else { return false }
        guard let code = SFSpeechRecognizerErrorCode(rawValue: nsError.code) else { return false }
        switch code {
        case .noSpeech, .canceled:
            return true
        }
    }

    private func updateState(_ newState: SpeechTranscriberState) {
        state = newState
        onStateChange?(newState)
    }
}
