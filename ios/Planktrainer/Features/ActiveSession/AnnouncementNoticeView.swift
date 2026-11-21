import SwiftUI

struct AnnouncementNoticeView: View {
    let error: AnnouncerError

    var body: some View {
        Label {
            Text(verbatim: error.localizedDescription)
        } icon: {
            Image(systemName: "speaker.slash.fill")
        }
        .font(ThemeFont.caption)
        .foregroundStyle(ThemeColor.contentPrimary)
        .padding(.horizontal, ThemeSpacing.l)
        .padding(.vertical, ThemeSpacing.s)
        .glassEffect(.regular, in: .capsule)
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
