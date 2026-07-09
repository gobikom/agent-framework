---
description: Save session context + Learning Loop audit + Git commit/push (end-of-session)
---

# /handoff — Save session context + Learning Loop audit + Git commit/push

Save current session so the next one can resume, run Stage 4 (EVOLVE) audit, AND commit+push all session changes to remote (so other machines/sessions stay in sync).

## Self-Configuration (run once per session)

Read the repo's `AGENT.md` (or `CLAUDE.md` for backward compatibility) to extract:
- **AGENT_NAME**: from Identity table -> Name field
- **AGENT_ID**: from Identity table -> Agent ID field
- **HUMAN_NAME**: from "Workspace Human" section
- **LANGUAGE**: from Identity table or default English
- **PERSONA_PARTICLE**: from Persona section (speech ending particle, if any)
- **AGENT_ROLE**: from Identity table -> Role field (used in Co-Authored-By)

Use these values throughout. If neither file is found, use defaults:
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

### Step 2 — Save session context (delegate to /save)

Invoke `/save` to save session context. This handles:
- Summarizing what was accomplished, decisions, state, open questions, next steps
- Creating session memory file (`memory/{YYYY-MM}/{date}-session-{slug}.md`)
- Updating `memory/MEMORY.md` index under `## Session History`
- Overwriting `memory/latest-handoff.md` for next session's `/resume`

The audit report from Step 1 is included inline in the session memory file.

See `save.md` for the full procedure. `/save` must be called AFTER `/audit` (audit informs the session summary).

### Step 3 — Commit changes

Commit all session changes. Do NOT use `git add -A` or `git add .` (risk of secrets/binaries). Use **specific paths only**.

#### 3.1 Stage allowed paths

```bash
# Stage by directory/file — extend as new artifact types are added
git add memory/                          # session memory + handoff + audit log
git add AGENT.md                         # if updated
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

#### 3.2 Sanity-check staged files

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

#### 3.3 Build commit message

Format:
```
chore(handoff): {date} — {short session title (<=50 chars)}

{1-3 line summary of accomplishments}

{Key memory deltas if applicable}:
- Applied: {memory-name} (#{count})
- New: {memory-name}
- Promoted: {memory-name} -> AGENT.md#{section} (if any)

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

#### 3.4 Create commit

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

#### 3.5 Verify

```bash
git status        # should show "nothing to commit, working tree clean"
git log -1        # confirm new commit
```

### Step 4 — Push to remote

#### 4.1 Check remote configured

```bash
git remote -v
```
If empty -> warn user "No remote configured — handoff saved locally only" + skip Step 4.

#### 4.2 Determine branch + push strategy

```bash
BR=$(git rev-parse --abbrev-ref HEAD)
git ls-remote --exit-code --heads origin "$BR" >/dev/null 2>&1
```

If branch exists on remote -> `git push origin $BR`
If branch is new (no upstream) -> `git push -u origin $BR`

#### 4.3 Handle push failure

**Non-fast-forward (remote has commits we don't)**:
- NEVER `git push --force`
- Warn user: "Remote has new commits — run `/resume` first (pulls latest) then `/handoff` again"
- Stop here (the local commit is safely preserved)

**Auth failure**:
- Tell user: "Push auth failed — check credentials (git config + gh auth status)"
- Local commit is preserved

**Network failure**:
- Tell user: "Network failed — local commit preserved, retry push later with `git push`"

#### 4.4 Verify

```bash
git log -1 --format='%H %s'
git rev-parse @{u}     # remote tracking ref — should match HEAD now
```

### Step 5 — Surface action items

End with concrete asks for user:
- "Promote {memory}?" (if promotion candidates exist from audit)
- "Evolve {memory} into a skill?" (if skill evolution candidates exist from audit)
- "Memory {name} has not been used in {N} days — archive?"
- Confirmation: "Committed + pushed — session saved. See you next time."
  - Or if push was skipped: "Committed locally (no remote) — session saved."
  - Or if push failed: "Committed locally — push failed ({reason}) — retry manually or run `/resume` first."

## Rules

- **Always run audit** — even if session was short. Audit is the only Stage 4 mechanism.
- **Always delegate session save to /save** — keeps handoff focused on audit + commit + push
- **Be specific about next steps** — future sessions should know exactly where to resume (file path, line number, ID)
- **Never `git add -A` / `git add .` / `--all`** — stage specific paths only (avoid secrets, .venv, .DS_Store)
- **Never force push** — even on personal repos
- **Always create NEW commit, never amend** — failed hook = fix + re-stage + new commit
- **Commit even if push fails** — local state preserved + can retry push later

## See also

- `docs/LEARNING-LOOP.md` Stage 4 (EVOLVE) and Stage 6 (EVOLVE SKILL) — if exists in repo
- `/audit` — standalone audit (same logic, no save)
- `/save` — save session context without audit/commit/push (called by handoff Step 2)
- `/promote` — execute promotions for candidates found
- `/evolve` — graduate workflow patterns into executable skills
- `/resume` — next session loads latest-handoff.md + pulls latest from remote
