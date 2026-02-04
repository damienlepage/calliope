//
//  ContentView.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct ContentView: View {
    @State private var isRecording = false
    @State private var pace: Double = 0
    @State private var crutchWords: Int = 0
    @State private var pauseCount: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Calliope")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Recording status
            HStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.gray)
                    .frame(width: 12, height: 12)
                Text(isRecording ? "Recording" : "Stopped")
                    .font(.headline)
            }

            // Real-time feedback panel (placeholder values)
            FeedbackPanel(
                pace: pace,
                crutchWords: crutchWords,
                pauseCount: pauseCount
            )

            // Control buttons
            HStack(spacing: 20) {
                Button(action: toggleRecording) {
                    Text(isRecording ? "Stop" : "Start")
                        .frame(width: 100, height: 40)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .onAppear {
            resetDemoValues()
        }
    }

    private func toggleRecording() {
        isRecording.toggle()

        if isRecording {
            // Simple demo values while "recording"
            pace = 150
            crutchWords = 2
            pauseCount = 1
        } else {
            resetDemoValues()
        }
    }

    private func resetDemoValues() {
        pace = 0
        crutchWords = 0
        pauseCount = 0
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
