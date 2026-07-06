# Agent Framework

Scaffold persistent AI agents with memory, learning loop, personality, and dual-runtime support.

## Overview

Agent Framework creates a complete agent repo with:

- **Identity** — `CLAUDE.md` + `AGENTS.md` generated from an interactive wizard
- **Persistent Memory** — `memory/` directory with structured YAML-frontmatter markdown files
- **5-Stage Learning Loop** — Capture → Apply → Verify → Evolve → Promote
- **7 Core Skills** — remember, recall, apply, audit, handoff, resume, promote
- **Dual-Runtime** — Claude Code (slash commands) + Codex/Antigravity (AGENTS.md)
- **Zero Dependencies** — Pure markdown + bash. No database, no server, no runtime.

## Quick Start

```bash
# 1. Create a new agent
agent-init ~/repos/my-agent/

# 2. Open Claude Code in the new repo, run the wizard
cd ~/repos/my-agent && claude
# Then type: /agent-init

# 3. Start working — your agent has memory now
/resume            # Load last session context
/remember <slug>   # Save something to memory
/recall <keyword>  # Search memory
/handoff           # End session (save + commit + push)
```

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for full setup instructions.

## How It Works

### The Learning Loop

AI agents forget everything between sessions. The Learning Loop solves this with a 5-stage pipeline that turns corrections into permanent behavioral changes:

```
  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
  │ 1 CAPTURE│──>│ 2 APPLY  │──>│ 3 VERIFY │──>│ 4 EVOLVE │──>│ 5 PROMOTE│
  │ /remember│   │ /apply   │   │ (auto)   │   │ /audit   │   │ /promote │
  └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
       ^                                              |               |
       └──────────────────────────────────────────────┘               v
                          refine                              CLAUDE.md rule
```

| Stage | What Happens | Command |
|-------|-------------|---------|
| **CAPTURE** | Agent detects a correction, pattern, or decision → saves to `memory/` | `/remember` |
| **APPLY** | Before acting, agent recalls relevant memories → announces transparently | `/recall` + `/apply` |
| **VERIFY** | User confirms or corrects → memory metadata updated | (embedded in apply) |
| **EVOLVE** | Session-end audit: stale? missed? promotion-ready? | `/audit` (auto via `/handoff`) |
| **PROMOTE** | Memory proven 3+ times across contexts → graduates to CLAUDE.md | `/promote` |

See [docs/LEARNING-LOOP.md](docs/LEARNING-LOOP.md) for the full architecture and rationale.

### The Wizard

The `/agent-init` wizard asks 6 freetext questions in a single prompt:

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
├── _template/                        <- Memory file templates
│   ├── feedback-template.md
│   └── pattern-template.md
├── latest-handoff.md                 <- Quick-access to last session
└── 2026-07/                          <- Monthly folders (auto-created)
    ├── 2026-07-06-feedback-slug.md   <- Memory entries
    └── 2026-07-06-pattern-slug.md
```

Each memory entry has YAML frontmatter tracking: `applied_count`, `last_applied`, `verified_by_user`, `promoted_to`, `status`. This metadata drives the learning loop — the agent can't promote something it hasn't verified.

## Dual-Runtime Support

| Runtime | Identity File | Skills | Status |
|---------|--------------|--------|--------|
| **Claude Code** | `CLAUDE.md` | `.claude/commands/agent-core/*.md` (slash commands) | Full support |
| **Codex / Antigravity** | `AGENTS.md` | `.claude/commands/agent-core/*.md` (read by agent) | Identity + memory; skills via file reference |

Both files are generated from the same wizard answers. The content is identical; only the framing differs (slash commands vs natural language).

## Project Structure

```
agent-framework/
├── scripts/
│   ├── agent-init.sh              # Scaffold new agent repo
│   ├── agent-install.sh           # Install/update skills in a repo
│   └── agent-install-all.sh       # Batch update all agent repos
├── wizard/
│   └── wizard.md                  # Interactive birth wizard
├── templates/
│   ├── CLAUDE.md.tmpl             # Claude Code identity template
│   ├── AGENTS.md.tmpl             # Codex/Antigravity identity template
│   ├── .gitignore.tmpl            # Default gitignore
│   └── memory/                    # Memory structure templates
│       ├── MEMORY.md.tmpl         # Index template
│       ├── _promotions.md.tmpl    # Promotion log template
│       ├── latest-handoff.md      # Placeholder
│       └── _template/             # Memory entry templates
│           ├── feedback-template.md
│           └── pattern-template.md
├── skills/                        # 7 core learning loop commands
│   ├── remember.md                # Stage 1: CAPTURE
│   ├── recall.md                  # Memory search
│   ├── apply.md                   # Stage 2: APPLY (with verify)
│   ├── audit.md                   # Stage 4: EVOLVE
│   ├── handoff.md                 # End-of-session
│   ├── resume.md                  # Start-of-session
│   └── promote.md                 # Stage 5: PROMOTE
└── docs/
    ├── INSTALLATION.md            # Setup and installation guide
    ├── LEARNING-LOOP.md           # Architecture deep-dive
    └── CUSTOMIZATION.md           # Persona, language, skills customization
```

## Commands Reference

### For Users (inside an agent repo)

| Command | Description |
|---------|-------------|
| `/resume` | Start session — pull remote + load last handoff |
| `/remember <slug>` | Save to memory (feedback, pattern, lesson, decision, etc.) |
| `/recall <keyword>` | Search memory by keyword, type, or category |
| `/apply <memory>` | Mark memory as applied + transparency announcement |
| `/audit` | Session health report (applied, stale, promotion candidates) |
| `/promote <memory>` | Graduate proven memory to CLAUDE.md hard rule |
| `/handoff` | End session — audit + save + git commit + push |

### For Operators (managing the framework)

| Command | Description |
|---------|-------------|
| `agent-init [dir]` | Scaffold a new agent in target directory |
| `agent-install [dir]` | Install/update skills in an existing agent repo |
| `agent-install-all` | Batch update all agent repos under ~/repos/ |
| `agent-install-all --dry-run` | Preview which repos would be updated |

## Documentation

| Document | Description |
|----------|-------------|
| [INSTALLATION.md](docs/INSTALLATION.md) | Setup, prerequisites, PATH integration |
| [LEARNING-LOOP.md](docs/LEARNING-LOOP.md) | Architecture: why structural learning, 5-stage pipeline |
| [CUSTOMIZATION.md](docs/CUSTOMIZATION.md) | Persona, language, custom skills, MCP integration |

## Inspired By

| Source | What We Took |
|--------|-------------|
| [Oracle awaken ritual](https://github.com/Soul-Brews-Studio) | Wizard flow, batch freetext, brain filesystem concept |
| [KK (agent-kk)](https://github.com/gobikom/agent-kk) | 5-stage learning loop, local memory system, 7 commands |
| [PRP Framework](https://github.com/gobikom/prp-framework) | install-all pattern, CLAUDE.md injection, adapter model |

## License

MIT
