import Foundation
import Testing
@testable import Planktrainer

private func makePlanner(_ localeIdentifier: String) -> AnnouncementPlanner {
    let locale = Locale(identifier: localeIdentifier)
    return AnnouncementPlanner(
        texts: AnnouncementTexts(locale: locale),
        coach: PhraseSelector(locale: locale, generator: SplitMix64(seed: 42))
    )
}

private func makeInput(
    total: Int,
    style: CoachStyle,
    posture: Bool = false,
    history: SessionHistoryContext = .empty
) -> AnnouncementPlanInput {
    AnnouncementPlanInput(
        trigger: .start,
        totalSeconds: total,
        elapsedSeconds: 0,
        history: history,
        style: style,
        postureHintsEnabled: posture
    )
}

@Suite("PlannerIntegration")
struct PlannerIntegrationTests {
    @Test(arguments: ["de", "en"], [
        (300, [60, 120, 180, 210, 240, 270, 285, 290]),
        (150, [30, 60, 90, 120, 135, 140]),
        (60, [30, 45, 50]),
        (45, [15, 30, 35]),
        (20, [5, 10]),
        (130, [10, 40, 70, 100, 115, 120]),
    ])
    func timeMarksFollowSpecTable(locale: String, row: (total: Int, marks: [Int])) {
        let plan = makePlanner(locale).plan(makeInput(total: row.total, style: .off))

        let marks = plan.filter { if case .timeRemaining = $0.kind { true } else { false } }
        #expect(marks.map(\.elapsedSecond) == row.marks)
        #expect(marks.map(\.kind) == row.marks.map { .timeRemaining(row.total - $0) })

        let countdowns = plan.filter { if case .countdown = $0.kind { true } else { false } }
        #expect(countdowns.map(\.elapsedSecond) == (1...5).reversed().map { row.total - $0 }.filter { $0 >= 0 })
        #expect(plan.first?.kind == .start)
        #expect(plan.first?.elapsedSecond == 0)
    }

    @Test func startTextsOfFiveMinuteSession() {
        let german = makePlanner("de").plan(makeInput(total: 300, style: .off))
        let english = makePlanner("en").plan(makeInput(total: 300, style: .off))
        #expect(german.first?.text == "Planking Session gestartet, noch 5 Minuten.")
        #expect(english.first?.text == "Planking session started, 5 minutes to go.")
    }

    @Test func ninetySecondsRemainingMarkIsSpokenInGerman() {
        let plan = makePlanner("de").plan(makeInput(total: 150, style: .off))
        let mark = plan.first { $0.kind == .timeRemaining(90) }
        #expect(mark?.elapsedSecond == 60)
        #expect(mark?.text == "Noch 1 Minute 30.")
    }

    @Test(arguments: ["de", "en"], [CoachStyle.calm, .demanding, .cheeky])
    func thirtySecondsMarkDependsOnEstimatedStartSentence(locale: String, style: CoachStyle) throws {
        for seed in 0..<20 {
            let planner = AnnouncementPlanner(
                texts: AnnouncementTexts(locale: Locale(identifier: locale)),
                coach: PhraseSelector(locale: Locale(identifier: locale), generator: SplitMix64(seed: UInt64(seed)))
            )
            let plan = planner.plan(makeInput(total: 35, style: style))
            let start = try #require(plan.first { $0.kind == .start })
            let hasMark = plan.contains { $0.kind == .timeRemaining(30) }
            #expect(
                hasMark == (start.estimatedDuration <= 5.0),
                "seed \(seed): \"\(start.text)\" estimated \(start.estimatedDuration) s, mark present: \(hasMark)"
            )
        }
    }

    @Test(arguments: ["de", "en"], CoachStyle.allCases)
    func planInvariantsHoldForAllDurations(locale: String, style: CoachStyle) {
        let history = SessionHistoryContext(
            recordSeconds: 45,
            lastSession: LastSessionInfo(achievedSeconds: 30, isGoalReached: false)
        )
        for total in stride(from: 10, through: 600, by: 5) {
            let plan = makePlanner(locale).plan(makeInput(total: total, style: style, posture: true, history: history))
            let context = "locale \(locale), style \(style), total \(total)"

            let seconds = plan.map(\.elapsedSecond)
            #expect(seconds == seconds.sorted(), "unsorted: \(context)")
            #expect(Set(seconds).count == seconds.count, "duplicate seconds: \(context)")

            for item in plan {
                #expect(!item.text.contains("%@") && !item.text.contains("%lld"), "placeholder in \"\(item.text)\": \(context)")
            }

            for (previous, current) in zip(plan, plan.dropFirst()) {
                if case .countdown = current.kind { continue }
                let previousEnd = Double(previous.elapsedSecond) + previous.estimatedDuration
                #expect(
                    Double(current.elapsedSecond) >= previousEnd,
                    "\(current.kind) at \(current.elapsedSecond) overlaps \(previous.kind) ending \(previousEnd): \(context)"
                )
            }
        }
    }
}
