---
description: Promote a memory entry to CLAUDE.md Hard Rule after meeting criteria (Learning Loop Stage 5)
---

# /promote — Promote memory entry to CLAUDE.md Hard Rule (Learning Loop Stage 5)

Verify a memory entry meets promotion criteria, insert into CLAUDE.md as a Hard Rule, and update tracking files.

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

- Agent suggests promotion in `/audit` report and user agrees
- User manually requests promotion of a specific entry
- Auto-suggest after `applied_count` crosses threshold

## Arguments

- `$ARGUMENTS` = memory entry short slug (e.g. `feedback-always-confirm-before-deploy`)
- If empty, ask user which memory to promote (suggest candidates via `/audit`)

## Steps

### Step 1 — Find and verify criteria

Find the memory file (under `memory/YYYY-MM/`):

```bash
find memory -type f -name "*-$ARGUMENTS.md" -not -path "*/_template/*"
```

Read the matched file and check ALL these criteria:

#### Standard criteria (all must pass)

- `applied_count >= 3`
- `verified_by_user = yes` (consistently — check Change Log for any "no" entries)
- `promoted_to = null` (not already promoted)
- `status = active`
- Applied across >= 2 distinct `last_context` patterns (check Change Log)

#### Fast-track criteria (rare — use only with user explicit approval)

- Rule is self-evident (failure causes obvious damage)
- User explicitly signals via leading question or direct request
- Cost-benefit clearly favors promotion

If standard criteria not met, output reasoning and ask user:
- "Criteria not fully met — would you like to fast-track?" (explain what is missing)
- Or "Needs {N} more applications before eligible"

### Step 2 — Decide CLAUDE.md target section

Read `CLAUDE.md` sections — pick the section that best matches the memory's category.

General mapping (adapt to actual CLAUDE.md structure):

| Memory category | Likely CLAUDE.md target |
|-----------------|-------------------------|
| `tooling` | Tools / Tooling section |
| `communication` | Interaction Patterns or Phrase Triggers |
| `workflow` | Workflow section |
| `architecture` | Architecture / Technical section |
| `testing` | Testing / QA section |
| Other | Ask user — propose new section if needed |

If the repo's CLAUDE.md has a `## Philosophy (Hard Rules)` section, that is the default target for general rules.

### Step 3 — Draft Hard Rule text

From memory body, distill to **1-3 lines** suitable for CLAUDE.md (CLAUDE.md must stay concise — full content lives in the memory entry):

```markdown
- {Rule one-liner} — see [[{memory-name}]] for full reasoning
```

Or for table-style sections:
```markdown
| {column 1} | {column 2} |
```

**Show draft to user before inserting. Never auto-insert.**

### Step 4 — Insert into CLAUDE.md

Use the Edit tool to add the Hard Rule in the chosen section.
- Preserve surrounding content
- Add at a logical position (alphabetical / topical / end of section)
- Include `[[memory-name]]` link back to full memory entry

### Step 5 — Update memory entry

Use the Edit tool to update the memory file's YAML frontmatter:

```yaml
status: promoted
promoted_to: "CLAUDE.md#{section-anchor}"
```

Add Change Log entry:
```
- {YYYY-MM-DD}: promoted to CLAUDE.md#{section} — criteria met (applied {N}x across {M} contexts)
```

### Step 6 — Update _promotions.md log

Append a row to the active promotions table in `memory/_promotions.md` (create file if missing). Use Obsidian wikilink:

```markdown
| {YYYY-MM-DD} | [[{slug}]] | {applied_count} | {contexts summary} | `CLAUDE.md#{section}` | {short reason} |
```

If `_promotions.md` does not exist, create it:

```markdown
# Promotion Log

Tracks memory entries promoted to CLAUDE.md Hard Rules.

## Active Promotions

| Date | Memory | Applied | Contexts | Target | Reason |
|------|--------|---------|----------|--------|--------|
```

### Step 7 — Update MEMORY.md

Find the entry in `memory/MEMORY.md` and append `**promoted to CLAUDE.md**` marker.

### Step 8 — Confirm to user

```
Promoted: {memory-name}
   -> CLAUDE.md#{section}
   -> memory entry: status=promoted, promoted_to=CLAUDE.md#{section}
   -> _promotions.md: logged

Memory entry remains as audit trail.
```

## Demotion (rare — if a promoted rule becomes wrong)

If user requests demotion:
1. Remove rule from CLAUDE.md
2. Update memory: `status: active`, `promoted_to: null`, add Change Log: `demoted_at: {date}, demotion_reason: {text}`
3. Move row in `_promotions.md` to a "Demotions / Reverted" section (create if needed)

## Rules

- **Never auto-promote without user confirmation** — promotion is a governance decision
- **Always show CLAUDE.md draft before inserting** — give user a chance to refine wording
- **Keep memory entry forever** — it is the audit trail. Don't delete after promotion.
- **CLAUDE.md must stay concise** — distill aggressively. Full content lives in the memory entry.

## See also

- `docs/LEARNING-LOOP.md` Stage 5 (PROMOTE) — if exists in repo
- `memory/_promotions.md` — promotion log
- `/audit` — find promotion candidates
- `/apply` — increment `applied_count` (prerequisite for promotion)
