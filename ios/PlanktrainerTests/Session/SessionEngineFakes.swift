import Foundation
@testable import Planktrainer

final class TestSessionClock: SessionClock {
    let origin = ContinuousClock.now
    var offset = Duration.zero
    var baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    var now: ContinuousClock.Instant { origin.advanced(by: offset) }

    var currentDate: Date {
        let components = offset.components
        return baseDate.addingTimeInterval(Double(components.seconds) + Double(components.attoseconds) * 1e-18)
    }

    func advance(by duration: Duration) {
        offset += duration
    }
}

final class FakeAnnouncer: Announcing {
    enum Event: Equatable {
        case speak(String)
        case stop
    }

    private(set) var events: [Event] = []
    private(set) var spoken: [String] = []
    private(set) var stopCount = 0
    private(set) var prepareCount = 0
    var prepareError: AnnouncerError?
    var speakError: AnnouncerError?
    /// Restricts `speakError` to this text; nil fails every call.
    var speakErrorText: String?

    func prepare() throws(AnnouncerError) {
        prepareCount += 1
        if let prepareError { throw prepareError }
    }

    func speak(_ text: String) throws(AnnouncerError) {
        if let speakError, speakErrorText == nil || speakErrorText == text { throw speakError }
        spoken.append(text)
        events.append(.speak(text))
    }

    func stopSpeaking() {
        stopCount += 1
        events.append(.stop)
    }
}

final class FakePlanner: AnnouncementPlanning {
    var preparation: (Int) -> [ScheduledAnnouncement] = { seconds in
        [
            ScheduledAnnouncement(elapsedSecond: 0, kind: .prepare, text: "P"),
            ScheduledAnnouncement(elapsedSecond: seconds - 3, kind: .countdown(3), text: "3"),
            ScheduledAnnouncement(elapsedSecond: seconds - 2, kind: .countdown(2), text: "2"),
            ScheduledAnnouncement(elapsedSecond: seconds - 1, kind: .countdown(1), text: "1")
        ]
    }
    var resumeCountdown = [
        ScheduledAnnouncement(elapsedSecond: 0, kind: .countdown(3), text: "3"),
        ScheduledAnnouncement(elapsedSecond: 1, kind: .countdown(2), text: "2"),
        ScheduledAnnouncement(elapsedSecond: 2, kind: .countdown(1), text: "1")
    ]
    var extraItems: [ScheduledAnnouncement] = []
    var closing = "END"

    private(set) var planInputs: [AnnouncementPlanInput] = []
    private(set) var closingInputs: [ClosingInput] = []

    func preparationAnnouncements(preparationSeconds: Int) -> [ScheduledAnnouncement] {
        preparation(preparationSeconds)
    }

    func resumeCountdownAnnouncements() -> [ScheduledAnnouncement] {
        resumeCountdown
    }

    func plan(_ input: AnnouncementPlanInput) -> [ScheduledAnnouncement] {
        planInputs.append(input)
        var items: [ScheduledAnnouncement] = []
        switch input.trigger {
        case .start:
            items.append(ScheduledAnnouncement(elapsedSecond: input.elapsedSeconds, kind: .start, text: "A\(input.elapsedSeconds)"))
        case .resume:
            items.append(ScheduledAnnouncement(elapsedSecond: input.elapsedSeconds, kind: .resume, text: "A\(input.elapsedSeconds)"))
        case .extended:
            break
        }
        items += extraItems.filter { $0.elapsedSecond > input.elapsedSeconds }
        return items.sorted { $0.elapsedSecond < $1.elapsedSecond }
    }

    func closingText(_ input: ClosingInput) -> String {
        closingInputs.append(input)
        return closing
    }
}

func advance(_ engine: SessionEngine, _ clock: TestSessionClock, seconds: Double) {
    let steps = Int((seconds * 10).rounded())
    for _ in 0..<steps {
        clock.advance(by: .milliseconds(100))
        engine.tick()
    }
}
