---
description: Archive a stale or no-longer-relevant memory entry — never deletes
---

# /archive — Archive a memory entry

Mark a memory entry as archived. Simpler than `/supersede` — there is no replacement entry, just a status change and index cleanup. Archived entries are never deleted.

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

- `/audit` flags an entry as stale (no `applied_count` bump in >= 30 days) and user agrees it is no longer relevant
- User explicitly says "archive X" or "we don't need this rule anymore"
- A memory describes a workflow/tool that has been removed from the project

## Arguments

- `$ARGUMENTS` = memory slug, optionally followed by a reason: `<slug> [reason...]`
- If empty, ask the user which memory to archive (suggest stale candidates via `/audit`)

## Steps

### Step 1 — Find memory file

```bash
find memory -type f -name "*-$ARGUMENTS.md" -not -path "*/_template/*"
```

If not found, error clearly and suggest close matches via `/recall {slug}`.

### Step 2 — Update frontmatter

Edit the memory file's YAML frontmatter:

```yaml
status: archived
```

### Step 3 — Add Change Log entry

```
- {YYYY-MM-DD}: archived — {reason if provided, else "no longer relevant"}
```

### Step 4 — Update MEMORY.md

Find the entry's index line in `memory/MEMORY.md`:
- Move it to the bottom of its section
- Mark it with a `(archived)` suffix (or strikethrough, matching whatever convention the repo's MEMORY.md already uses)

### Step 5 — Confirm to user

```
Archived: {memory-name}
   -> status=archived
   -> MEMORY.md: moved to bottom of {section}, marked (archived)

Entry remains on disk — excluded from /recall by default.
```

## Rules

- **Never deletes the file** — archiving is a status change only, the entry stays as an audit trail
- **Archived memories are excluded from `/recall` by default** (see `recall.md` Step 5 — same filtering rule applied to `superseded`, extended to `archived`)
- **Reversible** — to un-archive, edit `status` back to `active` and update the Change Log

## See also

- `/supersede` — same pattern, but with a replacement entry
- `/audit` — surfaces stale candidates for archiving
- `/recall` — filters out archived entries unless explicitly asked for history
