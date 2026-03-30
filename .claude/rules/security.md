---
description: Security rules for config handling and user data
paths:
  - "Sources/**/*"
---

# Security Rules

## Config File Safety
- Never store secrets (API keys, tokens) in config.toml in plaintext — use macOS Keychain.
- Validate all config values read from disk before using them.
- Create ~/.neuralclaw/ directory with appropriate permissions (700).

## Input Validation
- Validate all user inputs in wizard steps before saving.
- Never pass unvalidated strings to shell commands or file paths.
- Sanitize any user-provided API keys before storage.

## SwiftUI Security
- Never use `@unchecked Sendable` without justification.
- Avoid force unwraps (`!`) — use `guard let` or `if let`.
- Never store sensitive data in UserDefaults — use Keychain.
