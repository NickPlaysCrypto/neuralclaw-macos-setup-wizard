import Foundation

// MARK: - VolatileContent Core

/// A wrapper that marks content as subject to change over time.
/// Entries know their urgency, carry verification instructions,
/// and can have conditional associations that cascade UI changes.
///
/// Usage:
///   let steps = ContentRegistry.shared.getStrings("google.apiKeySteps", default: [...])
///   let badge = ContentRegistry.shared.conditional("openai.oauthStatus", field: "badge")
///
struct VolatileEntry: Codable {
    let key: String
    let category: ContentCategory
    let source: String?              // Where to verify this data (URL, docs page)
    let lastVerified: String?        // ISO 8601 timestamp of last verification
    let staleAfterDays: Int?         // Days before considered stale (nil = 30)

    // The actual value — stored as generic JSON
    let value: AnyCodableValue

    // How to verify this content is still accurate
    let verify: VerifyInstructions?

    // Value-dependent associated data: { "available": { "badge": null, "buttonEnabled": true }, ... }
    let conditionals: [String: [String: AnyCodableValue]]?

    // Keys that this entry affects when it changes
    let affects: [String]?

    var staleThreshold: TimeInterval {
        TimeInterval((staleAfterDays ?? 30) * 86400)
    }

    var lastVerifiedDate: Date? {
        guard let str = lastVerified else { return nil }
        return ISO8601DateFormatter().date(from: str)
    }

    var isStale: Bool { urgency >= .stale }

    /// How urgently this content needs updating — a gradient, not a binary.
    var urgency: ContentUrgency {
        guard let verified = lastVerifiedDate else { return .critical }
        let elapsed = Date().timeIntervalSince(verified)
        let threshold = staleThreshold
        let ratio = elapsed / threshold

        if ratio < 0.5 { return .fresh }
        if ratio < 0.8 { return .aging }
        if ratio < 1.0 { return .stale }
        if ratio < 2.0 { return .expired }
        return .critical
    }

    /// Resolve a conditional field based on the current value.
    /// Example: if value is "comingSoon", returns conditionals["comingSoon"]["badge"]
    func resolveConditional(field: String) -> AnyCodableValue? {
        guard let valueStr = value.asString,
              let conditions = conditionals?[valueStr] else { return nil }
        return conditions[field]
    }
}

// MARK: - Content Urgency

/// How urgently a piece of volatile content needs to be verified/updated.
/// Entries become progressively more "hungry" for fresh data as they age.
enum ContentUrgency: Int, Codable, Comparable {
    case fresh    = 0   // < 50% of stale threshold  — content is known good
    case aging    = 1   // 50-80% of threshold        — would appreciate an update
    case stale    = 2   // 80-100% of threshold       — needs an update
    case expired  = 3   // > threshold                — should be verified ASAP
    case critical = 4   // > 2x threshold             — data is unreliable

    static func < (lhs: ContentUrgency, rhs: ContentUrgency) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var emoji: String {
        switch self {
        case .fresh:    return "🟢"
        case .aging:    return "🟡"
        case .stale:    return "🟠"
        case .expired:  return "🔴"
        case .critical: return "⚫"
        }
    }

    var label: String {
        switch self {
        case .fresh:    return "Fresh"
        case .aging:    return "Aging"
        case .stale:    return "Stale"
        case .expired:  return "Expired"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Verification Instructions

/// Instructions for HOW to verify if content is still accurate.
/// An external agent (AI, cron job, or human) reads these and performs the check.
struct VerifyInstructions: Codable {
    let method: VerifyMethod
    let url: String?                 // URL to check (for checkURL/apiProbe)
    let lookFor: [String]?           // Keywords to search for on the page
    let onFound: String?             // Value to set if keywords are found
    let onNotFound: String?          // Value to set if keywords are NOT found
    let fallbackMethod: VerifyMethod? // Fallback if primary method fails
    let searchQuery: String?         // Query for webSearch method
    let notes: String?               // Human-readable context for manual verification
}

enum VerifyMethod: String, Codable {
    case checkURL       // Fetch a URL, look for keywords
    case webSearch      // Search the web for information
    case apiProbe       // Hit an API endpoint, check response
    case manual         // Requires human/agent judgment
}

// MARK: - Content Categories

enum ContentCategory: String, Codable {
    case steps          // Step-by-step instructions (high churn)
    case url            // URLs/endpoints (medium churn)
    case modelList      // Available models (very high churn)
    case version        // Version strings (medium churn)
    case label          // Display names, descriptions (low churn)
    case status         // Feature/availability status (medium churn, high impact)
}

// MARK: - AnyCodableValue (type-erased JSON value)

/// Represents any JSON-compatible value: string, array of strings, number, bool, or null.
enum AnyCodableValue: Codable, Equatable {
    case string(String)
    case strings([String])
    case int(Int)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        if let arr = try? container.decode([String].self) {
            self = .strings(arr)
        } else if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let num = try? container.decode(Int.self) {
            self = .int(num)
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else {
            throw DecodingError.typeMismatch(
                AnyCodableValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s):  try container.encode(s)
        case .strings(let a): try container.encode(a)
        case .int(let n):     try container.encode(n)
        case .bool(let b):    try container.encode(b)
        case .null:           try container.encodeNil()
        }
    }

    var asString: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var asStrings: [String]? {
        if case .strings(let a) = self { return a }
        return nil
    }

    var asInt: Int? {
        if case .int(let n) = self { return n }
        return nil
    }

    var asBool: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }

    var isNull: Bool {
        if case .null = self { return true }
        return false
    }
}

// MARK: - Content Manifest (JSON root)

struct ContentManifest: Codable {
    let version: Int
    let generated: String
    let content: [String: VolatileEntry]
}

// MARK: - ContentRegistry (singleton)

/// Central registry for all volatile content. Loads from:
/// 1. Bundled defaults (volatile_defaults.json in app resources)
/// 2. Local cache (~/.neuralclaw/volatile_content.json)
/// 3. Remote feed (future — stubbed)
///
/// Priority: Feed > Cache > Bundled Default > Hardcoded Fallback
final class ContentRegistry {
    static let shared = ContentRegistry()

    private(set) var entries: [String: VolatileEntry] = [:]
    private(set) var lastLoaded: Date?

    private let cacheURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".neuralclaw/volatile_content.json")
    }()

    init() {
        loadBundledDefaults()
        loadLocalCache()
    }

    // MARK: - Value Access

    /// Get a string value by key, with hardcoded fallback
    func getString(_ key: String, default fallback: String) -> String {
        entries[key]?.value.asString ?? fallback
    }

    /// Get a string array by key, with hardcoded fallback
    func getStrings(_ key: String, default fallback: [String]) -> [String] {
        entries[key]?.value.asStrings ?? fallback
    }

    /// Get an int value by key, with hardcoded fallback
    func getInt(_ key: String, default fallback: Int) -> Int {
        entries[key]?.value.asInt ?? fallback
    }

    /// Get a bool value by key, with hardcoded fallback
    func getBool(_ key: String, default fallback: Bool) -> Bool {
        entries[key]?.value.asBool ?? fallback
    }

    // MARK: - Conditional Resolution

    /// Resolve a conditional field based on an entry's current value.
    /// Example: conditional("openai.oauthStatus", field: "badge") → "Coming Soon"
    func conditional(_ key: String, field: String) -> AnyCodableValue? {
        entries[key]?.resolveConditional(field: field)
    }

    /// Get a conditional string, with fallback
    func conditionalString(_ key: String, field: String, default fallback: String) -> String {
        conditional(key, field: field)?.asString ?? fallback
    }

    /// Get a conditional bool, with fallback
    func conditionalBool(_ key: String, field: String, default fallback: Bool) -> Bool {
        conditional(key, field: field)?.asBool ?? fallback
    }

    /// Check if a conditional field is null (meaning "none" / "hidden")
    func conditionalIsNull(_ key: String, field: String) -> Bool {
        conditional(key, field: field)?.isNull ?? false
    }

    // MARK: - Urgency & Freshness

    /// Get the urgency level of a specific key
    func urgency(of key: String) -> ContentUrgency {
        entries[key]?.urgency ?? .critical
    }

    /// Get all entries at or above a given urgency level, sorted most urgent first
    func entries(above urgency: ContentUrgency) -> [VolatileEntry] {
        entries.values
            .filter { $0.urgency >= urgency }
            .sorted { $0.urgency.rawValue > $1.urgency.rawValue }
    }

    /// Ordered verification queue — most urgent entries first, with verify instructions
    var verificationQueue: [VolatileEntry] {
        entries.values
            .filter { $0.verify != nil && $0.urgency >= .stale }
            .sorted { $0.urgency.rawValue > $1.urgency.rawValue }
    }

    /// Get all keys whose content is considered stale
    var staleKeys: [String] {
        entries.filter { $0.value.isStale }.map(\.key).sorted()
    }

    /// Get all keys in a given category
    func keys(in category: ContentCategory) -> [String] {
        entries.filter { $0.value.category == category }.map(\.key).sorted()
    }

    /// Diagnostic summary of content freshness
    var freshnessSummary: String {
        let grouped = Dictionary(grouping: entries.values, by: \.urgency)
        let parts = ContentUrgency.allCases.compactMap { level -> String? in
            guard let count = grouped[level]?.count, count > 0 else { return nil }
            return "\(level.emoji) \(count) \(level.label.lowercased())"
        }
        return parts.joined(separator: "  ")
    }

    // MARK: - Update from external data

    /// Update the registry from a JSON data blob (e.g., downloaded feed)
    func update(from data: Data) {
        guard let manifest = try? JSONDecoder().decode(ContentManifest.self, from: data) else { return }
        for (key, entry) in manifest.content {
            entries[key] = entry
        }
        lastLoaded = Date()
        saveLocalCache()
    }

    /// Update a single entry programmatically
    func set(_ key: String, value: AnyCodableValue, category: ContentCategory, source: String? = nil) {
        let existing = entries[key]
        let entry = VolatileEntry(
            key: key,
            category: category,
            source: source ?? existing?.source,
            lastVerified: ISO8601DateFormatter().string(from: Date()),
            staleAfterDays: existing?.staleAfterDays,
            value: value,
            verify: existing?.verify,
            conditionals: existing?.conditionals,
            affects: existing?.affects
        )
        entries[key] = entry
        saveLocalCache()
    }

    // MARK: - Remote Feed (stubbed for future)

    /// Fetch updates from remote feed. Currently a no-op placeholder.
    func fetchRemoteUpdates() async {
        // TODO: Implement remote feed fetching
        // let url = URL(string: "https://api.neuralclaw.com/content/feed")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // update(from: data)
    }

    // MARK: - Loading

    private func loadBundledDefaults() {
        guard let url = Bundle.module.url(forResource: "volatile_defaults", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(ContentManifest.self, from: data) else {
            return
        }
        for (key, entry) in manifest.content {
            entries[key] = entry
        }
        lastLoaded = Date()
    }

    private func loadLocalCache() {
        guard FileManager.default.fileExists(atPath: cacheURL.path),
              let data = try? Data(contentsOf: cacheURL),
              let manifest = try? JSONDecoder().decode(ContentManifest.self, from: data) else {
            return
        }
        for (key, entry) in manifest.content {
            entries[key] = entry
        }
    }

    private func saveLocalCache() {
        let manifest = ContentManifest(
            version: 2,
            generated: ISO8601DateFormatter().string(from: Date()),
            content: entries
        )
        guard let data = try? JSONEncoder().encode(manifest) else { return }
        let dir = cacheURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: cacheURL)
    }
}

// MARK: - CaseIterable for ContentUrgency (needed for freshnessSummary)

extension ContentUrgency: CaseIterable {}
