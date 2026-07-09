---
description: Save something important to agent memory using the Learning Loop schema (Stage 1 — CAPTURE)
---

# /remember — Save to local memory

Save something important to this agent's local memory using the Learning Loop schema.

## Self-Configuration (run once per session)

Read the repo's `AGENT.md` (or `CLAUDE.md` for backward compatibility) to extract:
- **AGENT_NAME**: from Identity table -> Name field (e.g. "KK", "PSak", "Atlas")
- **AGENT_ID**: from Identity table -> Agent ID field (e.g. "kk", "psak", "atlas")
- **HUMAN_NAME**: from "Workspace Human" section (the person operating this workspace)
- **LANGUAGE**: from Identity table or default English
- **PERSONA_PARTICLE**: from Persona section (speech ending particle, if any — e.g. a cat agent might end with a specific word)

Use these values throughout. If neither file is found or has no Identity table, use defaults:
- AGENT_NAME = repo directory name
- HUMAN_NAME = "human"
- LANGUAGE = English
- PERSONA_PARTICLE = (none)

## When to Use

- `$ARGUMENTS` provided — save that content
- Empty — ask user what to remember
- **Auto-triggered** by Phrase Triggers defined in AGENT.md "Proactive Memory" table (if present) — agent saves without being asked

### Common Phrase Triggers (detect and auto-save)

| User Phrase Pattern | Signal | Action |
|---------------------|--------|--------|
| "why / why not / why didn't you" | Agent missed an assumption | save `feedback` immediately |
| "should you / shouldn't you" (leading question) | User teaching through questions | save `feedback` — high priority |
| "missing / forgot / should have" | Agent missed a proactive step | save `lesson` |
| "I already told you / told you before / again" | Lesson not applied from prior session | upgrade existing `feedback` priority |
| "instead of / you should" + alternative | User proposing better approach | save `pattern` or refine `feedback` |
| "perfect / exactly / yes / love it" | Approach works | save positive `pattern` |

## Steps

### Step 1 — Determine type

Pick ONE based on content:

| `type:` | When |
|---------|------|
| `feedback` | User corrected the agent, or sent a leading question, or signaled a preference |
| `pattern` | Reusable approach that worked — a workflow pattern, code pattern, communication pattern |
| `lesson` | Mistake to avoid, friction point, what NOT to do |
| `decision` | Key decision made during work (with reasoning) |
| `session` | Session checkpoint or handoff note (use `/handoff` instead usually) |
| `reference` | Pointer to external system (issue tracker, channel, dashboard URL, API endpoint) |
| `project` | Project-level fact (who's doing what, deadlines, motivation, stakeholders) |

### Step 2 — Pick template

- `feedback`, `pattern` -> use `memory/_template/<type>-template.md` as base (if exists)
- Other types -> use simpler frontmatter (no Learning Loop tracking required, but encouraged for feedback-like content)
- If no templates exist in `memory/_template/`, use the schemas defined in Step 3 below

### Step 3 — Create file

**Folder**: `memory/{YYYY-MM}/` (current year-month — create if missing)
**Filename**: `{YYYY-MM-DD}-{type}-{kebab-case-slug}.md`

Example: `memory/2026-07/2026-07-06-feedback-always-confirm-before-deploy.md`

For `feedback` / `pattern` types, use this full schema:

```markdown
---
name: {type}-{kebab-case-slug}
aliases:
  - {type}-{kebab-case-slug}     # short slug — keeps [[wikilinks]] working
description: "{one-line summary — used for relevance search}"
metadata:
  type: {feedback|pattern|lesson|decision|session|reference|project}
  category: "{topic — e.g., tooling, communication, workflow, architecture, testing}"
  status: active
  date: {YYYY-MM-DD today}
  # Learning Loop tracking — see docs/LEARNING-LOOP.md
  applied_count: 0
  last_applied: null
  last_context: null
  verified_by_user: pending  # yes | no | pending
  promoted_to: null          # null | "AGENT.md#section"
---

# {Title}

## Rule / Pattern / Decision
{Core content — one-sentence ideally}

## Why
{Reason — past incident, user preference. Cite original phrase if possible.}

## How to apply
{Concrete trigger + action}

## Anti-patterns
- {what NOT to do}

## Trigger
- {situation that fires this lesson}

## Related
- [[other-memory-entry]]

## Change Log
- {YYYY-MM-DD}: created — captured from "{original phrase/scenario}"
```

For other types (lesson/decision/session/reference/project) — use simpler frontmatter:

```markdown
---
name: {type}-{slug}
aliases:
  - {type}-{slug}
description: "{summary}"
metadata:
  type: {type}
  category: "{topic}"
  status: active
  date: {YYYY-MM-DD}
---

# {Title}

{content}

## Context / Why
{reasoning so future sessions understand}
```

### Step 4 — Update MEMORY.md index

Read `memory/MEMORY.md`. Add a one-line entry under the matching section header. Create the section if it does not exist yet.

Suggested section mapping:

| Memory type | Index section |
|-------------|---------------|
| `decision` | `## Decisions` |
| `pattern` | `## Patterns` |
| `feedback` | `## Feedback` |
| `lesson` | `## Lessons Learned` |
| `session` | `## Session History` |
| `reference` | `## References` |
| `project` | `## Projects` |

Format: `- [[{type}-{slug}]] -- {one-line hook}` (Obsidian wikilink resolves via `aliases`)

Add `**promoted to AGENT.md**` marker if `promoted_to` is set.

### Step 4.5 — Proactive skill evolution detection

When saving a `pattern` type entry, check if this could become a reusable skill:

1. Count actionable steps in the "How to apply" section being saved
2. If >= 3 steps:
   - Search existing memories for similar patterns: `grep -rli "category: {same-category}" memory/ --include="*.md"`
   - For each match with `type: pattern` and `applied_count >= 2`, check if "How to apply" has overlapping step keywords
   - If a similar multi-step pattern is found, suggest proactively (advisory only — never auto-create):
     ```
     This looks like a repeated workflow. Combined with [[existing-pattern]],
     this could become a reusable skill.
     Want me to draft a skill? (run /evolve {suggested-name})
     ```
3. If < 3 steps: skip silently (it's a rule, not a workflow)

The keyword overlap check is a hint, not a gate — false positives are acceptable because the user decides. False negatives are preferred over false auto-creation.

### Step 5 — Link related memories

If this memory relates to an existing one, add `[[name]]` link in both directions (in the Related section of each).

### Step 6 — Confirm what was saved

Report to user:
- Filename + type + category
- Note: `applied_count` starts at 0 — will be bumped by `/apply` when used

## Rules

- **One memory per file** — don't append to existing memory files
- **Check for duplicates** in MEMORY.md before creating — update existing if same topic
- **MEMORY.md entries < 150 chars** (index file, keep concise)
- **Language**: match content language (use the language from AGENT.md Identity, or match whatever language the user used)
- **Wikilinks** use `[[name]]` (Obsidian compatible) — both in index AND inline body. Add `aliases` in frontmatter so `[[short-slug]]` resolves correctly even when filename has date prefix.
- **Frontmatter** must be valid YAML — quote strings with `:` or special chars
- **Status default** = `active`. Never delete old memory — set `status: superseded` + `superseded_by: "[[new-memory]]"`
- **Date** = today in YYYY-MM-DD (convert relative dates like "Thursday" to absolute)

## See also

- `docs/LEARNING-LOOP.md` — full architecture (if exists in repo)
- `memory/_template/feedback-template.md` — feedback schema
- `memory/_template/pattern-template.md` — pattern schema
- `/apply` — use a memory entry (Stage 2)
- `/audit` — review memory health (Stage 4)
- `/promote` — promote memory to AGENT.md Hard Rule (Stage 5)
- `/evolve` — graduate workflow pattern into executable skill (Stage 6)
