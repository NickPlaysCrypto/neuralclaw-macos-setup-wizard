---
description: Session boot sequence. Run at the start of every session to load memory and verify rules.
---

## Load Memory

### Learned Rules
!`cat .claude/memory/learned-rules.md 2>/dev/null || echo "No learned rules yet"`

### Last Session Score
!`tail -1 .claude/memory/sessions.jsonl 2>/dev/null || echo "No session history"`

### Unresolved Violations
!`tail -5 .claude/memory/violations.jsonl 2>/dev/null || echo "No violations logged"`

## Instructions

1. Read every rule in learned-rules.md. For each rule that has a `verify:` line, run the check NOW.

2. Report results:
   - All pass → "All rules verified. Ready to work."
   - Any fail → list violations with file:line and specific fix.

3. Check session trend: if sessions.jsonl has 5+ entries, report one-line trend (corrections increasing/decreasing, common violations).

4. You are now primed. Proceed with the user's task.
