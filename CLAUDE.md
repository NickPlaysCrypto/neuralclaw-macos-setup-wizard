# NeuralClaw Setup Wizard

## Project Overview
Native macOS SwiftUI setup wizard for the NeuralClaw AI agent platform. Built with Swift Package Manager (SPM), not Xcode project files.

**Design Philosophy:** This is a minimal-friction installer — its only job is to gather just enough information to get the user chatting with an AI agent ASAP. The wizard collects a provider + API key + model choice, then immediately closes so the NeuralClaw agent can take over. All other configuration (features, channels, preferences, fallback providers) happens post-install through the agent's chat interface. The wizard should never block the user with unnecessary steps.

**Limitations:** This is a UI-only installer. It does NOT:
- Launch the NeuralClaw agent or gateway (handled by system launch agents or user action)
- Make real network requests to validate API keys (stubs only — backend integration pending)
- Download or install any files (saves config to `~/.neuralclaw/` only)
- Manage runtime agent state

## Architecture
- **App.swift** — App entry point, window configuration, icon loading
- **SetupWizardView.swift** — Root view with page transitions, stepper, progress bar, footer nav
- **SetupState.swift** — ViewModel managing navigation state, page sequences, per-service API key storage, and configuration saving
- **Models.swift** — Design system (DS), enums (WizardPage, ConsumerAI, AIProvider, OAuthAvailability, ExtraProvider, etc.)
- **VolatileContent.swift** — Intelligent content system with urgency, verification, and conditional associations
- **VOLATILE_CONTENT.md** — **Full developer guide** for the VolatileContent system (read this before building new UI objects)
- **Resources/volatile_defaults.json** — Bundled JSON manifest of all volatile content with metadata
- **WelcomeAndProviderSteps.swift** — AI usage questionnaire, OAuth connect page, API key guide with inline key entry, provider selection
- **ModelAndFeaturesSteps.swift** — Model picker (final step), install confirmation overlay, biometric auth, feature toggles
- **ChannelsAndDoneSteps.swift** — Channel toggles, legacy done page (no longer navigated to — success is shown inline on model picker)

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
| Panel title | `wizard.providerPanel.title` | label | 90 days |
| Panel subtitle | `wizard.providerPanel.subtitle` | label | 90 days |

## Key Patterns
- Two wizard paths: **Consumer** (OAuth flow) and **API Key** (direct config)
- **Streamlined flow**: aiUsage → provider/oauth → apiConfig (terminal step). No separate "done" page — success is shown inline.
- **Unified provider list**: First page + APIProviderStep both show the same 5 providers (Gemini, ChatGPT, Claude, OpenRouter, Venice) plus an "Add a Provider" card with 18+ searchable extras
- **Footer nav hidden on**: aiUsage (has its own buttons), apiConfig (Install button is the action), and done (legacy)
- Provider list is in a `ScrollView` to handle overflow in the fixed 720×700 window
- OAuth has 3 states: `.available` (Log In button), `.comingSoon` (amber tag), `.unavailable` (grey + popover tooltip)
- `OAuthAvailability.from(_:)` converts string values from the registry to the enum
- `ConsumerAI.oauthSubtitle`, `.oauthButtonEnabled`, `.oauthBadge` resolve from conditionals
- **Local Models** option: checkbox toggle for Ollama support (`SetupState.wantsLocalModel`)
- **Inline API Key** input: SecureField + Save button on the provider panel (`SetupState.directAPIKey`)
- **Info popovers**: ⓘ circles on "Get Your API Key" title (explains what an API key is) and "Learn how to get an API key" button (explains when you need one)
- **File access warning**: ⚠️ amber banner on first page: "NeuralClaw will not have access to any of your device files unless you give it explicit access"
- **Biometric checkbox**: Touch ID toggle for file access permissions (`SetupState.requireBiometric`, defaults off)
- **Model picker is terminal**: Select model → "Install with {model}" → confirmation overlay → biometric auth (if enabled) → inline "You're All Set!" success → Close button terminates wizard
- Page sequence is dynamic based on chosen path
- Config saves to `~/.neuralclaw/config.toml`, API keys to `~/.neuralclaw/.secrets.toml` (chmod 600)
- Per-service API keys stored in `SetupState.serviceAPIKeys` dictionary, saved via `saveServiceKey()` method
- API Key Guide step features inline SecureField + Save button per provider card with visual feedback

## Model Detection Strategy
When a user saves an API key, the wizard shows a "Detecting provider AI models" overlay. The detection approach varies by provider:

### Tier 1 — Known providers (fast path, ~3s)
Major providers like **OpenAI, Anthropic, Google, OpenRouter, Venice** have well-known model lists. For these:
- We already know which models a given API key grants access to
- Detection is really just a **quick validation ping** to verify the key works
- On success, auto-navigate to the model picker with the known model list pre-populated

### Tier 2 — Semi-known providers
Providers like **Mistral, Groq, Together AI, Fireworks** have stable model lists but may require:
- A `/models` endpoint call to confirm which specific models the key has access to
- Key format validation (prefix matching, length checks)

### Tier 3 — Unknown/custom providers
For providers added via "Add a Provider" or custom OpenAI-compatible endpoints:
- Full model discovery via API introspection (`/v1/models` or equivalent)
- May require the user to manually specify the base URL
- 10-second timeout with "No models detected" fallback

### Flow (unified, all pages)
`Save API key` → `Model detection overlay (10s bar)` → `Model picker` → `Install confirmation` → `Biometric auth` → `Done`

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

## Before You Write Any Code

Every time. No exceptions.

1. **Grep first.** Search for existing patterns before creating anything. If a convention exists, follow it. `grep -r "similar_term" Sources/` before writing a single line.

2. **Blast radius.** What depends on what you're changing? Check imports, views, consumers. Unknown blast radius = not ready to code.

3. **Ask, don't assume.** Ambiguous request? Ask ONE clarifying question. Don't guess, don't ask five questions. One, then move.

4. **Smallest change.** Solve what was asked. No bonus refactors. No unrequested features. Scope creep is a bug.

5. **Verification plan.** How will you prove this works? Answer this before writing code.

## Completion Criteria

ALL must pass before any task is done:
1. `swift build` — zero errors
2. No warnings treated as errors
3. No orphan TODO/FIXME without tracking issue
4. New modules have corresponding test coverage

## Self-Evolution Protocol

You are an evolving system. During every session:

1. **Observe.** When you discover a non-obvious pattern, constraint, or convention in the codebase that isn't documented here, log it to `.claude/memory/observations.jsonl`.

2. **Learn from corrections.** When the user corrects you, log the correction to `.claude/memory/corrections.jsonl`. This is your most valuable signal.

3. **Consult memory.** At the start of complex tasks, read `.claude/memory/learned-rules.md` for patterns accumulated from past sessions. These are rules that graduated from observations.

4. **Never forget a mistake twice.** If a correction matches a previous correction in the log, it should already be a learned rule. If it isn't, promote it immediately.

Read `.claude/memory/README.md` for the full memory system protocol.

## Things You Must Never Do

- Commit to main directly
- Read or modify .env or secret files
- Run destructive commands (rm -rf, git reset --hard, git push --force) without confirmation
- Create .xcodeproj or .xcworkspace files (SPM only)
- Leave dead code
- Swallow errors silently
- Modify `.claude/memory/learned-rules.md` without running /evolve
