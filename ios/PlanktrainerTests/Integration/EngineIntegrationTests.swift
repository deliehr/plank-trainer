import Foundation
import Testing
@testable import Planktrainer

private final class IntegrationClock: SessionClock {
    private let origin = ContinuousClock.now
    private var offset = Duration.zero
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    var now: ContinuousClock.Instant { origin.advanced(by: offset) }
    var currentDate: Date { baseDate.addingTimeInterval(Double(offset.components.seconds)) }

    func advance(by duration: Duration) { offset += duration }
}

private final class RecordingAnnouncer: Announcing {
    private(set) var spoken: [String] = []

    func prepare() throws(AnnouncerError) {}
    func speak(_ text: String) throws(AnnouncerError) { spoken.append(text) }
    func stopSpeaking() {}
}

@MainActor
@Suite("EngineIntegration")
struct EngineIntegrationTests {
    @Test func sixtySecondGermanSessionSpeaksExpectedSequence() {
        let locale = Locale(identifier: "de")
        let clock = IntegrationClock()
        let announcer = RecordingAnnouncer()
        let engine = SessionEngine(
            configuration: SessionConfiguration(plannedSeconds: 60, preparationSeconds: 10),
            history: .empty,
            coachStyle: .off,
            postureHintsEnabled: false,
            announcer: announcer,
            planner: AnnouncementPlanner(
                texts: AnnouncementTexts(locale: locale),
                coach: PhraseSelector(locale: locale, generator: SplitMix64(seed: 42))
            ),
            clock: clock
        )

        engine.start()
        var ticks = 0
        while !engine.phase.isTerminal && ticks < 2_000 {
            clock.advance(by: .milliseconds(100))
            engine.tick()
            ticks += 1
        }

        #expect(engine.phase == .finished(.completed))
        #expect(engine.result?.achievedSeconds == 60)

        let expected: [(String) -> Bool] = [
            { $0 == "Mach dich bereit." },
            { $0 == "3" }, { $0 == "2" }, { $0 == "1" },
            { $0.contains("noch 1 Minute") },
            { $0 == "Noch 30 Sekunden." },
            { $0 == "Noch 15 Sekunden." },
            { $0 == "Noch 10 Sekunden." },
            { $0 == "5" }, { $0 == "4" }, { $0 == "3" }, { $0 == "2" }, { $0 == "1" },
            { $0.hasPrefix("Planking Session abgeschlossen.") },
        ]
        var remaining = announcer.spoken[...]
        for matches in expected {
            guard let index = remaining.firstIndex(where: matches) else {
                Issue.record("expected announcement missing in order; spoken: \(announcer.spoken)")
                return
            }
            remaining = remaining[remaining.index(after: index)...]
        }
    }
}
