import SwiftUI

extension SessionHaptic {
    var feedback: SensoryFeedback {
        switch self {
        case .countdownTick: .impact(weight: .light)
        case .runningStarted: .impact(weight: .medium)
        case .completed: .success
        }
    }
}
