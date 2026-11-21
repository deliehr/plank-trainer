import Foundation
import Observation

@Observable
final class SessionEngine {
    private static let resumeCountdownSeconds = 3
    private static let extensionStepSeconds = 10
    private static let tickInterval = Duration.milliseconds(100)

    let configuration: SessionConfiguration
    private(set) var phase: SessionPhase = .preparing
    private(set) var elapsedSeconds = 0
    private(set) var extensionSeconds = 0
    private(set) var pauseCount = 0
    private(set) var preparationRemainingSeconds: Int
    private(set) var resumeCountdownRemainingSeconds = SessionEngine.resumeCountdownSeconds
    private(set) var result: SessionResult?
    private(set) var announcementError: AnnouncerError?
    private(set) var hapticSignal: SessionHapticSignal?

    @ObservationIgnored private let history: SessionHistoryContext
    @ObservationIgnored private let coachStyle: CoachStyle
    @ObservationIgnored private let postureHintsEnabled: Bool
    @ObservationIgnored private let announcer: any Announcing
    @ObservationIgnored private let planner: any AnnouncementPlanning
    @ObservationIgnored private let clock: any SessionClock

    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var schedule: [ScheduledAnnouncement] = []
    @ObservationIgnored private var nextScheduleIndex = 0
    @ObservationIgnored private var accumulatedActive = Duration.zero
    @ObservationIgnored private var runningSince: ContinuousClock.Instant?
    @ObservationIgnored private var phaseStart: ContinuousClock.Instant
    @ObservationIgnored private var spokenOneOffs: Set<OneOffAnnouncement> = []
    @ObservationIgnored private var lastGapAnnouncement: GapAnnouncement?
    @ObservationIgnored private var lastSpoken: PreviousAnnouncement?
    @ObservationIgnored private var startedAt: Date?
    @ObservationIgnored private var hapticSequence = 0

    var totalSeconds: Int { configuration.plannedSeconds + extensionSeconds }
    var remainingSeconds: Int { max(0, totalSeconds - elapsedSeconds) }

    var timerDisplay: SessionTimerDisplay {
        SessionTimerDisplay(
            remainingSeconds: remainingSeconds,
            elapsedSeconds: elapsedSeconds,
            totalSeconds: totalSeconds,
            extensionSeconds: extensionSeconds,
            isPaused: phase == .paused || phase == .resuming
        )
    }

    init(
        configuration: SessionConfiguration,
        history: SessionHistoryContext,
        coachStyle: CoachStyle,
        postureHintsEnabled: Bool,
        announcer: any Announcing,
        planner: any AnnouncementPlanning,
        clock: any SessionClock
    ) {
        self.configuration = configuration
        self.history = history
        self.coachStyle = coachStyle
        self.postureHintsEnabled = postureHintsEnabled
        self.announcer = announcer
        self.planner = planner
        self.clock = clock
        self.preparationRemainingSeconds = configuration.preparationSeconds
        self.phaseStart = clock.now
    }

    func remainingFraction() -> Double {
        let total = Double(totalSeconds)
        let fraction = (total - Self.seconds(of: activeDuration)) / total
        return min(max(fraction, 0), 1)
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        phase = .preparing
        phaseStart = clock.now
        do {
            try announcer.prepare()
        } catch {
            announcementError = error
        }
        schedule = planner.preparationAnnouncements(preparationSeconds: configuration.preparationSeconds)
        nextScheduleIndex = 0
        speakDueAnnouncements(atSecond: 0)
    }

    func tick() {
        guard hasStarted else { return }
        switch phase {
        case .preparing:
            tickCountdown(length: configuration.preparationSeconds) { [self] remaining in
                preparationRemainingSeconds = remaining
            }
        case .resuming:
            tickCountdown(length: Self.resumeCountdownSeconds) { [self] remaining in
                resumeCountdownRemainingSeconds = remaining
            }
        case .running:
            updateElapsedSeconds()
            speakDueAnnouncements(atSecond: elapsedSeconds)
            if elapsedSeconds >= totalSeconds {
                finish(.completed)
            }
        case .paused, .finished, .cancelled:
            break
        }
    }

    func run() async {
        while !Task.isCancelled && !phase.isTerminal {
            tick()
            do {
                try await Task.sleep(for: Self.tickInterval)
            } catch {
                return
            }
        }
    }

    func pause() {
        guard hasStarted else { return }
        switch phase {
        case .preparing, .running, .resuming:
            accumulateActiveTime()
            announcer.stopSpeaking()
            schedule = []
            nextScheduleIndex = 0
            pauseCount += 1
            phase = .paused
        case .paused, .finished, .cancelled:
            break
        }
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .resuming
        phaseStart = clock.now
        resumeCountdownRemainingSeconds = Self.resumeCountdownSeconds
        schedule = planner.resumeCountdownAnnouncements()
        nextScheduleIndex = 0
        speakDueAnnouncements(atSecond: 0)
    }

    func extend() {
        switch phase {
        case .running:
            extensionSeconds += Self.extensionStepSeconds
            updateElapsedSeconds()
            makePlan(trigger: .extended, previous: lastSpoken)
        case .paused:
            extensionSeconds += Self.extensionStepSeconds
        case .preparing, .resuming, .finished, .cancelled:
            break
        }
    }

    func stop() {
        switch phase {
        case .running, .paused:
            finish(.stopped)
        case .preparing, .resuming, .finished, .cancelled:
            break
        }
    }

    func cancel() {
        guard !phase.isTerminal else { return }
        announcer.stopSpeaking()
        phase = .cancelled
    }

    private var activeDuration: Duration {
        accumulatedActive + (runningSince.map { clock.now - $0 } ?? .zero)
    }

    private static func seconds(of duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) + Double(components.attoseconds) * 1e-18
    }

    private func tickCountdown(length: Int, publishRemaining: (Int) -> Void) {
        let passed = Int((clock.now - phaseStart).components.seconds)
        speakDueAnnouncements(atSecond: passed)
        publishRemaining(max(1, length - passed))
        if passed >= length {
            enterRunning(runStart: phaseStart + .seconds(length))
        }
    }

    private func updateElapsedSeconds() {
        let seconds = Int(activeDuration.components.seconds)
        if seconds != elapsedSeconds {
            elapsedSeconds = seconds
        }
    }

    private func accumulateActiveTime() {
        guard let runningSince else { return }
        accumulatedActive += clock.now - runningSince
        self.runningSince = nil
    }

    private func enterRunning(runStart: ContinuousClock.Instant) {
        runningSince = runStart
        phase = .running
        updateElapsedSeconds()
        let trigger: PlanTrigger
        if startedAt == nil {
            startedAt = clock.currentDate
            emitHaptic(.runningStarted)
            trigger = .start
        } else {
            trigger = .resume
        }
        makePlan(trigger: trigger, previous: nil)
        speakDueAnnouncements(atSecond: elapsedSeconds)
    }

    private func makePlan(trigger: PlanTrigger, previous: PreviousAnnouncement?) {
        let input = AnnouncementPlanInput(
            trigger: trigger,
            totalSeconds: totalSeconds,
            elapsedSeconds: elapsedSeconds,
            history: history,
            style: coachStyle,
            postureHintsEnabled: postureHintsEnabled,
            spokenOneOffs: spokenOneOffs,
            lastGapAnnouncement: lastGapAnnouncement,
            previous: previous
        )
        schedule = planner.plan(input)
        nextScheduleIndex = 0
    }

    private func speakDueAnnouncements(atSecond current: Int) {
        while nextScheduleIndex < schedule.count, schedule[nextScheduleIndex].elapsedSecond <= current {
            let item = schedule[nextScheduleIndex]
            nextScheduleIndex += 1
            guard item.elapsedSecond >= current - 1 else { continue }
            speak(item.text)
            didSpeak(item)
        }
    }

    private func didSpeak(_ item: ScheduledAnnouncement) {
        spokenOneOffs.formUnion(item.oneOffs)
        switch item.kind {
        case .filler, .postureHint:
            lastGapAnnouncement = GapAnnouncement(second: item.elapsedSecond, kind: item.kind)
        case .countdown:
            emitHaptic(.countdownTick)
        default:
            break
        }
        if phase == .running {
            lastSpoken = PreviousAnnouncement(
                startSecond: item.elapsedSecond,
                estimatedDuration: item.estimatedDuration
            )
        }
    }

    private func speak(_ text: String) {
        do {
            try announcer.speak(text)
            announcementError = nil
        } catch {
            announcementError = error
        }
    }

    private func finish(_ outcome: SessionOutcome) {
        let activeSeconds = Int(activeDuration.components.seconds)
        accumulateActiveTime()
        let achieved = outcome == .completed ? totalSeconds : min(activeSeconds, totalSeconds)
        elapsedSeconds = achieved
        let endedAt = clock.currentDate
        let isNewRecord = history.recordSeconds.map { achieved > $0 } ?? false
        let result = SessionResult(
            configuration: configuration,
            startedAt: startedAt ?? endedAt,
            endedAt: endedAt,
            extensionSeconds: extensionSeconds,
            achievedSeconds: achieved,
            pauseCount: pauseCount,
            outcome: outcome,
            isNewRecord: isNewRecord
        )
        self.result = result
        phase = .finished(outcome)
        let closing = planner.closingText(ClosingInput(
            achievedSeconds: achieved,
            plannedSeconds: configuration.plannedSeconds,
            isNewRecord: isNewRecord,
            newRecordAlreadyAnnounced: spokenOneOffs.contains(.newRecord),
            style: coachStyle
        ))
        if outcome == .stopped {
            announcer.stopSpeaking()
        }
        speak(closing)
        if result.isGoalReached {
            emitHaptic(.completed)
        }
    }

    private func emitHaptic(_ haptic: SessionHaptic) {
        hapticSequence += 1
        hapticSignal = SessionHapticSignal(sequence: hapticSequence, haptic: haptic)
    }
}
