//
//  SpeechTranscriber.swift
//  Calliope
//
//  Created on [Date]
//

import Speech
import AVFoundation

protocol SpeechRecognizing {
    var isAvailable: Bool { get }
    var supportsOnDeviceRecognition: Bool { get }
    func recognitionTask(
        with request: SFSpeechAudioBufferRecognitionRequest,
        resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void
    ) -> SFSpeechRecognitionTask
}

protocol SpeechTranscriberLogging {
    func info(_ message: String)
    func error(_ message: String)
}

struct SystemSpeechTranscriberLogger: SpeechTranscriberLogging {
    func info(_ message: String) {
        print(message)
    }

    func error(_ message: String) {
        print(message)
    }
}

final class SystemSpeechRecognizer: SpeechRecognizing {
    private let recognizer: SFSpeechRecognizer?

    init(locale: Locale) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    var isAvailable: Bool {
        recognizer?.isAvailable ?? false
    }

    var supportsOnDeviceRecognition: Bool {
        guard let recognizer = recognizer else { return false }
        if #available(macOS 10.15, *) {
            return recognizer.supportsOnDeviceRecognition
        }
        return false
    }

    func recognitionTask(
        with request: SFSpeechAudioBufferRecognitionRequest,
        resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void
    ) -> SFSpeechRecognitionTask {
        guard let recognizer = recognizer else {
            fatalError("Speech recognizer unavailable.")
        }
        return recognizer.recognitionTask(with: request, resultHandler: resultHandler)
    }
}

protocol SpeechTranscribing: AnyObject {
    var onTranscription: ((String) -> Void)? { get set }
    func startTranscription()
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer)
    func stopTranscription()
}

enum SpeechTranscriberState: Equatable {
    case idle
    case listening
    case stopped
    case error
}

class SpeechTranscriber: SpeechTranscribing {
    private let speechRecognizer: SpeechRecognizing
    private let requestAuthorization: (@escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) -> Void
    private let logger: SpeechTranscriberLogging
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isStopping = false

    private(set) var state: SpeechTranscriberState = .idle
    
    var onTranscription: ((String) -> Void)?
    var onStateChange: ((SpeechTranscriberState) -> Void)?

    init(
        speechRecognizer: SpeechRecognizing = SystemSpeechRecognizer(locale: Locale(identifier: "en-US")),
        requestAuthorization: @escaping (@escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) -> Void = SFSpeechRecognizer.requestAuthorization,
        logger: SpeechTranscriberLogging = SystemSpeechTranscriberLogger()
    ) {
        self.speechRecognizer = speechRecognizer
        self.requestAuthorization = requestAuthorization
        self.logger = logger
    }
    
    func startTranscription() {
        isStopping = false
        guard speechRecognizer.isAvailable else {
            logger.error("Speech recognizer not available")
            updateState(.error)
            return
        }

        guard speechRecognizer.supportsOnDeviceRecognition else {
            logger.error("On-device speech recognition not supported")
            updateState(.error)
            return
        }

        requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard status == .authorized else {
                    self.logger.error("Speech recognition not authorized: \(status)")
                    self.updateState(.error)
                    return
                }

                self.beginRecognition(with: self.speechRecognizer)
            }
        }
    }

    private func beginRecognition(with speechRecognizer: SpeechRecognizing) {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true
        if #available(macOS 10.15, *), speechRecognizer.supportsOnDeviceRecognition {
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
        isStopping = true
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        updateState(.stopped)
    }

    func handleRecognitionError(_ error: Error) {
        if isStopping {
            updateState(.stopped)
            return
        }
        if isBenignRecognitionError(error) {
            updateState(.stopped)
            return
        }

        updateState(.error)
        logger.error("Recognition error: \(error)")
    }

    func isBenignRecognitionError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if isAFAssistantNoSpeechError(nsError) {
            return true
        }
        guard nsError.domain == SFSpeechRecognizerErrorDomain else { return false }
        guard let code = SFSpeechRecognizerErrorCode(rawValue: nsError.code) else { return false }
        switch code {
        case .noSpeech, .canceled:
            return true
        }
    }

    private func isAFAssistantNoSpeechError(_ error: NSError) -> Bool {
        return error.domain == "kAFAssistantErrorDomain" && error.code == 1110
    }

    private func updateState(_ newState: SpeechTranscriberState) {
        state = newState
        onStateChange?(newState)
    }
}
