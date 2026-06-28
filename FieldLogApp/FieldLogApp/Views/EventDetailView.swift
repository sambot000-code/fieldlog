import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: FieldEvent

    var body: some View {
        ZStack {
            Color.flBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Header card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            PillBadge(label: event.status.rawValue, color: event.status.color)
                            if event.syncStatus == .pendingSync {
                                PillBadge(label: "⏳ Pending sync", color: .flWarning)
                            }
                            Spacer()
                            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Text(event.title.isEmpty ? "Untitled Event" : event.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)

                        // Sync failure notice + retry
                        if event.syncStatus == .failed {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(Color.flDanger)
                                    Text("AI enrichment failed after 3 attempts")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.flDanger)
                                }
                                if let errMsg = event.syncError {
                                    Text(errMsg)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Button {
                                    SyncQueue.shared.retry(event: event, eventStore: store)
                                } label: {
                                    Label("Retry Now", systemImage: "arrow.clockwise")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.flAccent)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .cardStyle()

                    // MARK: - Photo
                    if let filename = event.photoFilenames.first,
                       let image = loadImage(filename: filename) {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    // MARK: - AI Summary
                    if let summary = event.aiSummary {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "AI Summary")
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color.flAccent)
                                    .padding(.top, 2)
                                Text(summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                            .padding(14)
                            .cardStyle()
                        }
                    }

                    // MARK: - Raw Note
                    if !event.rawNote.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Field Note")
                            Text(event.rawNote)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cardStyle()
                        }
                    }

                    // MARK: - Location
                    if let lat = event.latitude, let lon = event.longitude {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Location")
                            VStack(alignment: .leading, spacing: 12) {
                                // Map preview
                                Map(position: .constant(.region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                                )))) {
                                    Marker("Event", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                        .tint(Color.flAccent)
                                }
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(.horizontal, 14)
                                .padding(.top, 14)

                                Divider().padding(.horizontal, 14)

                                // Coordinate details
                                VStack(spacing: 6) {
                                    CoordRow(label: "Latitude",  value: String(format: "%.6f°", lat))
                                    CoordRow(label: "Longitude", value: String(format: "%.6f°", lon))
                                    if let alt = event.altitude {
                                        CoordRow(label: "Altitude",  value: String(format: "%.0f m", alt))
                                    }
                                    if let acc = event.horizontalAccuracy {
                                        CoordRow(label: "Accuracy",  value: String(format: "±%.0f m", acc))
                                    }
                                    if let deg = event.headingDegrees {
                                        CoordRow(
                                            label: "Heading",
                                            value: "\(Int(deg))° \(event.headingLabel ?? "")"
                                        )
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.bottom, 14)
                            }
                            .cardStyle()
                        }
                    }

                    // MARK: - Tags
                    if !event.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Tags")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(event.tags, id: \.self) { tag in
                                        PillBadge(label: tag, color: .flAccent)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                            .cardStyle()
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("")
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

// MARK: - Coord Row

struct CoordRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}
