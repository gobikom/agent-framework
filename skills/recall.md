---
description: Search agent local memory for relevant context
---

# /recall — Search local memory

Search this agent's local memory for relevant context.

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

- User asks about past decisions, patterns, or lessons
- Before performing an action that has a matching memory category (see CLAUDE.md Learning Loop Stage 2 if present)
- User says "what did we decide about...", "how did we handle...", "remember when..."
- Empty `$ARGUMENTS` — show the full MEMORY.md index

## Steps

### Step 1 — Get search query

Take the search query from `$ARGUMENTS`. If empty, show the full `memory/MEMORY.md` index and stop.

### Step 2 — Read index

Read `memory/MEMORY.md` to scan the index.

### Step 3 — Search strategy (multi-pass, recursive)

Memory files live under `memory/YYYY-MM/` subfolders. Run these searches in order, stopping when you have sufficient results:

1. **Index grep**: Search for keywords in `memory/MEMORY.md` index lines
2. **Full-text grep**: Search recursively across all memory entries:
   ```bash
   grep -ri "<query>" memory/ --include="*.md" --exclude-dir="_template"
   ```
3. **Type match**: If `$ARGUMENTS` matches a `type` value (`decision`, `pattern`, `feedback`, `lesson`, `session`, `reference`, `project`): grep `type: <value>` in frontmatter
4. **Category match**: If `$ARGUMENTS` looks like a category (e.g. `tooling`, `communication`, `workflow`, `architecture`): grep `category: <value>`
5. **Slug match**: If `$ARGUMENTS` looks like a slug (e.g. `feedback-always-confirm`): find by `name:` or `aliases:` in frontmatter, or by filename matching `*-{slug}.md`

### Step 4 — Read and present

Read the matched memory files and present a summary. If no matches found, say so clearly.

### Step 5 — Filter superseded

Skip files with `status: superseded` unless the user explicitly asks for history.

## Output Format

For each match:
```
**[[slug]]** (type, category, date, status)
applied_count: N | verified_by_user: yes/no/pending | promoted_to: ...
> content summary
> Related: [[other-memory-slug]]
File: memory/YYYY-MM/YYYY-MM-DD-{slug}.md
```

## Rules

- **Read actual files**, don't guess from filenames alone
- **Show max 5 results** unless user asks for more
- **Most recent first** within each category
- **Show `Related:` links** so user can follow the knowledge graph
- **Superseded memories**: show only if user asks "history" or "all"

## See also

- `/remember` — save new memory (Stage 1)
- `/apply` — use a memory entry (Stage 2)
- `/audit` — review all memories (Stage 4)
