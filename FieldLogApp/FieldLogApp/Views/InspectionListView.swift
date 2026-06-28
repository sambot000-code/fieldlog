import SwiftUI
import MapKit

// MARK: - Inspection List Tab

struct InspectionListView: View {
    @EnvironmentObject var inspectionStore: InspectionStore
    @EnvironmentObject var projectStore: ProjectStore
    @StateObject private var session = InspectionSession.shared
    @State private var showStartSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.flBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {

                        // Active session banner
                        if let active = session.activeInspection {
                            ActiveInspectionBanner(inspection: active)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }

                        if inspectionStore.inspections.isEmpty && session.activeInspection == nil {
                            VStack(spacing: 16) {
                                Image(systemName: "figure.walk.motion")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.flAccent.opacity(0.6))
                                Text("No Inspections Yet")
                                    .font(.title3.weight(.semibold))
                                Text("Tap Start Inspection to begin tracking your path on site.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(inspectionStore.inspections) { inspection in
                                NavigationLink(destination: InspectionDetailView(inspection: inspection)) {
                                    InspectionCard(inspection: inspection)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }

                // FAB — Start or Stop
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if session.isRecording {
                            Button {
                                stopInspection()
                            } label: {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 10, height: 10)
                                    Text("Stop Inspection")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color.flDanger)
                                .clipShape(Capsule())
                                .shadow(color: Color.flDanger.opacity(0.45), radius: 12, x: 0, y: 6)
                            }
                        } else {
                            Button { showStartSheet = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Start Inspection")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color.flAccent)
                                .clipShape(Capsule())
                                .shadow(color: Color.flAccent.opacity(0.45), radius: 12, x: 0, y: 6)
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Inspections")
            .sheet(isPresented: $showStartSheet) {
                StartInspectionSheet()
                    .environmentObject(projectStore)
            }
        }
    }

    private func stopInspection() {
        if let completed = session.stop() {
            inspectionStore.save(completed)
        }
    }
}

// MARK: - Active Inspection Banner

struct ActiveInspectionBanner: View {
    @ObservedObject var inspection: Inspection = .init() // observe via session
    let insp: Inspection

    init(inspection: Inspection) { self.insp = inspection }

    var body: some View {
        HStack(spacing: 12) {
            // Pulsing dot
            ZStack {
                Circle().fill(Color.flDanger.opacity(0.25)).frame(width: 24, height: 24)
                Circle().fill(Color.flDanger).frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Inspection in progress")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.flDanger)
                Text(insp.title.isEmpty ? "Untitled Inspection" : insp.title)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    Text("\(insp.pathPoints.count) points")
                    Text("·")
                    Text(insp.distanceLabel)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.flDanger.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Inspection Card

struct InspectionCard: View {
    let inspection: Inspection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(inspection.title.isEmpty ? "Untitled Inspection" : inspection.title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                PillBadge(label: inspection.status.rawValue,
                          color: inspection.status == .active ? .flDanger : .flSuccess)
            }

            HStack(spacing: 16) {
                Label(inspection.durationLabel, systemImage: "clock")
                Label(inspection.distanceLabel, systemImage: "arrow.triangle.swap")
                Label("\(inspection.eventIds.count) events", systemImage: "list.clipboard")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(inspection.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Start Inspection Sheet

struct StartInspectionSheet: View {
    @EnvironmentObject var projectStore: ProjectStore
    @Environment(\.dismiss) var dismiss
    @StateObject private var session = InspectionSession.shared
    @State private var title = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.flBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Inspection Name")
                        TextField("e.g. North Dam Wall — Morning Round", text: $title)
                            .padding(14)
                            .cardStyle()
                    }

                    if let active = projectStore.activeProject {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: active.color) ?? Color.flAccent)
                                .frame(width: 10, height: 10)
                            Text("Logging against: \(active.name)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(14)
                        .cardStyle()
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.flWarning)
                            Text("No active site — go to Sites tab to set one")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .cardStyle()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill").foregroundStyle(Color.flAccent)
                            Text("Path recorded every 15m or 60 seconds")
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "iphone.radiowaves.left.and.right").foregroundStyle(Color.flAccent)
                            Text("Works offline — syncs when back in service")
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "list.clipboard.fill").foregroundStyle(Color.flAccent)
                            Text("Events logged during inspection are auto-linked")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .cardStyle()

                    Spacer()

                    Button {
                        session.start(
                            title: title.isEmpty ? "Inspection \(Date().formatted(date: .abbreviated, time: .shortened))" : title,
                            projectId: projectStore.activeProject?.id
                        )
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.walk")
                            Text("Start Inspection")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.flAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(16)
            }
            .navigationTitle("New Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.flAccent)
                }
            }
        }
    }
}
