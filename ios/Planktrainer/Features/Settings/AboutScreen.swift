import SwiftUI

struct AboutScreen: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = ThemeSize.aboutIcon
    private static let sourceCodeURL = URL(string: "https://github.com/deliehr/plank-trainer")

    var body: some View {
        Form {
            Section {
                VStack(spacing: ThemeSpacing.m) {
                    Image(.aboutIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large, style: .continuous))
                        .accessibilityHidden(true)
                    Text("about.appName", tableName: LocalizationTable.settings.rawValue)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section {
                LabeledContent {
                    Text(verbatim: versionText)
                } label: {
                    Text("about.version", tableName: LocalizationTable.settings.rawValue)
                }
                LabeledContent {
                    Text("about.license.value", tableName: LocalizationTable.settings.rawValue)
                } label: {
                    Text("about.license", tableName: LocalizationTable.settings.rawValue)
                }
                if let url = Self.sourceCodeURL {
                    Link(destination: url) {
                        HStack {
                            Text("about.sourceCode", tableName: LocalizationTable.settings.rawValue)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .accessibilityHidden(true)
                        }
                    }
                }
            } footer: {
                Text("about.footer", tableName: LocalizationTable.settings.rawValue)
            }
        }
        .navigationTitle(Text("about.title", tableName: LocalizationTable.settings.rawValue))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String
        switch (version, build) {
        case let (version?, build?): return "\(version) (\(build))"
        case let (version?, nil): return version
        case let (nil, build?): return build
        case (nil, nil): return ""
        }
    }
}

#Preview {
    PreviewHost { NavigationStack { AboutScreen() } }
}

#Preview("AX3") {
    PreviewHost { NavigationStack { AboutScreen() } }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { NavigationStack { AboutScreen() } }
        .preferredColorScheme(.dark)
}
