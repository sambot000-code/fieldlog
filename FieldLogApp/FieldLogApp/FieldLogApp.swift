import SwiftUI

@main
struct FieldLogApp: App {
    @StateObject private var store = EventStore()

    var body: some Scene {
        WindowGroup {
            EventListView()
                .environmentObject(store)
        }
    }
}
