import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var showApiKey = false
    @State private var saved = false

    var body: some View {
        ZStack {
            Color.flBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - AI Provider
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "AI Provider")
                        VStack(spacing: 0) {
                            ForEach(AppSettings.ProviderType.allCases) { type in
                                Button {
                                    settings.providerType = type
                                    if type == .openAI {
                                        settings.apiEndpoint = "https://api.openai.com"
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(type.rawValue)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.primary)
                                            if type == .custom {
                                                Text("Connect your company's LLM endpoint")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        if settings.providerType == type {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.flAccent)
                                        }
                                    }
                                    .padding(14)
                                }
                                if type != AppSettings.ProviderType.allCases.last {
                                    Divider().padding(.leading, 14)
                                }
                            }
                        }
                        .cardStyle()
                    }

                    // MARK: - API Endpoint
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "API Endpoint")
                        TextField("https://api.openai.com", text: $settings.apiEndpoint)
                            .font(.system(.subheadline, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .padding(14)
                            .cardStyle()
                        Text("For your company API, enter the base URL — e.g. https://ai.yourcompany.com")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }

                    // MARK: - API Key
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "API Key")
                        HStack {
                            Group {
                                if showApiKey {
                                    TextField("sk-...", text: $settings.apiKey)
                                } else {
                                    SecureField("sk-...", text: $settings.apiKey)
                                }
                            }
                            .font(.system(.subheadline, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                            Button {
                                showApiKey.toggle()
                            } label: {
                                Image(systemName: showApiKey ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .cardStyle()

                        // Status indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(settings.isConfigured ? Color.flSuccess : Color.flWarning)
                                .frame(width: 7, height: 7)
                            Text(settings.isConfigured ? "API key configured" : "No API key — AI features disabled")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }

                    // MARK: - Save confirmation
                    if saved {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.flSuccess)
                            Text("Settings saved")
                                .font(.subheadline)
                                .foregroundStyle(Color.flSuccess)
                        }
                        .transition(.opacity)
                    }

                    // MARK: - About
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "About")
                        VStack(spacing: 0) {
                            InfoRow(label: "App", value: "FieldLog")
                            Divider().padding(.leading, 14)
                            InfoRow(label: "Version", value: "0.1.0")
                            Divider().padding(.leading, 14)
                            InfoRow(label: "Built with", value: "SwiftUI + BasecampKit")
                        }
                        .cardStyle()
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: settings.apiKey) { _, _ in flashSaved() }
        .onChange(of: settings.apiEndpoint) { _, _ in flashSaved() }
        .onChange(of: settings.providerType) { _, _ in flashSaved() }
    }

    private func flashSaved() {
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { saved = false }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline)
        }
        .padding(14)
    }
}
