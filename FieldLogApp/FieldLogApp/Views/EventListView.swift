import SwiftUI

struct EventListView: View {
    @EnvironmentObject var store: EventStore

    var body: some View {
        NavigationStack {
            Group {
                if store.events.isEmpty {
                    ContentUnavailableView(
                        "No Events Yet",
                        systemImage: "list.clipboard",
                        description: Text("Tap + to log your first field observation.")
                    )
                } else {
                    List {
                        ForEach(store.events) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventRowView(event: event)
                            }
                        }
                        .onDelete(perform: store.delete)
                    }
                }
            }
            .navigationTitle("FieldLog 📋")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: CaptureView()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
    }
}

struct EventRowView: View {
    let event: FieldEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.title.isEmpty ? "Untitled Event" : event.title)
                    .font(.headline)
                Spacer()
                StatusBadge(status: event.status)
            }
            Text(event.aiSummary ?? event.rawNote)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: EventStatus

    var color: Color {
        switch status {
        case .draft: return .orange
        case .submitted: return .blue
        case .reviewed: return .green
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
