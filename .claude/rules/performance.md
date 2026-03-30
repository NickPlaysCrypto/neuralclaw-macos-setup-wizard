---
description: Performance patterns for SwiftUI macOS app
paths:
  - "Sources/**/*"
---

# Performance Rules

## SwiftUI
- Avoid heavy computation in `body` — move to ViewModel or computed properties with caching.
- Use `@StateObject` for view-owned state, `@ObservedObject` for injected state. Never create ObservableObject in `body`.
- Minimize view invalidation — break large views into small subviews with focused state dependencies.
- Use `task {}` for async work, not `onAppear` with Task {}.

## File I/O
- Config reads/writes to ~/.neuralclaw/ should be async or on a background queue.
- Never block the main thread with file operations.
