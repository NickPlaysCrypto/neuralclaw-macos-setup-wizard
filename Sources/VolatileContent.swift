import Foundation

// MARK: - VolatileContent Core

/// A wrapper that marks content as subject to change over time.
/// Any UI element displaying volatile content should use this system
/// so it can be updated without rebuilding the app.
///
/// Usage:
///   let steps = ContentRegistry.shared.get("google.apiKeySteps", default: ["Go to aistudio..."])
///
struct VolatileEntry: Codable {
    let key: String
    let category: ContentCategory
    let source: String?          // Where to verify this data (URL, docs page)
    let lastVerified: String?    // ISO 8601 timestamp of last manual verification
    let staleAfterDays: Int?     // How many days before this is considered stale (nil = 30)

    // The actual value — stored as generic JSON
    let value: AnyCodableValue

    var staleThreshold: TimeInterval {
        TimeInterval((staleAfterDays ?? 30) * 86400)
    }

    var lastVerifiedDate: Date? {
        guard let str = lastVerified else { return nil }
        return ISO8601DateFormatter().date(from: str)
    }

    var isStale: Bool {
        guard let verified = lastVerifiedDate else { return true }
        return Date().timeIntervalSince(verified) > staleThreshold
    }
}

enum ContentCategory: String, Codable {
    case steps          // Step-by-step instructions (high churn)
    case url            // URLs/endpoints (medium churn)
    case modelList      // Available models (very high churn)
    case version        // Version strings (medium churn)
    case label          // Display names, descriptions (low churn)
}

// MARK: - AnyCodableValue (type-erased JSON value)

/// Represents any JSON-compatible value: string, array of strings, number, etc.
enum AnyCodableValue: Codable, Equatable {
    case string(String)
    case strings([String])
    case int(Int)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
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

    // MARK: - Public API

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

    /// Check if a specific key's content is stale
    func isStale(_ key: String) -> Bool {
        entries[key]?.isStale ?? true
    }

    /// Get all keys whose content is considered stale
    var staleKeys: [String] {
        entries.filter { $0.value.isStale }.map(\.key).sorted()
    }

    /// Get all keys in a given category
    func keys(in category: ContentCategory) -> [String] {
        entries.filter { $0.value.category == category }.map(\.key).sorted()
    }

    /// Summary of content freshness for diagnostics
    var freshnessSummary: String {
        let total = entries.count
        let stale = staleKeys.count
        let fresh = total - stale
        return "\(fresh)/\(total) fresh, \(stale) stale"
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
        let entry = VolatileEntry(
            key: key,
            category: category,
            source: source,
            lastVerified: ISO8601DateFormatter().string(from: Date()),
            staleAfterDays: nil,
            value: value
        )
        entries[key] = entry
        saveLocalCache()
    }

    // MARK: - Remote Feed (stubbed for future)

    /// Fetch updates from remote feed. Currently a no-op placeholder.
    /// When implemented, this will hit a URL like:
    ///   https://api.neuralclaw.com/content/feed?version=1
    func fetchRemoteUpdates() async {
        // TODO: Implement remote feed fetching
        // let url = URL(string: "https://api.neuralclaw.com/content/feed")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // update(from: data)
    }

    // MARK: - Loading

    private func loadBundledDefaults() {
        // Try loading from Bundle.module (SPM resource bundle)
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
        // Cache takes precedence over bundled defaults
        for (key, entry) in manifest.content {
            entries[key] = entry
        }
    }

    private func saveLocalCache() {
        let manifest = ContentManifest(
            version: 1,
            generated: ISO8601DateFormatter().string(from: Date()),
            content: entries
        )
        guard let data = try? JSONEncoder().encode(manifest) else { return }
        let dir = cacheURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: cacheURL)
    }
}

