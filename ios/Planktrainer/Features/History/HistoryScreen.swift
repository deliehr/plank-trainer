import SwiftData
import SwiftUI

struct HistoryScreen: View {
    @Query(sort: \PlankSession.startedAt, order: .reverse) private var sessions: [PlankSession]
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var deleteError: SessionStoreError?

    var body: some View {
        let summary = SessionHistorySummary(sessions: sessions)
        Group {
            if sessions.isEmpty {
                emptyState
            } else {
                list(summary: summary)
            }
        }
        .navigationTitle(Text("history.title", tableName: LocalizationTable.history.rawValue))
        .toolbar {
            if !sessions.isEmpty {
                EditButton()
            }
        }
        .alert(
            Text("history.deleteError.title", tableName: LocalizationTable.history.rawValue),
            isPresented: isShowingDeleteError,
            presenting: deleteError
        ) { _ in
            Button(role: .cancel) {} label: {
                Text("common.ok", tableName: LocalizationTable.common.rawValue)
            }
        } message: { error in
            Text(verbatim: error.localizedDescription)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label {
                Text("history.empty.title", tableName: LocalizationTable.history.rawValue)
            } icon: {
                Image(systemName: "figure.core.training")
            }
        } description: {
            Text("history.empty.message", tableName: LocalizationTable.history.rawValue)
        } actions: {
            Button {
                router.selectedTab = .training
            } label: {
                Text("history.empty.action", tableName: LocalizationTable.history.rawValue)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func list(summary: SessionHistorySummary) -> some View {
        List {
            Section {
                HistoryChartView(points: HistoryChartData.points(from: sessions), recordSeconds: summary.recordSeconds)
            }
            Section {
                ForEach(sessions) { session in
                    NavigationLink(value: Route.sessionDetail(session.idValue)) {
                        HistoryRow(session: session, isRecord: summary.isRecord(session))
                    }
                }
                .onDelete(perform: delete)
            }
        }
    }

    private var isShowingDeleteError: Binding<Bool> {
        Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })
    }

    private func delete(at offsets: IndexSet) {
        let store = SessionStore(context: modelContext)
        let targets = offsets.map { sessions[$0] }
        do {
            for session in targets {
                try store.delete(session)
            }
        } catch {
            deleteError = error
        }
    }
}

#Preview {
    NavigationStack { PreviewHost { HistoryScreen() } }
}

#Preview("AX3") {
    NavigationStack { PreviewHost { HistoryScreen() } }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    NavigationStack { PreviewHost { HistoryScreen() } }
        .preferredColorScheme(.dark)
}

#Preview("Empty") {
    NavigationStack { EmptyHistoryPreview() }
}

private struct EmptyHistoryPreview: View {
    var body: some View {
        do {
            let container = try ModelContainerFactory.make(inMemory: true)
            return AnyView(HistoryScreen().environment(AppRouter()).modelContainer(container))
        } catch {
            return AnyView(Text(verbatim: error.localizedDescription))
        }
    }
}
