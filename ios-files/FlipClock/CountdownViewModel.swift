//
//  CountdownViewModel.swift
//  FlipClock
//
//  Adapted from FlipClock-SwiftUI ClockViewModel
//  Original source: https://github.com/elpassion/FlipClock-SwiftUI
//  Licensed under GPL-3.0
//  Modified for Golden Hour countdown from dealEndTime
//

import SwiftUI
import Combine

class CountdownViewModel: ObservableObject {
    @Published var hours: String = "00"
    @Published var minutes: String = "00"
    @Published var seconds: String = "00"
    @Published var isExpired: Bool = false
    
    private var timer: Timer?
    private let dealEndTime: Date
    
    init(dealEndTimeInMilliseconds: Double) {
        self.dealEndTime = Date(timeIntervalSince1970: dealEndTimeInMilliseconds / 1000.0)
        updateCountdown()
        startTimer()
    }
    
    deinit {
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateCountdown() {
        let now = Date()
        let timeInterval = dealEndTime.timeIntervalSince(now)
        
        guard timeInterval > 0 else {
            hours = "00"
            minutes = "00"
            seconds = "00"
            isExpired = true
            stopTimer()
            return
        }
        
        let totalSeconds = Int(timeInterval)
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        
        hours = String(format: "%02d", h)
        minutes = String(format: "%02d", m)
        seconds = String(format: "%02d", s)
        isExpired = false
    }
}
