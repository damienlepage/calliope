//
//  AudioCapture.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Combine

class AudioCapture: NSObject, ObservableObject {
    @Published var isRecording = false
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private let recordingManager = RecordingManager.shared
    
    override init() {
        super.init()
        // macOS doesn't use AVAudioSession - AVAudioEngine handles this directly
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Create audio file
        let url = recordingManager.getNewRecordingURL()
        do {
            audioFile = try AVAudioFile(forWriting: url, settings: recordingFormat.settings)
        } catch {
            print("Failed to create audio file: \(error)")
            return
        }
        
        // Install tap to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, let audioFile = self.audioFile else { return }
            do {
                try audioFile.write(from: buffer)
            } catch {
                print("Failed to write audio buffer: \(error)")
            }
        }
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioFile = nil
        audioEngine = nil
        inputNode = nil
        
        isRecording = false
    }
    
    func getAudioBuffer() -> AVAudioPCMBuffer? {
        // This will be used by the analyzer to process audio in real-time
        // Implementation depends on how we want to share buffers
        return nil
    }
}
