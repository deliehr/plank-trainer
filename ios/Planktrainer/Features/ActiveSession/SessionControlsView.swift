import SwiftUI

struct SessionControlsView: View {
    let engine: SessionEngine
    let onDone: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isAccessibilityLayout: Bool { dynamicTypeSize.isAccessibilitySize }

    private var primaryHeight: CGFloat {
        isAccessibilityLayout ? SessionControlMetrics.accessibilityPrimaryHeight : SessionControlMetrics.primaryHeight
    }

    private var secondaryHeight: CGFloat {
        isAccessibilityLayout ? SessionControlMetrics.accessibilitySecondaryHeight : SessionControlMetrics.secondaryHeight
    }

    var body: some View {
        switch engine.phase {
        case .running:
            controls(title: .activeSession("active.pause"), symbol: "pause.fill", action: engine.pause)
        case .paused:
            controls(title: .activeSession("active.resume"), symbol: "play.fill", action: engine.resume)
        case .finished:
            primaryButton(Text(.sessionDisplay("display.result.done")), symbol: nil, action: onDone)
        case .preparing, .resuming, .cancelled:
            EmptyView()
        }
    }

    private func controls(title: LocalizedStringResource, symbol: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: SessionControlMetrics.spacing) {
            primaryButton(Text(title), symbol: symbol, action: action)
            secondaryControls
        }
    }

    private func primaryButton(_ title: Text, symbol: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let symbol {
                    Label { title } icon: { Image(systemName: symbol) }
                } else {
                    title
                }
            }
            .font(ThemeFont.sessionButton)
            .foregroundStyle(ThemeColor.onAccent)
            .frame(maxWidth: .infinity, minHeight: primaryHeight)
        }
        .buttonStyle(.glassProminent)
    }

    private var secondaryControls: some View {
        let layout = isAccessibilityLayout
            ? AnyLayout(VStackLayout(spacing: SessionControlMetrics.spacing))
            : AnyLayout(HStackLayout(spacing: SessionControlMetrics.spacing))
        return layout {
            Button(action: engine.extend) {
                Label { Text(.activeSession("active.extend")) } icon: { Image(systemName: "plus") }
                    .font(ThemeFont.sessionButton)
                    .foregroundStyle(ThemeColor.contentPrimary)
                    .frame(maxWidth: .infinity, minHeight: secondaryHeight)
            }
            .accessibilityLabel(Text(.activeSession("active.extend.accessibility")))
            Button(action: engine.stop) {
                stopLabel
                    .font(ThemeFont.sessionButton)
                    .foregroundStyle(ThemeColor.contentPrimary)
                    .frame(maxWidth: .infinity, minHeight: secondaryHeight)
            }
            .accessibilityLabel(Text(.activeSession("active.stop.combined")))
            .accessibilityHint(Text(.activeSession("active.stop.hint")))
        }
        .buttonStyle(.glass)
    }

    @ViewBuilder
    private var stopLabel: some View {
        if isAccessibilityLayout {
            Label { Text(.activeSession("active.stop.combined")) } icon: { Image(systemName: "stop.fill") }
        } else {
            Label {
                VStack(spacing: 0) {
                    Text(.activeSession("active.stop"))
                    Text(.activeSession("active.stop.subtitle"))
                        .font(ThemeFont.caption)
                        .foregroundStyle(ThemeColor.contentSecondary)
                }
            } icon: {
                Image(systemName: "stop.fill")
            }
        }
    }
}

extension LocalizedStringResource {
    static func sessionDisplay(_ key: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(key, table: LocalizationTable.sessionDisplay.rawValue)
    }
}

#if DEBUG
private func previewEngine(_ state: ActiveSessionPreview.State) -> SessionEngine {
    ActiveSessionPreview.engine(state: state)
}

#Preview("Running") {
    PreviewHost { SessionControlsView(engine: previewEngine(.running), onDone: {}).padding() }
}

#Preview("Paused") {
    PreviewHost { SessionControlsView(engine: previewEngine(.paused), onDone: {}).padding() }
}

#Preview("Finished") {
    PreviewHost { SessionControlsView(engine: previewEngine(.finished(achieved: 60, record: nil)), onDone: {}).padding() }
}

#Preview("AX3") {
    PreviewHost { SessionControlsView(engine: previewEngine(.paused), onDone: {}).padding() }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { SessionControlsView(engine: previewEngine(.running), onDone: {}).padding() }
        .preferredColorScheme(.dark)
}
#endif
