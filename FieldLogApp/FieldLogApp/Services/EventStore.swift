import Foundation
import Combine

/// In-memory + local persistence store for FieldEvents.
/// Phase 1: JSON to disk. Phase 2: sync to backend.
class EventStore: ObservableObject {
    @Published var events: [FieldEvent] = []

    private let saveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("fieldlog_events.json")
    }()

    init() {
        load()
    }

    func add(_ event: FieldEvent) {
        events.insert(event, at: 0)
        save()
    }

    func update(_ event: FieldEvent) {
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(events)
            try data.write(to: saveURL)
        } catch {
            print("EventStore save error: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            events = try JSONDecoder().decode([FieldEvent].self, from: data)
        } catch {
            print("EventStore load error: \(error)")
        }
    }
}
