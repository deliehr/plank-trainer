struct ShuffleBag<Element: Equatable> {
    private let elements: [Element]
    private var remaining: [Element] = []
    private var lastDrawn: Element?

    init(_ elements: [Element]) {
        self.elements = elements
    }

    var isEmpty: Bool { elements.isEmpty }

    mutating func next(using generator: inout some RandomNumberGenerator) -> Element? {
        guard !elements.isEmpty else { return nil }
        if remaining.isEmpty {
            refill(using: &generator)
        }
        let drawn = remaining.removeFirst()
        lastDrawn = drawn
        return drawn
    }

    private mutating func refill(using generator: inout some RandomNumberGenerator) {
        remaining = elements.shuffled(using: &generator)
        if remaining.count > 1, remaining.first == lastDrawn {
            remaining.swapAt(0, 1)
        }
    }
}
