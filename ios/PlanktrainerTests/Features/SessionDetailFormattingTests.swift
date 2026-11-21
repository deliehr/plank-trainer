import Foundation
import Testing
@testable import Planktrainer

@Suite struct SessionDetailFormattingTests {
    nonisolated private static let utc = TimeZone(identifier: "UTC") ?? .gmt
    nonisolated private static let sampleDate = Date(timeIntervalSince1970: 1_763_662_200) // 2025-11-20 18:10 UTC

    @Test func fullDateIncludesDayAndTime() {
        let text = SessionDetailFormatting.fullDate(Self.sampleDate, locale: Locale(identifier: "de_DE"), timeZone: Self.utc)
        #expect(text.contains("20"))
        #expect(text.contains("18:10"))
    }

    @Test func titleUsesRelativeDayForToday() {
        let text = SessionDetailFormatting.title(for: .now, locale: Locale(identifier: "de_DE"), timeZone: Self.utc)
        #expect(text.contains("Heute"))
    }
}
