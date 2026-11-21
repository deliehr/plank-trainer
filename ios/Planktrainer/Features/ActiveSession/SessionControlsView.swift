import SwiftUI

struct SessionControlsView: View {
    let engine: SessionEngine
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if let primary {
            VStack(spacing: ThemeSize.sessionControlSpacing) {
                controlButton(primary.title, systemImage: primary.symbol, action: primary.action)
                    .buttonStyle(.borderedProminent)
                secondaryControls
            }
        }
    }

    private var primary: (title: LocalizedStringResource, symbol: String, action: () -> Void)? {
        switch engine.phase {
        case .running: (.activeSession("active.pause"), "pause.fill", engine.pause)
        case .paused: (.activeSession("active.resume"), "play.fill", engine.resume)
        case .preparing, .resuming, .finished, .cancelled: nil
        }
    }

    private var secondaryControls: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: ThemeSize.sessionControlSpacing))
            : AnyLayout(HStackLayout(spacing: ThemeSize.sessionControlSpacing))
        return layout {
            controlButton(.activeSession("active.extend"), systemImage: "plus", action: engine.extend)
                .accessibilityLabel(Text(.activeSession("active.extend.accessibility")))
            controlButton(.activeSession("active.stop"), systemImage: "stop.fill", action: engine.stop)
                .accessibilityHint(Text(.activeSession("active.stop.hint")))
        }
        .buttonStyle(.bordered)
    }

    private func controlButton(
        _ title: LocalizedStringResource,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label { Text(title) } icon: { Image(systemName: systemImage) }
                .frame(maxWidth: .infinity, minHeight: ThemeSize.sessionControlHeight)
        }
    }
}

#if DEBUG
private func previewEngine(paused: Bool) -> SessionEngine {
    let engine = ActiveSessionPreview.engine()
    engine.start()
    if paused { engine.pause() }
    return engine
}

#Preview("Paused") {
    PreviewHost { SessionControlsView(engine: previewEngine(paused: true)).padding() }
}

#Preview("AX3") {
    PreviewHost { SessionControlsView(engine: previewEngine(paused: true)).padding() }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { SessionControlsView(engine: previewEngine(paused: true)).padding() }
        .preferredColorScheme(.dark)
}
#endif
