# NeuralClaw Setup Wizard

## Project Overview
Native macOS SwiftUI setup wizard for the NeuralClaw AI agent platform. Built with Swift Package Manager (SPM), not Xcode project files.

## Architecture
- **App.swift** — App entry point, window configuration, icon loading
- **SetupWizardView.swift** — Root view with page transitions, stepper, progress bar, footer nav
- **SetupState.swift** — ViewModel managing navigation state, page sequences, and configuration saving
- **Models.swift** — Design system (DS), enums (WizardPage, ConsumerAI, AIProvider, OAuthAvailability, etc.)
- **WelcomeAndProviderSteps.swift** — AI usage questionnaire, OAuth connect page, API key guide, provider selection
- **ModelAndFeaturesSteps.swift** — Model picker, feature toggles with presets
- **ChannelsAndDoneSteps.swift** — Channel toggles, summary/done page

## Key Patterns
- Two wizard paths: **Consumer** (OAuth flow) and **API Key** (direct config)
- OAuth has 3 states: `.available` (Log In button), `.comingSoon` (amber tag), `.unavailable` (grey + popover tooltip)
- Page sequence is dynamic based on chosen path
- Config saves to `~/.neuralclaw/config.toml`

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
