import SwiftUI
import Testing
@testable import Planktrainer

@Suite struct SessionHapticFeedbackTests {
    @Test func countdownTickIsLightImpact() {
        #expect(SessionHaptic.countdownTick.feedback == .impact(weight: .light))
    }

    @Test func runningStartedIsMediumImpact() {
        #expect(SessionHaptic.runningStarted.feedback == .impact(weight: .medium))
    }

    @Test func completedIsSuccess() {
        #expect(SessionHaptic.completed.feedback == .success)
    }
}
