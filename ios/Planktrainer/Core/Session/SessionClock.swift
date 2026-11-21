import Foundation

protocol SessionClock {
    var now: ContinuousClock.Instant { get }
    var currentDate: Date { get }
}

struct SystemSessionClock: SessionClock {
    var now: ContinuousClock.Instant { ContinuousClock.now }
    var currentDate: Date { Date.now }
}
