---
description: Mark a memory entry superseded by a newer one — never deletes, always links
---

# /supersede — Mark a memory entry superseded

Mark an old memory entry as replaced by a newer one. Old entries are never deleted — only their `status` changes, and a link is added in both directions.

## Self-Configuration (run once per session)

Read the repo's `AGENT.md` (fallback: `CLAUDE.md`, for repos not yet migrated to the tool-neutral identity file) to extract:
- **AGENT_NAME**: from Identity table -> Name field
- **AGENT_ID**: from Identity table -> Agent ID field
- **HUMAN_NAME**: from "Workspace Human" section
- **LANGUAGE**: from Identity table or default English
- **PERSONA_PARTICLE**: from Persona section (speech ending particle, if any)

Use these values throughout. If neither file exists, use defaults:
- AGENT_NAME = repo directory name
- HUMAN_NAME = "human"

## When to Use

- A memory entry has been replaced by a refined or corrected version
- `/remember` creates a new entry that clearly obsoletes an existing one
- User explicitly says "supersede X with Y" or "the old rule about X is wrong now"

## Arguments

- `$ARGUMENTS` = `<old-slug> <new-slug>` (space-separated)
- If missing either slug, ask the user for both before proceeding

## Steps

### Step 1 — Parse arguments

Split `$ARGUMENTS` into `old_slug` and `new_slug`. If parsing is ambiguous, ask the user to clarify which is being replaced and which is the replacement.

### Step 2 — Find both memory files

```bash
find memory -type f -name "*-$old_slug.md" -not -path "*/_template/*"
find memory -type f -name "*-$new_slug.md" -not -path "*/_template/*"
```

### Step 3 — Verify both exist

If either file is not found:
- Error clearly which slug failed
- Suggest close matches via `/recall {slug}`
- Stop — do not partially update

### Step 4 — Check for prior graduation (warn, don't block)

Read the old entry's frontmatter:
- If `promoted_to` is set (non-null) -> warn: "This memory was promoted to AGENT.md — consider updating or removing the corresponding rule."
- If `evolved_to` is set (non-null) -> warn: "This memory was evolved to a skill — the skill may need updating."

Show the warning(s), then continue (these are advisory, not blocking).

### Step 5 — Update old entry

Edit the old entry's YAML frontmatter:

```yaml
status: superseded
superseded_by: "[[{new-slug}]]"
```

Add a Change Log entry:
```
- {YYYY-MM-DD}: superseded by [[{new-slug}]]
```

### Step 6 — Update new entry

Edit the new entry's body to add (or append to) a `## Supersedes` section:

```markdown
## Supersedes
- [[{old-slug}]]
```

### Step 7 — Update MEMORY.md

Find the old entry's index line in `memory/MEMORY.md` and add a `⚠️` marker (per the index legend already defined at the top of the file).

### Step 8 — Confirm to user

```
Superseded: {old-slug} -> {new-slug}
   -> {old-slug}: status=superseded, superseded_by=[[{new-slug}]]
   -> {new-slug}: Supersedes section updated
   -> MEMORY.md: ⚠️ marker added
```

## Rules

- **Old entry is NEVER deleted** — status change only, it remains the audit trail
- **Warn (don't block)** if the old entry was promoted or evolved — those artifacts may need separate manual follow-up
- **Both files must exist** before any edit is made — no partial updates

## See also

- `/remember` — creates the new memory that may need to supersede an old one
- `/archive` — simpler status change for stale entries with no replacement
- `/recall` — find candidate slugs when the exact one is unknown
- `/promote`, `/evolve` — graduation paths that `/supersede` checks for and warns about
