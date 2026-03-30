# VolatileContent Developer Guide

> **What is this?** A framework for marking UI content as "subject to change" so it can be
> updated without rebuilding the app. Every piece of text, URL, list, or status that might
> go stale is wrapped in this system.

> **This is developer/agent infrastructure.** End users never interact with urgency scores,
> feed quality, happiness metrics, or verification queues. They just see a working wizard.
> This system exists so that developers and AI agents can systematically track content
> freshness, find better data sources, and keep the app accurate over time.

## Quick Start

### Reading volatile content in Swift

```swift
// Simple values (string, array, bool)
let url = ContentRegistry.shared.getString("google.apiKeyURL", default: "aistudio.google.com/apikey")
let steps = ContentRegistry.shared.getStrings("google.apiKeySteps", default: ["Go to aistudio..."])
let enabled = ContentRegistry.shared.getBool("openai.oauthEnabled", default: false)

// Conditional values (resolved from current entry value)
let subtitle = ContentRegistry.shared.conditionalString("openai.oauthStatus", field: "subtitle", default: "Sign in...")
let badge = ContentRegistry.shared.conditional("openai.oauthStatus", field: "badge")  // returns AnyCodableValue?
let isNull = ContentRegistry.shared.conditionalIsNull("google.oauthStatus", field: "badge")  // true = no badge
```

### Adding a new volatile entry

**Step 1:** Add to `volatile_defaults.json`:
```json
"myProvider.featureName": {
  "key": "myProvider.featureName",
  "category": "status",
  "source": "https://example.com/docs",
  "lastVerified": "2026-03-29T00:00:00Z",
  "staleAfterDays": 14,
  "value": "currentValue",
  "verify": { ... },
  "conditionals": { ... },
  "affects": null,
  "feedQuality": "manual"
}
```

**Step 2:** Add a Swift property with hardcoded fallback:
```swift
var featureName: String {
    ContentRegistry.shared.getString("\(rawValue).featureName", default: defaultFeatureName)
}

private var defaultFeatureName: String {
    switch self {
    case .google:  return "default for google"
    case .openai:  return "default for openai"
    // ...
    }
}
```

The hardcoded fallback is the LAST resort. Priority chain:
```
Remote Feed > Local Cache > Bundled JSON > Hardcoded Fallback
```

## Key Pattern: "Always keep the hardcoded fallback"

Every volatile property MUST have a `private var default*` fallback. The app must work
even if the JSON file is missing, corrupt, or fails to decode. Example:

```swift
// ✅ Correct — volatile with fallback
var models: [String] {
    ContentRegistry.shared.getStrings("\(rawValue).models", default: defaultModels)
}
private var defaultModels: [String] { ... }

// ❌ Wrong — no fallback, will crash if registry is empty
var models: [String] {
    ContentRegistry.shared.getStrings("\(rawValue).models")!
}
```

---

## Anatomy of a VolatileEntry

```json
{
  "key": "openai.oauthStatus",       // Unique identifier (provider.property)
  "category": "status",               // Type of content (see categories below)
  "source": "https://...",             // Where to verify (URL, docs page, API ref)
  "lastVerified": "2026-03-29T...",    // When was this data last confirmed accurate (ISO 8601)
  "staleAfterDays": 14,               // How many days before this is considered stale
  "value": "comingSoon",              // The actual content value

  "verify": {                          // Instructions for external agent verification
    "method": "checkURL",              //   How to check: checkURL, webSearch, apiProbe, manual
    "url": "https://platform...",      //   URL to fetch (for checkURL/apiProbe)
    "lookFor": ["OAuth", "oauth2"],    //   Keywords to scan for
    "onFound": "available",            //   New value if keywords found
    "onNotFound": null,                //   New value if keywords NOT found (null = no change)
    "fallbackMethod": "webSearch",     //   Try this method if primary fails
    "searchQuery": "OpenAI OAuth...",  //   Query for webSearch method
    "notes": "Check if they shipped OAuth"  // Context for human/AI verifier
  },

  "conditionals": {                    // Value-dependent associated data
    "available":   { "subtitle": "Sign in with OpenAI account", "badge": null,           "buttonEnabled": true  },
    "comingSoon":  { "subtitle": "Sign in with OpenAI account", "badge": "Coming Soon",  "buttonEnabled": false },
    "unavailable": { "subtitle": "Not available via login",     "badge": "Unavailable",  "buttonEnabled": false }
  },

  "affects": ["openai.oauthSubtitle"],  // Other keys this entry impacts (for dependency tracking)

  "feedQuality": "manual"              // How good is the data source? (see Feed Quality below)
                                        // goldAPI | structured | scraped | manual | disconnected
}
```

---

## Content Categories

| Category | Description | Typical Stale After | Examples |
|---|---|---|---|
| `steps` | Step-by-step UI instructions | 30 days | API key creation flow |
| `url` | URLs, endpoints | 30 days | API key page URLs |
| `modelList` | Available AI models | 7 days | Provider model names |
| `label` | Display names, descriptions | 60-90 days | Product names, taglines |
| `version` | Version strings | 30 days | SDK versions, API versions |
| `status` | Feature/availability flags | 14-30 days | OAuth availability, beta features |

---

## Urgency System (how "hungry" content is)

Content doesn't just say "stale" — it expresses a gradient of hunger based on how much time
has passed relative to its `staleAfterDays` threshold:

```
Time elapsed / threshold    Urgency     What it means
─────────────────────────   ────────    ─────────────────────
< 50%                       🟢 Fresh    Content is known good
50-80%                      🟡 Aging    Would appreciate an update
80-100%                     🟠 Stale    Needs an update
100-200%                    🔴 Expired  Should be verified ASAP
> 200%                      ⚫ Critical Data is unreliable
```

Access urgency:
```swift
let urgency = ContentRegistry.shared.urgency(of: "openai.models")  // .fresh, .aging, etc.
let needsWork = ContentRegistry.shared.entries(above: .stale)       // all stale+ entries
let queue = ContentRegistry.shared.verificationQueue                // stale+ with verify instructions
```

---

## Feed Quality (how well-fed is this entry?)

Every entry has a `feedQuality` that grades how reliable its data source is.
The agent's ongoing mission is to **upgrade entries toward goldAPI**.

```
Rank    Emoji   Name           Description                              Example
────    ─────   ────           ───────────                              ───────
4       🥇      Gold API       Direct API, structured JSON on demand    OpenAI /v1/models
3       🥈      Structured     Reliable docs/feed, predictable format   Anthropic models docs page
2       🥉      Scraped        Web scraping, data good but fragile       aistudio.google.com/apikey
1       🔧      Manual         Requires manual research to verify        OAuth status checks
0       💀      Disconnected   No data source — flying blind             Company names, descriptions
```

### How the agent uses feed quality

1. **`sourceUpgradeQueue`** — Entries with quality < `structured`, sorted worst-first
   ```swift
   let needsBetterFeeds = ContentRegistry.shared.sourceUpgradeQueue
   // Returns: disconnected entries first, then manual, then scraped
   ```

2. **Agent priorities**:
   - 💀 **Disconnected → Find ANY source** (highest priority)
   - 🔧 **Manual → Find a scrapeable page or API**
   - 🥉 **Scraped → Find a structured feed or API**
   - 🥈 **Structured → Find a direct API** (nice-to-have)
   - 🥇 **Gold API → Already optimal** (no action needed)

3. **Setting feed quality** in `volatile_defaults.json`:
   ```json
   "feedQuality": "goldAPI"      // or "structured", "scraped", "manual", "disconnected"
   ```

4. **Defaults**: If `feedQuality` is not set:
   - Entries WITH `verify` instructions default to `manual`
   - Entries WITHOUT `verify` default to `disconnected`

---

## Happiness System

Each entry has a **happiness score** (0.0 – 1.0) that combines freshness and feed quality:

```
Happiness = (freshness_score × 0.6) + (feed_quality_score × 0.4)
```

| Score | Freshness Weight | Feed Quality Weight | Meaning |
|---|---|---|---|
| 1.0 | Fresh (1.0) | Gold API (1.0) | Thriving — best possible state |
| ~0.7 | Fresh (1.0) | Manual (0.3) | Fresh but fragile — needs better feed |
| ~0.5 | Stale (0.45) | Scraped (0.55) | Middling — needs refresh AND better feed |
| ~0.1 | Expired (0.2) | Disconnected (0.0) | Suffering — urgent attention needed |
| 0.0 | Critical (0.0) | Disconnected (0.0) | Miserable — data is unreliable |

Access happiness:
```swift
let score = ContentRegistry.shared.happiness(of: "openai.models")   // 0.0 - 1.0
let system = ContentRegistry.shared.systemHappiness                 // average across all entries
let diag = ContentRegistry.shared.systemDiagnostic                  // full text diagnostic
// "Happiness: 62%  |  Freshness: 🟢 15 fresh  🟡 8 aging  |  Feeds: 🥇 2 gold api  🥉 6 scraped  💀 10 disconnected"
```

---

## Verification Instructions

Verification is performed by **external agents** (AI assistants, cron jobs, humans).
The app itself NEVER fetches verification data. It just provides the framework for
the agent to know WHAT to check, HOW to check, and WHAT to change.

### Verification methods

| Method | When to use | What the agent does |
|---|---|---|
| `checkURL` | Page structure is known | Fetch URL, search for `lookFor` keywords |
| `webSearch` | Exact URL unknown or may change | Search the web with `searchQuery` |
| `apiProbe` | Public API available | Hit the URL, parse the JSON response |
| `manual` | Requires judgment | Read `notes`, make a human decision |

### Agent workflow
1. Read `ContentRegistry.shared.verificationQueue` (priority-ordered)
2. For each entry, follow the `verify` instructions
3. If verification finds changes, update the local cache:
   ```bash
   # Write updated JSON to the local cache
   ~/.neuralclaw/volatile_content.json
   ```
4. On next app launch, the cache takes precedence over bundled defaults

---

## Conditionals (Object Associations)

Conditionals let ONE value change cascade to ALL associated UI elements.
Instead of the UI checking the value and branching, the data itself resolves:

### How it works
```json
"openai.oauthStatus": {
  "value": "comingSoon",
  "conditionals": {
    "available":   { "subtitle": "Sign in with OpenAI account", "badge": null, "buttonEnabled": true },
    "comingSoon":  { "subtitle": "Sign in with OpenAI account", "badge": "Coming Soon", "buttonEnabled": false },
    "unavailable": { "subtitle": "Not available via login",     "badge": "Unavailable", "buttonEnabled": false }
  }
}
```

### Accessing conditionals in Swift
```swift
// String conditional
let subtitle = ContentRegistry.shared.conditionalString(
    "openai.oauthStatus", field: "subtitle", default: "Sign in with OpenAI account"
)

// Bool conditional
let enabled = ContentRegistry.shared.conditionalBool(
    "openai.oauthStatus", field: "buttonEnabled", default: false
)

// Null check (null means "hidden" / "none" / "empty")
let hasBadge = !ContentRegistry.shared.conditionalIsNull("google.oauthStatus", field: "badge")
```

### When to use `null` in conditionals
Use JSON `null` to mean "this element should not appear":
- `"badge": null` → no badge shown
- `"buttonLabel": null` → no button rendered
- `"tooltip": null` → no tooltip

### Adding conditionals to a new UI element
1. Identify the parent value that drives UI changes (e.g., `oauthStatus`)
2. List all possible values (e.g., `available`, `comingSoon`, `unavailable`)
3. For each value, define what every associated field should be
4. Add to the entry's `conditionals` block in `volatile_defaults.json`
5. In Swift, read with `conditionalString()`, `conditionalBool()`, `conditionalIsNull()`

---

## Key Naming Convention

All keys follow the pattern: `{provider}.{property}`

- Provider names use the `rawValue` of the Swift enum (e.g., `google`, `openai`, `anthropic`, `openrouter`, `venice`, `local`)
- Property names are camelCase
- Examples: `google.apiKeySteps`, `openai.oauthStatus`, `venice.models`, `local.desc`

For non-provider content, use: `{component}.{property}`
- Examples: `app.version`, `wizard.stepCount`, `gateway.latestVersion`

---

## File Locations

| File | Purpose |
|---|---|
| `Sources/VolatileContent.swift` | Core types: VolatileEntry, ContentUrgency, VerifyInstructions, ContentRegistry |
| `Sources/Resources/volatile_defaults.json` | Bundled defaults (shipped with app) |
| `~/.neuralclaw/volatile_content.json` | Local cache (overrides bundled defaults) |
| `Sources/Models.swift` | Enum properties that consume volatile content |

---

## Currently Tracked Volatile Content (27 entries)

### Consumer AI (3 providers × 5-7 properties)
| Key | Category | Stale After | Feed Quality | Has Verify | Has Conditionals |
|---|---|---|---|---|---|
| `{provider}.productName` | label | 90 days | 🔧 Manual | ✅ (checkURL) | ❌ |
| `{provider}.companyName` | label | 365 days | 💀 Disconnected | ❌ | ❌ |
| `{provider}.oauthStatus` | status | 14-30 days | 🔧 Manual | ✅ (checkURL/webSearch) | ✅ (subtitle, badge, buttonEnabled) |
| `{provider}.apiKeyURL` | url | 30 days | 🥉 Scraped | ✅ (checkURL) | ❌ |
| `{provider}.apiKeySteps` | steps | 30 days | 🥉 Scraped | ✅ (checkURL) | ❌ |

### AI Providers (5 providers × 2-3 properties)
| Key | Category | Stale After | Feed Quality | Has Verify | Has Conditionals |
|---|---|---|---|---|---|
| `openai.models` | modelList | 7 days | 🥇 Gold API | ✅ (apiProbe) | ❌ |
| `openrouter.models` | modelList | 7 days | 🥇 Gold API | ✅ (apiProbe) | ❌ |
| `anthropic.models` | modelList | 7 days | 🥈 Structured | ✅ (checkURL) | ❌ |
| `venice.models` | modelList | 7 days | 🥈 Structured | ✅ (checkURL) | ❌ |
| `local.models` | modelList | 14 days | 🥈 Structured | ✅ (checkURL) | ❌ |
| `{provider}.desc` | label | 60 days | 💀 Disconnected | ❌ | ❌ |
| `{provider}.keyPlaceholder` | label | 90 days | 💀 Disconnected | ❌ | ❌ |
