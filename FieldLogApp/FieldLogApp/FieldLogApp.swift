import SwiftUI
import Combine

@main
struct FieldLogApp: App {
    @StateObject private var store = EventStore()
    @StateObject private var projectStore = ProjectStore()
    @StateObject private var syncQueue = SyncQueue.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // When connectivity is restored, auto-process pending AI jobs
        SyncQueue.shared.$isOnline
            .filter { $0 }
            .sink { _ in
                SyncQueue.shared.processIfOnline(eventStore: EventStore())
            }
            .store(in: &cancellables) // Note: store reference needed; see ViewModel pattern for prod
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                EventListView()
                    .tabItem {
                        Label("Events", systemImage: "list.clipboard.fill")
                    }
                    .badge(syncQueue.pendingJobs.isEmpty ? 0 : syncQueue.pendingJobs.count)

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
            .environmentObject(syncQueue)
            .onAppear {
                // Process any queued jobs on launch if online
                syncQueue.processIfOnline(eventStore: store)
            }
        }
    }
}
