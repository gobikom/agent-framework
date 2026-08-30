# Agent Framework

> v2.0.0 — Tool-agnostic agent scaffolding with memory, learning loop, and self-improving skills.

Scaffold persistent AI agents with memory, learning loop, personality, and multi-tool support.

## Overview

Agent Framework creates a complete agent repo with:

- **Identity** — `AGENT.md` as the single source of truth, with tool-specific adapters for Claude Code, Cursor, Codex, and others
- **Persistent Memory** — `memory/` directory with structured YAML-frontmatter markdown files
- **6-Stage Learning Loop** — Capture → Apply → Verify → Evolve → Promote → Skill Evolution
- **11 Core Skills** — remember, recall, apply, audit, handoff, resume, promote, evolve, supersede, archive, save
- **Tool-Agnostic** — works with Claude Code, Cursor, Codex, and any AI coding assistant
- **Multi-Project Scoping** — tag memories by `project:`; `promote`/`resume` route project-specific rules to per-project identity files (`projects/<name>/AGENT.md`) so unrelated projects stay uncluttered. Optional — single-project agents ignore it. See [docs/CUSTOMIZATION.md §6](docs/CUSTOMIZATION.md).
- **Zero Dependencies** — Pure markdown + bash. No database, no server, no runtime.

## Quick Start

```bash
# 1. Create a new agent
agent-init ~/repos/my-agent/

# 2. Run the wizard in your AI coding assistant
cd ~/repos/my-agent
# Claude Code: type /agent-init
# Other tools: paste "Follow the instructions in WIZARD.md"

# 3. Start working — your agent has memory now
resume            # Load last session context
remember <slug>   # Save something to memory
recall <keyword>  # Search memory
handoff           # End session (save + commit + push)
```

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for full setup instructions.

## How It Works

### The Learning Loop

AI agents forget everything between sessions. The Learning Loop solves this with a 6-stage pipeline that turns corrections into permanent behavioral changes:

```
  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
  │ 1 CAPTURE│──>│ 2 APPLY  │──>│ 3 VERIFY │──>│ 4 EVOLVE │──>│ 5 PROMOTE│──>│ 6 SKILL  │
  │ /remember│   │ /apply   │   │ (auto)   │   │ /audit   │   │ /promote │   │ /evolve  │
  └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
       ^                                              |               |              |
       └──────────────────────────────────────────────┘               v              v
                          refine                              AGENT.md rule    Executable skill
```

| Stage | What Happens | Command |
|-------|-------------|---------|
| **CAPTURE** | Agent detects a correction, pattern, or decision → saves to `memory/` | `remember` |
| **APPLY** | Before acting, agent recalls relevant memories → announces transparently | `recall` + `apply` |
| **VERIFY** | User confirms or corrects → memory metadata updated | (embedded in apply) |
| **EVOLVE** | Session-end audit: stale? missed? promotion-ready? skill-ready? | `audit` (auto via `handoff`) |
| **PROMOTE** | Memory proven 3+ times across contexts → graduates to AGENT.md | `promote` |
| **SKILL EVOLUTION** | Multi-step workflow proven reliable → graduates to executable skill | `evolve` |

See [docs/LEARNING-LOOP.md](docs/LEARNING-LOOP.md) for the full architecture and rationale.

### The Wizard

The wizard asks 6 freetext questions in a single prompt:

1. **Agent name** — "TestBot", "Vera", "Atlas"
2. **Role / purpose** — "QA engineer", "Code reviewer", "DevOps specialist"
3. **Personality / tone** — "Friendly, uses emoji sparingly", "Precise and formal"
4. **Philosophy / hard rules** — "Always test before deploy", "Never assume, always ask"
5. **Human name** — How the agent should address you
6. **Language** — Primary language for output

The AI parses freetext answers, generates full persona + philosophy prose, and creates all files in one pass. No presets, no templates to fill — the wizard creates a unique agent from your description.

### Memory Structure

```
memory/
├── MEMORY.md                         <- Index (Map of Content, wikilinks)
├── _promotions.md                    <- Promotion audit trail
├── _evolutions.md                    <- Skill evolution audit trail
├── _template/                        <- Memory file templates
│   ├── feedback-template.md
│   └── pattern-template.md
├── latest-handoff.md                 <- Quick-access to last session
└── 2026-07/                          <- Monthly folders (auto-created)
    ├── 2026-07-06-feedback-slug.md   <- Memory entries
    └── 2026-07-06-pattern-slug.md
```

Each memory entry has YAML frontmatter tracking: `applied_count`, `last_applied`, `verified_by_user`, `promoted_to`, `evolved_to`, `status`. This metadata drives the learning loop — the agent can't promote or evolve something it hasn't verified.

## Tool-Agnostic Support

`AGENT.md` is the single source of truth. Tool-specific files are generated automatically by adapters:

| Tool | Identity | Skills | Install command |
|------|----------|--------|-----------------|
| **Claude Code** | `CLAUDE.md` (auto-generated from AGENT.md) | `.claude/commands/agent-core/` | `agent-install --target claude` |
| **Codex** | `AGENTS.md` (auto-generated from AGENT.md) | `.claude/commands/agent-core/` | `agent-install --target codex` |
| **Cursor** | `.cursorrules` (reference to AGENT.md) | `.cursor/rules/agent-core/` | `agent-install --target cursor` |
| **Generic** | `AGENTS.md` (auto-generated from AGENT.md) | `skills/` | `agent-install --target generic` |

Edit `AGENT.md` only — run `agent-install` to regenerate tool-specific stubs.

## Project Structure

```
agent-framework/
├── VERSION                        # Framework version (semver)
├── LICENSE                        # MIT license
├── scripts/
│   ├── agent-init.sh              # Scaffold new agent repo
│   ├── agent-install.sh           # Install/update skills in a repo (--target support)
│   └── agent-install-all.sh       # Batch update all agent repos
├── wizard/
│   └── wizard.md                  # Interactive birth wizard
├── templates/
│   ├── AGENT.md.tmpl              # Universal identity template (single source of truth)
│   ├── CLAUDE.md.tmpl             # Legacy Claude Code template (backward compat)
│   ├── AGENTS.md.tmpl             # Legacy Codex template (backward compat)
│   ├── .agent-config.yaml.tmpl    # Default configuration template
│   ├── .gitignore.tmpl            # Default gitignore
│   ├── adapters/                  # Tool-specific adapter instructions
│   │   ├── claude.md
│   │   ├── codex.md
│   │   ├── cursor.md
│   │   └── generic.md
│   └── memory/                    # Memory structure templates
│       ├── MEMORY.md.tmpl
│       ├── _promotions.md.tmpl
│       ├── _evolutions.md.tmpl    # Skill evolution audit trail
│       ├── latest-handoff.md
│       └── _template/
│           ├── feedback-template.md
│           └── pattern-template.md
├── skills/                        # 11 core learning loop commands
│   ├── remember.md                # Stage 1: CAPTURE
│   ├── recall.md                  # Memory search
│   ├── apply.md                   # Stage 2: APPLY (with verify)
│   ├── audit.md                   # Stage 4: EVOLVE (with skill detection)
│   ├── handoff.md                 # End-of-session (delegates to /save)
│   ├── resume.md                  # Start-of-session
│   ├── promote.md                 # Stage 5: PROMOTE
│   ├── evolve.md                  # Stage 6: SKILL EVOLUTION
│   ├── supersede.md               # Mark old memory replaced by new
│   ├── archive.md                 # Archive stale memories
│   └── save.md                    # Save session context (no commit)
└── docs/
    ├── INSTALLATION.md            # Setup and installation guide
    ├── LEARNING-LOOP.md           # Architecture deep-dive (6-stage)
    └── CUSTOMIZATION.md           # Persona, language, skills, adapters
```

## Commands Reference

### For Users (inside an agent repo)

| Command | Description |
|---------|-------------|
| `resume` | Start session — pull remote + load last handoff |
| `remember <slug>` | Save to memory (feedback, pattern, lesson, decision, etc.) |
| `recall <keyword>` | Search memory by keyword, type, or category |
| `apply <memory>` | Mark memory as applied + transparency announcement |
| `audit` | Session health report (applied, stale, promotion + evolution candidates) |
| `promote <memory>` | Graduate proven memory to AGENT.md hard rule |
| `evolve <memory>` | Graduate multi-step pattern to executable skill |
| `supersede <old> <new>` | Mark old memory replaced by new one |
| `archive <memory>` | Archive a stale memory |
| `save` | Save session context without commit/push |
| `handoff` | End session — audit + save + git commit + push |

### For Operators (managing the framework)

| Command | Description |
|---------|-------------|
| `agent-init [dir]` | Scaffold a new agent in target directory |
| `agent-install [dir]` | Install/update skills in an existing agent repo |
| `agent-install --target <tool> [dir]` | Install for specific tool (claude, cursor, codex, generic) |
| `agent-install-all` | Batch update all agent repos under ~/repos/ |
| `agent-install-all --dry-run` | Preview which repos would be updated |

## Documentation

| Document | Description |
|----------|-------------|
| [INSTALLATION.md](docs/INSTALLATION.md) | Setup, prerequisites, PATH integration, --target docs |
| [LEARNING-LOOP.md](docs/LEARNING-LOOP.md) | Architecture: why structural learning, 6-stage pipeline |
| [CUSTOMIZATION.md](docs/CUSTOMIZATION.md) | Persona, language, custom skills, tool adapters |

## Inspired By

| Source | What We Took |
|--------|-------------|
| [Oracle awaken ritual](https://github.com/Soul-Brews-Studio) | Wizard flow, batch freetext, brain filesystem concept |
| [KK (agent-kk)](https://github.com/gobikom/agent-kk) | 5-stage learning loop, local memory system, 7 commands |
| [PRP Framework](https://github.com/gobikom/prp-framework) | install-all pattern, CLAUDE.md injection, adapter model |

## License

MIT
