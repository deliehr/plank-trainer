enum SessionHaptic: Equatable, Sendable { case countdownTick, runningStarted, completed }

struct SessionHapticSignal: Equatable, Sendable {
    let sequence: Int
    let haptic: SessionHaptic
}
