---
description: Memory health audit — scan all entries, report applied/corrected/missed/stale/new (Learning Loop Stage 4)
---

# /audit — Memory health audit (Learning Loop Stage 4)

Scan all memory entries and report what was applied, corrected, missed, stale, or new this session.

## Self-Configuration (run once per session)

Read the repo's `CLAUDE.md` to extract:
- **AGENT_NAME**: from Identity table -> Name field
- **AGENT_ID**: from Identity table -> Agent ID field
- **HUMAN_NAME**: from "Workspace Human" section
- **LANGUAGE**: from Identity table or default English
- **PERSONA_PARTICLE**: from Persona section (speech ending particle, if any)

Use these values throughout. If CLAUDE.md is missing, use defaults:
- AGENT_NAME = repo directory name
- HUMAN_NAME = "human"

## When to Use

- **Auto** — invoked by `/handoff` before saving session
- **Manual** — anytime user wants to review memory health
- **Periodic** — recommend every 5-10 sessions

## Arguments

- `$ARGUMENTS` — optional filter: `since:YYYY-MM-DD` or `category:tooling`
- Empty — audit current session activity

## Steps

### Step 1 — Scan memory directory (recursive)

Read all `memory/**/*.md` files, recursing into `YYYY-MM/` subfolders.
Skip: `MEMORY.md`, `_promotions.md`, `_template/*`, `latest-handoff.md`.

```bash
find memory -type f -name "*.md" \
  -not -path "*/_template/*" \
  -not -name "MEMORY.md" \
  -not -name "_promotions.md" \
  -not -name "latest-handoff.md"
```

For each file, parse YAML frontmatter to extract:
- `name`, `type`, `applied_count`, `last_applied`, `verified_by_user`, `promoted_to`, `status`

### Step 2 — Categorize into 5 lists

#### Applied & Verified (this session)
- Entries where `last_applied = today` AND `verified_by_user = yes`

#### Applied & Corrected (this session)
- Entries where `last_applied = today` AND `verified_by_user = no`
- Note: was the body refined? If not, flag it.

#### Should Have Been Applied (agent missed)
- The agent introspects: in this session, were there moments where a memory entry's trigger matched but was not applied?
- This requires judgment — not strictly parseable from files
- Output: list any candidates with reasoning

#### Stale (>= 30 days unreferenced)
- Entries where `last_applied` is null OR `last_applied` is more than 30 days ago
- Exclude entries with `status: superseded` or `status: archived`
- Suggest: "Review relevance? Archive? Supersede?"

#### New This Session
- Entries where `date = today`

### Step 3 — Check promotion candidates

For each `feedback` / `pattern` entry, check Stage 5 criteria:
- `applied_count >= 3`
- `verified_by_user = yes` consistently
- `promoted_to = null` (not yet promoted)
- Applied across >= 2 different `last_context` patterns (check Change Log)

If matches found, list them as **promotion candidates** and suggest `/promote {name}`.

### Step 4 — Output report

```markdown
## Memory Audit — {date}

### Applied & Verified ({N})
- `{name}` — applied {N}x total, last context: "{text}"

### Applied & Corrected ({N})
- `{name}` — refined: {what changed}

### Possibly Missed ({N})
- `{name}` — trigger matched at: {moment}, but not recalled

### Stale ({N})
- `{name}` — last applied: {date or never} -> review?

### New ({N})
- `{name}` — captured from "{phrase}"

### Ready to Promote ({N})
- `{name}` — applied {N}x across {M} contexts, all verified
  -> suggest: /promote {name}

### Summary
- Total active memories: {N}
- Health score: {Applied & Verified / Total Active}
```

### Step 5 — Recommendations

At the end of the report, suggest concrete actions:
- "Promote {memory}? It has met all criteria." (if candidates exist)
- "Memory {name} has not been used in {N} days — archive?"
- "Trigger phrase for {name} may be too narrow — refine?"

## Rules

- Audit is **read-only by default** — propose changes, ask before executing
- If invoked via `/handoff`, include audit report inline in handoff document
- Don't overwhelm — limit each category to top 10 entries; suggest deeper review if more exist

## See also

- `docs/LEARNING-LOOP.md` Stage 4 (EVOLVE) — if exists in repo
- `/promote` — execute promotion for ready candidates
- `/handoff` — auto-runs audit
