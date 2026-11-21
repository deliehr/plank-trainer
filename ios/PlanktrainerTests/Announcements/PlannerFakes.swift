@testable import Planktrainer

struct FakeAnnouncementTexts: AnnouncementTextProviding {
    func duration(_ seconds: Int) -> String { "D\(seconds)" }
    func timeRemaining(_ seconds: Int) -> String { "T\(seconds)" }
    func countdown(_ number: Int) -> String { "\(number)" }

    func fixed(_ phrase: FixedPhrase, argument: String?) -> String {
        switch phrase {
        case .prepare: "P"
        case .startWithoutCoach: "S \(argument ?? "")"
        case .complete: "C"
        case .stoppedWithoutCoach: "X \(argument ?? "")"
        }
    }
}

final class FakeCoachPhrases: CoachPhraseProviding {
    var phrases: [CoachOccasion: String] = Dictionary(uniqueKeysWithValues: CoachOccasion.allCases.map { ($0, $0.rawValue) })
    var postureHintText = "H"
    private(set) var callCounts: [CoachOccasion: Int] = [:]

    func coachPhrase(_ occasion: CoachOccasion, style: CoachStyle, argument: String?) -> String? {
        guard style != .off else { return nil }
        callCounts[occasion, default: 0] += 1
        let template = phrases[occasion] ?? occasion.rawValue
        return template.replacingOccurrences(of: "%@", with: argument ?? "")
    }

    func postureHint() -> String? { postureHintText }
}
