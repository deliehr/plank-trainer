struct AnnouncementPlanner: AnnouncementPlanning {
    private static let minimumGap = 4
    private static let gapAnnouncementInterval = 20
    private static let mergeTolerance = 4
    private static let mergeLookahead = 10
    private static let gapFillerCutoff = 15
    private static let firstGapSecond = 10
    private static let recordEventCutoff = 10

    private let texts: any AnnouncementTextProviding
    private let coach: any CoachPhraseProviding

    init(texts: any AnnouncementTextProviding, coach: any CoachPhraseProviding) {
        self.texts = texts
        self.coach = coach
    }

    func preparationAnnouncements(preparationSeconds: Int) -> [ScheduledAnnouncement] {
        let countdown = (1...3).reversed().map { number in
            ScheduledAnnouncement(
                elapsedSecond: preparationSeconds - number,
                kind: .countdown(number),
                text: texts.countdown(number)
            )
        }
        return [ScheduledAnnouncement(elapsedSecond: 0, kind: .prepare, text: texts.fixed(.prepare, argument: nil))] + countdown
    }

    func resumeCountdownAnnouncements() -> [ScheduledAnnouncement] {
        [3, 2, 1].enumerated().map { offset, number in
            ScheduledAnnouncement(elapsedSecond: offset, kind: .countdown(number), text: texts.countdown(number))
        }
    }

    func plan(_ input: AnnouncementPlanInput) -> [ScheduledAnnouncement] {
        var timeline = Timeline(previous: input.previous)
        placeAnchor(input, in: &timeline)
        placeTimeMarks(input, in: &timeline)
        placeRecordEvents(input, in: &timeline)
        placeHalfway(input, in: &timeline)
        placeFinalStretch(input, in: &timeline)
        placeLastSession(input, in: &timeline)
        fillGaps(input, in: &timeline)
        return timeline.announcements
    }

    func closingText(_ input: ClosingInput) -> String {
        var parts: [String] = []
        if input.isGoalReached {
            parts.append(texts.fixed(.complete, argument: nil))
            if let completion = coach.coachPhrase(.completion, style: input.style, argument: nil) {
                parts.append(completion)
            }
        } else {
            let achieved = texts.duration(input.achievedSeconds)
            parts.append(
                coach.coachPhrase(.stopped, style: input.style, argument: achieved)
                    ?? texts.fixed(.stoppedWithoutCoach, argument: achieved)
            )
        }
        if input.isNewRecord, !input.newRecordAlreadyAnnounced,
           let record = coach.coachPhrase(.newRecord, style: input.style, argument: nil) {
            parts.append(record)
        }
        return parts.joined(separator: " ")
    }
}

private extension AnnouncementPlanner {
    struct Slot {
        let second: Int
        var duration: Double
        var announcement: ScheduledAnnouncement?
    }

    struct Timeline {
        private(set) var slots: [Slot] = []

        init(previous: PreviousAnnouncement?) {
            if let previous {
                slots.append(Slot(second: previous.startSecond, duration: previous.estimatedDuration, announcement: nil))
            }
        }

        var announcements: [ScheduledAnnouncement] { slots.compactMap(\.announcement) }

        func previousSlot(before second: Int) -> Slot? { slots.last { $0.second < second } }
        func nextSlot(after second: Int) -> Slot? { slots.first { $0.second > second } }

        func isSpacedAfterPrevious(_ second: Int) -> Bool {
            guard let previous = previousSlot(before: second) else { return true }
            return second - previous.second >= AnnouncementPlanner.minimumGap && Double(second) >= Double(previous.second) + previous.duration
        }

        func fits(_ second: Int, duration: Double) -> Bool {
            guard !slots.contains(where: { $0.second == second }), isSpacedAfterPrevious(second) else { return false }
            guard let next = nextSlot(after: second) else { return true }
            return Double(second) + duration + 1 <= Double(next.second)
        }

        func canExtend(_ slot: Slot, toDuration duration: Double) -> Bool {
            guard let next = nextSlot(after: slot.second) else { return true }
            return Double(slot.second) + duration + 1 <= Double(next.second)
        }

        mutating func insert(_ announcement: ScheduledAnnouncement) {
            let slot = Slot(second: announcement.elapsedSecond, duration: announcement.estimatedDuration, announcement: announcement)
            let index = slots.firstIndex { $0.second > slot.second } ?? slots.endIndex
            slots.insert(slot, at: index)
        }

        mutating func replace(_ announcement: ScheduledAnnouncement) {
            guard let index = slots.firstIndex(where: { $0.second == announcement.elapsedSecond }) else { return }
            slots[index] = Slot(second: announcement.elapsedSecond, duration: announcement.estimatedDuration, announcement: announcement)
        }

        func unprefixedTimeRemaining(where isIncluded: (ScheduledAnnouncement) -> Bool) -> [Slot] {
            slots.filter { slot in
                guard let announcement = slot.announcement,
                      case .timeRemaining = announcement.kind,
                      announcement.prefixKind == nil
                else { return false }
                return isIncluded(announcement)
            }
        }
    }

    func remaining(_ input: AnnouncementPlanInput, at second: Int) -> Int { input.totalSeconds - second }

    func placeAnchor(_ input: AnnouncementPlanInput, in timeline: inout Timeline) {
        let left = remaining(input, at: input.elapsedSeconds)
        let duration = texts.duration(left)
        switch input.trigger {
        case .start:
            let text = coach.coachPhrase(.start, style: input.style, argument: duration)
                ?? texts.fixed(.startWithoutCoach, argument: duration)
            timeline.insert(ScheduledAnnouncement(elapsedSecond: input.elapsedSeconds, kind: .start, text: text))
        case .resume where left > 10:
            let text = coach.coachPhrase(.resume, style: input.style, argument: duration) ?? texts.timeRemaining(left)
            timeline.insert(ScheduledAnnouncement(elapsedSecond: input.elapsedSeconds, kind: .resume, text: text))
        case .resume, .extended:
            break
        }
    }

    func isTimeMark(_ left: Int) -> Bool {
        (left > 120 && left % 60 == 0) || (left <= 120 && left % 30 == 0) || left == 15 || left == 10
    }

    func placeTimeMarks(_ input: AnnouncementPlanInput, in timeline: inout Timeline) {
        let startRemaining = remaining(input, at: input.elapsedSeconds)
        guard startRemaining > 1 else { return }
        for left in (1..<startRemaining).reversed() {
            let second = input.totalSeconds - left
            if (1...5).contains(left) {
                timeline.insert(ScheduledAnnouncement(elapsedSecond: second, kind: .countdown(left), text: texts.countdown(left)))
            } else if isTimeMark(left), timeline.isSpacedAfterPrevious(second) {
                timeline.insert(ScheduledAnnouncement(elapsedSecond: second, kind: .timeRemaining(left), text: texts.timeRemaining(left)))
            }
        }
    }

    func placeRecordEvents(_ input: AnnouncementPlanInput, in timeline: inout Timeline) {
        guard input.style != .off, let record = input.history.recordSeconds, record > 0 else { return }
        let events: [(AnnouncementKind, CoachOccasion, Int)] = [
            (.recordInSight, .recordInSight, record - 5),
            (.newRecord, .newRecord, record + 1),
        ]
        for (kind, occasion, second) in events {
            guard let oneOff = kind.oneOff, !input.spokenOneOffs.contains(oneOff),
                  second > input.elapsedSeconds,
                  remaining(input, at: second) > Self.recordEventCutoff,
                  let text = coach.coachPhrase(occasion, style: input.style, argument: nil)
            else { continue }
            let announcement = ScheduledAnnouncement(elapsedSecond: second, kind: kind, text: text)
            if timeline.fits(second, duration: announcement.estimatedDuration) {
                timeline.insert(announcement)
            }
        }
    }

    func merged(_ prefix: String, kind: AnnouncementKind, into slot: Slot) -> ScheduledAnnouncement? {
        guard let target = slot.announcement else { return nil }
        return ScheduledAnnouncement(
            elapsedSecond: target.elapsedSecond,
            kind: target.kind,
            prefixKind: kind,
            text: prefix + " " + target.text
        )
    }

    func merge(_ prefix: String, kind: AnnouncementKind, into slot: Slot, in timeline: inout Timeline) {
        guard let combined = merged(prefix, kind: kind, into: slot),
              timeline.canExtend(slot, toDuration: combined.estimatedDuration)
        else { return }
        timeline.replace(combined)
    }

    func placeHalfway(_ input: AnnouncementPlanInput, in timeline: inout Timeline) {
        let halfway = input.totalSeconds - input.totalSeconds / 2
        guard input.style != .off, !input.spokenOneOffs.contains(.halfway), halfway > input.elapsedSeconds,
              let phrase = coach.coachPhrase(.halfway, style: input.style, argument: nil)
        else { return }

        let nearby = timeline
            .unprefixedTimeRemaining { abs($0.elapsedSecond - halfway) < Self.mergeTolerance }
            .min { (abs($0.second - halfway), $0.second) < (abs($1.second - halfway), $1.second) }
        if let nearby {
            merge(phrase, kind: .halfway, into: nearby, in: &timeline)
            return
        }

        let standalone = ScheduledAnnouncement(elapsedSecond: halfway, kind: .halfway, text: phrase)
        if timeline.fits(halfway, duration: standalone.estimatedDuration) {
            timeline.insert(standalone)
            return
        }

        let upcoming = timeline
            .unprefixedTimeRemaining { $0.elapsedSecond > halfway && $0.elapsedSecond <= halfway + Self.mergeLookahead }
            .first
        if let upcoming {
            merge(phrase, kind: .halfway, into: upcoming, in: &timeline)
        }
    }

    func placeFinalStretch(_ input: AnnouncementPlanInput, in timeline: inout Timeline) {
        guard input.style != .off, !input.spokenOneOffs.contains(.finalStretch) else { return }
        let target = timeline
            .unprefixedTimeRemaining { $0.kind == .timeRemaining(15) && $0.elapsedSecond > input.elapsedSeconds }
            .first
        guard let target,
              let phrase = coach.coachPhrase(.finalStretch, style: input.style, argument: nil)
        else { return }
        merge(phrase, kind: .finalStretch, into: target, in: &timeline)
    }

    func placeLastSession(_ input: AnnouncementPlanInput, in timeline: inout Timeline) {
        guard input.style != .off, let last = input.history.lastSession, !last.isGoalReached,
              last.achievedSeconds < input.totalSeconds, last.achievedSeconds > input.elapsedSeconds,
              !input.spokenOneOffs.contains(.lastSession),
              let text = coach.coachPhrase(.lastSession, style: input.style, argument: nil)
        else { return }
        let announcement = ScheduledAnnouncement(elapsedSecond: last.achievedSeconds, kind: .lastSession, text: text)
        if timeline.fits(announcement.elapsedSecond, duration: announcement.estimatedDuration) {
            timeline.insert(announcement)
        }
    }

    func fillGaps(_ input: AnnouncementPlanInput, in timeline: inout Timeline) {
        let fillerAvailable = input.style != .off
        let postureAvailable = input.postureHintsEnabled
        guard fillerAvailable || postureAvailable else { return }

        var kind: AnnouncementKind
        switch (fillerAvailable, postureAvailable) {
        case (true, true): kind = input.lastGapAnnouncement?.kind == .filler ? .postureHint : .filler
        case (true, false): kind = .filler
        default: kind = .postureHint
        }
        let alternates = fillerAvailable && postureAvailable

        var second = max(
            input.elapsedSeconds + 1,
            Self.firstGapSecond,
            (input.lastGapAnnouncement?.second ?? -Self.gapAnnouncementInterval) + Self.gapAnnouncementInterval
        )
        var pending: String?
        while remaining(input, at: second) > Self.gapFillerCutoff {
            if pending == nil {
                pending = kind == .filler
                    ? coach.coachPhrase(.filler, style: input.style, argument: nil)
                    : coach.postureHint()
            }
            guard let text = pending else { return }
            let announcement = ScheduledAnnouncement(elapsedSecond: second, kind: kind, text: text)
            if timeline.fits(second, duration: announcement.estimatedDuration) {
                timeline.insert(announcement)
                pending = nil
                if alternates { kind = kind == .filler ? .postureHint : .filler }
                second += Self.gapAnnouncementInterval
            } else {
                second += 1
            }
        }
    }
}
