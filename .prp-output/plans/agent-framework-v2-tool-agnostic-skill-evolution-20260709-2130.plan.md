---
status: pending
runner: bash
mode: full
complexity: HIGH
created: 2026-07-09
---

# Agent Framework v2: Tool-Agnostic Refactor + Stage 6 Skill Evolution + Quality Improvements

## Summary

Transform agent-framework from a Claude Code-coupled scaffolding tool into a runtime-neutral agent framework, add a 6th Learning Loop stage (Skill Evolution) that auto-detects repeated workflows and graduates them into executable skills, and ship quality improvements (versioning, config, search optimization, handoff split). Three scopes, 20 tasks, ~30 files touched.

## User Story

As an AI agent operator using any coding assistant (Claude Code, Cursor, Codex, Windsurf, Aider)
I want to scaffold persistent agents with memory, learning loop, and self-improving skills
So that my agents learn from corrections, evolve repeated workflows into reusable skills, and work with any tool — not just Claude Code.

## Problem / Solution

**Problem**: Agent-framework v1.0 is tightly coupled to Claude Code (skills live in `.claude/commands/`, identity file named `CLAUDE.md`, wizard is a slash command). Memory is flat-file but the docs promise MCP integration that conflicts with the vault-only decision. The Learning Loop has no mechanism for agents to proactively create new skills from repeated patterns — it only promotes rules, not workflows.

**Solution**: (A) Decouple from Claude Code — universal `AGENT.md` + tool-specific adapters. (B) Add Stage 6 Skill Evolution — detect repeated multi-step patterns, draft executable skills, track evolution audit trail. (C) Quality sweep — versioning, config file, search optimization, handoff split, missing lifecycle commands.

## Metadata

| Field | Value |
|-------|-------|
| Type | REFACTOR + NEW_CAPABILITY + QUALITY |
| Complexity | HIGH |
| Systems | scripts/, skills/, templates/, wizard/, docs/ |
| Dependencies | None (zero-dependency project) |
| Task Count | 20 |
| Runner | `bash` |
| Validate | Manual: scaffold test agent, run all skills |

## Mandatory Reading

| Priority | File | Why |
|----------|------|-----|
| P0 | `wizard/wizard.md` (563 lines) | Largest file, most Claude Code coupling — drives Phase 4 Build logic |
| P0 | `skills/remember.md` (186 lines) | B5 modifies this — must understand trigger detection + Step 3 schema |
| P0 | `skills/audit.md` (129 lines) | B4/B8 modifies this — must understand Step 2 categorization + Step 3 promotion logic |
| P0 | `skills/handoff.md` (307 lines) | C4 splits this — must understand all 8 steps |
| P1 | `templates/CLAUDE.md.tmpl` (66 lines) | A1 replaces this with AGENT.md.tmpl |
| P1 | `templates/AGENTS.md.tmpl` (73 lines) | A1 replaces this with AGENT.md.tmpl |
| P1 | `scripts/agent-install.sh` (69 lines) | A2 adds --target routing, C5 adds conflict detection |
| P1 | `skills/recall.md` (83 lines) | C3 optimizes search strategy |
| P2 | `docs/LEARNING-LOOP.md` (408 lines) | B1 adds Stage 6 documentation |
| P2 | `docs/CUSTOMIZATION.md` (330 lines) | A4 removes MCP section |
| P2 | `scripts/agent-init.sh` (65 lines) | A3 decouples wizard, C7 adds bash version check |

## Patterns to Mirror

### File naming convention
```
SOURCE: codebase (skills/remember.md, skills/recall.md, all 7 skills)
Pattern: {verb}.md — single verb, lowercase
New skills: evolve.md, supersede.md, archive.md, save.md
```

### Skill file structure
```markdown
SOURCE: codebase (skills/remember.md:1-9)
---
description: {one-line description}
---

# /{name} — {Short title}

{One-line summary}

## Self-Configuration (run once per session)

Read the repo's `CLAUDE.md` to extract:  ← NOTE: must change to AGENT.md
- **AGENT_NAME**: from Identity table
...
```
Every skill starts with frontmatter + Self-Configuration that reads identity from the agent's identity file. New skills MUST follow this pattern but read from `AGENT.md` instead of `CLAUDE.md`.

### Template variable convention
```
SOURCE: codebase (templates/CLAUDE.md.tmpl, wizard/wizard.md:309-326)
Pattern: {{VARIABLE_NAME}} — double curly braces, UPPER_SNAKE_CASE
Used in: CLAUDE.md.tmpl, AGENTS.md.tmpl, MEMORY.md.tmpl, _promotions.md.tmpl
```

### Memory frontmatter schema
```yaml
SOURCE: codebase (skills/remember.md:73-89, templates/memory/_template/feedback-template.md)
---
name: {type}-{kebab-case-slug}
aliases:
  - {type}-{kebab-case-slug}
description: "{one-line summary}"
metadata:
  type: {type}
  category: "{topic}"
  status: active
  date: YYYY-MM-DD
  applied_count: 0
  last_applied: null
  last_context: null
  verified_by_user: pending
  promoted_to: null
---
```
B7 adds `evolved_to: null` and `skill_version: null` to this schema.
B7 also adds `contexts: []` (list of short context strings from each /apply invocation — replaces reliance on single `last_context` for multi-context verification). `last_context` remains for backward compat but `contexts` is the source of truth for "applied across >= 2 contexts" checks in /audit and /evolve. (F4: single `last_context` field was insufficient for reliable multi-context detection.)

### Script structure
```bash
SOURCE: codebase (scripts/agent-install.sh:1-9)
#!/usr/bin/env bash
set -euo pipefail

FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    echo "Error: Directory '$1' does not exist."
    exit 1
}
```
All 3 scripts share this preamble pattern. New logic must follow.

### MEMORY.md index format
```
SOURCE: codebase (templates/memory/MEMORY.md.tmpl:9)
- [[{type}-{slug}]] -- {one-line hook}
Markers: ✅ = promoted | ⚠️ = superseded
```
B1 adds: ⚡ = evolved to skill

## Files to Change

### CREATE (12 files)

| File | Scope | Purpose |
|------|-------|---------|
| `templates/AGENT.md.tmpl` | A1 | Universal identity template (replaces CLAUDE.md.tmpl + AGENTS.md.tmpl) |
| `templates/adapters/claude.md` | A1 | Claude Code adapter instructions (how to wire AGENT.md → .claude/) |
| `templates/adapters/cursor.md` | A1 | Cursor adapter instructions |
| `templates/adapters/codex.md` | A1 | Codex adapter instructions (generates AGENTS.md stub from AGENT.md) |
| `templates/adapters/generic.md` | A1 | Generic/fallback adapter (produces AGENTS.md-equivalent) |
| `skills/evolve.md` | B1 | Stage 6: graduate pattern → executable skill |
| `skills/supersede.md` | B2 | Mark old memory superseded by new |
| `skills/archive.md` | B3 | Archive stale memories |
| `skills/save.md` | C4 | Save session context only (no audit/commit/push) |
| `templates/memory/_evolutions.md.tmpl` | B6 | Skill evolution audit trail |
| `templates/.agent-config.yaml.tmpl` | C2 | Default config template |
| `VERSION` | C1 | Framework version (semver) |
| `LICENSE` | C8 | MIT license |

### UPDATE (13 files)

| File | Scope | What Changes | Insert At |
|------|-------|-------------|-----------|
| `skills/audit.md` | B4, B8 | Add Step 3.5 (skill candidate detection) + Step 3.6 (skill improvement detection) | After line 79 (Step 3 promotion check) |
| `skills/remember.md` | B5 | Add Step 4.5 (proactive skill detection when saving multi-step patterns) | After line 113 (Step 4 "Update MEMORY.md index") |
| `skills/handoff.md` | C4 | Refactor Step 2-3 to delegate to /save; keep Step 1 audit + Step 6-7 commit/push | Rewrite Steps 2-5, keep 0-1 and 6-8 |
| `skills/recall.md` | C3 | Enhance Step 3 search strategy: add frontmatter-first scan, config-driven limits | Rewrite Step 3 (lines 39-50) |
| `skills/resume.md` | A1 | Change "CLAUDE.md" → "AGENT.md" in Self-Configuration | Lines 12-17 |
| `skills/apply.md` | A1, B7 | Change "CLAUDE.md" → "AGENT.md"; mention evolved_to field | Lines 10-15 |
| `skills/promote.md` | A1 | Change "CLAUDE.md" → "AGENT.md" throughout (target section ref) | Lines 11-16, 66-78, 96-99 |
| `scripts/agent-init.sh` | A3, C7 | Add bash version check; decouple wizard to work with any tool | Lines 1-10 (version check), lines 32-48 (wizard install) |
| `scripts/agent-install.sh` | A2, C5 | Add --target flag (claude\|cursor\|generic); add checksum conflict detection | Lines 9-36 (rewrite install logic) |
| `scripts/agent-install-all.sh` | A2 | Pass --target to agent-install.sh; update detection markers (AGENT.md not CLAUDE.md) | Lines 47-48 (marker grep), line 55 |
| `templates/.gitignore.tmpl` | C6 | Fix comment: "uncomment to EXCLUDE memory from git" (current comment is backwards) | Line 14 |
| `templates/memory/latest-handoff.md` | C10 | Add placeholder text instead of empty file | Replace empty content |
| `templates/memory/_template/feedback-template.md` | B7 | Add `evolved_to: null` and `skill_version: null` to frontmatter | After line 16 (`promoted_to: null`) |
| `templates/memory/_template/pattern-template.md` | B7 | Add `evolved_to: null` and `skill_version: null` to frontmatter | After line 14 (`promoted_to: null`) |

### UPDATE (docs — 4 files)

| File | Scope | What Changes |
|------|-------|-------------|
| `docs/LEARNING-LOOP.md` | B1 | Add Stage 6 section (Skill Evolution) after Stage 5 (~60 lines) |
| `docs/CUSTOMIZATION.md` | A4 | Remove Section 5 "Connecting to MCP Memory Backend"; update Section 6 sync for AGENT.md |
| `docs/INSTALLATION.md` | A1-A3 | Update all CLAUDE.md refs → AGENT.md; update wizard instructions; add --target docs |
| `README.md` | A1, B1, C1 | Update Quick Start; add Stage 6 to loop diagram; add version badge |

### DELETE (0 files)

Legacy templates (`CLAUDE.md.tmpl`, `AGENTS.md.tmpl`) are **kept for one release** as backward-compat stubs. They are no longer the source of truth but are used by adapters to generate tool-specific compatibility files (Finding F2). They will be deprecated in v2.1 and removed in v3.0.

## Integration Points

| New Code | Hooks Into | How |
|----------|-----------|-----|
| `skills/evolve.md` | `skills/audit.md` Step 3.5 | Audit suggests `/evolve <slug>` when pattern is skill candidate |
| `skills/evolve.md` | `memory/_evolutions.md` | Writes evolution audit row (parallel to `_promotions.md` in `/promote`) |
| `skills/evolve.md` | `memory/MEMORY.md` | Adds `⚡ evolved to skill` marker on index entry |
| `skills/save.md` | `skills/handoff.md` Step 2 | Handoff calls `/save` inline for session context save |
| `skills/supersede.md` | `memory/MEMORY.md` | Adds `⚠️ superseded` marker on index entry |
| `scripts/agent-install.sh --target` | `templates/adapters/*.md` | Reads adapter instructions to determine install paths per tool |
| `templates/AGENT.md.tmpl` | `wizard/wizard.md` Phase 4 Step 3 | Wizard generates AGENT.md from this template (was CLAUDE.md.tmpl) |
| `.agent-config.yaml` | All skills Self-Configuration | Skills read config at startup for thresholds (promotion_threshold, stale_days, etc.) |
| `VERSION` | `wizard/wizard.md` Phase 4 | Stamped in generated AGENT.md footer |

## NOT Building

- **MCP memory backend** — explicitly out of scope per user decision (vault/flat file only)
- **CI/CD pipeline** — no tests to run (pure markdown + bash); manual validation
- **Automated adapter generation** — adapters are static markdown templates, not programmatic generators
- **Cross-agent memory sharing** — future scope; current is single-agent local files
- **Migration script from v1 → v2** — agents can re-run wizard or manually rename CLAUDE.md → AGENT.md

## Step-by-Step Tasks

### Phase 1: Foundation (C1, C2, C8)

#### Task 1: Create VERSION, LICENSE, .agent-config.yaml template
**ACTION**: CREATE `VERSION`, `LICENSE`, `templates/.agent-config.yaml.tmpl`
**IMPLEMENT**:
- `VERSION`: Single line `2.0.0`
- `LICENSE`: Standard MIT license text, copyright `2026 OpenClaw`
- `.agent-config.yaml.tmpl`:
```yaml
# Agent Framework Configuration
# Copy to .agent-config.yaml in your agent repo to customize.

learning_loop:
  promotion_threshold: 3        # applied_count needed for promotion
  evolution_threshold: 3        # applied_count needed for skill evolution
  stale_days: 30                # days without apply before flagged stale
  max_recall_results: 5         # max results from /recall
  auto_audit_on_handoff: true   # run /audit during /handoff

identity:
  file: AGENT.md                # primary identity file name
  budget: "5.00 USD"            # default budget per session
```
**MIRROR**: No existing config files; follow YAML conventions from memory templates
**VALIDATE**: `test -f VERSION && test -f LICENSE && test -f templates/.agent-config.yaml.tmpl && echo OK`

#### Task 2: Fix .gitignore.tmpl comment
**ACTION**: UPDATE `templates/.gitignore.tmpl`
**IMPLEMENT**: Change line 14 from `# Memory (optional — uncomment to track memory in git)` to `# Memory (optional — uncomment to EXCLUDE memory from git tracking)`. The current comment says the opposite of what uncommenting the line does.
**MIRROR**: `templates/.gitignore.tmpl:9` (existing comment pattern)
**VALIDATE**: `grep -q "EXCLUDE" templates/.gitignore.tmpl && echo OK`

#### Task 3: Add placeholder to latest-handoff.md
**ACTION**: UPDATE `templates/memory/latest-handoff.md`
**IMPLEMENT**: Replace empty file with:
```markdown
# Latest Handoff

> No sessions recorded yet. Run `/handoff` at the end of your first session to populate this file.
> The next session's `/resume` will read this for context.
```
**VALIDATE**: `test -s templates/memory/latest-handoff.md && echo OK`

### Phase 2: Tool-Agnostic Refactor (A1-A4)

#### Task 4: Create AGENT.md.tmpl (universal identity template)
**ACTION**: CREATE `templates/AGENT.md.tmpl`
**IMPLEMENT**: Merge `CLAUDE.md.tmpl` and `AGENTS.md.tmpl` into one universal template:
- Keep the Identity table, Persona, Philosophy, Capabilities, Memory System, Budget sections from CLAUDE.md.tmpl
- Remove slash-command-specific syntax — use plain command names: `remember <slug>` not `/remember <slug>`
- Add `## Tool Integration` section at the bottom with a note: `> See docs/INSTALLATION.md for tool-specific setup (Claude Code, Cursor, Codex, etc.)`
- Add footer: `*Generated by agent-framework v{{VERSION}}*`
- Add `{{PROACTIVE_TRIGGERS_SECTION}}` (already in CLAUDE.md.tmpl)
- Add empty `## Escalation Rules` section (placeholder for user to fill)
- Add `## Schedule` section (empty placeholder)
- All `{{VARIABLE}}` placeholders remain identical to current templates
**MIRROR**: `templates/CLAUDE.md.tmpl:1-66` (structure), `templates/AGENTS.md.tmpl:47-49` (codex note style)
**GOTCHA**: Do NOT use `/command` syntax anywhere — must be tool-neutral. Commands referenced as `remember`, `recall`, `apply` etc.
**VALIDATE**: `grep -c '{{' templates/AGENT.md.tmpl` should return same count as current CLAUDE.md.tmpl (~10)

#### Task 5: Create adapter templates + compatibility stubs
**ACTION**: CREATE `templates/adapters/claude.md`, `templates/adapters/codex.md`, `templates/adapters/cursor.md`, `templates/adapters/generic.md`
**IMPLEMENT**: Each adapter is a short instruction file explaining how to wire AGENT.md skills into the specific tool, PLUS generates a compatibility stub file:
- `claude.md`: Skills → `.claude/commands/agent-core/`. **MUST generate `CLAUDE.md`** as a compatibility stub (Claude Code requires this filename). Stub content: `<!-- Auto-generated from AGENT.md by agent-framework. Edit AGENT.md, not this file. -->` + full copy of AGENT.md content. Use `cp` not symlink (symlinks break on some filesystems/tools). Regenerate on every `agent-install --target claude`.
- `codex.md`: Skills → `.claude/commands/agent-core/` (Codex reads same directory). **MUST generate `AGENTS.md`** as a compatibility stub with codex-adapted command syntax (plain `remember` not `/remember`). Stub content: `<!-- Auto-generated from AGENT.md by agent-framework. Edit AGENT.md, not this file. -->` + AGENT.md content with command syntax adapted per `templates/AGENTS.md.tmpl:39-49` pattern. Regenerate on every `agent-install --target codex`.
- `cursor.md`: Skills → `.cursor/rules/agent-core/`. Cursor reads `.cursorrules` — adapter generates it from AGENT.md sections.
- `generic.md`: Skills → `skills/` directory. Generates `AGENTS.md` stub (same as codex adapter). For tools that need a specific filename, user creates their own symlink.
- Each adapter includes exact directory creation commands
- **Compatibility guarantee (F2)**: Every `agent-install` run regenerates tool-specific stubs from AGENT.md. Stubs are marked auto-generated and gitignored. AGENT.md is the single source of truth; stubs are derived artifacts.
**MIRROR**: `templates/AGENTS.md.tmpl:47-49` (note style for non-Claude tools)
**VALIDATE**: `ls templates/adapters/ | wc -l` should be 4

#### Task 6: Update agent-install.sh with --target routing + conflict detection
**ACTION**: UPDATE `scripts/agent-install.sh`
**IMPLEMENT**:
- Add `--target` flag parsing (accept: `claude`, `cursor`, `codex`, `generic`; default: auto-detect from repo)
- Auto-detect: check for `.claude/` → claude; `.cursor/` → cursor; `AGENTS.md` without `.claude/` → codex; else → generic
- Support comma-separated: `--target claude,cursor`
- Per target, install skills to correct directory:
  - `claude` → `.claude/commands/agent-core/` + regenerate `CLAUDE.md` stub from `AGENT.md`
  - `codex` → `.claude/commands/agent-core/` + regenerate `AGENTS.md` stub from `AGENT.md` (codex syntax)
  - `cursor` → `.cursor/rules/agent-core/`
  - `generic` → `skills/` (copy to repo root skills/ directory) + regenerate `AGENTS.md` stub
- Add conflict detection: before copying each skill, `md5sum` compare source vs destination. If different AND destination was modified after last install (check `.agent-framework-install-stamp` file), warn: `"WARNING: {file} has local modifications. Overwrite? [y/N]"`. If non-interactive (`--force`), overwrite with backup.
- Write `.agent-framework-install-stamp` with timestamp after successful install
- Update identity file detection: check for `AGENT.md` first, then fall back to `CLAUDE.md` / `AGENTS.md`
**MIRROR**: `scripts/agent-install.sh:1-9` (preamble pattern), `scripts/agent-install.sh:30-36` (skill copy loop)
**GOTCHA**: Keep backward compat — if repo has `CLAUDE.md` but no `AGENT.md`, still install (just warn about migration)
**VALIDATE**: `bash scripts/agent-install.sh --help` should show --target flag

#### Task 7: Update agent-init.sh (bash version check + wizard decouple)
**ACTION**: UPDATE `scripts/agent-init.sh`
**IMPLEMENT**:
- Add bash version check after line 4:
```bash
if ((BASH_VERSINFO[0] < 4)); then
    echo "Error: bash 4.0+ required (found ${BASH_VERSION}). On macOS: brew install bash"
    exit 1
fi
```
- Change wizard install to be tool-agnostic:
  - Still copy wizard.md to `.claude/commands/agent-init.md` IF `.claude/` exists or `claude` CLI detected
  - Also copy wizard.md to project root as `WIZARD.md` for non-Claude tools
  - Update instructions: "Run the wizard in your AI coding assistant: paste 'Follow the instructions in WIZARD.md' or use `/agent-init` in Claude Code"
- Save framework path: change `.agent-framework-path` to also record version: `echo "$FRAMEWORK_DIR $(cat $FRAMEWORK_DIR/VERSION 2>/dev/null || echo unknown)" > "$TARGET_DIR/.agent-framework-path"`
**MIRROR**: `scripts/agent-init.sh:1-10` (preamble), `scripts/agent-init.sh:46-48` (wizard install)
**VALIDATE**: `bash scripts/agent-init.sh --help 2>&1 | head -1`

#### Task 8: Update agent-install-all.sh
**ACTION**: UPDATE `scripts/agent-install-all.sh`
**IMPLEMENT**:
- Update detection markers: grep for `"Agent ID\|Memory System\|Learning Loop\|AGENT.md"` (add AGENT.md)
- Pass `--target` to agent-install.sh if provided (add `--target` flag parsing with pass-through)
- Update agent_name extraction: try `AGENT.md` first, then `CLAUDE.md`
**MIRROR**: `scripts/agent-install-all.sh:47-48` (grep pattern)
**VALIDATE**: `bash scripts/agent-install-all.sh --dry-run 2>&1 | head -5`

#### Task 9: Update wizard.md for tool-agnostic generation
**ACTION**: UPDATE `wizard/wizard.md`
**IMPLEMENT**:
- Phase 0 Runtime Detection: detect any `.claude/`, `.cursor/`, `.codex/` — no longer default to "both Claude + Codex" but "detected runtimes + generic"
- Phase 4 Step 3: read `AGENT.md.tmpl` instead of `CLAUDE.md.tmpl`; generate `AGENT.md` (universal)
- Phase 4 Step 4: REMOVE separate AGENTS.md generation step; instead, based on detected runtimes, generate compatibility stubs:
  - If Claude Code detected: copy AGENT.md → CLAUDE.md with auto-generated header (not symlink — compat)
  - If Codex detected: generate AGENTS.md stub with codex command syntax
  - If Cursor detected: create `.cursorrules` reference
  - Always: AGENT.md is the primary
- Phase 4 Step 2 (memory templates): ALSO copy `_evolutions.md.tmpl` → `memory/_evolutions.md` (with {{AGENT_NAME}} replacement) and copy `.agent-config.yaml.tmpl` → `.agent-config.yaml` in the new agent repo (F3: fresh scaffolds must have Stage 6 runtime artifacts)
- Phase 4 Step 8 (git commit): update staged files list (AGENT.md instead of CLAUDE.md + AGENTS.md)
- Phase 5 (Summary): update created files list
- Initialization: read VERSION file from framework and use in footer stamp
- Remove slash-command format from the file's own frontmatter description (make it a generic instruction doc)
**MIRROR**: `wizard/wizard.md:26-55` (initialization pattern), `wizard/wizard.md:278-343` (Phase 4 build steps)
**GOTCHA**: Wizard must still WORK as a slash command in Claude Code (the frontmatter `description` field), but also work as a plain instruction file for other tools. Keep the frontmatter.
**VALIDATE**: `grep -c 'CLAUDE.md.tmpl' wizard/wizard.md` should be 0 after update

#### Task 10: Remove MCP section from CUSTOMIZATION.md + update sync section
**ACTION**: UPDATE `docs/CUSTOMIZATION.md`
**IMPLEMENT**:
- Delete Section 5 "Connecting to MCP Memory Backend" entirely (lines 229-269)
- Renumber Section 6 → Section 5
- Update Section 5 (was 6) "Syncing CLAUDE.md and AGENTS.md" → "Tool-Specific Adapters":
  - Explain AGENT.md is the single source of truth
  - Describe how adapters create tool-specific configs
  - Remove "Commit discipline: update both in same commit" (no longer relevant — single source)
**MIRROR**: `docs/CUSTOMIZATION.md:1-10` (section style)
**VALIDATE**: `grep -c 'MCP Memory Backend' docs/CUSTOMIZATION.md` should be 0

### Phase 3: Stage 6 — Skill Evolution (B1-B8)

#### Task 11: Update memory schema (add evolved_to + skill_version)
**ACTION**: UPDATE `templates/memory/_template/feedback-template.md`, `templates/memory/_template/pattern-template.md`
**IMPLEMENT**: Add two fields after `promoted_to: null` in both files:
```yaml
  evolved_to: null           # null | "skill:{skill-name}"
  skill_version: null         # null | 1, 2, 3...
```
Also update the schema examples in `skills/remember.md` Step 3 (lines 73-89) — add the same two fields to the full schema block.
**MIRROR**: `templates/memory/_template/feedback-template.md:16` (promoted_to line)
**VALIDATE**: `grep -c 'evolved_to' templates/memory/_template/feedback-template.md` should be 1

#### Task 12: Create _evolutions.md template
**ACTION**: CREATE `templates/memory/_evolutions.md.tmpl`
**IMPLEMENT**:
```markdown
# Skill Evolution Log — {{AGENT_NAME}}

> Audit trail of memory patterns evolved into executable skills.

## Criteria

**Standard evolution** (all required):
- `applied_count >= 3` (or configured `evolution_threshold`)
- `verified_by_user = yes` consistently
- "How to apply" section contains >= 3 distinct steps (workflow, not rule)
- Applied across >= 2 distinct contexts

## Active Evolutions

| Date | Source Memory | Skill Created | Applied | Contexts | Version | Status |
|------|-------------|---------------|---------|----------|---------|--------|

## Retired Skills

| Date | Skill | Reason | Replaced By |
|------|-------|--------|-------------|

---
*Maintained by `/evolve` command*
```
**MIRROR**: `templates/memory/_promotions.md.tmpl` (parallel structure)
**VALIDATE**: `test -f templates/memory/_evolutions.md.tmpl && echo OK`

#### Task 13: Create /evolve skill
**ACTION**: CREATE `skills/evolve.md`
**IMPLEMENT**: New skill following the standard skill structure:
- **Self-Configuration**: Read `AGENT.md` (not CLAUDE.md) for agent identity
- **When to Use**: Audit suggests evolution candidate; user manually requests; proactive detection from /remember
- **Arguments**: `$ARGUMENTS` = pattern slug (e.g., `pattern-pre-deploy-workflow`)
- **Steps**:
  1. Find memory entry: `find memory -type f -name "*-$ARGUMENTS.md"` (same as /apply)
  2. Verify evolution criteria:
     - `applied_count >= 3` (read from `.agent-config.yaml` → `evolution_threshold`, default 3)
     - `verified_by_user = yes`
     - "How to apply" section has >= 3 actionable steps — count ONLY items under the "How to apply" heading (not "Anti-patterns", "Trigger", "Related", or inline examples). Count numbered list items (`1.`, `2.`, `3.`) or `### Step N` subsections. Exclude lines that are pure examples or notes (lines starting with `e.g.`, `Example:`, `Note:`) (F4)
     - Applied across >= 2 distinct contexts — read `contexts` list from frontmatter (preferred) or parse Change Log entries for unique context strings if `contexts` is empty/missing (F4: backward compat for pre-v2 memories)
     - `evolved_to = null` (not already evolved)
     - `status = active`
     - If criteria not met → output reasoning, offer fast-track with user approval
  3. Extract workflow steps from "How to apply" section + analyze Change Log for variations
  4. Draft skill file:
     - Frontmatter: `description: {extracted from memory}`
     - Add `## Evolved From` section with `[[source-memory]]` link, applied count, contexts
     - Add `## Steps` with each extracted step as a subsection
     - Add `## Revision History` section
  5. Show draft to user — NEVER auto-create. Ask for confirmation + name
  6. On approval:
     - Write skill file to `skills/` directory (or configured skill location)
     - Update source memory: `evolved_to: "skill:{name}"`, `status: evolved`
     - Add Change Log entry: `{date}: evolved to skill:{name}`
  7. Update `memory/_evolutions.md`: append row to Active Evolutions table
  8. Update `memory/MEMORY.md`: add `⚡ evolved to skill` marker on index entry
  9. Confirm to user with file path and next steps
- **Rules**:
  - Never auto-create without user confirmation
  - Keep source memory file (audit trail)
  - Skill file name = verb form of the pattern (e.g., `pattern-pre-deploy` → `pre-deploy.md`)
  - Read `.agent-config.yaml` for `evolution_threshold` if file exists
**MIRROR**: `skills/promote.md` (parallel graduation path — same verify-draft-confirm-update pattern)
**VALIDATE**: `wc -l skills/evolve.md` should be 120-180 lines

#### Task 14: Create /supersede skill
**ACTION**: CREATE `skills/supersede.md`
**IMPLEMENT**: New skill:
- **Self-Configuration**: Read `AGENT.md`
- **Arguments**: `$ARGUMENTS` = `<old-slug> <new-slug>` (space-separated)
- **Steps**:
  1. Parse arguments into old_slug and new_slug
  2. Find both memory files via `find memory -type f -name "*-{slug}.md"`
  3. Verify both exist; if not → error with suggestions
  4. Update old entry frontmatter: `status: superseded`, add `superseded_by: "[[{new-slug}]]"`
  5. Update new entry body: add `## Supersedes` section with `[[{old-slug}]]` link
  6. Update `memory/MEMORY.md`: add `⚠️` marker on old entry's index line
  7. Confirm to user: show both files updated
- **Rules**:
  - Old entry is NEVER deleted — status change only
  - If old entry was promoted (has `promoted_to`), warn user: "This memory was promoted to AGENT.md — consider updating or removing the rule."
  - If old entry was evolved (has `evolved_to`), warn: "This memory was evolved to a skill — the skill may need updating."
**MIRROR**: `skills/apply.md` (similar find-read-update-confirm pattern)
**VALIDATE**: `test -f skills/supersede.md && echo OK`

#### Task 15: Create /archive skill
**ACTION**: CREATE `skills/archive.md`
**IMPLEMENT**: Simpler version of /supersede:
- **Self-Configuration**: Read `AGENT.md`
- **Arguments**: `$ARGUMENTS` = memory slug
- **Steps**:
  1. Find memory file
  2. Update frontmatter: `status: archived`
  3. Add Change Log entry: `{date}: archived — {reason if provided}`
  4. Update `memory/MEMORY.md`: move entry to bottom of its section, mark with strikethrough or `(archived)` suffix
  5. Confirm to user
- **Rules**: Archived memories excluded from `/recall` by default (existing rule in recall.md Step 5)
**MIRROR**: `skills/supersede.md` (simpler version of same pattern)
**VALIDATE**: `test -f skills/archive.md && echo OK`

#### Task 16: Create /save skill
**ACTION**: CREATE `skills/save.md`
**IMPLEMENT**: Extracted from `/handoff` Steps 2-5 (session context save without audit/commit/push):
- **Self-Configuration**: Read `AGENT.md`
- **When to Use**: Quick session checkpoint; mid-session save without ending; called by `/handoff` internally
- **Steps**:
  1. Summarize session: what was accomplished, decisions, state, open questions, next steps
  2. Create session memory file: `memory/{YYYY-MM}/{date}-session-{slug}.md`
  3. Update `memory/MEMORY.md` index under `## Session History`
  4. Overwrite `memory/latest-handoff.md` with session content
  5. Confirm to user (no git operations)
- **Rules**:
  - NO audit (that's `/handoff`'s job)
  - NO git commit/push (that's `/handoff`'s job)
  - Safe to call multiple times per session (creates separate dated files)
**MIRROR**: `skills/handoff.md:59-145` (Steps 2-5, extracted verbatim then simplified)
**VALIDATE**: `test -f skills/save.md && echo OK`

#### Task 17: Update /audit for skill candidate + skill improvement detection
**ACTION**: UPDATE `skills/audit.md`
**IMPLEMENT**:
- Add **Step 3.5 — Check skill evolution candidates** after Step 3 (line 79):
  - For each `pattern`/`feedback` entry with `applied_count >= evolution_threshold`:
    - Read the file body; count steps in "How to apply" section
    - If >= 3 steps AND `evolved_to = null` → skill candidate
  - Add new output section: `### Ready to Evolve (skills) ({N})`
  - Format: `- {name} — applied {N}x across {M} contexts, {S} steps -> suggest: /evolve {name}`
- Add **Step 3.6 — Check skill improvement candidates**:
  - Search for `feedback` entries where `category` matches an existing skill name (in skills/ directory)
  - If such feedback has `applied_count >= 3` → skill improvement candidate
  - Add output section: `### Skill Improvements Suggested ({N})`
  - Format: `- skill:{name} has {N} verified corrections -> suggest: update skill and bump version`
- Read `.agent-config.yaml` for `evolution_threshold` (default 3 if no config)
**MIRROR**: `skills/audit.md:64-79` (Step 3 promotion check — parallel structure)
**GOTCHA**: Don't double-count — if an entry is both a promotion AND evolution candidate, prefer evolution (workflows should become skills, not rules)
**VALIDATE**: `grep -c 'skill evolution\|skill improvement' skills/audit.md` should be >= 2

#### Task 18: Update /remember for proactive skill detection
**ACTION**: UPDATE `skills/remember.md`
**IMPLEMENT**: Add **Step 4.5 — Proactive skill evolution detection** after Step 4 (MEMORY.md update, ~line 143):
- When saving a `pattern` type entry:
  - Count steps in the "How to apply" section being saved
  - If >= 3 steps:
    1. Search existing memories: `grep -rli "category: {same-category}" memory/ --include="*.md"`
    2. For each match with `type: pattern` and `applied_count >= 2`:
       - Check if "How to apply" has overlapping step keywords
    3. If found similar: suggest proactively (ADVISORY only — never auto-create, F4):
       ```
       This looks like a repeated workflow. Combined with [[existing-pattern]],
       this could become a reusable skill.
       Want me to draft a skill? (run /evolve {suggested-name})
       ```
       The keyword overlap check is a hint, not a gate — false positives are acceptable because the user decides. False negatives (missing a match) are preferred over false auto-creation.
  - If < 3 steps: skip silently (it's a rule, not a workflow)
**MIRROR**: `skills/remember.md:28-38` (existing auto-trigger detection table — same proactive style)
**VALIDATE**: `grep -c 'skill evolution\|proactive skill' skills/remember.md` should be >= 1

#### Task 19: Update /handoff to delegate to /save
**ACTION**: UPDATE `skills/handoff.md`
**IMPLEMENT**:
- Step 2 (Summarize) + Step 3 (Save memory) + Step 4 (Update MEMORY.md) + Step 5 (Update latest-handoff.md) → replace with: "Invoke `/save` to save session context (see save.md for full procedure)"
- Keep: Step 0 (pre-flight), Step 1 (audit), Step 6 (commit), Step 7 (push), Step 8 (surface action items)
- Add to Step 8: include skill evolution candidates from audit (if any)
- Net effect: handoff = audit + save + commit + push (save is now a separate reusable skill)
**MIRROR**: `skills/handoff.md:0-57` (keep Steps 0-1 structure)
**GOTCHA**: `/save` must be called AFTER `/audit` (audit informs the session summary)
**VALIDATE**: `grep -c '/save' skills/handoff.md` should be >= 1

### Phase 4: All Skills Tool-Neutral Update + Docs (A1 across all skills)

#### Task 20: Update all skills Self-Configuration + docs
**ACTION**: UPDATE all 11 skills (7 original + 4 new), `docs/LEARNING-LOOP.md`, `docs/INSTALLATION.md`, `README.md`
**IMPLEMENT**:
- **All skills**: In Self-Configuration section, change `Read the repo's \`CLAUDE.md\`` → `Read the repo's \`AGENT.md\` (or \`CLAUDE.md\` for backward compatibility)`:
  - `skills/remember.md:12`, `skills/recall.md:12`, `skills/apply.md:12`, `skills/audit.md:12`, `skills/handoff.md:12`, `skills/resume.md:12`, `skills/promote.md:12`
  - New skills (evolve, supersede, archive, save) should already reference AGENT.md from creation
- **skills/apply.md**: In Step 2 (Bump metadata), also append current context string to `contexts` list in frontmatter (creates the list if missing). This builds the context history needed for multi-context verification in /audit and /evolve (F4).
- **skills/promote.md**: Change all `CLAUDE.md` references in target section logic (Step 2, Step 4) → `AGENT.md`:
  - `skills/promote.md:66` "CLAUDE.md target section" → "AGENT.md target section"
  - `skills/promote.md:78` "CLAUDE.md#section" → "AGENT.md#section"
  - `skills/promote.md:96` "Insert into CLAUDE.md" → "Insert into AGENT.md"
- **docs/LEARNING-LOOP.md**: Add Stage 6 section after Stage 5 (after line 216):
  - Title: `## Stage 6: EVOLVE SKILL — Graduate to executable command`
  - Content: detection criteria (multi-step patterns), evolution process, skill improvement loop, difference from promotion (rules vs workflows)
  - Add Stage 6 to the ASCII diagram (line 27-39)
  - Update "Session Lifecycle" flow chart to include skill evolution check
- **docs/INSTALLATION.md**: Replace all `CLAUDE.md` → `AGENT.md`; update wizard instructions for tool-agnostic flow; add --target docs for agent-install
- **README.md**:
  - Update overview: 6-Stage Learning Loop (was 5), add `evolve` to command list
  - Update Quick Start: reference `AGENT.md` not `CLAUDE.md`
  - Update Learning Loop diagram: add Stage 6 box
  - Add `## Version` section or badge area
  - Update Project Structure tree (add new files: adapters/, evolve.md, etc.)
  - Update Commands Reference: add /evolve, /supersede, /archive, /save
  - Add note: "v2.0 is tool-agnostic — works with Claude Code, Cursor, Codex, and any AI coding assistant"
**MIRROR**: Existing CLAUDE.md references across all files (use global find-replace where safe)
**GOTCHA**: Don't change `CLAUDE.md` references in the wizard's backward-compatibility symlink logic (Task 9)
**VALIDATE**: `grep -rl 'CLAUDE.md' skills/ templates/AGENT.md.tmpl docs/ | grep -v 'backward compat\|symlink\|fallback'` should return 0 files (only backward-compat mentions remain)

## Testing Strategy

### Manual Test Plan

| Test | Steps | Expected |
|------|-------|----------|
| Fresh agent scaffold | `agent-init /tmp/test-agent && cd /tmp/test-agent && claude` → `/agent-init` | AGENT.md generated, 11 skills installed, memory/ created |
| Backward compat | Run on repo with existing CLAUDE.md (no AGENT.md) | Skills install, CLAUDE.md detected, migration warning shown |
| --target claude | `agent-install --target claude /tmp/test-agent` | Skills in `.claude/commands/agent-core/` |
| --target cursor | `agent-install --target cursor /tmp/test-agent` | Skills in `.cursor/rules/agent-core/` |
| --target generic | `agent-install --target generic /tmp/test-agent` | Skills in `skills/` of target repo |
| /remember + /evolve | Create pattern with 4 steps, apply 3x, run /audit | Audit shows "Ready to Evolve" candidate |
| /supersede | Create two memories, supersede old with new | Old entry `status: superseded`, MEMORY.md has ⚠️ |
| /archive | Archive a stale memory | Status: archived, excluded from /recall |
| /save without commit | Run /save mid-session | Session file created, no git commit |
| /handoff delegates to /save | Run /handoff | Audit runs, /save called, git commit + push |
| Config override | Set `evolution_threshold: 5` in .agent-config.yaml | /audit uses 5 instead of default 3 |
| Conflict detection | Modify a skill locally, run agent-install | Warning about local modifications |

### Edge Cases

- [ ] Empty memory/ directory — /audit should handle gracefully (0 entries)
- [ ] No .agent-config.yaml — all skills use hardcoded defaults
- [ ] Pattern with exactly 2 steps — should NOT trigger skill evolution (rule threshold is 3)
- [ ] Pattern already evolved (`evolved_to` set) — /evolve should reject
- [ ] Pattern already promoted AND eligible for evolution — /audit should prefer evolution
- [ ] Repo with both CLAUDE.md and AGENT.md — skills should prefer AGENT.md
- [ ] No git remote configured — /handoff should commit locally, skip push with warning
- [ ] Bash 3.x on macOS — agent-init.sh should error clearly

## Docs Impact

| Doc | Action | Scope |
|-----|--------|-------|
| `README.md` | UPDATE | Stage 6, tool-agnostic, new commands, version |
| `docs/LEARNING-LOOP.md` | UPDATE | Add Stage 6 section (~60 lines) |
| `docs/CUSTOMIZATION.md` | UPDATE | Remove MCP section, update sync → adapters |
| `docs/INSTALLATION.md` | UPDATE | AGENT.md refs, --target flag, tool-agnostic wizard |

## Gate Compliance

Gate Compliance: N/A — this is an open-source framework repo (gobikom/agent-framework) with no CI, no deploy pipeline, no /gate skill, no production environment. Changes are pure markdown + bash, validated manually. No user-facing web pages, no API routes, no schema changes, no feature flags, no billing.

## Validation Commands

| Level | Command | Expected |
|-------|---------|----------|
| Static | `bash -n scripts/agent-init.sh && bash -n scripts/agent-install.sh && bash -n scripts/agent-install-all.sh` | Exit 0 (syntax valid) |
| Static | `find skills/ -name "*.md" -exec grep -L "Self-Configuration" {} \;` | Empty (all skills have Self-Configuration) |
| Static | `grep -rl 'Read the repo.*CLAUDE\.md' skills/ \| wc -l` | 0 (all updated to AGENT.md) |
| Smoke | `agent-init /tmp/af-test-$(date +%s) 2>&1` | "Wizard installed" message |
| Smoke | `agent-install /tmp/af-test-* --target generic 2>&1` | "11 skills installed" |
| Integration | Scaffold agent → run wizard → /resume → /remember → /recall → /handoff | Full lifecycle works |

## Confidence Score

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Patterns | 2/2 | All codebase patterns documented with file:line refs |
| Gotchas | 2/2 | Backward compat, bash version, config absence, slash command format |
| Integration | 2/2 | All hook points mapped (audit→evolve, handoff→save, remember→proactive) |
| Validation | 1/2 | No automated tests (pure markdown); manual validation plan covers all cases |
| Testing | 1/2 | Manual-only; edge cases enumerated but no executable test suite |

**Total: 8/10** — High confidence for one-pass implementation. -2 because no automated test suite exists (inherent to the project type).

## Acceptance Criteria

- [ ] AC1: `AGENT.md` is the universal identity file; `CLAUDE.md` and `AGENTS.md` are tool-specific adapters or symlinks
- [ ] AC2: `agent-install.sh --target claude|cursor|generic` installs skills to correct tool-specific directories
- [ ] AC3: Wizard generates `AGENT.md` (not `CLAUDE.md`) and creates tool-specific adapters based on detected runtimes
- [ ] AC4: MCP section removed from CUSTOMIZATION.md; docs reference flat-file-only memory
- [ ] AC5: `/evolve` command exists and can graduate a multi-step pattern into a skill file with user confirmation
- [ ] AC6: `/supersede` command marks old memory superseded and links to new entry
- [ ] AC7: `/archive` command sets status to archived and excludes from /recall
- [ ] AC8: `/audit` detects skill evolution candidates (patterns with applied_count >= 3 AND >= 3 steps)
- [ ] AC9: `/audit` detects skill improvement candidates (feedback about existing skills)
- [ ] AC10: `/remember` proactively suggests skill creation when saving multi-step patterns similar to existing ones
- [ ] AC11: `/save` extracts session save from `/handoff`; handoff delegates to save
- [ ] AC12: `.agent-config.yaml` controls thresholds (promotion, evolution, stale_days, recall_results)
- [ ] AC13: All skills read identity from `AGENT.md` (with CLAUDE.md fallback)
- [ ] AC14: VERSION file exists; generated AGENT.md includes version footer
- [ ] AC15: `docs/LEARNING-LOOP.md` documents Stage 6 with diagram
- [ ] AC16: README updated with 6-stage loop, tool-agnostic messaging, new commands
- [ ] AC17: Backward compatibility: existing agents with CLAUDE.md still work (skills detect and use it)

## Completion Checklist

- [ ] All 20 tasks implemented
- [ ] All skills have Self-Configuration reading AGENT.md (with CLAUDE.md fallback)
- [ ] No unintended CLAUDE.md references remain (except backward compat)
- [ ] Manual test: scaffold fresh agent with wizard
- [ ] Manual test: install to existing agent with --target
- [ ] Manual test: full learning loop through Stage 6
- [ ] README, LEARNING-LOOP, CUSTOMIZATION, INSTALLATION updated

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Breaking existing agents (CLAUDE.md → AGENT.md rename) | HIGH | MEDIUM | Backward compat: skills check AGENT.md first, fall back to CLAUDE.md. Wizard creates symlink. |
| Wizard too complex for non-Claude tools | MEDIUM | HIGH | Wizard.md works as plain instruction (any tool reads markdown). Bash fallback in agent-init.sh creates .agent-wizard-answers.yaml for simpler flow. |
| Skill evolution criteria too strict/loose | LOW | LOW | Configurable via .agent-config.yaml; defaults match promotion threshold (3). |
| /evolve creates low-quality skills | LOW | MEDIUM | Never auto-create; always show draft for user confirmation. Revision History tracks improvements. |
| adapter proliferation (new tools) | LOW | LOW | Generic adapter covers all; tool-specific adapters are optional enhancement. Community can contribute. |

---

## Peer Review Amendments

Reviewed by **devlead-codex** on 2026-07-09. APPROVE with 4 findings, all applied:

| Finding | Summary | Amendment |
|---------|---------|-----------|
| F1 | Missing Codex adapter — `--target codex` defined but no adapter template | Added `templates/adapters/codex.md` (CREATE count: 12→13). Codex adapter generates `AGENTS.md` stub with codex command syntax. |
| F2 | Backward compat: Claude Code **requires** `CLAUDE.md` filename; symlinks unreliable | Changed strategy: adapters generate compatibility stub FILES (not symlinks). `CLAUDE.md` and `AGENTS.md` are auto-generated derived artifacts from `AGENT.md`. Legacy templates kept for one release. DELETE count: 2→0. |
| F3 | Wizard (Task 9) missing `_evolutions.md` and `.agent-config.yaml` in fresh scaffold | Added to wizard Phase 4 Step 2: copy both templates into new agent repos. |
| F4 | Stage 6 context detection unreliable from single `last_context` field; step counting too loose | Added `contexts: []` list to schema (populated by /apply). Step counting scoped to "How to apply" only, excludes examples/notes. Keyword overlap in /remember is advisory only. |

---

*Plan generated by PSak (Analyst & Architect) — agent-framework v2.0.0*
*Peer-reviewed by devlead-codex — APPROVE with findings (all applied)*
*Next step: `/prp-core:prp-implement .prp-output/plans/agent-framework-v2-tool-agnostic-skill-evolution-20260709-2130.plan.md`*
