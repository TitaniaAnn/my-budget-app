# README voice — Claude Code instructions

How to write README files in this project. Self-contained — Claude Code should be able to apply this without reading other project docs.

The reader of any README in this project is another engineer (or future-you) trying to understand what something does, why it exists, and how to work with it. Their time is finite. Treat the README as documentation, not marketing.

---

## Core principles

**Third-person, dry, lowercase confidence.** The README is not the product. It describes the product.

**Past tense + active voice.** "Built X. Tested with Y." Not "X has been architected by leveraging Y."

**Evidence over adjectives.** "60→100+ members" beats "scaled significantly." "30 migrations, named after the bug they fix" beats "robust migration history." Cite line counts, table names, file paths, before/afters wherever load-bearing.

**Acknowledge trade-offs explicitly.** Don't write a README that pretends the project has no limits. "The keyword matcher takes over when the ML model isn't loaded — fine choice, just don't overclaim" is the right register.

**Specifics are what separate a real README from a generated one.** File paths, migration names, version numbers, dependency choices, line counts.

---

## Forbidden words

If these appear in a draft, replace with something concrete:

- passionate, innovative, ultimate, intuitive, powerful, seamless
- beautiful, beautifully, elegant, elegantly
- elevate, streamline, leverage, empower, unlock
- robust, scalable (unless followed by specific numbers showing scale)
- world-class, best-in-class, cutting-edge, state-of-the-art
- delightful, magical, effortless, blazing

If the rewrite removes the sentence entirely, the sentence wasn't earning its place.

## Forbidden patterns

- **Marketing-doc opener.** "Welcome to MyProject!" / "MyProject is a powerful tool that..." → replace with what it actually does in one sentence.
- **Capability lists without evidence.** A bullet list of features reads like a brochure. Show one piece of real code or one cited migration instead.
- **Decorative emoji in body text.** Domain glyphs (🏺 for pottery projects) in section headers can stay. Generic ✨🚀💪 is out.
- **Hyperbole-as-tagline.** "The fastest CSV parser in the universe." Either there are benchmark numbers, or there isn't a tagline.
- **First-person "I"** — README is third-person across all projects, including the pottery brands. First-person belongs in commit messages, not READMEs.

## Required patterns

- **Lead with what it does, in one sentence.** Optionally followed by what it deliberately doesn't do, when the contrast is informative.
- **Show one real code example early.** Not "Hello World" — a real usage from the codebase.
- **Document deliberate trade-offs as decisions, not gaps.** "No Plaid integration: deliberate compliance posture (GLBA, state breach laws). The integration enum value exists but isn't wired up."
- **Use prose for explanation, code blocks for examples, tables only when comparing 3+ items along the same axis.** Don't bullet-point things that flow as sentences.
- **Migrations get cited by name.** `004_fix_household_members_rls.sql` tells the reader what the migration is for without opening the file. Honor that pattern in prose: "see migration 004."

---

## Examples

### Bad — marketing opener + capability list

```markdown
# Awesome Pottery App

Welcome to Awesome Pottery App, the ultimate solution for managing
your pottery studio. With our intuitive interface and powerful
features, you'll track your work, manage clients, and grow your
business effortlessly.

## ✨ Features

- 🏺 Track works-in-progress
- 🔥 Log kiln firings
- 🎨 Manage glaze inventory
- 📊 Beautiful analytics
```

### Good — engineer-brand README

```markdown
# my-pottery-studio

Studio management app for ceramic artists. Tracks pieces from clay
through firing through sale, logs kiln runs and material inventory,
manages clients and commissioned work.

Flutter (mobile) + Supabase (Postgres + auth + storage). Material 3
dynamic seed-color theming, so each user picks their own primary
color — the app is theirs, including the colors.

## What it does

- Pieces table with a configurable workflow engine (stages are
  user-defined; the engine is generic).
- Kiln log: cone, atmosphere, schedule, load notes.
- Materials inventory in grams (display unit configurable per user).
- Sales history with hourly-rate-derived suggested pricing.
- Peer-to-peer sync (in progress, see migration v28).

## What it deliberately doesn't do

- No cloud-only requirement. Works offline, syncs when reachable.
- No multi-user shared studios in v1. Each tester has one studio.
- No subscription model in the beta. Pricing TBD.
```

The second version's specifics: framework choices, design philosophy behind seed coloring, migration references, explicit "doesn't do" section.

### Bad — claims without evidence

```markdown
## Why my-budget-app?

- Lightning-fast sync
- Bulletproof security
- Beautifully designed UI
- Powerful categorization
```

### Good — claims grounded in evidence

```markdown
## What's interesting under the hood

- **RLS that doesn't recurse.** Original household-membership RLS
  policy queried itself (Postgres error 42P17). Fixed via
  `SECURITY DEFINER` helper. See migration 004.
- **Categorizer is two layers.** ML model (ONNX, ~2MB, char n-gram +
  logistic regression) for high-confidence labels; keyword matcher
  takes over below threshold or when assets aren't loaded. The
  keyword fallback is load-bearing on a fresh clone.
- **Migrations named after the bug they fix.** Idempotent. The
  filename is the changelog entry.
```

---

## When in doubt

1. **Read the existing README in this repo.** If a section already exists in the project's voice, match it.
2. **Ask: would this sentence appear on a SaaS marketing site?** If yes, rewrite.
3. **Ask: does this sentence cite something specific** (file path, line number, migration name, version count, before/after)? If no, can it?
4. **Length should reflect content, not effort.** A README for a 200-line utility doesn't need 800 words. A README for a complex system can run long if every paragraph earns its place.

---

## When this doc doesn't apply

If the README is explicitly for a *public marketing landing page* (rare in this project — those go on the website, not in a repo), some softening is acceptable. But the default for any README under version control is the engineer voice above.

If the user explicitly asks for "marketing copy" or "a sales-pitch README," follow the request — but flag that it's a deliberate departure from project default voice.
