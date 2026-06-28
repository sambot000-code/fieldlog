import SwiftUI

@main
struct FieldLogApp: App {
    @StateObject private var store = EventStore()
    @StateObject private var projectStore = ProjectStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                EventListView()
                    .tabItem {
                        Label("Events", systemImage: "list.clipboard.fill")
                    }
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
        }
    }
}
