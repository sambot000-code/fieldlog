import SwiftUI

struct EventDetailView: View {
    let event: FieldEvent

    var body: some View {
        List {
            // MARK: Summary
            if let summary = event.aiSummary {
                Section("AI Summary") {
                    Text(summary)
                }
            }

            // MARK: Raw Note
            if !event.rawNote.isEmpty {
                Section("Raw Note") {
                    Text(event.rawNote)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: Photos
            if !event.photoFilenames.isEmpty {
                Section("Photos") {
                    ForEach(event.photoFilenames, id: \.self) { filename in
                        if let image = loadImage(filename: filename) {
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                        }
                    }
                }
            }

            // MARK: Metadata
            Section("Details") {
                LabeledContent("Status", value: event.status.rawValue)
                LabeledContent("Logged", value: event.timestamp.formatted(
                    date: .long, time: .shortened
                ))
                if let lat = event.latitude, let lon = event.longitude {
                    LabeledContent("Location", value: "\(lat), \(lon)")
                }
                if !event.tags.isEmpty {
                    LabeledContent("Tags", value: event.tags.joined(separator: ", "))
                }
            }
        }
        .navigationTitle(event.title.isEmpty ? "Event" : event.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadImage(filename: String) -> Image? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
}
