import SwiftUI

struct SettingsScreen: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var settings = environment.userSettings
        Form {
            Section {
                Picker(selection: $settings.appearance) {
                    ForEach(UserSettings.Appearance.allCases, id: \.self) { appearance in
                        appearance.title.tag(appearance)
                    }
                } label: {
                    Text("settings.appearance", tableName: LocalizationTable.settings.rawValue)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            } header: {
                Text("settings.appearance", tableName: LocalizationTable.settings.rawValue)
            }

            Section {
                Picker(selection: $settings.coachStyle) {
                    ForEach(CoachStyle.allCases, id: \.self) { style in
                        CoachStyleRow(style: style).tag(style)
                    }
                } label: {
                    Text("settings.coach.header", tableName: LocalizationTable.settings.rawValue)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("settings.coach.header", tableName: LocalizationTable.settings.rawValue)
            }

            Section {
                Toggle(isOn: $settings.postureHintsEnabled) {
                    Text("settings.postureHints", tableName: LocalizationTable.settings.rawValue)
                }
                Toggle(isOn: $settings.hapticsEnabled) {
                    Text("settings.haptics", tableName: LocalizationTable.settings.rawValue)
                }
            } footer: {
                Text("settings.postureHints.footer", tableName: LocalizationTable.settings.rawValue)
            }

            Section {
                NavigationLink(value: Route.about) {
                    Text("settings.about", tableName: LocalizationTable.settings.rawValue)
                }
            }
        }
        .navigationTitle(Text("settings.title", tableName: LocalizationTable.settings.rawValue))
    }
}

private struct CoachStyleRow: View {
    let style: CoachStyle

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
            style.name
                .font(ThemeFont.sectionTitle)
                .foregroundStyle(ThemeColor.contentPrimary)
            style.description
                .font(.subheadline)
                .foregroundStyle(ThemeColor.contentSecondary)
            if let example = style.exampleSentence {
                Text(verbatim: quoted(example))
                    .font(.subheadline.italic())
                    .foregroundStyle(ThemeColor.contentSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func quoted(_ text: String) -> String {
        let locale = AppLocale.current
        let open = locale.quotationBeginDelimiter ?? "\""
        let close = locale.quotationEndDelimiter ?? "\""
        return open + text + close
    }
}

private extension UserSettings.Appearance {
    var title: Text {
        let table = LocalizationTable.settings.rawValue
        return switch self {
        case .system: Text("settings.appearance.system", tableName: table)
        case .light: Text("settings.appearance.light", tableName: table)
        case .dark: Text("settings.appearance.dark", tableName: table)
        }
    }
}

private extension CoachStyle {
    var name: Text {
        let table = LocalizationTable.settings.rawValue
        return switch self {
        case .calm: Text("settings.coach.calm", tableName: table)
        case .demanding: Text("settings.coach.demanding", tableName: table)
        case .cheeky: Text("settings.coach.cheeky", tableName: table)
        case .off: Text("settings.coach.off", tableName: table)
        }
    }

    var description: Text {
        let table = LocalizationTable.settings.rawValue
        return switch self {
        case .calm: Text("settings.coach.calm.description", tableName: table)
        case .demanding: Text("settings.coach.demanding.description", tableName: table)
        case .cheeky: Text("settings.coach.cheeky.description", tableName: table)
        case .off: Text("settings.coach.off.description", tableName: table)
        }
    }

    var exampleSentence: String? {
        switch self {
        case .calm: L10n.string("coach.calm.filler.01", table: .coach)
        case .demanding: L10n.string("coach.demanding.filler.04", table: .coach)
        case .cheeky: L10n.string("coach.cheeky.filler.02", table: .coach)
        case .off: nil
        }
    }
}

#Preview {
    PreviewHost { NavigationStack { SettingsScreen() } }
}

#Preview("AX3") {
    PreviewHost { NavigationStack { SettingsScreen() } }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { NavigationStack { SettingsScreen() } }
        .preferredColorScheme(.dark)
}
