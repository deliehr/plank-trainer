import SwiftUI

struct AboutScreen: View {
    private static let sourceCodeURL = URL(string: "https://github.com/deliehr/plank-trainer")

    var body: some View {
        Form {
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
                    Text("about.sourceCode", tableName: LocalizationTable.settings.rawValue)
                }
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
