---
description: Memory health audit — scan all entries, report applied/corrected/missed/stale/new (Learning Loop Stage 4)
---

# /audit — Memory health audit (Learning Loop Stage 4)

Scan all memory entries and report what was applied, corrected, missed, stale, or new this session.

## Self-Configuration (run once per session)

Read the repo's `AGENT.md` (or `CLAUDE.md` for backward compatibility) to extract:
- **AGENT_NAME**: from Identity table -> Name field
- **AGENT_ID**: from Identity table -> Agent ID field
- **HUMAN_NAME**: from "Workspace Human" section
- **LANGUAGE**: from Identity table or default English
- **PERSONA_PARTICLE**: from Persona section (speech ending particle, if any)

Use these values throughout. If neither file is found, use defaults:
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

### Step 3.5 — Check skill evolution candidates

For each `pattern` / `feedback` entry with `applied_count >= evolution_threshold` (read from `.agent-config.yaml`, default 3):

1. Read the file body; count actionable steps in the "How to apply" section (numbered items `1.`, `2.`, `3.` or `### Step N` subsections — exclude examples, notes, and content under other headings)
2. If >= 3 steps AND `evolved_to = null` AND applied across >= 2 distinct contexts → **skill evolution candidate**
3. Don't double-count: if an entry qualifies for both promotion (Step 3) and evolution, prefer evolution (workflows should become skills, not rules)

Output section: `### Ready to Evolve (skills) ({N})`
Format: `- {name} — applied {N}x across {M} contexts, {S} steps -> suggest: /evolve {name}`

### Step 3.6 — Check skill improvement candidates

Search for `feedback` entries whose `category` matches the name of an existing skill file in `skills/` directory:

```bash
ls skills/*.md | sed 's|skills/||;s|\.md||'
```

If such feedback has `applied_count >= 3` and `verified_by_user = yes` → **skill improvement candidate** (the skill may need updating based on repeated corrections).

Output section: `### Skill Improvements Suggested ({N})`
Format: `- skill:{name} has {N} verified corrections -> suggest: update skill and bump version`

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

### Ready to Evolve (skills) ({N})
- `{name}` — applied {N}x across {M} contexts, {S} steps
  -> suggest: /evolve {name}

### Skill Improvements Suggested ({N})
- skill:`{name}` has {N} verified corrections
  -> suggest: update skill and bump version

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

- `docs/LEARNING-LOOP.md` Stage 4 (EVOLVE) and Stage 6 (EVOLVE SKILL) — if exists in repo
- `/promote` — execute promotion for ready candidates
- `/evolve` — graduate workflow patterns into executable skills
- `/handoff` — auto-runs audit
