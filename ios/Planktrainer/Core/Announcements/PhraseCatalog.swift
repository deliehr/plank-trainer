enum PhraseCatalog {
    static let postureHintKeys: [String] = keys(prefix: "coach.posture", count: 10)

    static func keys(for occasion: CoachOccasion, style: CoachStyle) -> [String] {
        guard style != .off else { return [] }
        return keys(prefix: "coach.\(style.rawValue).\(occasion.rawValue)", count: phraseCount(for: occasion))
    }

    private static func phraseCount(for occasion: CoachOccasion) -> Int {
        switch occasion {
        case .start, .halfway, .finalStretch, .newRecord: 4
        case .filler: 10
        case .recordInSight, .lastSession, .resume, .stopped: 3
        case .completion: 5
        }
    }

    private static func keys(prefix: String, count: Int) -> [String] {
        (1...count).map { "\(prefix).\($0 < 10 ? "0" : "")\($0)" }
    }
}
