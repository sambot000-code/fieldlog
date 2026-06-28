import Foundation
import AVFoundation
import Combine

/// Handles microphone recording to an m4a file.
/// Call startRecording() / stopRecording() — observe state via @Published properties.
class VoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {

    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var lastRecordingURL: URL? = nil

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    // MARK: - Public API

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            print("VoiceRecorder: session setup failed — \(error)")
            return
        }

        let filename = "\(UUID().uuidString).m4a"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            isRecording = true
            recordingDuration = 0
            lastRecordingURL = nil

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingDuration = self?.recorder?.currentTime ?? 0
            }
        } catch {
            print("VoiceRecorder: failed to start — \(error)")
        }
    }

    /// Stops recording and returns the file URL
    @discardableResult
    func stopRecording() -> URL? {
        recorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false

        let url = recorder?.url
        lastRecordingURL = url

        try? AVAudioSession.sharedInstance().setActive(false)
        return url
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag { lastRecordingURL = nil }
    }
}

// MARK: - Duration formatter

extension TimeInterval {
    var mmss: String {
        let m = Int(self) / 60
        let s = Int(self) % 60
        return String(format: "%d:%02d", m, s)
    }
}
