import Foundation
import SwiftData
import Testing
@testable import Planktrainer

@Suite struct SessionStoreTests {
    private func makeResult(achieved: Int = 75) -> SessionResult {
        SessionResult(
            configuration: SessionConfiguration(plannedSeconds: 60, preparationSeconds: 15),
            startedAt: Date(timeIntervalSince1970: 1_000),
            endedAt: Date(timeIntervalSince1970: 1_100),
            extensionSeconds: 15,
            achievedSeconds: achieved,
            pauseCount: 2,
            outcome: .completed,
            isNewRecord: false
        )
    }

    @Test func saveTransfersAllFields() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let saved = try SessionStore(context: context).save(makeResult())

        let stored = try context.fetch(FetchDescriptor<PlankSession>())
        #expect(stored.count == 1)
        #expect(saved.id != nil)
        #expect(saved.startedAt == Date(timeIntervalSince1970: 1_000))
        #expect(saved.endedAt == Date(timeIntervalSince1970: 1_100))
        #expect(saved.preparationSeconds == 15)
        #expect(saved.plannedSeconds == 60)
        #expect(saved.extensionSeconds == 15)
        #expect(saved.achievedSeconds == 75)
        #expect(saved.pauseCount == 2)
    }

    @Test func savingTwiceCreatesTwoRecords() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let store = SessionStore(context: context)
        let first = try store.save(makeResult())
        let second = try store.save(makeResult())

        #expect(try context.fetch(FetchDescriptor<PlankSession>()).count == 2)
        #expect(first.id != second.id)
    }

    @Test func deleteRemovesExactlyThatRecord() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let store = SessionStore(context: context)
        let keep = try store.save(makeResult(achieved: 40))
        let remove = try store.save(makeResult(achieved: 90))

        try store.delete(remove)

        let remaining = try context.fetch(FetchDescriptor<PlankSession>())
        #expect(remaining.map(\.idValue) == [keep.idValue])
    }
}
