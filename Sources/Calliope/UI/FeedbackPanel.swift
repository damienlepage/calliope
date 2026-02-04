//
//  FeedbackPanel.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct FeedbackPanel: View {
    let pace: Double // words per minute
    let crutchWords: Int
    let pauseCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Real-time Feedback")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Pace indicator
            HStack {
                Text("Pace:")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(pace)) WPM")
                    .font(.subheadline)
                    .foregroundColor(paceColor(pace))
            }
            
            // Crutch words indicator
            HStack {
                Text("Crutch Words:")
                    .font(.subheadline)
                Spacer()
                Text("\(crutchWords)")
                    .font(.subheadline)
                    .foregroundColor(crutchWords > 5 ? .orange : .green)
            }
            
            // Pauses indicator
            HStack {
                Text("Pauses:")
                    .font(.subheadline)
                Spacer()
                Text("\(pauseCount)")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private func paceColor(_ pace: Double) -> Color {
        if pace < 120 {
            return .blue // Too slow
        } else if pace > 180 {
            return .red // Too fast
        } else {
            return .green // Good pace
        }
    }
}

#if DEBUG
struct FeedbackPanel_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackPanel(pace: 150, crutchWords: 3, pauseCount: 2)
            .padding()
    }
}
#endif
