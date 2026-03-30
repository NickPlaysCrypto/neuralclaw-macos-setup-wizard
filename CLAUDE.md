# NeuralClaw Setup Wizard

## Project Overview
Native macOS SwiftUI setup wizard for the NeuralClaw AI agent platform. Built with Swift Package Manager (SPM), not Xcode project files.

## Architecture
- **App.swift** — App entry point, window configuration, icon loading
- **SetupWizardView.swift** — Root view with page transitions, stepper, progress bar, footer nav
- **SetupState.swift** — ViewModel managing navigation state, page sequences, per-service API key storage, and configuration saving
- **Models.swift** — Design system (DS), enums (WizardPage, ConsumerAI, AIProvider, OAuthAvailability, etc.)
- **VolatileContent.swift** — Intelligent content system with urgency, verification, and conditional associations
- **WelcomeAndProviderSteps.swift** — AI usage questionnaire, OAuth connect page, API key guide with inline key entry, provider selection
- **ModelAndFeaturesSteps.swift** — Model picker, feature toggles with presets
- **ChannelsAndDoneSteps.swift** — Channel toggles, summary/done page

## VolatileContent System (v2)

Content that changes over time is managed by `ContentRegistry` — an intelligent system that tracks freshness, carries verification instructions, and resolves conditional UI associations.

### Core Types
- **`VolatileEntry`** — Wraps any content with metadata: category, source, `lastVerified`, `staleAfterDays`, verify instructions, and conditionals
- **`ContentUrgency`** — Five-level gradient: `fresh → aging → stale → expired → critical`
- **`VerifyInstructions`** — HOW to check if content is still accurate (checkURL, webSearch, apiProbe, manual)
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

### Verification Queue
External agents (AI) read `ContentRegistry.shared.verificationQueue` for a priority-ordered list of entries needing checking. Each entry carries `VerifyInstructions` describing the method (checkURL, webSearch, etc.), target URL, keywords to look for, and fallback strategies.

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
cd /Users/nick/Desktop/NeuralClawSetup && swift run
```

## Building .app Bundle
```bash
bash build_app.sh
```

## App Icon
- Source: `Sources/Resources/AppIcon.icns`
- Loaded via `Bundle.module`, set via `NSApp.applicationIconImage`

## Important Notes
- Uses SPM, NOT an Xcode project
- Minimum macOS 13 / Swift tools 5.9
- Window is fixed size 720x620 with hidden title bar
- `ContentRegistry` is NOT `@MainActor` — must be accessible from nonisolated enum properties
- Break complex SwiftUI views into computed properties to avoid compiler type-check timeouts
