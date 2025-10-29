//
//  SingleFlipView.swift
//  FlipClock
//
//  Original source: https://github.com/elpassion/FlipClock-SwiftUI
//  Licensed under GPL-3.0
//  Modified for Golden Hour Live Activity countdown
//

import SwiftUI

struct SingleFlipView: View {
    let value: String
    let isTop: Bool
    let showShadow: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.9))
                
                Text(value)
                    .font(.system(size: geometry.size.width * 0.6, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .offset(y: isTop ? geometry.size.height * 0.25 : -geometry.size.height * 0.25)
                    .clipped()
            }
            .frame(height: geometry.size.height / 2)
            .offset(y: isTop ? 0 : geometry.size.height / 2)
            .clipped()
            .shadow(
                color: showShadow ? Color.black.opacity(0.5) : Color.clear,
                radius: 4,
                x: 0,
                y: isTop ? 2 : -2
            )
        }
    }
}
