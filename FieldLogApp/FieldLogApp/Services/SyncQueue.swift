import Foundation
import Network
import Combine

// MARK: - Sync Job

struct SyncJob: Codable, Identifiable {
    let id: UUID
    let eventId: UUID
    let kind: JobKind
    var attempts: Int
    var createdAt: Date

    enum JobKind: String, Codable {
        case transcribeAudio   // Whisper transcription pending
        case generateSummary   // AI summarization pending
    }

    init(eventId: UUID, kind: JobKind) {
        self.id = UUID()
        self.eventId = eventId
        self.kind = kind
        self.attempts = 0
        self.createdAt = Date()
    }
}

// MARK: - Sync Queue

/// Persists pending AI jobs and processes them when connectivity is restored.
class SyncQueue: ObservableObject {
    static let shared = SyncQueue()

    @Published var pendingJobs: [SyncJob] = []
    @Published var isOnline: Bool = false

    private let saveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("fieldlog_syncqueue.json")
    }()

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "fieldlog.network")
    private var processing = false

    init() {
        load()
        startNetworkMonitor()
    }

    // MARK: - Public API

    func enqueue(eventId: UUID, kind: SyncJob.JobKind) {
        // Don't double-queue same event + kind
        guard !pendingJobs.contains(where: { $0.eventId == eventId && $0.kind == kind }) else { return }
        let job = SyncJob(eventId: eventId, kind: kind)
        pendingJobs.append(job)
        save()
        print("SyncQueue: enqueued \(kind.rawValue) for event \(eventId)")
    }

    func hasPendingJobs(for eventId: UUID) -> Bool {
        pendingJobs.contains(where: { $0.eventId == eventId })
    }

    // MARK: - Processing

    func processIfOnline(eventStore: EventStore) {
        guard isOnline, !processing, !pendingJobs.isEmpty else { return }
        Task { await process(eventStore: eventStore) }
    }

    @MainActor
    private func process(eventStore: EventStore) async {
        processing = true
        var remaining: [SyncJob] = []

        for var job in pendingJobs {
            guard let eventIndex = eventStore.events.firstIndex(where: { $0.id == job.eventId }) else {
                // Event deleted — drop the job
                continue
            }
            var event = eventStore.events[eventIndex]
            job.attempts += 1

            do {
                switch job.kind {

                case .transcribeAudio:
                    guard let filename = event.audioFilename else { continue }
                    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent(filename)
                    let transcript = try await AIService.shared.transcribe(audioFileURL: url)
                    if event.rawNote.isEmpty {
                        event.rawNote = transcript
                    } else {
                        event.rawNote += "\n\n[Voice transcript]\n" + transcript
                    }
                    event.syncStatus = .synced
                    eventStore.update(event)
                    // Queue summary now that we have a transcript
                    enqueue(eventId: event.id, kind: .generateSummary)
                    print("SyncQueue: transcribed event \(event.id)")

                case .generateSummary:
                    guard !event.rawNote.isEmpty else { continue }
                    let summary = try await AIService.shared.summarize(rawNote: event.rawNote)
                    event.aiSummary = summary
                    event.syncStatus = .synced
                    eventStore.update(event)
                    print("SyncQueue: summarized event \(event.id)")
                }

                // Job succeeded — don't re-add to remaining

            } catch {
                print("SyncQueue: job failed (attempt \(job.attempts)) — \(error)")
                if job.attempts < 3 {
                    remaining.append(job)  // retry later
                }
                // After 3 attempts, drop the job
            }
        }

        pendingJobs = remaining
        save()
        processing = false
    }

    // MARK: - Network Monitor

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                print("SyncQueue: network \(path.status == .satisfied ? "online" : "offline")")
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(pendingJobs)
            try data.write(to: saveURL)
        } catch {
            print("SyncQueue save error: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            pendingJobs = try JSONDecoder().decode([SyncJob].self, from: data)
            print("SyncQueue: loaded \(pendingJobs.count) pending jobs")
        } catch {
            print("SyncQueue load error: \(error)")
        }
    }
}
