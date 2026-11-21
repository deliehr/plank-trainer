import Foundation
import Testing
@testable import Planktrainer

struct TimeTextTests {
    private let german = Locale(identifier: "de")
    private let english = Locale(identifier: "en")
    private let utc = TimeZone(identifier: "UTC") ?? .gmt

    @Test(arguments: [
        (0, "0:00"), (5, "0:05"), (59, "0:59"), (60, "1:00"),
        (90, "1:30"), (600, "10:00"), (-3, "0:00")
    ])
    func clockFormatsMinutesAndSeconds(seconds: Int, expected: String) {
        #expect(TimeText.clock(seconds) == expected)
    }

    @Test func accessibleDurationEnglish() {
        let text = TimeText.accessibleDuration(90, locale: english)
        #expect(text.contains("minute"))
        #expect(text.contains("30"))
        let short = TimeText.accessibleDuration(45, locale: english)
        #expect(short.contains("45"))
        #expect(short.contains("second"))
    }

    @Test func accessibleDurationGerman() {
        let text = TimeText.accessibleDuration(90, locale: german)
        #expect(text.contains("Minute"))
        #expect(text.contains("30"))
    }

    @Test func compactDurationFormats() {
        let englishText = TimeText.compactDuration(12, locale: english)
        let germanText = TimeText.compactDuration(72, locale: german)
        #expect(englishText.contains("12"))
        #expect(germanText.contains("1"))
        #expect(germanText.contains("12"))
    }

    @Test func relativeDateTimeUsesRelativeWordsForToday() {
        let now = Date.now
        let germanText = TimeText.relativeDateTime(now, locale: german, timeZone: utc)
        let englishText = TimeText.relativeDateTime(now, locale: english, timeZone: utc)
        #expect(germanText.contains("Heute"))
        #expect(englishText.contains("Today"))
    }

    @Test func relativeDateTimeOmitsRelativeWordsForOldDate() {
        let old = Date.now.addingTimeInterval(-30 * 24 * 3600)
        let germanText = TimeText.relativeDateTime(old, locale: german, timeZone: utc)
        let englishText = TimeText.relativeDateTime(old, locale: english, timeZone: utc)
        #expect(!germanText.contains("Heute"))
        #expect(!englishText.contains("Today"))
    }
}
