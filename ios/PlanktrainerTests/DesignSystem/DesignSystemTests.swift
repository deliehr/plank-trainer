import SwiftUI
import Testing
@testable import Planktrainer

struct DesignSystemTests {
    @Test func sessionDiameterIsRatioOfWidth() {
        #expect(RingMetrics.sessionDiameter(screenWidth: 390, accessibilitySize: false) == 390 * 0.78)
    }

    @Test func sessionDiameterIsCapped() {
        #expect(RingMetrics.sessionDiameter(screenWidth: 600, accessibilitySize: false) == 340)
    }

    @Test func accessibilitySessionDiameterIsLargerAndUncapped() {
        #expect(RingMetrics.sessionDiameter(screenWidth: 390, accessibilitySize: true) == 390 * 0.92)
        #expect(RingMetrics.sessionDiameter(screenWidth: 600, accessibilitySize: true) == 600 * 0.92)
    }

    @Test(arguments: [
        (ColorScheme.light, false, false, 0.16),
        (ColorScheme.dark, false, false, 0.22),
        (ColorScheme.light, true, false, 0.30),
        (ColorScheme.dark, false, true, 0.30),
        (ColorScheme.dark, true, true, 0.30)
    ])
    func trackOpacityFollowsEnvironment(scheme: ColorScheme, reduceTransparency: Bool, highContrast: Bool, expected: Double) {
        let value = RingTrackOpacity.value(colorScheme: scheme, reduceTransparency: reduceTransparency, highContrast: highContrast)
        #expect(value == expected)
    }
}
