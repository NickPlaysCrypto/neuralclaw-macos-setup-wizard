# NeuralClaw Setup Wizard

## Project Overview
Native macOS SwiftUI setup wizard for the NeuralClaw AI agent platform. Built with Swift Package Manager (SPM), not Xcode project files.

## Architecture
- **App.swift** — App entry point, window configuration, icon loading
- **SetupWizardView.swift** — Root view with page transitions, stepper, progress bar, footer nav
- **SetupState.swift** — ViewModel managing navigation state, page sequences, per-service API key storage, and configuration saving
- **Models.swift** — Design system (DS), enums (WizardPage, ConsumerAI, AIProvider, OAuthAvailability, etc.)
- **VolatileContent.swift** — `VolatileEntry`, `ContentRegistry` singleton for content that changes over time
- **WelcomeAndProviderSteps.swift** — AI usage questionnaire, OAuth connect page, API key guide with inline key entry, provider selection
- **ModelAndFeaturesSteps.swift** — Model picker, feature toggles with presets
- **ChannelsAndDoneSteps.swift** — Channel toggles, summary/done page

## VolatileContent System
Content that is subject to change (API key steps, URLs, model lists, descriptions) uses the `ContentRegistry`:

- **`VolatileContent.swift`** — Core types: `VolatileEntry`, `AnyCodableValue`, `ContentCategory`, `ContentManifest`, `ContentRegistry`
- **`volatile_defaults.json`** — Bundled JSON manifest with all volatile content, freshness metadata, source URLs, and stale thresholds
- **Priority**: Remote Feed > Local Cache (`~/.neuralclaw/volatile_content.json`) > Bundled Default > Hardcoded Fallback
- **Stale thresholds**: 7 days for model lists, 30 days for steps/URLs, 60 days for labels, 90 days for key placeholders
- **Usage**: `ContentRegistry.shared.getString("google.apiKeyURL", default: "aistudio.google.com/apikey")`
- **Remote feed**: Stubbed (`fetchRemoteUpdates()`) — not yet implemented
- All enum properties that consume volatile data have `private var default*` fallbacks so the app always works without a feed

### Volatile Content Categories
| Category | Examples | Stale After |
|---|---|---|
| `steps` | API key creation instructions | 30 days |
| `url` | API key page URLs | 30 days |
| `modelList` | Available AI models | 7 days |
| `label` | Provider descriptions | 60 days |
| `version` | Version strings | 30 days |

## Key Patterns
- Two wizard paths: **Consumer** (OAuth flow) and **API Key** (direct config)
- OAuth has 3 states: `.available` (Log In button), `.comingSoon` (amber tag), `.unavailable` (grey + popover tooltip)
- Page sequence is dynamic based on chosen path
- Config saves to `~/.neuralclaw/config.toml`, API keys to `~/.neuralclaw/.secrets.toml` (chmod 600)
- Per-service API keys stored in `SetupState.serviceAPIKeys` dictionary, saved via `saveServiceKey()` method
- API Key Guide step features inline SecureField + Save button per provider card with visual feedback (green glow, ✓ badge)

## Build & Run
```bash
# ALWAYS kill old instances first
pkill -f NeuralClawSetup 2>/dev/null
sleep 0.5
cd /Users/nick/Desktop/NeuralClawSetup
swift run
```

## Building .app Bundle
```bash
bash build_app.sh
```
This creates `NeuralClawSetup.app` on the Desktop.

## App Icon
- Source: `Sources/Resources/AppIcon.icns` (brain with wizard hat)
- Loaded at runtime via `Bundle.module` in App.swift
- Set via `NSApp.applicationIconImage`

## Important Notes
- Uses SPM, NOT an Xcode project
- Minimum macOS 13
- Window is fixed size 720x620 with hidden title bar
- `stepIcon()`, `stepTitle()`, `stepDesc()` are helper functions (likely in one of the step files)
- Break complex SwiftUI views into computed properties to avoid "unable to type-check" compiler errors
- ConsumerAI maps to AIProvider via `.apiProvider` property for key storage
- `ContentRegistry` is NOT `@MainActor` — it must be accessible from nonisolated enum computed properties
