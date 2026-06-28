import Foundation
import Combine

/// Manages projects/sites and tracks the active one.
class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []

    /// The currently active project — events get logged against this automatically.
    @Published var activeProject: Project? {
        didSet { saveActiveProjectId() }
    }

    private let saveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("fieldlog_projects.json")
    }()

    private let activeIdKey = "fieldlog_active_project_id"

    init() {
        load()
        restoreActiveProject()
    }

    // MARK: - Public API

    func add(_ project: Project) {
        projects.append(project)
        save()
    }

    func update(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { projects[$0] }
        projects.remove(atOffsets: offsets)
        // Clear active if deleted
        if let active = activeProject, toDelete.contains(where: { $0.id == active.id }) {
            activeProject = nil
        }
        save()
    }

    func activate(_ project: Project) {
        activeProject = project
    }

    func deactivate() {
        activeProject = nil
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(projects)
            try data.write(to: saveURL)
        } catch {
            print("ProjectStore save error: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            projects = try JSONDecoder().decode([Project].self, from: data)
        } catch {
            print("ProjectStore load error: \(error)")
        }
    }

    private func saveActiveProjectId() {
        UserDefaults.standard.set(activeProject?.id.uuidString, forKey: activeIdKey)
    }

    private func restoreActiveProject() {
        guard let idString = UserDefaults.standard.string(forKey: activeIdKey),
              let id = UUID(uuidString: idString) else { return }
        activeProject = projects.first(where: { $0.id == id })
    }
}
