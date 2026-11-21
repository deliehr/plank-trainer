import SwiftUI

struct AnnouncementNoticeView: View {
    let error: AnnouncerError

    var body: some View {
        Label(error.localizedDescription, systemImage: "speaker.slash")
            .font(ThemeFont.caption)
            .foregroundStyle(ThemeColor.contentSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                AccessibilityNotification.Announcement(error.localizedDescription).post()
            }
    }
}

#Preview {
    PreviewHost { AnnouncementNoticeView(error: .unavailable).padding() }
}

#Preview("AX3") {
    PreviewHost { AnnouncementNoticeView(error: .unavailable).padding() }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { AnnouncementNoticeView(error: .unavailable).padding() }
        .preferredColorScheme(.dark)
}
