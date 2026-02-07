//
//  PaceRangeBar.swift
//  Calliope
//
//  Created on [Date]
//

import SwiftUI

struct PaceRangeBar: View {
    let pace: Double
    let paceMin: Double
    let paceMax: Double
    let indicatorColor: Color
    let barHeight: CGFloat

    init(
        pace: Double,
        paceMin: Double,
        paceMax: Double,
        indicatorColor: Color,
        barHeight: CGFloat = 8
    ) {
        self.pace = pace
        self.paceMin = paceMin
        self.paceMax = paceMax
        self.indicatorColor = indicatorColor
        self.barHeight = barHeight
    }

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let layout = PaceRangeBarLayout.compute(
                pace: pace,
                minPace: paceMin,
                maxPace: paceMax
            )
            let indicatorSize: CGFloat = max(6, barHeight)
            let indicatorOffset = max(
                0,
                min(
                    barWidth - indicatorSize,
                    barWidth * CGFloat(layout.pacePosition) - indicatorSize / 2
                )
            )

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                Capsule()
                    .fill(Color.green.opacity(0.24))
                    .frame(width: barWidth * CGFloat(layout.targetWidth))
                    .offset(x: barWidth * CGFloat(layout.targetStart))
                Circle()
                    .fill(indicatorColor)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .offset(x: indicatorOffset, y: -1)
            }
        }
        .frame(height: barHeight)
        .accessibilityHidden(true)
    }
}
