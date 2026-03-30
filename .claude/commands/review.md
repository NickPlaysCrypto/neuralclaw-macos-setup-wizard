---
description: Pre-commit review pipeline. Builds, then reviews the diff.
---

## Pre-flight
!`swift build 2>&1 | tail -15`

## Diff
!`git diff main...HEAD 2>/dev/null || git diff HEAD~1 2>/dev/null || git diff --cached`

## Instructions
1. If build failed, list failures with exact fixes.
2. Review diff for: crashes (force unwraps, unhandled optionals), security (plaintext secrets, unsafe paths), SwiftUI issues (wrong property wrappers, missing MainActor), and test gaps.
3. For each issue: file, line, what's wrong, how to fix.
4. Verdict: SHIP IT / NEEDS WORK / BLOCKED.
5. If SHIP IT: suggest commit message in conventional commits format.
