protocol AnnouncementTextProviding {
    /// "{time}"/"{achieved}" without "noch"/"to go": "45 Sekunden", "1 Minute", "2 Minuten 30".
    func duration(_ seconds: Int) -> String
    /// Stand-alone time announcement: "Noch 2 Minuten 30." / "2 minutes 30 to go."
    func timeRemaining(_ seconds: Int) -> String
    /// Number only: "5".
    func countdown(_ number: Int) -> String
    /// `argument` fills the placeholder of `.startWithoutCoach` and `.stoppedWithoutCoach`; ignored otherwise.
    func fixed(_ phrase: FixedPhrase, argument: String?) -> String
}

protocol CoachPhraseProviding: AnyObject {
    /// Returns nil for `.off`. Draws without repetition per (style, occasion).
    func coachPhrase(_ occasion: CoachOccasion, style: CoachStyle, argument: String?) -> String?
    /// Style-independent posture hint, drawn without repetition.
    func postureHint() -> String?
}

protocol AnnouncementPlanning {
    /// Seconds are relative to the start of the preparation phase.
    func preparationAnnouncements(preparationSeconds: Int) -> [ScheduledAnnouncement]
    /// Seconds are relative to the start of the resume countdown.
    func resumeCountdownAnnouncements() -> [ScheduledAnnouncement]
    /// Seconds are active session seconds. Result is sorted by `elapsedSecond`.
    func plan(_ input: AnnouncementPlanInput) -> [ScheduledAnnouncement]
    func closingText(_ input: ClosingInput) -> String
}
