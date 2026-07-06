# Agent Framework

Scaffold persistent AI agents with memory, learning loop, personality, and dual-runtime support (Claude Code + Codex/Antigravity).

## What It Does

Creates a new AI agent repo with:
- **Identity** — CLAUDE.md + AGENTS.md generated from an interactive wizard
- **Persistent Memory** — `memory/` directory with structured YAML-frontmatter markdown files
- **5-Stage Learning Loop** — Capture → Apply → Verify → Evolve → Promote
- **7 Core Skills** — `/remember`, `/recall`, `/apply`, `/audit`, `/handoff`, `/resume`, `/promote`
- **Dual-Runtime** — Works with Claude Code (.claude/commands/) and Codex/Antigravity (AGENTS.md)

## Quick Start

### Create a New Agent

```bash
# From the target repo directory
~/repos/agents/agent-framework/scripts/agent-init.sh .

# Then in Claude Code:
/agent-init
# → Interactive wizard asks 6 questions → builds everything
```

### Update Skills in Existing Agent

```bash
# Single repo
~/repos/agents/agent-framework/scripts/agent-install.sh ~/repos/my-agent/

# All agent repos under ~/repos/
~/repos/agents/agent-framework/scripts/agent-install-all.sh
~/repos/agents/agent-framework/scripts/agent-install-all.sh --dry-run  # preview
```

## Structure

```
agent-framework/
├── scripts/
│   ├── agent-init.sh           # Scaffold new agent repo
│   ├── agent-install.sh        # Install/update skills in target repo
│   └── agent-install-all.sh    # Batch update all agent repos
├── wizard/
│   └── wizard.md               # Interactive birth wizard (Claude Code command)
├── templates/
│   ├── CLAUDE.md.tmpl           # Identity template (Claude Code)
│   ├── AGENTS.md.tmpl           # Identity template (Codex/Antigravity)
│   ├── .gitignore.tmpl
│   └── memory/                  # Memory structure templates
│       ├── MEMORY.md.tmpl
│       ├── _promotions.md.tmpl
│       ├── latest-handoff.md
│       └── _template/
│           ├── feedback-template.md
│           └── pattern-template.md
├── skills/                      # 7 core learning loop commands
│   ├── remember.md              # Stage 1: CAPTURE
│   ├── recall.md                # Search memory
│   ├── apply.md                 # Stage 2: APPLY
│   ├── audit.md                 # Stage 4: EVOLVE
│   ├── handoff.md               # End-of-session (audit + commit + push)
│   ├── resume.md                # Start-of-session (pull + restore)
│   └── promote.md               # Stage 5: PROMOTE
└── docs/
    ├── LEARNING-LOOP.md         # Architecture: why & how the 5 stages work
    └── CUSTOMIZATION.md         # Customize persona, add skills, change language
```

## The Learning Loop

```
  CAPTURE → APPLY → VERIFY → EVOLVE → PROMOTE
  /remember  /apply  (auto)   /audit   /promote
```

1. **CAPTURE** — Agent detects corrections, patterns, decisions → saves to `memory/`
2. **APPLY** — Before acting, agent recalls relevant memories → announces transparently
3. **VERIFY** — User confirms or corrects → memory updated accordingly
4. **EVOLVE** — Session-end audit identifies stale, missed, and promotion-ready memories
5. **PROMOTE** — Well-proven memories (3+ applies, verified, multi-context) graduate to CLAUDE.md

See [docs/LEARNING-LOOP.md](docs/LEARNING-LOOP.md) for the full architecture.

## Wizard Flow

The `/agent-init` wizard asks 6 freetext questions in one prompt:

1. Agent name
2. Role / purpose
3. Personality / tone
4. Philosophy / hard rules
5. Human name (workspace owner)
6. Language preference

AI parses answers → generates full persona + philosophy prose → creates all files → git commits.

## Dual-Runtime Support

| Runtime | Identity File | Skills Location | Status |
|---------|--------------|-----------------|--------|
| Claude Code | `CLAUDE.md` | `.claude/commands/agent-core/` | Full support |
| Codex / Antigravity | `AGENTS.md` | `.claude/commands/agent-core/*.md` (read by agent) | Identity + memory structure; skills require reading .claude/commands/ files |

Both files are generated from the same wizard answers. CLAUDE.md uses `/slash-commands`, AGENTS.md references skill files that codex-compatible tools can read for full procedures.

## Inspired By

- [awaken ritual](https://github.com/Soul-Brews-Studio) — Oracle birth wizard, psi/ brain filesystem
- [agent-kk](../kk/agent-kk/) — KK's 5-stage learning loop, local memory system
- [prp-framework](../agents/prp-framework/) — install-all pattern, CLAUDE.md injection

## License

Internal — OpenClaw workspace tooling.
