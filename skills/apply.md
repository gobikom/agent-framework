---
description: Apply a memory entry — bump tracking counters + transparency announcement (Learning Loop Stage 2)
---

# /apply — Apply a memory entry (Learning Loop Stage 2)

Mark a memory entry as "applied" — bump tracking counters + provide transparency announcement.

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

- The agent is about to perform an action that matches a memory entry's trigger
- Auto-triggered by the Action-to-Recall map defined in AGENT.md Learning Loop Stage 2 (if present)
- User explicitly asks to apply a specific memory

## Arguments

- `$ARGUMENTS` = memory entry short slug (without date prefix or `.md`), e.g. `feedback-always-confirm-before-deploy`
- If empty, ask "Which memory entry should be applied?" then suggest matches via `/recall`

## Steps

### Step 1 — Find memory entry

Memory files live under `memory/YYYY-MM/YYYY-MM-DD-{slug}.md` — use recursive search to find:

```bash
find memory -type f -name "*-$ARGUMENTS.md" -not -path "*/_template/*"
```

If multiple matches found (e.g., refined versions), pick the latest by date prefix. Read the matched file.

### Step 2 — Bump metadata

Update YAML frontmatter using the Edit tool:

```yaml
applied_count: {old + 1}
last_applied: {YYYY-MM-DD today}
last_context: "{short text — what the agent is applying this to right now}"
```

Preserve all other metadata fields exactly.

### Step 3 — Announce transparency (CRITICAL)

The agent MUST announce in its reply before performing the actual action. Use this template:

```
({AGENT_NAME} recall: `{memory-name}` — {rule summary} -> applying: {action} {short reason})
```

Example:
```
(Atlas recall: `feedback-always-confirm-before-deploy` — never deploy without explicit user confirmation -> applying: will ask for deploy confirmation before proceeding)
```

If PERSONA_PARTICLE is set, incorporate it naturally into the announcement.

### Step 4 — After action, observe verification

After performing the action, observe the user's response:
- If user **confirms or does not correct** -> set `verified_by_user: yes` in frontmatter
- If user **corrects or refines** -> set `verified_by_user: no` + update memory body via `/remember` + add Change Log entry
- If **no observable reaction** (conversation ended, topic changed) -> leave as `verified_by_user: pending` (resolved in next `/audit`)

### Step 5 — Add Change Log entry

In the memory file, append to the Change Log section:
```
- {YYYY-MM-DD}: applied — {short context}
```

## Output

Report concisely:
```
Applied: {memory-name}
   applied_count: {N-1} -> {N}
   last_context: "{text}"

Announcement to use in your next reply:
> ({AGENT_NAME} recall: {memory-name} — ...)
```

## Rules

- **Never bump count without performing the actual action** — fake metrics corrupt Stage 5 promotion decisions
- **Never skip the transparency announcement** — it is the core mechanism of Stage 2
- **If applied to wrong context** (wrong memory for the situation) -> revert metadata + do not count
- **Preserve all other frontmatter fields** when editing — only change `applied_count`, `last_applied`, `last_context`

## See also

- `docs/LEARNING-LOOP.md` Stage 2 (APPLY) — if exists in repo
- `/recall` — find memory to apply
- `/audit` — review applied lessons end-of-session
