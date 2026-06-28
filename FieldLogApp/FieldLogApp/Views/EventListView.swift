import SwiftUI

struct EventListView: View {
    @EnvironmentObject var store: EventStore
    @State private var showCapture = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.flBackground.ignoresSafeArea()

                ScrollView {
                    if store.events.isEmpty {
                        EmptyStateView()
                            .padding(.top, 80)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(store.events) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCard(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }

                // FAB
                Button {
                    showCapture = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Log Event")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.flAccent)
                    .clipShape(Capsule())
                    .shadow(color: Color.flAccent.opacity(0.45), radius: 12, x: 0, y: 6)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("FieldLog")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCapture) {
                CaptureView()
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - Event Card

struct EventCard: View {
    let event: FieldEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title.isEmpty ? "Untitled Event" : event.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Image(systemName: event.status.icon)
                    .font(.title3)
                    .foregroundStyle(event.status.color)
            }

            // Summary or raw note
            if let summary = event.aiSummary ?? (event.rawNote.isEmpty ? nil : event.rawNote) {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            // Location pill
            if let lat = event.latitude, let lon = event.longitude {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(String(format: "%.5f, %.5f", lat, lon))
                        .font(.caption2.monospacedDigit())
                    if let heading = event.headingLabel {
                        Text("· \(heading)")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(Color.flAccent)
            }

            // Tags
            if !event.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(event.tags, id: \.self) { tag in
                            PillBadge(label: tag, color: .flAccent)
                        }
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "scope")
                .font(.system(size: 56))
                .foregroundStyle(Color.flAccent.opacity(0.7))
            Text("No Events Logged")
                .font(.title3.weight(.semibold))
            Text("Tap Log Event to capture your first field observation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
