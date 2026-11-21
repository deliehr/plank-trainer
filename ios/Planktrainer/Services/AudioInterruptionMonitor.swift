import AVFAudio

enum AudioInterruption: Equatable, Sendable {
    case began
    case ended(shouldResume: Bool)
}

enum AudioInterruptionMonitor {
    static func interruption(from userInfo: [AnyHashable: Any]?) -> AudioInterruption? {
        guard let rawType = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else { return nil }

        switch type {
        case .began:
            return .began
        case .ended:
            let rawOptions = userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            return .ended(shouldResume: options.contains(.shouldResume))
        @unknown default:
            return nil
        }
    }

    static func interruptions() -> AsyncStream<AudioInterruption> {
        AsyncStream { continuation in
            let task = Task {
                let notifications = NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification)
                for await notification in notifications {
                    if let interruption = interruption(from: notification.userInfo) {
                        continuation.yield(interruption)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
