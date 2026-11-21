import Foundation
import Testing
@testable import Planktrainer

@Suite struct PlankSessionValuesTests {
    @Test func defaultsApplyWhenAllPropertiesAreNil() {
        let session = PlankSession(id: nil)
        #expect(session.idValue == PlankSession.missingID)
        #expect(session.startedAtValue == .distantPast)
        #expect(session.endedAtValue == .distantPast)
        #expect(session.plannedSecondsValue == 60)
        #expect(session.preparationSecondsValue == 10)
        #expect(session.extensionSecondsValue == 0)
        #expect(session.achievedSecondsValue == 0)
        #expect(session.pauseCountValue == 0)
        #expect(!session.isGoalReached)
    }

    @Test func storedValuesArePassedThrough() {
        let id = UUID()
        let start = Date(timeIntervalSince1970: 1_000)
        let end = Date(timeIntervalSince1970: 1_100)
        let session = PlankSession(
            id: id, startedAt: start, endedAt: end, preparationSeconds: 15, plannedSeconds: 90,
            extensionSeconds: 5, achievedSeconds: 95, pauseCount: 2
        )
        #expect(session.idValue == id)
        #expect(session.startedAtValue == start)
        #expect(session.endedAtValue == end)
        #expect(session.preparationSecondsValue == 15)
        #expect(session.plannedSecondsValue == 90)
        #expect(session.extensionSecondsValue == 5)
        #expect(session.achievedSecondsValue == 95)
        #expect(session.pauseCountValue == 2)
        #expect(session.configuration == SessionConfiguration(plannedSeconds: 90, preparationSeconds: 15))
    }

    @Test func goalIsReachedWhenAchievedEqualsPlanned() {
        let session = PlankSession(plannedSeconds: 60, achievedSeconds: 60)
        #expect(session.isGoalReached)
    }
}
