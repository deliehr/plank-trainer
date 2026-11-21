import Testing
@testable import Planktrainer

@Suite struct ShuffleBagTests {
    @Test func firstDrawsContainEveryElementExactlyOnce() {
        var bag = ShuffleBag([1, 2, 3, 4, 5])
        var generator = SplitMix64(seed: 1)
        let drawn = (0..<5).compactMap { _ in bag.next(using: &generator) }
        #expect(drawn.sorted() == [1, 2, 3, 4, 5])
    }

    @Test(arguments: [UInt64(1), 2, 3, 42, 1234])
    func neverRepeatsDirectlyAcrossRefills(seed: UInt64) {
        var bag = ShuffleBag([1, 2, 3])
        var generator = SplitMix64(seed: seed)
        let drawn = (0..<50).compactMap { _ in bag.next(using: &generator) }
        #expect(drawn.count == 50)
        #expect(zip(drawn, drawn.dropFirst()).allSatisfy { $0 != $1 })
    }

    @Test func neverRepeatsWithTwoElements() {
        var bag = ShuffleBag(["a", "b"])
        var generator = SplitMix64(seed: 7)
        let drawn = (0..<50).compactMap { _ in bag.next(using: &generator) }
        #expect(zip(drawn, drawn.dropFirst()).allSatisfy { $0 != $1 })
    }

    @Test func sameSeedGivesSameSequence() {
        #expect(sequence(seed: 99) == sequence(seed: 99))
    }

    @Test func differentSeedGivesDifferentSequence() {
        #expect(sequence(seed: 1) != sequence(seed: 2))
    }

    @Test func emptyBagReturnsNil() {
        var bag = ShuffleBag<Int>([])
        var generator = SplitMix64(seed: 1)
        #expect(bag.isEmpty)
        #expect(bag.next(using: &generator) == nil)
        #expect(bag.next(using: &generator) == nil)
    }

    @Test func singleElementBagAlwaysReturnsIt() {
        var bag = ShuffleBag(["only"])
        var generator = SplitMix64(seed: 1)
        let drawn = (0..<5).compactMap { _ in bag.next(using: &generator) }
        #expect(drawn == Array(repeating: "only", count: 5))
    }

    private func sequence(seed: UInt64) -> [Int] {
        var bag = ShuffleBag(Array(1...10))
        var generator = SplitMix64(seed: seed)
        return (0..<20).compactMap { _ in bag.next(using: &generator) }
    }
}
