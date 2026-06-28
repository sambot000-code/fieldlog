import SwiftUI
import Combine

@main
struct FieldLogApp: App {
    @StateObject private var store = EventStore()
    @StateObject private var projectStore = ProjectStore()
    @StateObject private var inspectionStore = InspectionStore()
    @StateObject private var syncQueue = SyncQueue.shared
    @StateObject private var session = InspectionSession.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                EventListView()
                    .tabItem {
                        Label("Events", systemImage: "list.clipboard.fill")
                    }
                    .badge(syncQueue.pendingJobs.isEmpty ? 0 : syncQueue.pendingJobs.count)

                InspectionListView()
                    .tabItem {
                        Label("Inspections", systemImage: "figure.walk")
                    }
                    .badge(session.isRecording ? "●" : nil)

                ProjectListView()
                    .tabItem {
                        Label("Sites", systemImage: "building.2.fill")
                    }

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .tint(Color.flAccent)
            .environmentObject(store)
            .environmentObject(projectStore)
            .environmentObject(inspectionStore)
            .environmentObject(syncQueue)
            .environmentObject(session)
            .onAppear {
                syncQueue.processIfOnline(eventStore: store)
            }
        }
    }
}
