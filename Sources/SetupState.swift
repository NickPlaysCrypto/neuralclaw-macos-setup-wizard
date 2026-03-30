import SwiftUI

// MARK: - Setup State (ViewModel)

@MainActor
class SetupState: ObservableObject {
    // MARK: - Navigation
    @Published var currentPage: WizardPage = .aiUsage
    @Published var wizardPath: WizardPath? = nil

    // MARK: - AI Usage (page 1)
    @Published var selectedServices: Set<ConsumerAI> = []
    @Published var wantsLocalModel: Bool = false
    @Published var directAPIKey: String = ""

    // MARK: - Provider / API config
    @Published var provider: AIProvider = .openai
    @Published var apiKey: String = ""
    @Published var selectedModel: String = "gpt-5.4"
    @Published var fallback: String = ""

    // MARK: - Per-service API keys (consumer path)
    @Published var serviceAPIKeys: [ConsumerAI: String] = [:]
    @Published var savedServiceKeys: Set<ConsumerAI> = []

    func saveServiceKey(_ service: ConsumerAI) {
        guard let key = serviceAPIKeys[service], !key.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        savedServiceKeys.insert(service)
    }

    // MARK: - Features
    @Published var preset: FeaturePreset = .recommended
    @Published var features: [Feature] = SetupState.defaultFeatures()

    // MARK: - Channels
    @Published var channels: [ChannelInfo] = SetupState.defaultChannels()

    // MARK: - Save state
    @Published var isSaving: Bool = false
    @Published var saveComplete: Bool = false

    static let allFeatureIDs: [String] = [
        "vector_memory", "identity", "evolution", "traceline", "structured_output",
        "reflective_reasoning", "swarm", "dashboard", "vision", "voice",
        "browser", "desktop", "streaming_responses", "a2a_federation",
    ]

    // MARK: - Page sequence for each path

    /// The ordered pages for the consumer (OAuth) path
    private var consumerPages: [WizardPage] {
        [.aiUsage, .oauthInfo, .apiKeyGuide, .apiConfig, .done]
    }

    /// The ordered pages for the "I have an API key" path
    private var apiKeyPages: [WizardPage] {
        [.aiUsage, .apiProvider, .apiConfig, .done]
    }

    /// Current page sequence based on chosen path (defaults to consumer before path is set)
    var pageSequence: [WizardPage] {
        switch wizardPath {
        case .apiKey:    return apiKeyPages
        case .consumer:  return consumerPages
        case nil:        return consumerPages
        }
    }

    var totalSteps: Int { pageSequence.count }

    var currentStepIndex: Int {
        pageSequence.firstIndex(of: currentPage) ?? 0
    }

    var progressFraction: CGFloat {
        CGFloat(currentStepIndex + 1) / CGFloat(totalSteps)
    }

    var isFirstPage: Bool { currentPage == pageSequence.first }
    var isLastPage: Bool { currentPage == pageSequence.last }

    // MARK: - Navigation

    func goNext() {
        guard !isLastPage else {
            saveConfiguration()
            return
        }
        let seq = pageSequence
        guard let idx = seq.firstIndex(of: currentPage), idx + 1 < seq.count else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentPage = seq[idx + 1]
        }
    }

    func goBack() {
        let seq = pageSequence
        guard let idx = seq.firstIndex(of: currentPage), idx > 0 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentPage = seq[idx - 1]
        }
        // If we go back to aiUsage, reset the path so user can pick again
        if currentPage == .aiUsage {
            wizardPath = nil
        }
    }

    func goTo(_ stepIndex: Int) {
        let seq = pageSequence
        guard stepIndex >= 0, stepIndex < seq.count, stepIndex <= currentStepIndex else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentPage = seq[stepIndex]
        }
    }

    /// User tapped "I have an API key" on the first page
    func chooseAPIKeyPath() {
        wizardPath = .apiKey
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentPage = .apiProvider
        }
    }

    /// User tapped "Continue" on the first page with services selected
    func chooseConsumerPath() {
        wizardPath = .consumer
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentPage = .oauthInfo
        }
    }

    // MARK: - Service selection (multi-select)

    func toggleService(_ service: ConsumerAI) {
        if selectedServices.contains(service) {
            selectedServices.remove(service)
        } else {
            selectedServices.insert(service)
        }
    }

    // MARK: - Provider

    func selectProvider(_ p: AIProvider) {
        provider = p
        selectedModel = p.models.first ?? ""
    }

    // MARK: - Presets

    func applyPreset(_ p: FeaturePreset) {
        preset = p
        for i in features.indices {
            features[i].enabled = p.ids.contains(features[i].id)
        }
    }

    // MARK: - Save

    func saveConfiguration() {
        isSaving = true
        let config = buildTOML()
        let key = apiKey
        let providerRaw = provider.rawValue
        let perServiceKeys = savedServiceKeys.compactMap { svc -> (String, String)? in
            guard let k = serviceAPIKeys[svc], !k.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
            return (svc.apiProvider.rawValue, k)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let configDir = home.appendingPathComponent(".neuralclaw")
            try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            let configFile = configDir.appendingPathComponent("config.toml")
            try? config.write(to: configFile, atomically: true, encoding: .utf8)

            // Build secrets content from both single key and per-service keys
            var secretLines: [String] = []
            if !key.isEmpty {
                secretLines.append("\(providerRaw)_api_key = \"\(key)\"")
            }
            for (providerID, serviceKey) in perServiceKeys {
                let line = "\(providerID)_api_key = \"\(serviceKey)\""
                if !secretLines.contains(line) {
                    secretLines.append(line)
                }
            }

            if !secretLines.isEmpty {
                let secretsFile = configDir.appendingPathComponent(".secrets.toml")
                let secretContent = secretLines.joined(separator: "\n") + "\n"
                try? secretContent.write(to: secretsFile, atomically: true, encoding: .utf8)
                try? FileManager.default.setAttributes(
                    [.posixPermissions: 0o600], ofItemAtPath: secretsFile.path)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.isSaving = false
                self?.saveComplete = true
            }
        }
    }

    private func buildTOML() -> String {
        var lines: [String] = []
        lines.append("[general]")
        lines.append("name = \"NeuralClaw\"")
        lines.append("")
        lines.append("[providers]")
        lines.append("primary = \"\(provider.rawValue)\"")
        if !fallback.isEmpty {
            lines.append("fallback = [\"\(fallback)\"]")
        }
        lines.append("")
        lines.append("[providers.\(provider.rawValue)]")
        lines.append("model = \"\(selectedModel)\"")
        lines.append("")
        lines.append("[features]")
        for f in features {
            lines.append("\(f.id) = \(f.enabled)")
        }
        lines.append("")
        lines.append("[channels]")
        for ch in channels {
            lines.append("[channels.\(ch.id)]")
            lines.append("enabled = \(ch.enabled)")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Defaults

    static func defaultFeatures() -> [Feature] {
        let recommended: Set<String> = FeaturePreset.recommended.ids
        return [
            Feature(id: "vector_memory",       icon: "cpu.fill",                name: "Vector Memory",     desc: "Semantic similarity search",      enabled: recommended.contains("vector_memory")),
            Feature(id: "identity",            icon: "person.fill",             name: "User Identity",     desc: "Remember users across sessions",  enabled: recommended.contains("identity")),
            Feature(id: "evolution",           icon: "flask.fill",              name: "Self-Evolution",    desc: "Learn from interactions",          enabled: recommended.contains("evolution")),
            Feature(id: "traceline",           icon: "chart.bar.fill",          name: "Traceline",         desc: "Reasoning trace logging",          enabled: recommended.contains("traceline")),
            Feature(id: "structured_output",   icon: "rectangle.and.text.magnifyingglass", name: "Structured Output", desc: "Enforce JSON schemas", enabled: recommended.contains("structured_output")),
            Feature(id: "reflective_reasoning",icon: "brain.head.profile",      name: "Deep Thinking",     desc: "Multi-step planning",              enabled: recommended.contains("reflective_reasoning")),
            Feature(id: "swarm",               icon: "ant.fill",               name: "Swarm Agents",      desc: "Multi-agent collaboration",        enabled: recommended.contains("swarm")),
            Feature(id: "dashboard",           icon: "display",                name: "Web Dashboard",     desc: "Admin UI on port 8080",            enabled: recommended.contains("dashboard")),
            Feature(id: "vision",              icon: "eye.fill",               name: "Vision",            desc: "Image understanding",              enabled: false),
            Feature(id: "voice",               icon: "mic.fill",               name: "Voice / TTS",       desc: "Text-to-speech output",            enabled: false),
            Feature(id: "browser",             icon: "globe",                  name: "Browser Control",   desc: "Web automation",                   enabled: false),
            Feature(id: "desktop",             icon: "desktopcomputer",        name: "Desktop Control",   desc: "Mouse & keyboard (advanced)",      enabled: false),
            Feature(id: "streaming_responses", icon: "bolt.fill",              name: "Streaming",         desc: "Token-by-token output",            enabled: false),
            Feature(id: "a2a_federation",      icon: "network",               name: "A2A Federation",    desc: "Agent-to-Agent protocol",          enabled: false),
        ]
    }

    static func defaultChannels() -> [ChannelInfo] {
        [
            ChannelInfo(id: "telegram",  icon: "paperplane.fill",       name: "Telegram",  hint: "Create a bot via @BotFather",    enabled: false),
            ChannelInfo(id: "discord",   icon: "gamecontroller.fill",   name: "Discord",   hint: "Discord Developer Portal token", enabled: false),
            ChannelInfo(id: "slack",     icon: "briefcase.fill",        name: "Slack",     hint: "Slack App with Bot token",       enabled: false),
            ChannelInfo(id: "whatsapp",  icon: "phone.fill",            name: "WhatsApp",  hint: "QR code pairing — no token",     enabled: false),
            ChannelInfo(id: "signal",    icon: "lock.fill",             name: "Signal",    hint: "Requires signal-cli installed",  enabled: false),
        ]
    }
}
