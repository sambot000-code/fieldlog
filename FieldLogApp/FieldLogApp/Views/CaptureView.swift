import SwiftUI
import PhotosUI

/// Main capture screen — photo + text/voice → AI summary → save event
struct CaptureView: View {
    @EnvironmentObject var store: EventStore
    @Environment(\.dismiss) var dismiss
    @StateObject private var location = LocationService.shared

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
            ZStack {
                Color.flBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Title
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Event Title")
                            TextField("e.g. Crack in dam wall — north face", text: $title)
                                .font(.system(size: 16))
                                .padding(14)
                                .cardStyle()
                        }

                        // MARK: - Location
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Location")
                            LocationSnapshotView(service: location)
                                .cardStyle()
                        }

                        // MARK: - Photo
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Photo")
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                if let photo = photoImage {
                                    photo
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 220)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(alignment: .topTrailing) {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .font(.caption.weight(.semibold))
                                                .padding(8)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Circle())
                                                .padding(10)
                                        }
                                } else {
                                    HStack {
                                        Spacer()
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.title2)
                                                .foregroundStyle(Color.flAccent)
                                            Text("Tap to attach photo")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 28)
                                    .cardStyle()
                                }
                            }
                            .onChange(of: selectedPhoto) { _, item in
                                Task { await loadPhoto(item) }
                            }
                        }

                        // MARK: - Observation Note
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Observation Note")
                            TextEditor(text: $rawNote)
                                .font(.system(size: 16))
                                .frame(minHeight: 120)
                                .padding(12)
                                .cardStyle()
                                .scrollContentBackground(.hidden)
                        }

                        // MARK: - AI Summary
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "AI Summary")
                            VStack(alignment: .leading, spacing: 12) {
                                if isSummarizing {
                                    HStack(spacing: 10) {
                                        ProgressView()
                                        Text("Summarizing with AI...")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(14)
                                } else if let summary = aiSummary {
                                    Text(summary)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .padding(14)
                                    Divider()
                                    Button("Regenerate") { Task { await summarize() } }
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.flAccent)
                                        .padding(.horizontal, 14)
                                        .padding(.bottom, 12)
                                } else {
                                    Button {
                                        Task { await summarize() }
                                    } label: {
                                        HStack {
                                            Image(systemName: "sparkles")
                                            Text("Generate AI Summary")
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(rawNote.isEmpty ? .secondary : Color.flAccent)
                                        .padding(14)
                                    }
                                    .disabled(rawNote.isEmpty)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Color.flDanger)
                                .padding(.horizontal, 4)
                        }

                        // MARK: - Save button
                        Button(action: saveEvent) {
                            Text("Save Event")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    (title.isEmpty && rawNote.isEmpty)
                                    ? Color.secondary
                                    : Color.flAccent
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(title.isEmpty && rawNote.isEmpty)
                    }
                    .padding(16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.flAccent)
                }
            }
            .onAppear {
                location.requestPermission()
            }
        }
    }

    // MARK: - Actions

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            photoImage = Image(uiImage: uiImage)
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
        let snap = location.snapshot()
        let event = FieldEvent(
            latitude: snap?.lat,
            longitude: snap?.lon,
            altitude: snap?.alt,
            horizontalAccuracy: snap?.accuracy,
            headingDegrees: snap?.heading,
            headingAccuracy: snap?.headingAccuracy,
            title: title.isEmpty ? "Untitled Event" : title,
            rawNote: rawNote,
            aiSummary: aiSummary,
            photoFilenames: photoFilename.map { [$0] } ?? []
        )
        store.add(event)
        dismiss()
    }
}

// MARK: - Location Snapshot View

struct LocationSnapshotView: View {
    @ObservedObject var service: LocationService

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.title3)
                .foregroundStyle(Color.flAccent)

            if let loc = service.currentLocation {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.6f, %.6f", loc.coordinate.latitude, loc.coordinate.longitude))
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        if loc.altitude != 0 {
                            Text(String(format: "Alt %.0fm", loc.altitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if loc.horizontalAccuracy > 0 {
                            Text(String(format: "±%.0fm", loc.horizontalAccuracy))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let heading = service.currentHeading {
                            Text("Heading \(Int(heading.trueHeading))°")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text(service.authStatus == .denied
                     ? "Location access denied"
                     : "Acquiring GPS…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if service.currentLocation != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.flSuccess)
            }
        }
        .padding(14)
    }
}
