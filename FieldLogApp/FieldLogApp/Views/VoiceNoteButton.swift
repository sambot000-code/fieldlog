import SwiftUI

/// Self-contained voice recording + transcription widget.
/// Drop into any view. Calls onTranscript when Whisper finishes.
struct VoiceNoteButton: View {
    @StateObject private var recorder = VoiceRecorder()
    var onTranscript: (String) -> Void   // called with transcribed text
    var onAudioSaved: (String) -> Void   // called with saved filename

    @State private var transcribing = false
    @State private var transcribeError: String? = nil
    @State private var recordedFilename: String? = nil

    var body: some View {
        VStack(spacing: 14) {

            // MARK: Record button
            Button {
                if recorder.isRecording {
                    if let url = recorder.stopRecording() {
                        let filename = url.lastPathComponent
                        recordedFilename = filename
                        onAudioSaved(filename)
                        Task { await transcribe(url: url) }
                    }
                } else {
                    recorder.startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(recorder.isRecording
                              ? Color.flDanger.opacity(0.15)
                              : Color.flAccent.opacity(0.12))
                        .frame(width: 72, height: 72)

                    if recorder.isRecording {
                        // Pulsing ring
                        Circle()
                            .stroke(Color.flDanger.opacity(0.4), lineWidth: 2)
                            .frame(width: 72, height: 72)
                            .scaleEffect(recorder.isRecording ? 1.15 : 1)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                       value: recorder.isRecording)

                        Image(systemName: "stop.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.flDanger)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.flAccent)
                    }
                }
            }
            .buttonStyle(.plain)

            // MARK: Status text
            if recorder.isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.flDanger)
                        .frame(width: 7, height: 7)
                    Text(recorder.recordingDuration.mmss)
                        .font(.system(.subheadline, design: .monospaced).weight(.medium))
                        .foregroundStyle(Color.flDanger)
                }
            } else if transcribing {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text("Transcribing…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if recordedFilename != nil {
                Label("Voice note saved", systemImage: "waveform")
                    .font(.caption)
                    .foregroundStyle(Color.flSuccess)
            } else {
                Text("Tap to record")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = transcribeError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(Color.flDanger)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Transcription

    private func transcribe(url: URL) async {
        transcribing = true
        transcribeError = nil
        do {
            let text = try await AIService.shared.transcribe(audioFileURL: url)
            onTranscript(text)
        } catch {
            transcribeError = "Transcription failed — check your API key"
        }
        transcribing = false
    }
}
