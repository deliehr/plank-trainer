import Foundation
import SwiftData
import Testing
@testable import Planktrainer

@Suite struct ModelContainerFactoryTests {
    @Test func fetchesSessionsNewestFirst() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let older = PlankSession(startedAt: Date(timeIntervalSince1970: 100))
        let newer = PlankSession(startedAt: Date(timeIntervalSince1970: 200))
        context.insert(older)
        context.insert(newer)
        try context.save()

        let descriptor = FetchDescriptor<PlankSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        let sessions = try context.fetch(descriptor)

        #expect(sessions.map(\.startedAt) == [newer.startedAt, older.startedAt])
    }

    @Test func predicateFindsSessionByOptionalID() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let target = PlankSession()
        context.insert(target)
        context.insert(PlankSession())
        try context.save()

        let id: UUID? = target.id
        let descriptor = FetchDescriptor<PlankSession>(predicate: #Predicate { $0.id == id })
        let sessions = try context.fetch(descriptor)

        #expect(sessions.count == 1)
        #expect(sessions.first?.id == id)
    }
}
