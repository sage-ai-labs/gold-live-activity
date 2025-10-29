//
//  ClockView.swift
//  FlipClock
//
//  Original source: https://github.com/elpassion/FlipClock-SwiftUI
//  Licensed under GPL-3.0
//  Modified for Golden Hour Live Activity countdown
//

import SwiftUI

struct ClockView: View {
    let hours: String
    let minutes: String
    let seconds: String
    
    @StateObject private var hoursViewModel = FlipViewModel()
    @StateObject private var minutesViewModel = FlipViewModel()
    @StateObject private var secondsViewModel = FlipViewModel()
    
    var body: some View {
        HStack(spacing: 8) {
            // Hours
            FlipPairView(
                viewModel: hoursViewModel,
                label: "HOURS"
            )
            
            Text(":")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            
            // Minutes
            FlipPairView(
                viewModel: minutesViewModel,
                label: "MINUTES"
            )
            
            Text(":")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            
            // Seconds
            FlipPairView(
                viewModel: secondsViewModel,
                label: "SECONDS"
            )
        }
        .onChange(of: hours) { newValue in
            hoursViewModel.setValue(newValue)
        }
        .onChange(of: minutes) { newValue in
            minutesViewModel.setValue(newValue)
        }
        .onChange(of: seconds) { newValue in
            secondsViewModel.setValue(newValue)
        }
        .onAppear {
            hoursViewModel.setValue(hours, animated: false)
            minutesViewModel.setValue(minutes, animated: false)
            secondsViewModel.setValue(seconds, animated: false)
        }
    }
}

struct FlipPairView: View {
    @ObservedObject var viewModel: FlipViewModel
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                FlipView(
                    value: String(viewModel.currentValue.prefix(1)),
                    previousValue: String(viewModel.previousValue.prefix(1)),
                    flipState: .constant(viewModel.flipState)
                )
                .frame(width: 35, height: 50)
                
                FlipView(
                    value: String(viewModel.currentValue.suffix(1)),
                    previousValue: String(viewModel.previousValue.suffix(1)),
                    flipState: .constant(viewModel.flipState)
                )
                .frame(width: 35, height: 50)
            }
            
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
