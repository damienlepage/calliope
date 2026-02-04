//
//  ContentView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioCapture = AudioCapture()
    @StateObject private var audioAnalyzer = AudioAnalyzer()

    var body: some View {
        VStack(spacing: 20) {
            Text("Calliope")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Recording status
            HStack {
                Circle()
                    .fill(audioCapture.isRecording ? Color.red : Color.gray)
                    .frame(width: 12, height: 12)
                Text(audioCapture.isRecording ? "Recording" : "Stopped")
                    .font(.headline)
            }

            // Real-time feedback panel (placeholder values)
            FeedbackPanel(
                pace: audioAnalyzer.currentPace,
                crutchWords: audioAnalyzer.crutchWordCount,
                pauseCount: audioAnalyzer.pauseCount
            )

            // Control buttons
            HStack(spacing: 20) {
                Button(action: toggleRecording) {
                    Text(audioCapture.isRecording ? "Stop" : "Start")
                        .frame(width: 100, height: 40)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .onAppear {
            audioAnalyzer.setup(audioCapture: audioCapture)
        }
    }

    private func toggleRecording() {
        if audioCapture.isRecording {
            audioCapture.stopRecording()
        } else {
            audioCapture.startRecording()
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
