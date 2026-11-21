import Foundation
import Testing
@testable import Planktrainer

@Suite struct HistoryDateTextTests {
    nonisolated private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    nonisolated private static func date(day: Int, hour: Int, minute: Int) -> Date {
        let components = DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? .distantPast
    }

    private let now = HistoryDateTextTests.date(day: 21, hour: 12, minute: 0)

    private func text(for date: Date, language: String) -> String {
        HistoryDateText.sessionDate(date, now: now, locale: Locale(identifier: language), calendar: Self.calendar)
    }

    @Test func todayUsesRelativeDayInGerman() {
        #expect(text(for: Self.date(day: 21, hour: 7, minute: 42), language: "de_DE") == "Heute, 07:42")
    }

    @Test func yesterdayUsesRelativeDayInGerman() {
        #expect(text(for: Self.date(day: 20, hour: 18, minute: 10), language: "de_DE") == "Gestern, 18:10")
    }

    @Test func olderDateShowsWeekdayDayAndMonthInGerman() {
        #expect(text(for: Self.date(day: 16, hour: 7, minute: 35), language: "de_DE") == "Mo. 16. Nov., 07:35")
    }

    @Test func englishUsesLocalizedRelativeDay() {
        #expect(text(for: Self.date(day: 21, hour: 7, minute: 42), language: "en_US").hasPrefix("Today, "))
    }
}
