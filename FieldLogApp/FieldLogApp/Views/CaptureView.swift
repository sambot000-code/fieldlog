import SwiftUI
import PhotosUI

/// Main capture screen — photo + text/voice → AI summary → save event
struct CaptureView: View {
    @EnvironmentObject var store: EventStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var rawNote = ""
    @State private var aiSummary: String? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoImage: Image? = nil
    @State private var photoFilename: String? = nil

    @State private var isSummarizing = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Title
                Section("Event Title") {
                    TextField("e.g. Crack in dam wall — north face", text: $title)
                }

                // MARK: Photo
                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Attach Photo", systemImage: "camera")
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task { await loadPhoto(item) }
                    }
                    if let photo = photoImage {
                        photo
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    }
                }

                // MARK: Note
                Section("Observation Note") {
                    TextEditor(text: $rawNote)
                        .frame(minHeight: 100)
                    // TODO: Voice memo recording button goes here
                    // Will call AIService.transcribe() then populate rawNote
                }

                // MARK: AI Summary
                Section("AI Summary") {
                    if isSummarizing {
                        HStack {
                            ProgressView()
                            Text("Summarizing...").foregroundStyle(.secondary)
                        }
                    } else if let summary = aiSummary {
                        Text(summary)
                            .foregroundStyle(.secondary)
                        Button("Regenerate") { Task { await summarize() } }
                    } else {
                        Button("Generate Summary") { Task { await summarize() } }
                            .disabled(rawNote.isEmpty)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEvent() }
                        .disabled(title.isEmpty && rawNote.isEmpty)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            photoImage = Image(uiImage: uiImage)
            // Save to documents directory
            let filename = "\(UUID().uuidString).jpg"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(filename)
            try? data.write(to: url)
            photoFilename = filename
        }
    }

    private func summarize() async {
        isSummarizing = true
        errorMessage = nil
        do {
            aiSummary = try await AIService.shared.summarize(rawNote: rawNote)
        } catch {
            errorMessage = "AI summarization failed: \(error.localizedDescription)"
        }
        isSummarizing = false
    }

    private func saveEvent() {
        var event = FieldEvent(
            title: title.isEmpty ? "Untitled Event" : title,
            rawNote: rawNote,
            aiSummary: aiSummary,
            photoFilenames: photoFilename.map { [$0] } ?? []
        )
        // TODO: attach GPS coordinates from LocationManager
        store.add(event)
        dismiss()
    }
}
