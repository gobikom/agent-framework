---
description: Save session context + Learning Loop audit + Git commit/push (end-of-session)
---

# /handoff — Save session context + Learning Loop audit + Git commit/push

Save current session so the next one can resume, run Stage 4 (EVOLVE) audit, AND commit+push all session changes to remote (so other machines/sessions stay in sync).

## Self-Configuration (run once per session)

Read the repo's `CLAUDE.md` to extract:
- **AGENT_NAME**: from Identity table -> Name field
- **AGENT_ID**: from Identity table -> Agent ID field
- **HUMAN_NAME**: from "Workspace Human" section
- **LANGUAGE**: from Identity table or default English
- **PERSONA_PARTICLE**: from Persona section (speech ending particle, if any)
- **AGENT_ROLE**: from Identity table -> Role field (used in Co-Authored-By)

Use these values throughout. If CLAUDE.md is missing, use defaults:
- AGENT_NAME = repo directory name
- AGENT_ROLE = "Agent"
- HUMAN_NAME = "human"

## When to Use

- End of every work session
- User says "bye", "done", "wrap up", "handoff", "save session"
- Before switching to a different project context

## Steps

### Step 0 — Pre-flight git check

Before any save work, verify git state:

```bash
git status --porcelain        # show modified + untracked (porcelain = machine-readable)
git rev-parse --abbrev-ref HEAD  # current branch
git rev-parse --is-inside-work-tree  # verify in repo (should return true)
```

**Abort handoff (with warning) if**:
- Currently in middle of merge (`.git/MERGE_HEAD` exists) -> "Merge in progress detected — resolve before handoff"
- Currently in middle of rebase (`.git/rebase-apply` or `.git/rebase-merge` exists) -> "Rebase in progress detected — finish before handoff"
- On detached HEAD -> "On detached HEAD — checkout a branch before handoff"

**Note**: If no remote configured (`git remote -v` empty), commit locally and skip push (warn user).

### Step 1 — Run audit (Learning Loop Stage 4)

Invoke `/audit` workflow inline:
- Scan all `memory/**/*.md` entries
- Build 5 lists: Applied & Verified / Applied & Corrected / Possibly Missed / Stale / New This Session
- Identify promotion candidates (applied_count >= 3 + verified + multi-context)

(See `audit.md` for full procedure)

### Step 2 — Summarize the session

Cover:
- What was accomplished
- Key decisions made
- Current state (which phase, project, feature — whatever is relevant)
- Open questions / blockers
- Next steps (be specific: file paths, IDs, URLs)

### Step 3 — Save session memory

**Folder**: `memory/{YYYY-MM}/`
**Filename**: `{YYYY-MM-DD}-session-{short-slug}.md`

Example: `memory/2026-07/2026-07-06-session-auth-refactor-complete.md`

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

# Session Handoff — {date} — {short title}

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
- {what to do next session — specific file paths, URLs, IDs}

---

## Memory Audit (Stage 4 — EVOLVE)

### Applied & Verified ({N})
- `{memory-name}` — applied {N}x total, context: "{text}"

### Applied & Corrected ({N})
- `{memory-name}` — refined: {what changed}

### Possibly Missed ({N})
- `{memory-name}` — trigger matched at: {moment}, but not recalled

### Stale (last applied >= 30 days ago) ({N})
- `{memory-name}` — last: {date or never} -> review?

### New This Session ({N})
- `{memory-name}` — captured from "{phrase}"

### Ready to Promote ({N})
- `{memory-name}` — applied {N}x across {M} contexts
  -> suggest: /promote {memory-name}

### Health Score
- Active memories: {N}
- Verified rate: {applied & verified / total applied}
```

### Step 4 — Update MEMORY.md

Add session entry under `## Session History` section (create section if missing). Use Obsidian wikilink:
```
- [[session-{YYYY-MM-DD}-{slug}]] -- {hook}
```

### Step 5 — Update latest-handoff.md

Overwrite `memory/latest-handoff.md` with the same content from Step 3.
(Allows next session's `/resume` to read one file for quick context.)

### Step 6 — Commit changes

Commit all session changes. Do NOT use `git add -A` or `git add .` (risk of secrets/binaries). Use **specific paths only**.

#### 6.1 Stage allowed paths

```bash
# Stage by directory/file — extend as new artifact types are added
git add memory/                          # session memory + handoff + audit log
git add CLAUDE.md                        # if updated
git add .gitignore 2>/dev/null || true   # if updated
```

Dynamically detect and stage additional directories that exist in the repo:

```bash
# Stage common project directories if they exist and have changes
for dir in projects/ specs/ docs/ tools/ scripts/ .claude/commands/; do
  if [ -d "$dir" ]; then
    git add "$dir" 2>/dev/null || true
  fi
done
```

#### 6.2 Sanity-check staged files

```bash
git diff --cached --name-only
```

**Forbidden patterns** (abort and warn if any staged file matches):
- `.env*` / `*.key` / `*.pem` / `*secret*` / `*credential*` / `*token*`
- `.claude/settings.local.json` (machine-specific)
- `.venv/` / `node_modules/` / `__pycache__/` (build artifacts)
- Files > 1 MB (likely binary — ask user)

If a forbidden file is staged:
```bash
git reset HEAD <file>   # unstage
```
Then explain to user and continue without that file.

#### 6.3 Build commit message

Format:
```
chore(handoff): {date} — {short session title (<=50 chars)}

{1-3 line summary of accomplishments}

{Key memory deltas if applicable}:
- Applied: {memory-name} (#{count})
- New: {memory-name}
- Promoted: {memory-name} -> CLAUDE.md#{section} (if any)

Co-Authored-By: {AGENT_NAME} ({AGENT_ROLE}) via Claude Code <noreply@anthropic.com>
```

**Example**:
```
chore(handoff): 2026-07-06 — Auth refactor complete

Refactored auth module to use JWT refresh tokens.
Added rate limiting to login endpoint.

Memory deltas:
- Applied: pattern-jwt-refresh-flow (#3) — promotion criteria met
- New: lesson-rate-limit-before-auth

Co-Authored-By: Atlas (Backend Engineer) via Claude Code <noreply@anthropic.com>
```

#### 6.4 Create commit

```bash
git commit -m "$(cat <<'EOF'
<message from 6.3>
EOF
)"
```

**Hard rules** (git safety):
- NEVER `--amend` (always create NEW commit)
- NEVER `--no-verify` (pre-commit hooks must pass)
- NEVER `--no-gpg-sign`
- If hook fails -> fix issue -> re-stage -> NEW commit (don't amend the failed one)

#### 6.5 Verify

```bash
git status        # should show "nothing to commit, working tree clean"
git log -1        # confirm new commit
```

### Step 7 — Push to remote

#### 7.1 Check remote configured

```bash
git remote -v
```
If empty -> warn user "No remote configured — handoff saved locally only" + skip Step 7.

#### 7.2 Determine branch + push strategy

```bash
BR=$(git rev-parse --abbrev-ref HEAD)
git ls-remote --exit-code --heads origin "$BR" >/dev/null 2>&1
```

If branch exists on remote -> `git push origin $BR`
If branch is new (no upstream) -> `git push -u origin $BR`

#### 7.3 Handle push failure

**Non-fast-forward (remote has commits we don't)**:
- NEVER `git push --force`
- Warn user: "Remote has new commits — run `/resume` first (pulls latest) then `/handoff` again"
- Stop here (the local commit is safely preserved)

**Auth failure**:
- Tell user: "Push auth failed — check credentials (git config + gh auth status)"
- Local commit is preserved

**Network failure**:
- Tell user: "Network failed — local commit preserved, retry push later with `git push`"

#### 7.4 Verify

```bash
git log -1 --format='%H %s'
git rev-parse @{u}     # remote tracking ref — should match HEAD now
```

### Step 8 — Surface action items

End with concrete asks for user:
- "Promote {memory}?" (if candidates exist)
- "Memory {name} has not been used in {N} days — archive?"
- Confirmation: "Committed + pushed — session saved. See you next time."
  - Or if push was skipped: "Committed locally (no remote) — session saved."
  - Or if push failed: "Committed locally — push failed ({reason}) — retry manually or run `/resume` first."

## Rules

- **Always run audit** — even if session was short. Audit is the only Stage 4 mechanism.
- **Always create dated file AND overwrite latest-handoff.md** — history vs quick-access
- **Be specific about next steps** — future sessions should know exactly where to resume (file path, line number, ID)
- **Include audit inline** — don't separate. Next session reads one file.
- **Never `git add -A` / `git add .` / `--all`** — stage specific paths only (avoid secrets, .venv, .DS_Store)
- **Never force push** — even on personal repos
- **Always create NEW commit, never amend** — failed hook = fix + re-stage + new commit
- **Commit even if push fails** — local state preserved + can retry push later

## See also

- `docs/LEARNING-LOOP.md` Stage 4 (EVOLVE) — if exists in repo
- `/audit` — standalone audit (same logic, no save)
- `/promote` — execute promotions for candidates found
- `/resume` — next session loads latest-handoff.md + pulls latest from remote
