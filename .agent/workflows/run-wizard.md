---
description: How to run the NeuralClaw Setup Wizard
---

# Running the NeuralClaw Setup Wizard

Every time you need to run the wizard, follow these steps:

// turbo-all

1. Kill all existing instances of the wizard:
```
pkill -f NeuralClawSetup 2>/dev/null
```

2. Wait briefly for processes to terminate, then build and run:
```
sleep 0.5 && cd /Users/nick/Desktop/NeuralClawSetup && swift run 2>&1
```

**IMPORTANT**: Never skip step 1. Always kill old instances before launching a new one to avoid multiple windows stacking up.
