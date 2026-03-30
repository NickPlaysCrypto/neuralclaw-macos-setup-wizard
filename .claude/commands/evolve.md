---
description: Review the learning system and promote/prune rules. Run weekly or when learned-rules.md gets full.
---

## Current State

### Learned Rules
!`cat .claude/memory/learned-rules.md 2>/dev/null || echo "No learned rules yet"`

### Recent Corrections (last 20)
!`tail -20 .claude/memory/corrections.jsonl 2>/dev/null || echo "No corrections logged"`

### Recent Observations (last 20)
!`tail -20 .claude/memory/observations.jsonl 2>/dev/null || echo "No observations logged"`

### Previous Evolution Decisions
!`tail -40 .claude/memory/evolution-log.md 2>/dev/null || echo "No evolution history"`

## Your Task

You are the meta-engineer. Improve the system that runs you.

### Step 1: Analyze Corrections

Group corrections by pattern. Look for:
- Same correction appearing 2+ times (should already be in learned-rules, if not, promote now)
- Correction clusters pointing to a missing rule in CLAUDE.md or rules/
- Corrections that contradict existing rules (the rule is wrong, not the user)

### Step 2: Analyze Observations

Group observations by type. Look for:
- High-confidence observations confirmed multiple times
- Observations that match corrections (convergent signals are strongest)
- Architecture or gotcha observations that could prevent future bugs

### Step 3: Audit Learned Rules

For each rule in learned-rules.md:
- Still relevant? Does the codebase still follow this pattern?
- Promotion candidate? If it's been there 10+ sessions and always followed, propose moving it to CLAUDE.md or a rules/ file.
- Redundant? Is it now covered by a linter rule, a rules/ file, or CLAUDE.md?
- Too vague? Can Claude actually follow it without interpretation?

### Step 4: Check Evolution Log

Read evolution-log.md. Never re-propose a rejected rule unless the user explicitly asks.

### Step 5: Propose Changes

For each proposal, show:

```
PROPOSE: [action]
  Rule: [the rule text]
  Source: [corrections/observations/learned-rules]
  Evidence: [why this should change]
  Destination: [learned-rules.md | CLAUDE.md | rules/X.md | DELETE]
```

Categories of action:
- PROMOTE: Move from observations to learned-rules
- GRADUATE: Move from learned-rules to CLAUDE.md or rules/
- PRUNE: Remove redundant or outdated learned rule
- UPDATE: Modify existing rule based on new evidence
- ADD: New rule from correction patterns

### Step 6: Wait for Approval

List all proposals. Do NOT apply any changes.
For each, the user will say: approve, reject, or modify.

Apply only approved changes. Log everything (approved AND rejected) to evolution-log.md.

### Constraints

- Never remove security rules
- Never weaken completion criteria
- Never add rules that contradict CLAUDE.md
- Max 50 lines in learned-rules.md (force graduation or pruning if full)
- Every rule must be specific enough to test compliance
- Bias toward specificity over abstraction
