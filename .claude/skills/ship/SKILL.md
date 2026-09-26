---
name: ship
description: Run analyzer, run tests, scan for secrets, then create focused commits and push.
---
1. Run static analysis / linter for this project
2. Run full test suite; abort if anything fails
3. Scan staged changes for secrets (.env, API keys, tokens)
4. Group changes into focused single-purpose commits with conventional commit messages
5. Push to current branch
