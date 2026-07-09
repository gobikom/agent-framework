---
pr: 2
branch: "feature/agent-framework-v2-tool-agnostic-skill-evolution"
extracted: 2026-07-09T16:30:00+07:00
files_changed: 32
head_sha: b45fe1f8079e90739b55d7a463c439ee51213f77
---

# PR Review Context: #2 — feat: Agent Framework v2 — tool-agnostic + Stage 6 Skill Evolution

## PR Metadata
- **Author**: gobikom
- **Branch**: feature/agent-framework-v2-tool-agnostic-skill-evolution → main
- **State**: OPEN
- **Size**: +1583/-460 across 32 files (2 commits)
- **HEAD SHA**: b45fe1f8079e90739b55d7a463c439ee51213f77

## Review Round
This is round 2. Round 1 found 5 critical + 3 important issues in bash scripts, all fixed in commit b45fe1f.
This review certifies the CURRENT code, not the pre-fix code.

## Project Guidelines
This is a pure markdown + bash project (zero dependencies). No TypeScript, no Node.js, no tests.
Skills are markdown instruction files read by AI coding assistants. Scripts are bash.

## Changed Files
LICENSE, README.md, VERSION, docs/CUSTOMIZATION.md, docs/INSTALLATION.md, docs/LEARNING-LOOP.md,
scripts/agent-init.sh, scripts/agent-install-all.sh, scripts/agent-install.sh,
skills/apply.md, skills/archive.md, skills/audit.md, skills/evolve.md, skills/handoff.md,
skills/promote.md, skills/recall.md, skills/remember.md, skills/resume.md, skills/save.md,
skills/supersede.md, templates/.agent-config.yaml.tmpl, templates/.gitignore.tmpl,
templates/AGENT.md.tmpl, templates/adapters/claude.md, templates/adapters/codex.md,
templates/adapters/cursor.md, templates/adapters/generic.md,
templates/memory/_evolutions.md.tmpl, templates/memory/_template/feedback-template.md,
templates/memory/_template/pattern-template.md, templates/memory/latest-handoff.md,
wizard/wizard.md

## Key fixes in this HEAD (from round 1 review)
- shopt -s inherit_errexit added to all 3 scripts
- install_skill_file() warnings redirected to stderr (not stdout)
- md5_of() returns unique sentinel per call + MD5_UNAVAILABLE flag
- .agent-framework-path writes path only (not path+version)
- cursor target now calls generate_stub ".cursorrules"
- agent-init.sh has TTY check for read -p
- agent-install-all.sh validates $REPOS_DIR exists
- cp || true replaced with conditional success message
- .gitignore.tmpl updated with v2 paths
