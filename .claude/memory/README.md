# Memory System

This directory is Claude's learning infrastructure. It captures observations, corrections, and graduated rules across sessions.

## How It Works

```
Session start
    |
    v
VERIFICATION SWEEP   <-- Runs every rule's verify: check
    |
    v
Session activity
    |
    v
observations.jsonl   <-- Verified discoveries (not guesses)
corrections.jsonl    <-- User corrections (with auto-generated checks)
violations.jsonl     <-- Rule violations caught by verification
sessions.jsonl       <-- Session scorecards and trend data
    |
    v
/evolve              <-- Periodic review (run manually)
    |
    v
learned-rules.md     <-- Graduated patterns WITH verify: checks
    |
    v
CLAUDE.md / rules/   <-- Promoted to permanent config
```

## File Purposes

### observations.jsonl
Append-only log. One JSON object per line. Claude writes here when it discovers something non-obvious.

Example entries:
```jsonl
{"timestamp": "2026-03-29T14:30:00Z", "type": "convention", "observation": "All wizard page transitions use withAnimation(.easeInOut)", "file_context": "Sources/SetupWizardView.swift", "confidence": "high"}
{"timestamp": "2026-03-29T15:10:00Z", "type": "gotcha", "observation": "Config directory must be created with 700 permissions before writing", "file_context": "Sources/SetupState.swift", "confidence": "confirmed"}
```

Types: convention, gotcha, dependency, architecture, performance, pattern
Confidence: low (inferred), medium (observed once), high (observed multiple times), confirmed (user validated)

### corrections.jsonl
Append-only log. Claude writes here when the user corrects its behavior.

Example:
```jsonl
{"timestamp": "2026-03-29T16:00:00Z", "correction": "Always pkill before swift run", "context": "Was running swift run without killing old instance", "category": "process", "times_corrected": 1}
```

Categories: style, architecture, security, testing, naming, process, behavior

### violations.jsonl
Append-only log. Records every rule violation caught by the verification sweep. Used by /evolve to identify rules that need escalation (recurring violations mean the rule should graduate to CLAUDE.md or become a linter rule).

### sessions.jsonl
Session scorecards. One entry per session. Tracks corrections received, rules checked/passed/failed, observations made. Used for trend detection: are corrections decreasing over time? If not, the rules aren't working.

The `times_corrected` field tracks repeat corrections. When this reaches 2 for the same pattern, it auto-promotes to learned-rules.md without waiting for /evolve.

### learned-rules.md
Curated rules that graduated from observations and corrections. Claude reads this file at the start of complex tasks. Rules here have been validated by repetition (corrected 2+ times) or explicit approval during /evolve.

### evolution-log.md
Audit trail of every /evolve run. Records what was proposed, approved, rejected, and why. Prevents the system from re-proposing rejected rules.

## Rules for Writing to Memory

1. Observations are cheap. Log liberally. Low-confidence observations are fine.
2. Corrections are gold. Every correction gets logged. No exceptions.
3. Learned rules are expensive. They load into context every session. Each must be actionable, testable, and non-redundant.
4. Never delete correction logs. They're provenance.
5. Learned rules max at 50 lines. Forces graduation or pruning.

## Promotion Ladder

| Signal | Destination |
|--------|------------|
| Corrected once | corrections.jsonl (logged) |
| Corrected twice, same pattern | learned-rules.md (auto-promoted) |
| Observed 3+ times, same pattern | learned-rules.md (via /evolve) |
| In learned-rules 10+ sessions, always followed | Candidate for CLAUDE.md or rules/ |
| Rejected during evolve | evolution-log.md (never re-proposed) |
