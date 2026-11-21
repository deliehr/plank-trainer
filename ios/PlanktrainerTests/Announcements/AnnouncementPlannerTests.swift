import Testing
@testable import Planktrainer

private struct Entry: Equatable, CustomStringConvertible {
    let second: Int
    let kind: AnnouncementKind
    var description: String { "(\(second), \(kind))" }
}

private func entries(_ plan: [ScheduledAnnouncement]) -> [Entry] {
    plan.map { Entry(second: $0.elapsedSecond, kind: $0.kind) }
}

private func tr(_ second: Int, _ remaining: Int) -> Entry { Entry(second: second, kind: .timeRemaining(remaining)) }
private func countdowns(from first: Int, total: Int) -> [Entry] {
    (1...5).reversed().map { Entry(second: total - $0, kind: .countdown($0)) }.filter { $0.second >= first }
}

@Suite("AnnouncementPlanner")
struct AnnouncementPlannerTests {
    let coach = FakeCoachPhrases()

    private func makePlanner() -> AnnouncementPlanner {
        AnnouncementPlanner(texts: FakeAnnouncementTexts(), coach: coach)
    }

    private func input(
        total: Int,
        elapsed: Int = 0,
        trigger: PlanTrigger = .start,
        style: CoachStyle = .off,
        posture: Bool = false,
        history: SessionHistoryContext = .empty,
        spoken: Set<OneOffAnnouncement> = [],
        lastGap: GapAnnouncement? = nil,
        previous: PreviousAnnouncement? = nil
    ) -> AnnouncementPlanInput {
        AnnouncementPlanInput(
            trigger: trigger,
            totalSeconds: total,
            elapsedSeconds: elapsed,
            history: history,
            style: style,
            postureHintsEnabled: posture,
            spokenOneOffs: spoken,
            lastGapAnnouncement: lastGap,
            previous: previous
        )
    }

    private func plan(_ input: AnnouncementPlanInput) -> [ScheduledAnnouncement] {
        makePlanner().plan(input)
    }

    private func announcement(_ plan: [ScheduledAnnouncement], _ kind: AnnouncementKind) -> ScheduledAnnouncement? {
        plan.first { $0.kind == kind }
    }

    // MARK: Spec table 3.4

    @Test(arguments: [
        (300, [60, 120, 180, 210, 240, 270, 285, 290]),
        (150, [30, 60, 90, 120, 135, 140]),
        (60, [30, 45, 50]),
        (45, [15, 30, 35]),
        (20, [5, 10]),
        (130, [10, 40, 70, 100, 115, 120]),
    ])
    func timeMarksFollowSpecTable(total: Int, seconds: [Int]) {
        let result = plan(input(total: total))
        let expected = [Entry(second: 0, kind: .start)]
            + seconds.map { tr($0, total - $0) }
            + countdowns(from: 0, total: total)
        #expect(entries(result) == expected)
        #expect(result.first?.text == "S D\(total)")
    }

    @Test func startTextUsesCoachPhraseWhenStyleActive() {
        coach.phrases[.start] = "Go %@"
        let result = plan(input(total: 60, style: .calm))
        #expect(result.first?.text == "Go D60")
    }

    // MARK: Minimum gap

    @Test(arguments: [(60, true), (80, false)])
    func longStartSentenceSuppressesNearbyMark(characters: Int, markPresent: Bool) {
        coach.phrases[.start] = String(repeating: "a", count: characters - 3) + "%@"
        let result = plan(input(total: 35, style: .demanding))
        let kinds = result.map(\.kind)
        #expect(kinds.contains(.timeRemaining(30)) == markPresent)
        #expect(kinds.contains(.timeRemaining(15)))
        #expect(kinds.contains(.timeRemaining(10)))
        #expect(kinds.filter { if case .countdown = $0 { true } else { false } }.count == 5)
    }

    @Test func markWithinFourSecondsOfStartIsDropped() {
        let result = plan(input(total: 12))
        #expect(!result.contains { $0.kind == .timeRemaining(10) })
        #expect(result.filter { if case .countdown = $0.kind { true } else { false } }.count == 5)
    }

    @Test func previousAnnouncementBlocksNearbyMark() {
        let previous = PreviousAnnouncement(startSecond: 28, estimatedDuration: 3.0)
        let result = plan(input(total: 60, elapsed: 28, trigger: .extended, previous: previous))
        #expect(!result.contains { $0.kind == .timeRemaining(30) })
        #expect(!result.contains { $0.elapsedSecond == 28 })
    }

    @Test func countdownIgnoresMinimumGap() {
        coach.phrases = [:]
        struct LongTexts: AnnouncementTextProviding {
            let base = FakeAnnouncementTexts()
            func duration(_ seconds: Int) -> String { base.duration(seconds) }
            func timeRemaining(_ seconds: Int) -> String { seconds == 10 ? String(repeating: "x", count: 100) : base.timeRemaining(seconds) }
            func countdown(_ number: Int) -> String { base.countdown(number) }
            func fixed(_ phrase: FixedPhrase, argument: String?) -> String { base.fixed(phrase, argument: argument) }
        }
        let result = AnnouncementPlanner(texts: LongTexts(), coach: coach).plan(input(total: 60))
        #expect(result.contains { $0.kind == .timeRemaining(10) })
        #expect(entries(result).suffix(5) == countdowns(from: 0, total: 60)[...])
    }

    // MARK: Extension and resume

    @Test func extensionHasNoImmediateAnnouncement() {
        let result = plan(input(total: 70, elapsed: 15, trigger: .extended))
        #expect(entries(result) == [tr(40, 30), tr(55, 15), tr(60, 10)] + countdowns(from: 0, total: 70))
    }

    @Test func extensionPlacesStandaloneHalfwayUnlessSpoken() {
        let withHalfway = plan(input(total: 70, elapsed: 15, trigger: .extended, style: .demanding))
        #expect(announcement(withHalfway, .halfway)?.elapsedSecond == 35)
        let spoken = plan(input(total: 70, elapsed: 15, trigger: .extended, style: .demanding, spoken: [.halfway]))
        #expect(announcement(spoken, .halfway) == nil)
        #expect(!spoken.contains { $0.prefixKind == .halfway })
    }

    @Test func resumeWithoutCoachSpeaksTimeRemaining() {
        let result = plan(input(total: 120, elapsed: 50, trigger: .resume))
        #expect(result.first == ScheduledAnnouncement(elapsedSecond: 50, kind: .resume, text: "T70"))
    }

    @Test func resumeWithCoachUsesCoachPhrase() {
        coach.phrases[.resume] = "Back: %@"
        let result = plan(input(total: 120, elapsed: 50, trigger: .resume, style: .calm))
        #expect(result.first?.text == "Back: D70")
    }

    @Test func resumeNearEndHasNoAnchor() {
        let result = plan(input(total: 120, elapsed: 112, trigger: .resume))
        #expect(!result.contains { $0.kind == .resume })
    }

    // MARK: Halfway and final stretch

    @Test func halfwayMergesIntoCoincidingTimeMark() throws {
        let result = plan(input(total: 60, style: .demanding))
        let merged = try #require(result.first { $0.elapsedSecond == 30 })
        #expect(merged.kind == .timeRemaining(30))
        #expect(merged.prefixKind == .halfway)
        #expect(merged.text == "halfway T30")
    }

    @Test func halfwayStandsAloneWhenNoMarkIsNearby() {
        let result = plan(input(total: 300, style: .demanding))
        #expect(announcement(result, .halfway)?.elapsedSecond == 150)
    }

    @Test func halfwayMergesWithMarkWithinFourSeconds() {
        let result = plan(input(total: 124, style: .demanding))
        let merged = result.first { $0.prefixKind == .halfway }
        #expect(merged?.elapsedSecond == 64)
    }

    @Test func halfwayMergesWithUpcomingMarkWhenStandaloneDoesNotFit() {
        coach.phrases[.halfway] = String(repeating: "h", count: 140)
        let result = plan(input(total: 140, style: .demanding))
        #expect(announcement(result, .halfway) == nil)
        #expect(result.first { $0.prefixKind == .halfway }?.elapsedSecond == 80)
    }

    @Test func finalStretchPrefixesFifteenSecondMark() {
        let result = plan(input(total: 60, style: .demanding))
        #expect(result.first { $0.elapsedSecond == 45 }?.prefixKind == .finalStretch)
    }

    @Test func halfwayWinsOverFinalStretch() {
        let result = plan(input(total: 30, style: .demanding))
        let mark = result.first { $0.elapsedSecond == 15 }
        #expect(mark?.kind == .timeRemaining(15))
        #expect(mark?.prefixKind == .halfway)
        #expect(!result.contains { $0.prefixKind == .finalStretch })
    }

    @Test func spokenFinalStretchIsNotRepeated() {
        let result = plan(input(total: 60, style: .demanding, spoken: [.finalStretch]))
        #expect(!result.contains { $0.prefixKind == .finalStretch })
    }

    @Test func noHalfwayOrFinalStretchWithoutCoach() {
        let result = plan(input(total: 60))
        #expect(result.allSatisfy { $0.prefixKind == nil && $0.kind != .halfway })
    }

    // MARK: Record

    @Test func recordEventsAreScheduled() {
        let result = plan(input(total: 120, style: .demanding, history: SessionHistoryContext(recordSeconds: 40, lastSession: nil)))
        #expect(announcement(result, .recordInSight)?.elapsedSecond == 35)
        #expect(announcement(result, .newRecord)?.elapsedSecond == 41)
    }

    @Test func recordEventsRequireRecord() {
        let result = plan(input(total: 120, style: .demanding))
        #expect(announcement(result, .recordInSight) == nil)
        #expect(announcement(result, .newRecord) == nil)
    }

    @Test func newRecordNeedsMoreThanTenSecondsRemaining() {
        let result = plan(input(total: 120, style: .demanding, history: SessionHistoryContext(recordSeconds: 109, lastSession: nil)))
        #expect(announcement(result, .newRecord) == nil)
    }

    @Test func recordInSightNeedsMoreThanTenSecondsRemaining() {
        let result = plan(input(total: 120, style: .demanding, history: SessionHistoryContext(recordSeconds: 116, lastSession: nil)))
        #expect(announcement(result, .recordInSight) == nil)
    }

    @Test func recordEventsAreSkippedWithoutCoach() {
        let result = plan(input(total: 120, history: SessionHistoryContext(recordSeconds: 40, lastSession: nil)))
        #expect(announcement(result, .recordInSight) == nil)
        #expect(announcement(result, .newRecord) == nil)
    }

    @Test func spokenRecordEventsAreNotRepeated() {
        let history = SessionHistoryContext(recordSeconds: 40, lastSession: nil)
        let result = plan(input(total: 120, style: .demanding, history: history, spoken: [.recordInSight, .newRecord]))
        #expect(announcement(result, .recordInSight) == nil)
        #expect(announcement(result, .newRecord) == nil)
    }

    // MARK: Last session

    @Test func lastSessionLosesAgainstHigherPriorityEvent() {
        let history = SessionHistoryContext(recordSeconds: 40, lastSession: LastSessionInfo(achievedSeconds: 36, isGoalReached: false))
        let result = plan(input(total: 120, style: .demanding, history: history))
        #expect(announcement(result, .lastSession) == nil)
    }

    @Test func lastSessionIsScheduledAtAchievedSecond() {
        let history = SessionHistoryContext(recordSeconds: nil, lastSession: LastSessionInfo(achievedSeconds: 36, isGoalReached: false))
        let result = plan(input(total: 120, style: .demanding, history: history))
        #expect(announcement(result, .lastSession)?.elapsedSecond == 36)
    }

    @Test(arguments: [
        LastSessionInfo(achievedSeconds: 36, isGoalReached: true),
        LastSessionInfo(achievedSeconds: 130, isGoalReached: false),
    ])
    func lastSessionIsSkippedWhenIrrelevant(last: LastSessionInfo) {
        let history = SessionHistoryContext(recordSeconds: nil, lastSession: last)
        let result = plan(input(total: 120, style: .demanding, history: history))
        #expect(announcement(result, .lastSession) == nil)
    }

    @Test func lastSessionIsSkippedWithoutCoachAndWhenSpoken() {
        let history = SessionHistoryContext(recordSeconds: nil, lastSession: LastSessionInfo(achievedSeconds: 36, isGoalReached: false))
        #expect(announcement(plan(input(total: 120, history: history)), .lastSession) == nil)
        #expect(announcement(plan(input(total: 120, style: .demanding, history: history, spoken: [.lastSession])), .lastSession) == nil)
    }

    // MARK: Gap fillers

    private func gapAnnouncements(_ result: [ScheduledAnnouncement]) -> [ScheduledAnnouncement] {
        result.filter { $0.kind == .filler || $0.kind == .postureHint }
    }

    @Test func fillersAlternateWithPostureHints() {
        let result = plan(input(total: 300, style: .demanding, posture: true))
        let gaps = gapAnnouncements(result)
        #expect(gaps.first?.elapsedSecond ?? 0 >= 10)
        #expect(gaps.first?.kind == .filler)
        #expect(zip(gaps, gaps.dropFirst()).allSatisfy { $1.elapsedSecond - $0.elapsedSecond >= 20 && $0.kind != $1.kind })
        #expect(gaps.allSatisfy { 300 - $0.elapsedSecond > 15 })
        #expect(gaps.count > 5)
    }

    @Test func gapsContinueAfterLastGapAnnouncement() {
        let lastGap = GapAnnouncement(second: 100, kind: .filler)
        let result = plan(input(total: 300, elapsed: 105, trigger: .extended, style: .demanding, posture: true, lastGap: lastGap))
        let first = gapAnnouncements(result).first
        #expect(first?.kind == .postureHint)
        #expect(first?.elapsedSecond ?? 0 >= 120)
    }

    @Test func onlyPostureHintsWithoutCoach() {
        let result = gapAnnouncements(plan(input(total: 300, posture: true)))
        #expect(!result.isEmpty)
        #expect(result.allSatisfy { $0.kind == .postureHint })
    }

    @Test func noGapAnnouncementsWithoutCoachAndPosture() {
        #expect(gapAnnouncements(plan(input(total: 300))).isEmpty)
    }

    @Test func fillerDrawStopsWhenProviderIsExhausted() {
        final class Exhausted: CoachPhraseProviding {
            func coachPhrase(_ occasion: CoachOccasion, style: CoachStyle, argument: String?) -> String? {
                occasion == .filler ? nil : "x"
            }
            func postureHint() -> String? { nil }
        }
        let planner = AnnouncementPlanner(texts: FakeAnnouncementTexts(), coach: Exhausted())
        let result = planner.plan(input(total: 300, style: .demanding, posture: true))
        #expect(result.allSatisfy { $0.kind != .filler && $0.kind != .postureHint })
    }

    // MARK: Invariants

    @Test(arguments: Array(stride(from: 10, through: 600, by: 5)), [CoachStyle.off, .demanding])
    func planInvariantsHold(total: Int, style: CoachStyle) {
        let result = plan(input(total: total, style: style, posture: true))
        #expect(result.map(\.elapsedSecond) == result.map(\.elapsedSecond).sorted())
        #expect(Set(result.map(\.elapsedSecond)).count == result.count)
        for (earlier, later) in zip(result, result.dropFirst()) {
            if case .countdown = later.kind { continue }
            #expect(Double(later.elapsedSecond) >= Double(earlier.elapsedSecond) + earlier.estimatedDuration, "\(earlier.kind) -> \(later.kind) at \(total)")
        }
    }

    @Test func planIsDeterministic() {
        let value = input(total: 300, style: .demanding, posture: true)
        #expect(plan(value) == plan(value))
    }

    // MARK: Preparation and closing

    @Test func preparationAnnouncementsCountDownToTheEnd() {
        let result = makePlanner().preparationAnnouncements(preparationSeconds: 10)
        #expect(entries(result) == [
            Entry(second: 0, kind: .prepare), Entry(second: 7, kind: .countdown(3)),
            Entry(second: 8, kind: .countdown(2)), Entry(second: 9, kind: .countdown(1)),
        ])
        #expect(result.map(\.text) == ["P", "3", "2", "1"])
    }

    @Test func resumeCountdownStartsImmediately() {
        let result = makePlanner().resumeCountdownAnnouncements()
        #expect(entries(result) == [
            Entry(second: 0, kind: .countdown(3)), Entry(second: 1, kind: .countdown(2)), Entry(second: 2, kind: .countdown(1)),
        ])
    }

    private func closing(achieved: Int = 60, planned: Int = 60, record: Bool = false, announced: Bool = false, style: CoachStyle) -> String {
        makePlanner().closingText(
            ClosingInput(achievedSeconds: achieved, plannedSeconds: planned, isNewRecord: record, newRecordAlreadyAnnounced: announced, style: style)
        )
    }

    @Test func closingWhenGoalReached() {
        #expect(closing(style: .off) == "C")
        #expect(closing(style: .calm) == "C completion")
    }

    @Test func closingWhenGoalMissed() {
        #expect(closing(achieved: 42, style: .off) == "X D42")
        coach.phrases[.stopped] = "Stopped at %@"
        #expect(closing(achieved: 42, style: .cheeky) == "Stopped at D42")
    }

    @Test func closingAppendsNewRecordOnlyOnce() {
        #expect(closing(record: true, style: .demanding) == "C completion newRecord")
        #expect(closing(record: true, announced: true, style: .demanding) == "C completion")
        #expect(closing(record: true, style: .off) == "C")
    }
}
