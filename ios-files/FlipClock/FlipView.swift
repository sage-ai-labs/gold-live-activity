//
//  FlipView.swift
//  FlipClock
//
//  Original source: https://github.com/elpassion/FlipClock-SwiftUI
//  Licensed under GPL-3.0
//  Modified for Golden Hour Live Activity countdown
//

import SwiftUI

struct FlipView: View {
    let value: String
    let previousValue: String
    @Binding var flipState: FlipState
    
    var body: some View {
        ZStack {
            // Back cards
            SingleFlipView(
                value: value,
                isTop: true,
                showShadow: false
            )
            SingleFlipView(
                value: value,
                isTop: false,
                showShadow: false
            )
            
            // Top flipping card
            if flipState == .flipping {
                SingleFlipView(
                    value: previousValue,
                    isTop: true,
                    showShadow: true
                )
                .rotation3DEffect(
                    .degrees(-90),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.3
                )
            }
            
            // Bottom flipping card
            if flipState == .flipping {
                SingleFlipView(
                    value: value,
                    isTop: false,
                    showShadow: true
                )
                .rotation3DEffect(
                    .degrees(90),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.3
                )
            }
        }
    }
}

enum FlipState {
    case normal
    case flipping
}
