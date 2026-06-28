import Foundation

/// Persists completed inspections.
class InspectionStore: ObservableObject {
    @Published var inspections: [Inspection] = []

    private let saveURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("fieldlog_inspections.json")
    }()

    init() { load() }

    func save(_ inspection: Inspection) {
        if let idx = inspections.firstIndex(where: { $0.id == inspection.id }) {
            inspections[idx] = inspection
        } else {
            inspections.insert(inspection, at: 0)
        }
        persist()
    }

    func delete(at offsets: IndexSet) {
        inspections.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        try? JSONEncoder().encode(inspections).write(to: saveURL)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path),
              let data = try? Data(contentsOf: saveURL) else { return }
        inspections = (try? JSONDecoder().decode([Inspection].self, from: data)) ?? []
    }
}
