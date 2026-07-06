---
description: "Create a new persistent AI agent — interactive wizard with memory, learning loop, and dual-runtime support"
argument-hint: "[--minimal]"
---

# /wizard — Agent Birth Wizard

> Scaffold a persistent AI agent with identity, memory, and learning loop.

Run this command inside the target repo directory. The wizard gathers agent identity through a single freetext prompt, asks about memory preferences, then builds all files.

## Flow Overview

```
Phase 0: System Check         (automatic — git, runtime detection)
Phase 1: Batch Freetext        (6 questions, 1 prompt)
Phase 2: Memory Consent        (2 yes/no questions)
Phase 3: Confirmation Screen   (review + edit gate)
Phase 4: Build                 (create all files + git commit)
Phase 5: Summary               (what was created + quick-start)
```

---

## Initialization — Detect Framework Path

Before starting any phase, locate the agent-framework source directory. Check in this order:

1. Environment variable: `$AGENT_FRAMEWORK_DIR`
2. File in current repo: `.agent-framework-path` (contains a single absolute path)
3. Default: `~/repos/agents/agent-framework`

```bash
if [ -n "$AGENT_FRAMEWORK_DIR" ] && [ -d "$AGENT_FRAMEWORK_DIR" ]; then
  FRAMEWORK_DIR="$AGENT_FRAMEWORK_DIR"
elif [ -f ".agent-framework-path" ] && [ -d "$(cat .agent-framework-path)" ]; then
  FRAMEWORK_DIR="$(cat .agent-framework-path)"
elif [ -d "$HOME/repos/agents/agent-framework" ]; then
  FRAMEWORK_DIR="$HOME/repos/agents/agent-framework"
else
  echo "ERROR: Cannot find agent-framework directory."
  echo "Set AGENT_FRAMEWORK_DIR or create .agent-framework-path in this repo."
  # HARD STOP — cannot proceed without templates
fi
```

Verify the framework has the required files:

```bash
for f in templates/CLAUDE.md.tmpl templates/AGENTS.md.tmpl templates/memory/MEMORY.md.tmpl skills/remember.md; do
  [ -f "$FRAMEWORK_DIR/$f" ] || echo "WARNING: missing $FRAMEWORK_DIR/$f"
done
```

Store `FRAMEWORK_DIR` for use in Phase 4.

---

## Phase 0: System Check (automatic)

Run ALL checks silently, then display a single results panel. No user interaction unless a problem needs fixing.

### Required Checks

| # | Check | Command | If Missing |
|---|-------|---------|------------|
| 1 | Git installed | `git --version` | **HARD STOP** — print "Git is required. Install it and re-run." |
| 2 | Git repo | `git rev-parse --is-inside-work-tree 2>/dev/null` | Offer: "No git repo found. Initialize one? [Y/n]" — if yes, run `git init` |
| 3 | Git identity — name | `git config user.name` | Ask: "What name should git use for commits?" — run `git config user.name "<answer>"` |
| 4 | Git identity — email | `git config user.email` | Ask: "What email should git use for commits?" — run `git config user.email "<answer>"` |
| 5 | Existing identity files | Check for `CLAUDE.md` and/or `AGENTS.md` in repo root | If found, warn: "Existing CLAUDE.md / AGENTS.md detected. The wizard will overwrite these. Continue? [y/N]" — default NO to protect existing work |

### Runtime Detection

Detect which runtimes are available or configured in this repo:

```bash
HAS_CLAUDE_CODE="no"
HAS_CODEX="no"

# Claude Code: .claude/ directory or CLAUDE.md
[ -d ".claude" ] || [ -f "CLAUDE.md" ] && HAS_CLAUDE_CODE="yes"

# Codex: .codex/ directory or AGENTS.md
[ -d ".codex" ] || [ -f "AGENTS.md" ] && HAS_CODEX="yes"

# If neither detected yet (fresh repo), default to both
if [ "$HAS_CLAUDE_CODE" = "no" ] && [ "$HAS_CODEX" = "no" ]; then
  HAS_CLAUDE_CODE="yes"
  HAS_CODEX="yes"
fi
```

### Display Results

```
--- System Check ---

  Git:        v2.43.0
  Repo:       yes (branch: main)
  Identity:   Alex <alex@example.com>
  Existing:   (none)
  Runtimes:   Claude Code + Codex

  Framework:  ~/repos/agents/agent-framework

All clear — starting wizard.
```

If any check needs user input (git init, git identity, overwrite warning), resolve it inline before proceeding to Phase 1. Keep the interaction minimal — one question per issue, sensible defaults.

---

## Phase 1: Batch Freetext Wizard

Present ALL 6 questions in a single prompt. The user answers in one freetext message — prose, bullet points, numbered list, comma-separated, or any mix.

### The Prompt

```
Let's create your agent! Answer these questions (freetext is fine — write however you like):

1. What's your agent's name?
2. What's your agent's role or purpose?
   (e.g., "DevOps engineer", "QA tester", "Project manager", "Writing assistant")
3. Describe your agent's personality and tone.
   (e.g., "friendly and casual", "precise and formal", speech patterns, emoji style, any quirks)
4. What are your agent's core principles or hard rules?
   (e.g., "always ask before acting", "test before deploy", "security first")
5. What's your name? (how should the agent address you?)
6. What's the primary language?
   (e.g., English, Thai, Japanese — default: English)

Answer all at once, or just the ones you care about — I'll fill in sensible defaults for the rest.
```

### AI Parse Logic

After the user replies, parse the freetext into these structured fields:

| Field | Key | Required | Fallback if Missing |
|-------|-----|----------|---------------------|
| Agent name | `agent_name` | **YES** | Ask again — cannot proceed without |
| Agent role/purpose | `agent_role` | **YES** | Ask again — cannot proceed without |
| Personality description | `personality` | no | "Professional, helpful, and thorough" |
| Philosophy / hard rules | `philosophy` | no | AI generates sensible defaults based on `agent_role` (see below) |
| Human's name | `human_name` | **YES** | Ask again — cannot proceed without |
| Primary language | `language` | no | "English" |

### AI-Generated Derived Fields

From the parsed answers, generate these additional fields:

| Derived Field | How to Generate |
|---------------|-----------------|
| `agent_id` | Kebab-case from `agent_name`. E.g., "Code Reviewer" -> `code-reviewer`, "Luna" -> `luna`, "QA Bot" -> `qa-bot` |
| `persona_section` | Write a full paragraph (3-8 sentences) describing the agent's personality, communication style, and any speech quirks. Base it on the `personality` answer. If the user specified speech patterns, emoji preferences, or tics, include them. Write in prose, not bullets. |
| `philosophy_section` | Format the user's stated principles as a bulleted list of hard rules. Then add 2-3 AI-generated additions that are natural for the stated `agent_role`. For example, a "QA tester" naturally gets "never skip edge case validation" and "reproduce before closing". Each rule gets a one-line explanation. |
| `capabilities_section` | Infer 4-8 capabilities from `agent_role`. Format as a bulleted list. E.g., for "DevOps engineer": configuration management, CI/CD pipeline design, infrastructure monitoring, incident response, container orchestration. |
| `proactive_triggers` | Generate a table of 6-8 proactive memory triggers appropriate for the role. Always include the universal triggers (session start, session end, user correction, important decision) plus 2-4 role-specific triggers. |
| `budget` | Default "5.00 USD" unless the user specified otherwise. |
| `born_date` | Today's date in YYYY-MM-DD format. |

### Show Parsed Result

Display the parsed and derived fields for review:

```
--- Parsed ---

  Name:        Code Reviewer
  ID:          code-reviewer
  Role:        Senior code reviewer specializing in Python and TypeScript
  Personality: Precise, thorough, slightly dry humor. Uses checkmarks and X marks.
  Philosophy:  5 rules (user: 2 + AI-generated: 3)
  Human:       Alex
  Language:    English
  Budget:      5.00 USD
```

### Handle Missing Required Fields

If any **required** field (`agent_name`, `agent_role`, `human_name`) could not be parsed from the freetext, ask ONLY for the missing ones in a follow-up:

```
I got most of it! Just need a couple more details:
  - What's your agent's name?
  - What's your name? (how should the agent address you?)
```

Do NOT re-ask for fields that were successfully parsed. One follow-up round maximum — if still missing after the second attempt, use the repo directory name as agent_name and "human" as human_name.

---

## Phase 2: Memory Consent

Two sequential yes/no questions. Present one at a time.

### Question 1: Learning Loop

```
Enable persistent memory with learning loop? (recommended)

  What this does:
  - Agent remembers decisions, patterns, and lessons across sessions
  - 7 commands: /remember, /recall, /apply, /audit, /promote, /resume, /handoff
  - Memory stored as markdown files in memory/ (git-trackable, no external dependencies)

  [Y/n] (default: Yes)
```

| Answer | `memory_mode` |
|--------|---------------|
| Yes / y / Enter / empty | `full` — install all 7 skills + full memory structure |
| No / n | `minimal` — install only `/resume` + `/handoff` (basic session continuity) |

### Question 2: Auto-Audit on Handoff

Only ask if `memory_mode` is `full`:

```
Auto-run memory audit when you end a session with /handoff?

  What this does:
  - /handoff automatically scans memory health before saving
  - Reports: applied lessons, stale lessons, new captures, promotion candidates
  - Adds ~5 seconds to handoff

  [Y/n] (default: Yes)
```

| Answer | `auto_audit` |
|--------|--------------|
| Yes / y / Enter / empty | `true` |
| No / n | `false` — audit available manually via `/audit` but not auto-triggered |

If `memory_mode` is `minimal`, set `auto_audit` to `false` and skip this question.

---

## Phase 3: Confirmation Screen

Display all gathered info in a structured summary. This is the last gate before building.

```
+----------------------------------+
| Agent Framework -- New Agent     |
+----------------------------------+
| Name:        Code Reviewer       |
| ID:          code-reviewer       |
| Role:        Senior code reviewer|
| Personality: Precise, thorough   |
| Philosophy:  5 rules             |
| Human:       Alex                |
| Language:    English              |
| Budget:      5.00 USD            |
| Memory:      Full learning loop  |
| Auto-audit:  Yes                 |
| Runtimes:    Claude Code + Codex |
+----------------------------------+

Create this agent? [Y/n/edit]
```

### Response Handling

| Answer | Action |
|--------|--------|
| **Y** / y / Enter / empty | Proceed to Phase 4 (Build) |
| **n** / no | Abort the wizard. Print "Wizard cancelled. No files were created." and stop. |
| **edit** / e | Ask: "Which field would you like to change? (name/role/personality/philosophy/human/language/budget/memory)" — accept the new value, re-display the confirmation screen, and ask again. |

---

## Phase 4: Build

Execute these steps in order. Handle errors gracefully — if any step fails, report the error and continue with remaining steps where possible.

### Step 1: Create memory/ directory structure

```bash
YEAR_MONTH=$(date +%Y-%m)
mkdir -p memory/{_template,$YEAR_MONTH}
```

### Step 2: Copy memory templates from framework

Source files from `$FRAMEWORK_DIR/templates/memory/`. Copy each file, replacing `{{AGENT_NAME}}` with the actual agent name.

**Files to copy:**

| Source | Destination |
|--------|-------------|
| `templates/memory/MEMORY.md.tmpl` | `memory/MEMORY.md` |
| `templates/memory/_promotions.md.tmpl` | `memory/_promotions.md` |
| `templates/memory/latest-handoff.md` | `memory/latest-handoff.md` |
| `templates/memory/_template/feedback-template.md` | `memory/_template/feedback-template.md` |
| `templates/memory/_template/pattern-template.md` | `memory/_template/pattern-template.md` |

For each file:
1. Read the source file from `$FRAMEWORK_DIR`
2. Replace all `{{AGENT_NAME}}` occurrences with the actual agent name
3. Write to the destination in the current repo

If `memory_mode` is `minimal`, still create `memory/MEMORY.md` and `memory/latest-handoff.md` (needed for `/resume` and `/handoff`), but skip `_promotions.md` and `_template/` (not needed without full learning loop).

### Step 3: Generate CLAUDE.md

Read `$FRAMEWORK_DIR/templates/CLAUDE.md.tmpl` as a base. Replace all `{{VARIABLES}}` with wizard values.

**Variable replacement table:**

| Variable | Source |
|----------|--------|
| `{{AGENT_NAME}}` | `agent_name` from wizard |
| `{{AGENT_ID}}` | `agent_id` (derived, kebab-case) |
| `{{AGENT_ROLE}}` | `agent_role` from wizard |
| `{{BORN_DATE}}` | Today's date (YYYY-MM-DD) |
| `{{HUMAN_NAME_SECTION}}` | AI-generated paragraph about the workspace human. Format: "The human who runs this workspace is **{human_name}**." Add any relevant details if the user provided them. |
| `{{PERSONA_SECTION}}` | **AI-generated prose** — write 3-8 sentences describing the agent's personality, communication style, speech patterns, and any quirks based on the user's `personality` answer. This is NOT just variable substitution — the AI writes natural prose that reads as a coherent persona description. |
| `{{PHILOSOPHY_SECTION}}` | **AI-generated list** — format user's stated principles as bullet points with explanations, plus AI-generated additions appropriate for the role. Each rule as: `- **Rule name** -- explanation` |
| `{{CAPABILITIES_SECTION}}` | **AI-generated list** — inferred capabilities from role, formatted as bullet points. |
| `{{PROACTIVE_TRIGGERS_SECTION}}` | **AI-generated table** — proactive memory triggers appropriate for the role. Use the same table format as the template but with role-specific triggers. |
| `{{BUDGET}}` | `budget` value (default "5.00 USD") |

**Important**: The `{{PERSONA_SECTION}}`, `{{PHILOSOPHY_SECTION}}`, `{{CAPABILITIES_SECTION}}`, and `{{PROACTIVE_TRIGGERS_SECTION}}` are NOT literal string replacements. The AI must write original prose and content based on the wizard answers. The template provides structure; the AI provides the substance.

If `memory_mode` is `minimal`, strip the full "Memory System" section from the template and replace with a shorter version:

```markdown
## Memory System

> Minimal session continuity — `/resume` to start, `/handoff` to end.

| Command | Action |
|---------|--------|
| `/resume` | Pull + load last handoff |
| `/handoff` | Save session + commit + push |
```

Write the completed CLAUDE.md to the repo root.

**Overwrite guard**: If CLAUDE.md already exists and the user confirmed overwrite in Phase 0, proceed. If Phase 0 was not reached (should not happen) or the user did not confirm, do NOT overwrite — abort and report.

### Step 4: Generate AGENTS.md

Read `$FRAMEWORK_DIR/templates/AGENTS.md.tmpl` as a base. Apply the same variable replacements as Step 3.

The AGENTS.md template already adapts command references for codex-compatible tools (no slash prefixes, natural language descriptions). Apply the same persona/philosophy/capabilities content.

If `memory_mode` is `minimal`, apply the same minimal memory section adaptation.

Write the completed AGENTS.md to the repo root.

### Step 5: Install skills to .claude/commands/agent-core/

```bash
mkdir -p .claude/commands/agent-core
```

Copy skill files from `$FRAMEWORK_DIR/skills/`:

**If `memory_mode` is `full`**: Copy ALL skill files found in `$FRAMEWORK_DIR/skills/`.

**If `memory_mode` is `minimal`**: Copy only `resume.md` and `handoff.md` (if they exist). If they do not exist yet in the framework, skip this step and note it in the summary.

For each skill file:
1. Read from `$FRAMEWORK_DIR/skills/<name>.md`
2. Write to `.claude/commands/agent-core/<name>.md`

Do NOT modify skill content — skills are designed to be agent-agnostic (they read agent identity from CLAUDE.md at runtime via self-configuration).

### Step 6: Create docs/

```bash
mkdir -p docs
```

If `$FRAMEWORK_DIR/docs/LEARNING-LOOP.md` exists, copy it to `docs/LEARNING-LOOP.md`.

If it does not exist, create a minimal placeholder:

```markdown
# Learning Loop

> Architecture documentation for the agent's persistent memory system.
> See CLAUDE.md "Memory System" section for available commands.

## 5 Stages

1. **CAPTURE** (`/remember`) — Save lessons, patterns, decisions, feedback
2. **APPLY** (`/recall` + `/apply`) — Search memory before acting, announce when applying a lesson
3. **VERIFY** — Track whether applied lessons were confirmed or corrected by the user
4. **EVOLVE** (`/audit`) — Session-end health check of memory entries
5. **PROMOTE** (`/promote`) — Graduate battle-tested lessons to CLAUDE.md hard rules

## Criteria for Promotion

- `applied_count >= 3`
- `verified_by_user = yes` consistently
- Applied across >= 2 different contexts

---
*Generated by agent-framework wizard*
```

### Step 7: Create/update .gitignore

If `.gitignore` does not exist, copy from `$FRAMEWORK_DIR/templates/.gitignore.tmpl`.

If `.gitignore` already exists, check whether it already contains agent-framework entries. If not, append the agent-framework block:

```bash
# Check if already has agent-framework entries
if ! grep -q "Agent framework" .gitignore 2>/dev/null; then
  cat >> .gitignore << 'EOF'

# Agent framework (installed, not tracked)
.claude/commands/agent-core/
EOF
fi
```

### Step 8: Git commit

Stage all created files and commit:

```bash
git add CLAUDE.md AGENTS.md memory/ .claude/ docs/ .gitignore
git commit -m "feat: initialize agent -- AGENT_NAME (AGENT_ROLE)

Created by agent-framework wizard.

Co-Authored-By: AGENT_NAME <noreply@agent-framework>"
```

Replace `AGENT_NAME` and `AGENT_ROLE` with the actual values (shell-escaped for the commit message).

If the commit fails (e.g., pre-commit hook failure), report the error but do NOT treat it as fatal. The files are already on disk. Tell the user: "Files created successfully, but the git commit failed. You can commit manually."

---

## Phase 5: Summary

Display a clear summary of what was created, then a quick-start guide.

### Created Files Report

```
--- Agent "AGENT_NAME" created! ---

Files created:
  CLAUDE.md                          -- Agent identity (Claude Code)
  AGENTS.md                          -- Agent identity (Codex/Antigravity)
  memory/MEMORY.md                   -- Memory index
  memory/_promotions.md              -- Promotion audit trail
  memory/latest-handoff.md           -- Session handoff pointer
  memory/_template/feedback-template.md
  memory/_template/pattern-template.md
  memory/YYYY-MM/                    -- Current month folder (empty)
  .claude/commands/agent-core/       -- N skill commands installed
  docs/LEARNING-LOOP.md              -- Learning loop architecture
  .gitignore                         -- Updated

Git: committed to branch BRANCH_NAME
```

Adjust the file list based on what was actually created (e.g., if `memory_mode` is `minimal`, fewer files).

### Quick-Start Guide

```
Quick start:
  /resume            -- Start a session (load last context)
  /remember <slug>   -- Save something to memory
  /recall <keyword>  -- Search memory
  /handoff           -- End session (save + commit + push)
```

If `memory_mode` is `minimal`, show only:

```
Quick start:
  /resume            -- Start a session (load last context)
  /handoff           -- End session (save + commit + push)
```

### Learn More

```
Learn more:
  CLAUDE.md          -- Your agent's full identity and rules
  docs/LEARNING-LOOP.md  -- How the memory system works
  memory/MEMORY.md   -- Memory index (starts empty, grows with use)
```

### Final Note

```
Your agent is ready. Open a new Claude Code session in this directory
to start working with AGENT_NAME.
```

---

## Edge Cases and Error Handling

### User runs wizard in a non-empty repo with existing agent

Phase 0 detects existing CLAUDE.md/AGENTS.md and warns. If user declines overwrite, abort gracefully.

### Framework directory not found

Hard stop in Initialization phase. Print clear instructions on how to fix (set env var or create path file).

### Template file missing

If a template file is missing from the framework, skip that step and note it in the summary. The wizard should be resilient to incomplete framework installations — create what it can, report what it cannot.

### Git commit fails

Not fatal. Files are on disk. Report the error and suggest manual commit.

### User provides very minimal answers

If the user answers with just "Bob, dev, help me code" — parse what you can, generate generous defaults, and show the parsed result for confirmation. The confirmation screen (Phase 3) is the safety net.

### The --minimal argument

If `$ARGUMENTS` contains `--minimal`, skip Phase 2 (Memory Consent) entirely and default to `memory_mode: minimal`, `auto_audit: false`. This streamlines the wizard for users who want the fastest possible setup.

---

## Template Variable Reference

Complete list of all template variables used across CLAUDE.md.tmpl and AGENTS.md.tmpl:

| Variable | Type | Source |
|----------|------|--------|
| `{{AGENT_NAME}}` | string | User answer Q1 |
| `{{AGENT_ID}}` | string | Derived: kebab-case of agent_name |
| `{{AGENT_ROLE}}` | string | User answer Q2 |
| `{{BORN_DATE}}` | string | Today (YYYY-MM-DD) |
| `{{HUMAN_NAME_SECTION}}` | prose | AI-generated from Q5 |
| `{{PERSONA_SECTION}}` | prose | AI-generated from Q3 |
| `{{PHILOSOPHY_SECTION}}` | prose | AI-generated from Q4 + role-based additions |
| `{{CAPABILITIES_SECTION}}` | list | AI-generated from Q2 (role) |
| `{{PROACTIVE_TRIGGERS_SECTION}}` | table | AI-generated from Q2 (role) |
| `{{BUDGET}}` | string | Default "5.00 USD" or user override |

---

ARGUMENTS: $ARGUMENTS
