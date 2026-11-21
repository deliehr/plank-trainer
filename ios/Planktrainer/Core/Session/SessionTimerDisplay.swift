struct SessionTimerDisplay: Equatable, Sendable {
    var remainingSeconds: Int
    var elapsedSeconds: Int
    var totalSeconds: Int
    var extensionSeconds: Int
    var isPaused: Bool

    var isFinalCountdown: Bool { remainingSeconds > 0 && remainingSeconds <= 5 }
}
