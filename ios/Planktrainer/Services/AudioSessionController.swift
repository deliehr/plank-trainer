import AVFAudio

protocol AudioSessionControlling: AnyObject {
    func configureForAnnouncements() throws
    func activate() throws
    func deactivate() throws
}

final class AudioSessionController: AudioSessionControlling {
    init() {}

    func configureForAnnouncements() throws {
        try AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .voicePrompt,
            options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
        )
    }

    func activate() throws {
        try AVAudioSession.sharedInstance().setActive(true)
    }

    func deactivate() throws {
        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
