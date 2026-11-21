import SwiftUI

struct SessionCoachHintView: View {
    let style: CoachStyle

    var body: some View {
        Label {
            Text("active.coach \(styleName)", tableName: LocalizationTable.activeSession.rawValue)
        } icon: {
            Image(systemName: "bubble.left")
        }
        .font(ThemeFont.caption)
        .foregroundStyle(ThemeColor.contentSecondary)
        .lineLimit(1)
    }

    private var styleName: String {
        let key: String.LocalizationValue = switch style {
        case .calm: "settings.coach.calm"
        case .demanding: "settings.coach.demanding"
        case .cheeky: "settings.coach.cheeky"
        case .off: "settings.coach.off"
        }
        return L10n.string(key, table: .settings)
    }
}

#Preview {
    PreviewHost { SessionCoachHintView(style: .cheeky).padding() }
}

#Preview("Dark") {
    PreviewHost { SessionCoachHintView(style: .calm).padding() }
        .preferredColorScheme(.dark)
}
