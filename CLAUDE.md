# NeuralClaw Setup Wizard

## Project Overview
Native macOS SwiftUI setup wizard for the NeuralClaw AI agent platform. Built with Swift Package Manager (SPM), not Xcode project files.

## Architecture
- **App.swift** — App entry point, window configuration, icon loading
- **SetupWizardView.swift** — Root view with page transitions, stepper, progress bar, footer nav
- **SetupState.swift** — ViewModel managing navigation state, page sequences, per-service API key storage, and configuration saving
- **Models.swift** — Design system (DS), enums (WizardPage, ConsumerAI, AIProvider, OAuthAvailability, etc.)
- **VolatileContent.swift** — Intelligent content system with urgency, verification, and conditional associations
- **VOLATILE_CONTENT.md** — **Full developer guide** for the VolatileContent system (read this before building new UI objects)
- **Resources/volatile_defaults.json** — Bundled JSON manifest of all volatile content with metadata
- **WelcomeAndProviderSteps.swift** — AI usage questionnaire, OAuth connect page, API key guide with inline key entry, provider selection
- **ModelAndFeaturesSteps.swift** — Model picker, feature toggles with presets
- **ChannelsAndDoneSteps.swift** — Channel toggles, summary/done page

## VolatileContent System (v2)

> **Note:** VolatileContent is **developer/agent infrastructure**, not user-facing. End users never see urgency scores, feed quality, or happiness metrics — they just see a wizard that works. This system exists so developers and AI agents can track, maintain, and upgrade the accuracy of UI content over time.
>
> **Two-version architecture:** This (developer) version has the full VolatileContent system — registry, JSON manifests, urgency/happiness tracking, and verification queues. The **end-user "lite" version** will NOT include any of this — it ships with content baked in as plain hardcoded values. The developer version is the *source of truth* that produces accurate values; the lite version just consumes the final output.

Content that changes over time is managed by `ContentRegistry` — an intelligent system that tracks freshness, carries verification instructions, and resolves conditional UI associations.

### Core Types
- **`VolatileEntry`** — Wraps any content with metadata: category, source, `lastVerified`, `staleAfterDays`, verify instructions, conditionals, feedQuality, lastMetaTagCount
- **`ContentUrgency`** — Five-level gradient: `fresh → aging → stale → expired → critical`
- **`FeedQuality`** — Five-tier data source ranking: `🥇 goldAPI → 🥈 structured → 🥉 scraped → 🔧 manual → 💀 disconnected`
- **`VerifyInstructions`** — HOW to check if content is still accurate (checkURL, webSearch, apiProbe, manual)
- **`MetaTag`** / **`MetaTagStore`** — Agent-generated timestamped annotations stored in `~/.neuralclaw/meta_tags.json`
- **`AnyCodableValue`** — Type-erased JSON: string, strings, int, bool, null
- **`ContentCategory`** — steps, url, modelList, version, label, status

### Conditional Associations
One value change cascades to all associated UI. Example:
```json
"openai.oauthStatus": {
  "value": "comingSoon",
  "conditionals": {
    "available":   { "subtitle": "Sign in with OpenAI account", "badge": null, "buttonEnabled": true },
    "comingSoon":  { "subtitle": "Sign in with OpenAI account", "badge": "Coming Soon", "buttonEnabled": false },
    "unavailable": { "subtitle": "Not available via login",      "badge": "Unavailable", "buttonEnabled": false }
  }
}
```
Access: `ContentRegistry.shared.conditionalString("openai.oauthStatus", field: "subtitle", default: "...")`

### Agent Queues
- **`verificationQueue`** — Entries needing verification, most urgent first (with verify instructions)
- **`sourceUpgradeQueue`** — Entries needing better data feeds, worst quality first
- **`keysWithNewTags`** — Entries with unread meta-tag annotations
- **`systemDiagnostic`** — One-line health: `Happiness: 62% | Freshness: 🟢 15 fresh | Feeds: 🥇 2 gold`

### Meta-Tags (Agent Annotations)
Agents write timestamped notes to any entry via `MetaTagStore.shared.add(key:agent:type:content:)`. Types: `observation`, `correction`, `sourceFound`, `sourceDown`, `warning`, `context`. Entries track `lastMetaTagCount` so agents can detect unread annotations via `hasNewTags(for:)`.

### Priority Chain
```
Remote Feed > Local Cache (~/.neuralclaw/volatile_content.json) > Bundled JSON > Hardcoded Fallback
```

### What's Volatile
| Property | Key Pattern | Category | Stale After |
|---|---|---|---|
| OAuth status | `{provider}.oauthStatus` | status | 14-30 days |
| Product name | `{provider}.productName` | label | 90 days |
| Company name | `{provider}.companyName` | label | 365 days |
| API key URL | `{provider}.apiKeyURL` | url | 30 days |
| API key steps | `{provider}.apiKeySteps` | steps | 30 days |
| Model list | `{provider}.models` | modelList | 7 days |
| Description | `{provider}.desc` | label | 60 days |
| Key placeholder | `{provider}.keyPlaceholder` | label | 90 days |

## Key Patterns
- Two wizard paths: **Consumer** (OAuth flow) and **API Key** (direct config)
- OAuth has 3 states: `.available` (Log In button), `.comingSoon` (amber tag), `.unavailable` (grey + popover tooltip)
- `OAuthAvailability.from(_:)` converts string values from the registry to the enum
- `ConsumerAI.oauthSubtitle`, `.oauthButtonEnabled`, `.oauthBadge` resolve from conditionals
- Page sequence is dynamic based on chosen path
- Config saves to `~/.neuralclaw/config.toml`, API keys to `~/.neuralclaw/.secrets.toml` (chmod 600)
- Per-service API keys stored in `SetupState.serviceAPIKeys` dictionary, saved via `saveServiceKey()` method
- API Key Guide step features inline SecureField + Save button per provider card with visual feedback

## Build & Run
```bash
pkill -f NeuralClawSetup 2>/dev/null; sleep 0.5
swift run
```

## Building .app Bundle
```bash
bash build_app.sh
```

## First-Time Install (after cloning)
```bash
bash install.sh
```
Checks for Swift, builds release binary, creates `~/Desktop/NeuralClawSetup.app`, and launches it.

## App Icon
- Source: `Sources/Resources/AppIcon.icns` (glowing brain + wizard hat, dark bg, no white border)
- Loaded via `Bundle.module`, set via `NSApp.applicationIconImage`
- To regenerate: create PNG, convert to .icns using Python + Pillow (see below)

## Important Notes
- **Always use Xcode** for building, testing, and managing Swift projects — use the Xcode workflows in `clawnick-main/.agents/workflows/` (`/xcode-build`, `/xcode-test`, `/xcode-diagnostics`, `/xcode-project`, `/xcode-ide`)
- Uses SPM, NOT an Xcode project
- Minimum macOS 13 / Swift tools 5.9
- Window is fixed size 720x620 with hidden title bar
- `ContentRegistry` is NOT `@MainActor` — must be accessible from nonisolated enum properties
- Break complex SwiftUI views into computed properties to avoid compiler type-check timeouts
- **NEVER use `sips`** — it hangs/times out on this system. Use Python + Pillow for image conversion instead
- Build scripts are portable — use `$HOME` and `$(dirname "$0")`, never hardcode `/Users/nick`
