enum CoachOccasion: String, CaseIterable, Sendable {
    case start, halfway, finalStretch, filler, recordInSight, newRecord, lastSession, resume, completion, stopped
}

enum FixedPhrase: Sendable { case prepare, startWithoutCoach, complete, stoppedWithoutCoach }

enum AnnouncementKind: Hashable, Sendable {
    case prepare, start, resume
    case timeRemaining(Int)
    case countdown(Int)
    case halfway, finalStretch, recordInSight, newRecord, lastSession
    case postureHint, filler

    var oneOff: OneOffAnnouncement? {
        switch self {
        case .halfway: .halfway
        case .finalStretch: .finalStretch
        case .recordInSight: .recordInSight
        case .newRecord: .newRecord
        case .lastSession: .lastSession
        case .prepare, .start, .resume, .timeRemaining, .countdown, .postureHint, .filler: nil
        }
    }
}

enum OneOffAnnouncement: Hashable, Sendable { case halfway, finalStretch, recordInSight, newRecord, lastSession }

struct ScheduledAnnouncement: Equatable, Sendable {
    static let charactersPerSecond = 14.0

    let elapsedSecond: Int
    let kind: AnnouncementKind
    let prefixKind: AnnouncementKind?
    let text: String

    init(elapsedSecond: Int, kind: AnnouncementKind, prefixKind: AnnouncementKind? = nil, text: String) {
        self.elapsedSecond = elapsedSecond
        self.kind = kind
        self.prefixKind = prefixKind
        self.text = text
    }

    var estimatedDuration: Double { Double(text.count) / Self.charactersPerSecond }
    var oneOffs: Set<OneOffAnnouncement> { Set([kind.oneOff, prefixKind?.oneOff].compactMap { $0 }) }
}

enum PlanTrigger: Sendable { case start, resume, extended }

struct PreviousAnnouncement: Equatable, Sendable {
    let startSecond: Int
    let estimatedDuration: Double
}

struct GapAnnouncement: Equatable, Sendable {
    let second: Int
    let kind: AnnouncementKind   // .filler or .postureHint
}

struct AnnouncementPlanInput: Equatable, Sendable {
    var trigger: PlanTrigger
    var totalSeconds: Int
    var elapsedSeconds: Int
    var history: SessionHistoryContext
    var style: CoachStyle
    var postureHintsEnabled: Bool
    var spokenOneOffs: Set<OneOffAnnouncement> = []
    var lastGapAnnouncement: GapAnnouncement? = nil
    var previous: PreviousAnnouncement? = nil
}

struct ClosingInput: Equatable, Sendable {
    var achievedSeconds: Int
    var plannedSeconds: Int
    var isNewRecord: Bool
    var newRecordAlreadyAnnounced: Bool
    var style: CoachStyle

    var isGoalReached: Bool { achievedSeconds >= plannedSeconds }
}
