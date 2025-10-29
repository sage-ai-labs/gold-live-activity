//
//  FlipViewModel.swift
//  FlipClock
//
//  Original source: https://github.com/elpassion/FlipClock-SwiftUI
//  Licensed under GPL-3.0
//  Modified for Golden Hour Live Activity countdown
//

import SwiftUI
import Combine

class FlipViewModel: ObservableObject {
    @Published var currentValue: String = "0"
    @Published var previousValue: String = "0"
    @Published var flipState: FlipState = .normal
    
    private var cancellable: AnyCancellable?
    
    func updateValue(_ newValue: String) {
        guard newValue != currentValue else { return }
        
        previousValue = currentValue
        flipState = .flipping
        
        // Animate flip
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.currentValue = newValue
            self?.flipState = .normal
        }
    }
    
    func setValue(_ value: String, animated: Bool = true) {
        if animated {
            updateValue(value)
        } else {
            currentValue = value
            previousValue = value
            flipState = .normal
        }
    }
}
