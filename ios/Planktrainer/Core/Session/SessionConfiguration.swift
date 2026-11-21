import Foundation

nonisolated struct SessionConfiguration: Hashable, Sendable {
    static let plannedSecondsRange = 10...600
    static let preparationSecondsRange = 5...60
    static let stepSeconds = 5
    static let standard = SessionConfiguration(plannedSeconds: 60, preparationSeconds: 10)

    let plannedSeconds: Int
    let preparationSeconds: Int

    init(plannedSeconds: Int, preparationSeconds: Int) {
        self.plannedSeconds = Self.normalized(plannedSeconds, in: Self.plannedSecondsRange)
        self.preparationSeconds = Self.normalized(preparationSeconds, in: Self.preparationSecondsRange)
    }

    /// Rounds to the nearest multiple of `stepSeconds` (ties round up), then clamps to `range`.
    static func normalized(_ seconds: Int, in range: ClosedRange<Int>) -> Int {
        let rounded = ((seconds + stepSeconds / 2) / stepSeconds) * stepSeconds
        return min(max(rounded, range.lowerBound), range.upperBound)
    }
}
