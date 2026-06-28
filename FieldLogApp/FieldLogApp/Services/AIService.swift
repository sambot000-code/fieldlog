import Foundation

// MARK: - AI Provider Protocol
// Long-term: swap OpenAIProvider for your company's LLM endpoint
// by implementing this protocol and updating AppSettings.aiProvider.

protocol AIProvider {
    func summarize(rawNote: String, context: String) async throws -> String
    func transcribe(audioFileURL: URL) async throws -> String
}

// MARK: - App Settings (single source of truth)

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let apiKey      = "ai_api_key"
        static let apiEndpoint = "ai_api_endpoint"
        static let providerType = "ai_provider_type"
    }

    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: Keys.apiKey) }
    }

    /// Base URL for the AI endpoint.
    /// Default: OpenAI. Swap to your company's API when ready.
    @Published var apiEndpoint: String {
        didSet { UserDefaults.standard.set(apiEndpoint, forKey: Keys.apiEndpoint) }
    }

    @Published var providerType: ProviderType {
        didSet { UserDefaults.standard.set(providerType.rawValue, forKey: Keys.providerType) }
    }

    enum ProviderType: String, CaseIterable, Identifiable {
        case openAI  = "OpenAI"
        case custom  = "Custom (Company API)"
        var id: String { rawValue }
    }

    init() {
        self.apiKey       = UserDefaults.standard.string(forKey: Keys.apiKey) ?? ""
        self.apiEndpoint  = UserDefaults.standard.string(forKey: Keys.apiEndpoint) ?? "https://api.openai.com"
        self.providerType = ProviderType(rawValue: UserDefaults.standard.string(forKey: Keys.providerType) ?? "") ?? .openAI
    }

    var isConfigured: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }
}

// MARK: - Main AIService (delegates to provider)

class AIService {
    static let shared = AIService()
    private var settings: AppSettings { AppSettings.shared }

    func summarize(rawNote: String, context: String = "field inspection") async throws -> String {
        try await provider().summarize(rawNote: rawNote, context: context)
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        try await provider().transcribe(audioFileURL: audioFileURL)
    }

    private func provider() -> AIProvider {
        switch settings.providerType {
        case .openAI:  return OpenAIProvider(settings: settings)
        case .custom:  return CustomAPIProvider(settings: settings)
        }
    }
}

// MARK: - OpenAI Provider

private class OpenAIProvider: AIProvider {
    let settings: AppSettings
    init(settings: AppSettings) { self.settings = settings }

    func summarize(rawNote: String, context: String) async throws -> String {
        let prompt = """
        You are an assistant helping a field inspector document observations.
        Summarize the following note into a clear, concise professional observation.
        Context: \(context)

        Note: \(rawNote)

        Summary:
        """
        return try await chatCompletion(prompt: prompt)
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        let url = URL(string: "\(settings.apiEndpoint)/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let audioData = try Data(contentsOf: audioFileURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\nwhisper-1\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(WhisperResponse.self, from: data)
        return result.text
    }

    private func chatCompletion(prompt: String) async throws -> String {
        let url = URL(string: "\(settings.apiEndpoint)/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 300
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        return response.choices.first?.message.content ?? ""
    }
}

// MARK: - Custom / Company API Provider
// Replace this stub with your company's actual LLM API calls.

private class CustomAPIProvider: AIProvider {
    let settings: AppSettings
    init(settings: AppSettings) { self.settings = settings }

    func summarize(rawNote: String, context: String) async throws -> String {
        // TODO: implement your company's summarization endpoint
        // POST to \(settings.apiEndpoint)/summarize with Bearer \(settings.apiKey)
        throw AIError.notConfigured("Custom provider not yet implemented")
    }

    func transcribe(audioFileURL: URL) async throws -> String {
        // TODO: implement your company's transcription endpoint
        throw AIError.notConfigured("Custom provider not yet implemented")
    }
}

// MARK: - Errors & Response Models

enum AIError: Error, LocalizedError {
    case notConfigured(String)
    var errorDescription: String? {
        switch self { case .notConfigured(let msg): return msg }
    }
}

private struct WhisperResponse: Decodable { let text: String }
private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}
