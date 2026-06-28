import SwiftUI
import MapKit

struct InspectionDetailView: View {
    let inspection: Inspection
    @EnvironmentObject var eventStore: EventStore

    private var linkedEvents: [FieldEvent] {
        eventStore.events.filter { inspection.eventIds.contains($0.id) }
    }

    private var pathCoords: [CLLocationCoordinate2D] {
        inspection.pathPoints.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    private var mapRegion: MKCoordinateRegion? {
        guard !pathCoords.isEmpty else { return nil }
        let lats  = pathCoords.map(\.latitude)
        let lons  = pathCoords.map(\.longitude)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        let centre = CLLocationCoordinate2D(
            latitude:  (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta:  max(maxLat - minLat, 0.001) * 1.4,
            longitudeDelta: max(maxLon - minLon, 0.001) * 1.4
        )
        return MKCoordinateRegion(center: centre, span: span)
    }

    var body: some View {
        ZStack {
            Color.flBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Header
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            PillBadge(label: inspection.status.rawValue,
                                      color: inspection.status == .active ? .flDanger : .flSuccess)
                            Spacer()
                            Text(inspection.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                        Text(inspection.title.isEmpty ? "Untitled Inspection" : inspection.title)
                            .font(.system(size: 22, weight: .bold))

                        HStack(spacing: 20) {
                            StatPill(icon: "clock",          label: inspection.durationLabel)
                            StatPill(icon: "arrow.triangle.swap", label: inspection.distanceLabel)
                            StatPill(icon: "mappin",         label: "\(inspection.pathPoints.count) pts")
                            StatPill(icon: "list.clipboard", label: "\(linkedEvents.count) events")
                        }
                    }
                    .padding(16)
                    .cardStyle()

                    // MARK: Path Map
                    if let region = mapRegion {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Path of Travel")
                            Map(position: .constant(.region(region))) {
                                // Breadcrumb polyline
                                if pathCoords.count > 1 {
                                    MapPolyline(coordinates: pathCoords)
                                        .stroke(Color.flAccent, lineWidth: 3)
                                }
                                // Start marker
                                if let first = pathCoords.first {
                                    Annotation("Start", coordinate: first) {
                                        ZStack {
                                            Circle().fill(Color.flSuccess).frame(width: 20, height: 20)
                                            Image(systemName: "flag.fill")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                // End marker
                                if let last = pathCoords.last, pathCoords.count > 1 {
                                    Annotation("End", coordinate: last) {
                                        ZStack {
                                            Circle().fill(inspection.status == .active ? Color.flDanger : Color.secondary)
                                                .frame(width: 20, height: 20)
                                            Image(systemName: inspection.status == .active ? "record.circle" : "stop.fill")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                // Event pins
                                ForEach(linkedEvents) { event in
                                    if let lat = event.latitude, let lon = event.longitude {
                                        Annotation(event.title, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                            ZStack {
                                                Circle().fill(Color.flWarning).frame(width: 16, height: 16)
                                                Image(systemName: "exclamationmark")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }

                    // MARK: Path Stats
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Details")
                        VStack(spacing: 0) {
                            InfoRow(label: "Started",  value: inspection.startedAt.formatted(date: .long, time: .shortened))
                            if let ended = inspection.endedAt {
                                Divider().padding(.leading, 14)
                                InfoRow(label: "Ended", value: ended.formatted(date: .long, time: .shortened))
                            }
                            Divider().padding(.leading, 14)
                            InfoRow(label: "Duration",  value: inspection.durationLabel)
                            Divider().padding(.leading, 14)
                            InfoRow(label: "Distance",  value: inspection.distanceLabel)
                            Divider().padding(.leading, 14)
                            InfoRow(label: "Path points", value: "\(inspection.pathPoints.count)")
                        }
                        .cardStyle()
                    }

                    // MARK: Linked Events
                    if !linkedEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Events Logged")
                            VStack(spacing: 8) {
                                ForEach(linkedEvents) { event in
                                    HStack(spacing: 10) {
                                        Image(systemName: event.status.icon)
                                            .foregroundStyle(event.status.color)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.title.isEmpty ? "Untitled Event" : event.title)
                                                .font(.subheadline.weight(.medium))
                                            Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(12)
                                    .cardStyle()
                                }
                            }
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
}

struct StatPill: View {
    let icon: String
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.caption.weight(.medium))
        }
        .foregroundStyle(Color.flAccent)
    }
}
