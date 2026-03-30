---
description: Critical invariants that must survive context compression.
paths:
  - "**/*"
---

# Core Invariants

1. **Always kill old instances before running.** `pkill -f NeuralClawSetup` before `swift run`. Stale processes hold the window and port.

2. **SPM only — no Xcode project files.** Never create .xcodeproj or .xcworkspace. Build and run via `swift build` / `swift run`.

3. **Config saves to ~/.neuralclaw/config.toml.** Never write config anywhere else. Always ensure the directory exists before writing.
