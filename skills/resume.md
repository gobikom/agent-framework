---
description: Pull latest from remote + load last session context to resume work
---

# /resume — Pull latest + Load last session context

Resume from the last session: **pull latest from remote first** (so the agent doesn't work on stale state), then read the most recent handoff.

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

- **Every new session** — this should be the first command run
- After switching machines or contexts
- When resuming after a break
- User says "resume", "where were we", "continue", "what were we doing"

## Steps

### Step 0 — Pull latest from remote

Before reading any local handoff, sync with remote so the agent doesn't work on stale state.

#### 0.1 Pre-flight checks

```bash
git rev-parse --is-inside-work-tree 2>/dev/null   # in repo?
git remote -v                                      # has remote?
git status --porcelain                             # dirty?
git rev-parse --abbrev-ref HEAD                    # branch
```

**Skip pull if**:
- Not in git repo -> "Not a git repo — skipping pull"
- No remote configured -> "No remote configured — skipping pull" (skip silently for local-only repos)
- On detached HEAD -> "On detached HEAD — checkout a branch first"

#### 0.2 Detect divergence

```bash
git fetch origin --quiet
BR=$(git rev-parse --abbrev-ref HEAD)
git rev-list --left-right --count "HEAD...origin/$BR" 2>/dev/null
# Output: "{local_ahead}\t{remote_ahead}"
```

**Branch states**:
- `0  0` -> up to date -> skip pull silently
- `0  N` (remote ahead) -> fast-forward pull
- `N  0` (local ahead) -> no pull needed (remote will get it on next `/handoff`)
- `M  N` (diverged) -> warn + ask user

#### 0.3 Handle each state

**Clean + remote ahead** (fast-forward):
```bash
git pull --ff-only origin "$BR"
```
Report: "Pulled {N} new commits from remote"

**Dirty + remote ahead**:
- Warn: "Local has uncommitted changes ({N} files) + remote is ahead by {N} commits"
- Ask user to choose:
  - "A. Stash -> pull -> restore" (safest)
  - "B. Pull without stash" (risky — might conflict)
  - "C. Skip pull — proceed with local state"
- If A -> `git stash push -m "auto-stash-resume-$(date +%s)"` -> `git pull --ff-only` -> `git stash pop`

**Diverged** (both ahead):
- Warn: "Diverged — local +{N} commits, remote +{M} commits"
- Ask user to choose:
  - "A. Rebase local on top of remote" (`git pull --rebase`)
  - "B. Merge remote into local" (`git pull --no-rebase`)
  - "C. Skip — handle manually"
- NEVER auto-pick — user must choose (history-rewriting action)

**Conflict during pull**:
- Stop immediately
- Report: "Pull caused conflict in {files} — resolve before proceeding"
- Show conflicting files: `git diff --name-only --diff-filter=U`

### Step 1 — Read latest handoff

1. Check if `memory/latest-handoff.md` exists.
   - If YES -> read it and summarize what was done last time + next steps.
   - If NO -> check `memory/MEMORY.md` under `## Session History` for the most recent entry. Read that file.
   - If nothing found -> "No session history found — starting fresh."

### Step 2 — Present brief summary

- Pull result (pulled N commits / already up to date / skipped — reason)
- Last session date
- What was accomplished
- Where work left off (status, context)
- Next steps to resume

### Step 3 — Ask continuation

Ask if the user wants to continue from where things left off, or start fresh.

## Rules

- **Always read the actual file**, don't guess from memory
- **Keep the summary concise** — 5-8 lines max
- **Use the agent's persona** (from AGENT.md Persona section) in the summary
- **Pull only if clean local + fast-forward possible** — never silently merge/rebase
- **Never force-pull** (`git reset --hard origin/<branch>`) — would lose local work
- **If pull fails or conflicts** -> stop + ask user (don't try clever recovery)
- **Skip pull silently** if no remote configured (don't warn every time — common for new local repos)

## See also

- `/handoff` — end-of-session counterpart (commits + pushes)
- `memory/latest-handoff.md` — file being read in Step 1
