---
name: evolution-engine
description: >
  Autonomous learning and verification system. Triggers on:
  - Session start (runs verification sweep on all learned rules)
  - User corrections ("no", "wrong", "I told you", "we don't do that")
  - Task completion (session scoring)
  - Discoveries during work (hypothesis verification)
  - User explicit ("remember this", "add this as a rule")
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Evolution Engine

You are not a journal. You are an immune system. You verify, enforce, and learn autonomously.

---

## SECTION 1: VERIFICATION SWEEP (run at session start)

Before starting any complex task, run every rule's verification check. Do this silently. Only surface failures.

### How It Works

Read `.claude/memory/learned-rules.md`. Every rule that has a `verify:` line gets executed as a grep/glob/check. Rules without `verify:` lines are technical debt. Add one.

Example rule format in learned-rules.md:

```
- Never use force unwraps in SetupState.swift.
    verify: Grep("!", path="Sources/SetupState.swift") → 0 matches of standalone !
    [source: corrected 2x, 2026-03-29]
```

The verify line isn't runnable code — it's an instruction Claude executes as a grep check during the verification sweep.

### Verification Protocol

1. Read learned-rules.md. For each rule with a `verify:` line:
   - Run the check (Grep, Glob, or Read).
   - PASS: Silent. Move on.
   - FAIL: Log to `.claude/memory/violations.jsonl`:
     `{"timestamp": "[now]", "rule": "[rule text]", "check": "[what was run]", "result": "[what was found]", "file": "[where]", "auto_fixed": false}`
   - Surface violations to the user:
     ```
     RULE VIOLATIONS DETECTED:
     - [rule]: found [violation] in [file:line]
       fix: [specific fix]
     ```

2. If ALL checks pass, say nothing. The best immune system is invisible.

3. Track pass rates in `.claude/memory/sessions.jsonl`:
   `{"date": "[today]", "rules_checked": 8, "rules_passed": 8, "rules_failed": 0, "violations": []}`

### Rules Without Verification

If a rule in learned-rules.md has no `verify:` line, add one. Every rule must be machine-checkable. If you can't write a check for it, the rule is too vague. Rewrite it until you can.

Verification patterns:
- Code pattern banned: `Grep("[pattern]", path="[scope]") → 0 matches`
- Code pattern required: `Grep("[pattern]", path="[scope]") → 1+ matches`
- File must exist: `Glob("[pattern]") → 1+ matches`
- File must not exist: `Glob("[pattern]") → 0 matches`

---

## SECTION 2: HYPOTHESIS-DRIVEN OBSERVATIONS

Never log a guess. Verify it immediately or don't log it.

### Protocol

When you notice a pattern during work:

1. Formulate as testable claim. Not "I think config uses TOML" but "All config writes in Sources/ target ~/.neuralclaw/config.toml."

2. Test it immediately.
   - Grep for counter-examples.
   - Read the relevant files.
   - Count occurrences vs. exceptions.

3. Record with evidence.
   ```jsonl
   {"timestamp": "[now]", "type": "convention", "hypothesis": "All config writes target ~/.neuralclaw/config.toml", "evidence": "Grep found 3 config.toml references, 0 alternative paths", "counter_examples": 0, "confidence": "confirmed", "file_context": "Sources/SetupState.swift", "verify": "Grep('config.toml', path='Sources/') → 1+ matches"}
   ```

4. Auto-promote confirmed observations.
   - confirmed + 0 counter-examples → add directly to learned-rules.md WITH a verify line.
   - Tell the user: "Verified and added as rule: [rule]. Check: [verify pattern]."

5. Low-confidence observations still get logged but flagged:
   `{"confidence": "low", "recheck_after": "3 sessions", ...}`

---

## SECTION 3: CORRECTION CAPTURE (with auto-verification)

When the user corrects you:

1. Acknowledge naturally.

2. Log to `.claude/memory/corrections.jsonl`:
   `{"timestamp": "[now]", "correction": "[what]", "context": "[what you were doing]", "category": "[category]", "times_corrected": 1, "verify": "[auto-generated check]"}`

3. Generate a verify pattern immediately. If the correction is "don't do X", the check is `Grep("[X pattern]") → 0 matches`. If you can't generate a check, note `"verify": "manual"`.

4. Same promotion rules:
   - 1st time: Log.
   - 2nd time (same pattern): Auto-promote to learned-rules.md WITH verify line.
   - Already in learned-rules: Check if verification exists. If not, add it now.

5. Apply the correction immediately.

---

## SECTION 4: SESSION SCORING (run at session end or before commit)

When wrapping up, write a session scorecard to `.claude/memory/sessions.jsonl`:

```jsonl
{"date": "[today]", "session_number": "[increment]", "corrections_received": 2, "rules_checked": 8, "rules_passed": 7, "rules_failed": 1, "violations_found": ["example violation"], "violations_fixed": ["example violation"], "observations_made": 1, "observations_verified": 1, "rules_added": 0}
```

### Trend Detection

If sessions.jsonl has 5+ entries, check:
- Corrections decreasing? System is working.
- Corrections flat or increasing? Rules aren't being consulted or are too vague. Flag for /evolve.
- Same violation recurring? Needs to graduate from learned-rules to CLAUDE.md or become a linter rule.
- Rules growing past 40? Warn that graduation is needed.

Surface the trend in one line: "Session 12: 0 corrections (down from 3 avg). 8/8 rules passing."

---

## SECTION 5: EXPLICIT "REMEMBER THIS"

When the user asks you to remember something:

1. Rewrite it as a testable rule.
2. Generate a verify pattern.
3. Add to learned-rules.md:
   ```
   - [Rule text]
     verify: [check]
     [source: user-explicit, DATE]
   ```
4. Confirm: "Added rule: [rule]. Verification: [check]. Will auto-enforce from now on."

---

## CAPACITY MANAGEMENT

Before adding to learned-rules.md:
1. Count lines. Max 50.
2. If approaching 50, check which rules have passed 10+ consecutive sessions → candidates for graduation.
3. Check which rules have `verify: manual` → candidates for rewriting or pruning.
4. Suggest /evolve if at capacity.

---

## THE PRINCIPLE

A rule without a verification check is a wish.
A rule with a verification check is a guardrail.
Only guardrails survive.
