import Foundation

enum AnnouncerError: LocalizedError, Equatable {
    case unavailable

    var errorDescription: String? { L10n.string("error.announcer.unavailable", table: .errors) }
}

protocol Announcing: AnyObject {
    /// Configures the audio session once per session. Throws if audio is unavailable.
    func prepare() throws(AnnouncerError)
    func speak(_ text: String) throws(AnnouncerError)
    func stopSpeaking()
}

final class SilentAnnouncer: Announcing {
    func prepare() throws(AnnouncerError) {}
    func speak(_ text: String) throws(AnnouncerError) {}
    func stopSpeaking() {}
}
