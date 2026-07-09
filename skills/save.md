---
description: Save session context as a memory checkpoint — no audit, no git commit/push
---

# /save — Save session context (checkpoint, no audit/commit/push)

Save the current session's context to memory so it can be resumed later. This is the lightweight half of `/handoff` — it writes the same session-memory shape but skips Stage 4 audit and skips git commit/push. Safe to call repeatedly within a session.

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

- Mid-session checkpoint — you want a resumable snapshot without ending the session
- Before a risky operation, so context survives even if the session is lost
- Called internally by `/handoff` (which wraps `/save` and then adds audit + commit + push)
- User says "save", "checkpoint", "save progress" (without "wrap up" / "done" / "bye" — those mean `/handoff`)

## Steps

### Step 1 — Summarize the session

Cover:
- What was accomplished
- Key decisions made
- Current state (which phase, project, feature — whatever is relevant)
- Open questions / blockers
- Next steps (be specific: file paths, IDs, URLs)

### Step 2 — Create session memory file

**Folder**: `memory/{YYYY-MM}/`
**Filename**: `{YYYY-MM-DD}-session-{short-slug}.md`

Example: `memory/2026-07/2026-07-06-session-auth-refactor-wip.md`

```markdown
---
name: session-{YYYY-MM-DD}-{slug}
aliases:
  - session-{YYYY-MM-DD}-{slug}
description: "{one-line summary}"
metadata:
  type: session
  category: handoff
  status: active
  date: {YYYY-MM-DD}
  project: {project name if applicable}
---

# Session Checkpoint — {date} — {short title}

## Session Summary

### Accomplished
- {what was done}

### Key Decisions
- {decisions made, with reasoning}

### Current State
- Project/Feature: {name}
- Status: {in-progress / blocked / complete}

### Open Questions
- {unresolved items}

### Next Steps
- {what to do next — specific file paths, URLs, IDs}
```

If called multiple times in one session, create a **new** dated file each time (do not overwrite prior checkpoints) — the filename slug should reflect progress at that point (e.g. `-wip`, `-checkpoint-2`).

### Step 3 — Update MEMORY.md

Add a session entry under `## Session History` in `memory/MEMORY.md` (create the section if missing). Use an Obsidian wikilink:

```
- [[session-{YYYY-MM-DD}-{slug}]] -- {hook}
```

### Step 4 — Overwrite latest-handoff.md

Overwrite `memory/latest-handoff.md` with the same content written in Step 2. This lets `/resume` read one file for quick context regardless of how many checkpoints exist for the session.

### Step 5 — Confirm to user

```
Saved: session-{YYYY-MM-DD}-{slug}
   -> memory/{YYYY-MM}/{date}-session-{slug}.md
   -> MEMORY.md: indexed under Session History
   -> latest-handoff.md: overwritten

No git operations performed — run /handoff to audit + commit + push.
```

## Rules

- **NO audit** — that is `/handoff`'s job (Stage 4)
- **NO git commit/push** — that is `/handoff`'s job
- **Safe to call multiple times per session** — each call creates a new dated file; `latest-handoff.md` always reflects the most recent call
- **Always overwrite `latest-handoff.md`** even though the dated file is new — it is the single quick-access pointer

## See also

- `/handoff` — full end-of-session flow: audit + `/save`'s Steps 2-5 + commit + push
- `/resume` — next session loads `latest-handoff.md`
- `/audit` — standalone Stage 4 audit (not run by `/save`)
