import SwiftUI

// MARK: - Design System

enum DS {
    // Colors
    static let bg            = Color(red: 0.039, green: 0.055, blue: 0.102)
    static let surface       = Color(red: 0.067, green: 0.094, blue: 0.153)
    static let surfaceHover  = Color(red: 0.102, green: 0.133, blue: 0.212)
    static let border        = Color(red: 0.39, green: 0.53, blue: 0.82).opacity(0.12)
    static let borderActive  = Color(red: 0.376, green: 0.647, blue: 0.98).opacity(0.4)
    static let text          = Color(red: 0.91, green: 0.925, blue: 0.957)
    static let textMuted     = Color(red: 0.42, green: 0.478, blue: 0.6)
    static let textDim       = Color(red: 0.24, green: 0.29, blue: 0.4)
    static let accent        = Color(red: 0.376, green: 0.647, blue: 0.98)
    static let accent2       = Color(red: 0.655, green: 0.545, blue: 0.98)
    static let accent3       = Color(red: 0.204, green: 0.827, blue: 0.6)
    static let danger        = Color(red: 0.973, green: 0.443, blue: 0.443)

    // Gradients
    static let accentGradient = LinearGradient(
        colors: [accent, Color(red: 0.506, green: 0.549, blue: 0.98)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let successGradient = LinearGradient(
        colors: [accent3, Color(red: 0.18, green: 0.831, blue: 0.749)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Wizard Navigation

enum WizardPage: Equatable, CaseIterable {
    case aiUsage        // "Which AI companies do you use?"
    case oauthInfo      // OAuth availability for selected services
    case apiKeyGuide    // How to get an API key for selected providers
    case apiProvider    // API provider selection (API key path)
    case apiConfig      // API key + model picker
    case features       // Feature toggles
    case channels       // Channel toggles
    case done           // Summary + launch
}

enum WizardPath: Equatable {
    case consumer   // Selected consumer AI services → OAuth flow
    case apiKey     // Clicked "I have an API key"
}

// MARK: - Consumer AI Services (first page multi-select)

enum ConsumerAI: String, CaseIterable, Identifiable {
    case google, openai, anthropic

    var id: String { rawValue }

    var productName: String {
        switch self {
        case .google:    return "Gemini"
        case .openai:    return "ChatGPT"
        case .anthropic: return "Claude"
        }
    }

    var companyName: String {
        switch self {
        case .google:    return "Google"
        case .openai:    return "OpenAI"
        case .anthropic: return "Anthropic"
        }
    }

    var icon: String {
        switch self {
        case .google:    return "sparkles"
        case .openai:    return "bolt.fill"
        case .anthropic: return "brain.head.profile"
        }
    }

    var iconColor: Color {
        switch self {
        case .google:    return Color(red: 0.26, green: 0.52, blue: 0.96)  // Google blue
        case .openai:    return Color(red: 0.29, green: 0.84, blue: 0.63)  // OpenAI green
        case .anthropic: return Color(red: 0.85, green: 0.65, blue: 0.40)  // Anthropic orange
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .google:    return [Color(red: 0.26, green: 0.52, blue: 0.96), Color(red: 0.91, green: 0.26, blue: 0.21)]
        case .openai:    return [Color(red: 0.29, green: 0.84, blue: 0.63), Color(red: 0.10, green: 0.60, blue: 0.45)]
        case .anthropic: return [Color(red: 0.85, green: 0.65, blue: 0.40), Color(red: 0.78, green: 0.42, blue: 0.25)]
        }
    }

    /// Whether this service supports OAuth for agent connections (placeholder)
    var supportsOAuth: Bool {
        switch self {
        case .google:    return true   // Google OAuth
        case .openai:    return false  // Coming soon
        case .anthropic: return false  // Coming soon
        }
    }

    var oauthStatus: String {
        supportsOAuth ? "OAuth Available" : "Coming Soon"
    }

    /// The corresponding API provider for key-based auth
    var apiProvider: AIProvider {
        switch self {
        case .google:    return .openrouter  // Google doesn't have a direct API in our list
        case .openai:    return .openai
        case .anthropic: return .anthropic
        }
    }

    /// URL where users can get an API key
    var apiKeyURL: String {
        switch self {
        case .google:    return "aistudio.google.com/apikey"
        case .openai:    return "platform.openai.com/api-keys"
        case .anthropic: return "console.anthropic.com/settings/keys"
        }
    }

    /// Step-by-step instructions for getting an API key
    var apiKeySteps: [String] {
        switch self {
        case .google:
            return [
                "Go to aistudio.google.com",
                "Sign in with your Google account",
                "Click \"Get API key\" in the sidebar",
                "Create a new key and copy it",
            ]
        case .openai:
            return [
                "Go to platform.openai.com",
                "Sign in or create an account",
                "Navigate to API Keys in Settings",
                "Click \"Create new secret key\"",
            ]
        case .anthropic:
            return [
                "Go to console.anthropic.com",
                "Sign in or create an account",
                "Go to Settings → API Keys",
                "Click \"Create Key\" and copy it",
            ]
        }
    }
}

// MARK: - API Provider Selection

enum AIProvider: String, CaseIterable, Identifiable {
    case openai, anthropic, openrouter, venice, local

    var id: String { rawValue }

    var label: String {
        switch self {
        case .openai:      return "OpenAI"
        case .anthropic:   return "Anthropic"
        case .openrouter:  return "OpenRouter"
        case .venice:      return "Venice.ai"
        case .local:       return "Local / Ollama"
        }
    }

    var desc: String {
        switch self {
        case .openai:      return "GPT-5.4, o3/o4 reasoning"
        case .anthropic:   return "Claude Opus 4.6, Sonnet 4.6"
        case .openrouter:  return "300+ models, one API key"
        case .venice:      return "Privacy-first, uncensored models"
        case .local:       return "Qwen3, Llama 3.3, Gemma 3"
        }
    }

    var icon: String {
        switch self {
        case .openai:      return "bolt.fill"
        case .anthropic:   return "circle.hexagonpath.fill"
        case .openrouter:  return "arrow.triangle.branch"
        case .venice:      return "shield.checkered"
        case .local:       return "desktopcomputer"
        }
    }

    var iconColor: Color {
        switch self {
        case .openai:      return .green
        case .anthropic:   return .orange
        case .openrouter:  return DS.accent
        case .venice:      return Color(red: 0.86, green: 0.44, blue: 0.84)
        case .local:       return DS.accent2
        }
    }

    var needsKey: Bool { self != .local }

    var keyPlaceholder: String {
        switch self {
        case .venice:  return "venice-... or paste your key"
        default:       return "sk-... or paste your key"
        }
    }

    var models: [String] {
        switch self {
        case .openai:
            return ["gpt-5.4", "gpt-5.4-mini", "gpt-5.4-pro", "gpt-5.3-codex",
                    "gpt-5.2", "o4-mini", "o3", "o3-pro", "gpt-4.1", "gpt-4.1-mini"]
        case .anthropic:
            return ["claude-opus-4-6", "claude-sonnet-4-6",
                    "claude-haiku-4-5-20251001", "claude-sonnet-4-5-20250929"]
        case .openrouter:
            return ["anthropic/claude-opus-4-6", "anthropic/claude-sonnet-4-6",
                    "openai/gpt-5.4", "openai/gpt-5.4-mini",
                    "google/gemini-2.5-pro-preview", "deepseek/deepseek-r1"]
        case .venice:
            return ["llama-3.3-70b", "llama-3.1-405b", "deepseek-r1-671b",
                    "qwen3-235b", "dolphin-2.9.3", "nous-theta-8b"]
        case .local:
            return ["qwen3:8b", "qwen3:4b", "llama3.3:70b", "llama3.1:8b",
                    "gemma3:12b", "mistral:7b", "deepseek-r1:8b", "phi-4:14b"]
        }
    }
}

// MARK: - Features & Channels

struct Feature: Identifiable {
    let id: String
    let icon: String
    let name: String
    let desc: String
    var enabled: Bool
}

struct ChannelInfo: Identifiable {
    let id: String
    let icon: String
    let name: String
    let hint: String
    var enabled: Bool
}

enum FeaturePreset: String, CaseIterable {
    case minimal, recommended, full

    var label: String {
        switch self {
        case .minimal:     return "🪶 Minimal"
        case .recommended: return "⭐ Recommended"
        case .full:        return "🚀 Full Power"
        }
    }

    var ids: Set<String> {
        switch self {
        case .minimal:
            return ["vector_memory", "identity", "structured_output", "traceline", "evolution"]
        case .recommended:
            return ["vector_memory", "identity", "evolution", "traceline",
                    "structured_output", "reflective_reasoning", "swarm", "dashboard"]
        case .full:
            return Set(SetupState.allFeatureIDs)
        }
    }
}
