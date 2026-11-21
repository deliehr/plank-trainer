import AVFAudio
import Testing
@testable import Planktrainer

@Suite struct AudioInterruptionMonitorTests {
    @Test func beganInterruptionIsParsed() {
        let userInfo: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
        ]
        #expect(AudioInterruptionMonitor.interruption(from: userInfo) == .began)
    }

    @Test func endedWithShouldResumeIsParsed() {
        let userInfo: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
            AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
        ]
        #expect(AudioInterruptionMonitor.interruption(from: userInfo) == .ended(shouldResume: true))
    }

    @Test func endedWithoutOptionsDoesNotResume() {
        let userInfo: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue
        ]
        #expect(AudioInterruptionMonitor.interruption(from: userInfo) == .ended(shouldResume: false))
    }

    @Test func emptyOrUnknownUserInfoYieldsNil() {
        #expect(AudioInterruptionMonitor.interruption(from: nil) == nil)
        #expect(AudioInterruptionMonitor.interruption(from: [:]) == nil)
        #expect(AudioInterruptionMonitor.interruption(from: [AVAudioSessionInterruptionTypeKey: UInt(99)]) == nil)
    }
}
