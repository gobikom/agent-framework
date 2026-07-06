# Implementation Plan: Agent Framework

> Scaffold persistent AI agents with memory, learning loop, personality, and dual-runtime support.

## Context

Built from 3 proven systems in the OpenClaw ecosystem:
- **Awaken ritual** (soul-skills) — wizard flow, psi/ brain filesystem, identity generation
- **KK learning loop** (agent-kk) — 5-stage local memory system, 7 slash commands
- **AGENTS.md dual-runtime** (prp-framework + soul-orchestra) — CLAUDE.md + AGENTS.md from single source

## Architecture Decision: Memory System

Two memory systems exist in the ecosystem:

| System | Used by | Storage | Dependencies | Search |
|--------|---------|---------|-------------|--------|
| **KK local** (`memory/`) | agent-kk | markdown files + YAML frontmatter | zero (git only) | grep + frontmatter scan |
| **Oracle MCP** (`psi/` + Qdrant) | agent-psak | files + vector DB | my-ai-soul-mcp server | hybrid semantic + FTS5 |

**Decision**: Default to **KK-style local memory** (zero dependencies, git-trackable, works with any runtime). Optional MCP integration as a plugin layer for agents that need semantic search.

**Rationale**: A framework that requires running an MCP server before any agent works is too heavy. Local markdown files are universally accessible by Claude Code, Codex, Antigravity, and any future tool.

## Architecture Decision: Brain Directory

| Option | Pros | Cons |
|--------|------|------|
| `memory/` (KK-style) | Descriptive, familiar | Flat — no inbox/outbox/lab/learn pillars |
| `psi/` (Oracle-style) | 7-pillar organization, richer | Unicode path issues, less intuitive name |
| `brain/` (new) | Clear name, 7-pillar structure | New convention, no existing tooling |

**Decision**: Use `memory/` as default name with optional 7-pillar sub-structure (flatter than psi/ but richer than KK's current layout). Configurable via wizard.

## Scope

### In Scope (v1.0)
1. `agent-init` wizard — interactive agent birth (adapted from awaken)
2. Identity generation — CLAUDE.md + AGENTS.md from wizard answers
3. Memory structure — `memory/` directory with templates
4. Learning loop commands — 7 core skills (remember, recall, apply, audit, handoff, resume, promote)
5. Dual-runtime adapters — Claude Code (.claude/commands/) + Codex/Antigravity (AGENTS.md)
6. `agent-install` — update shared skills in target repo
7. `agent-install-all` — batch update across all agent repos

### Out of Scope (future)
- MCP memory backend integration
- Soul-orchestra conductor protocol
- Segment checkpoint/orient (autonomous durability)
- Family/community registry
- Re-awaken / soul-sync flows

---

## Implementation Steps

### Step 1: Repo Structure

```
~/repos/agents/agent-framework/
├── README.md
├── scripts/
│   ├── agent-init.sh           # Entry point: scaffold new agent
│   ├── agent-install.sh        # Install/update skills in target repo
│   └── agent-install-all.sh    # Batch install across ~/repos/
├── wizard/
│   └── wizard.md               # Wizard flow (Claude Code skill format)
├── templates/
│   ├── CLAUDE.md.tmpl           # Identity template (Claude Code)
│   ├── AGENTS.md.tmpl           # Identity template (Codex/Antigravity)
│   ├── .gitignore.tmpl          # Default gitignore for agent repos
│   └── memory/
│       ├── MEMORY.md.tmpl       # MOC index template
│       ├── _promotions.md.tmpl  # Promotion log template
│       ├── latest-handoff.md    # Empty placeholder
│       └── _template/
│           ├── feedback-template.md
│           └── pattern-template.md
├── skills/
│   ├── remember.md              # Stage 1: CAPTURE
│   ├── recall.md                # Search memory
│   ├── apply.md                 # Stage 2: APPLY
│   ├── audit.md                 # Stage 4: EVOLVE
│   ├── handoff.md               # End-of-session
│   ├── resume.md                # Start-of-session
│   └── promote.md               # Stage 5: PROMOTE
├── docs/
│   ├── LEARNING-LOOP.md         # Architecture doc (generic version)
│   └── CUSTOMIZATION.md         # How to customize persona, add skills
└── CLAUDE.md                    # Framework's own instructions
```

### Step 2: Wizard (`wizard/wizard.md`)

Adapted from awaken Phase 0-3 + Phase 4-6. Single skill file, no CLI dependency.

**Flow:**
```
Phase 0: System Check
  - Git installed? Git repo? Git identity?
  - Detect runtime: Claude Code / Codex / both

Phase 1: Batch Freetext (6 questions in 1 prompt)
  1. Agent name
  2. Agent role / purpose  
  3. Personality / tone (speech patterns, tics, emoji style)
  4. Philosophy / hard rules (what this agent cares about)
  5. Human name (workspace owner)
  6. Language preference

  → AI parse → show parsed result → confirm/edit

Phase 2: Memory Consent
  - Enable learning loop? (default: yes)
  - Auto-audit on handoff? (default: yes)

Phase 3: Confirmation Screen
  - Display all info
  - Edit or confirm

Phase 4: Build
  - Create memory/ directory structure
  - Generate CLAUDE.md from template + wizard answers
  - Generate AGENTS.md from template + wizard answers
  - Install skills to .claude/commands/
  - Create .gitignore
  - Git commit

Phase 5: Summary
  - Display what was created
  - Suggest quick-start: /resume, /remember, /handoff
```

### Step 3: Identity Templates

**CLAUDE.md.tmpl** — parameterized with `{{variables}}`:

```markdown
# {{AGENT_NAME}}

## Identity

| Field | Value |
|-------|-------|
| **Agent ID** | `{{AGENT_ID}}` |
| **Name** | {{AGENT_NAME}} |
| **Role** | {{AGENT_ROLE}} |
| **Born** | {{BORN_DATE}} |

## Workspace Human

{{HUMAN_NAME_SECTION}}

## Persona

{{PERSONA_SECTION}}

## Philosophy (Hard Rules)

{{PHILOSOPHY_SECTION}}

## Capabilities

{{CAPABILITIES_SECTION}}

## Memory System

> memory/ directory with Learning Loop — see docs/LEARNING-LOOP.md

### Available Commands

| Command | Action | Learning Loop Stage |
|---------|--------|---------------------|
| `/resume` | Pull + load last handoff | — |
| `/remember <slug>` | Save memory entry | 1. CAPTURE |
| `/recall <keyword>` | Search memory | 2. APPLY (pre) |
| `/apply <memory>` | Bump applied_count + announce | 2. APPLY |
| `/audit` | Session health report | 4. EVOLVE |
| `/promote <memory>` | Graduate to CLAUDE.md | 5. PROMOTE |
| `/handoff` | Audit + save + commit + push | 4. EVOLVE |

### Proactive Memory — AUTO

{{PROACTIVE_TRIGGERS_SECTION}}

## Budget

| Limit | Value |
|-------|-------|
| Max per session | {{BUDGET}} |
```

**AGENTS.md.tmpl** — same content, different framing:
- Replace slash command references with natural language instructions
- Replace "Running `claude` from this directory" with "Loaded by codex-compatible tools"
- Replace tool-specific phrases per ClientConfig pattern

### Step 4: Generic Learning Loop Skills (7 files)

Extract from KK's commands, parameterize:

| Variable | Description | Example |
|----------|-------------|---------|
| `{{AGENT_NAME}}` | Agent's display name | "KK", "DevBot" |
| `{{AGENT_ID}}` | Kebab-case ID | "kk", "devbot" |
| `{{HUMAN_NAME}}` | Workspace human | "นุด", "Alex" |
| `{{LANGUAGE}}` | Primary language | "Thai", "English" |
| `{{PERSONA_PARTICLE}}` | Speech tic (optional) | "งับ", "", "desu" |

**What changes per agent:**
- Agent name in announcements ("KK recall: ..." → "{{AGENT_NAME}} recall: ...")
- Human name references
- Language of instructions and examples
- Persona-specific phrasing
- Category-to-CLAUDE.md section mapping in /promote (dynamic — read from actual CLAUDE.md sections)
- Staged paths in /handoff (scan repo structure instead of hardcoding)

**What stays identical:**
- YAML frontmatter schema
- 5-stage loop logic
- File naming convention (YYYY-MM/YYYY-MM-DD-type-slug.md)
- MEMORY.md index format
- Promotion criteria (3+ applies, verified, multi-context)
- Git safety protocol
- Transparency announcement pattern

### Step 5: Installation Scripts

**agent-init.sh** — new agent creation:
```bash
#!/bin/bash
# Usage: agent-init [target-dir]
# If no target-dir: use current directory
# Launches Claude Code with wizard skill
```

Actually → `agent-init.sh` will:
1. Validate target dir (exists? git repo? already has agent identity?)
2. Copy wizard.md to `.claude/commands/agent-init.md` temporarily
3. Print instructions: "Run `/agent-init` in Claude Code to start the wizard"
4. OR: directly invoke `claude -p "Run /agent-init"` if claude CLI available

**agent-install.sh** — update skills:
```bash
#!/bin/bash
# Usage: agent-install [target-dir]
# Detects runtime → installs appropriate adapter

TARGET="${1:-.}"

# Install Claude Code commands
if [ -d "$TARGET/.claude" ] || [ -f "$TARGET/CLAUDE.md" ]; then
    mkdir -p "$TARGET/.claude/commands/agent-core"
    for skill in skills/*.md; do
        cp "$skill" "$TARGET/.claude/commands/agent-core/$(basename $skill)"
    done
fi

# Install AGENTS.md section (if dual-runtime)
if [ -f "$TARGET/AGENTS.md" ]; then
    # Inject memory commands section using BEGIN/END markers
    # (same pattern as prp-framework inject-claude-md.sh)
fi
```

**agent-install-all.sh** — batch update:
```bash
#!/bin/bash
# Scan ~/repos/ for agent repos (has CLAUDE.md with agent identity markers)
# Run agent-install.sh for each
```

### Step 6: Documentation

**docs/LEARNING-LOOP.md** — generic version of KK's architecture doc:
- Keep the "3 AI limitations" rationale (universal)
- Keep 5-stage diagram
- Remove KK/Thai-specific examples → replace with language-neutral examples
- Remove BA/UX domain references → use generic coding examples

**docs/CUSTOMIZATION.md**:
- How to add custom memory types
- How to customize trigger phrases for different languages
- How to add domain-specific skills beyond the core 7
- How to connect MCP memory backend (future)

### Step 7: PATH Integration

Add `agent-init`, `agent-install`, `agent-install-all` to `~/ops/bin/`:
```bash
# ~/ops/bin/agent-init → symlink to ~/repos/agents/agent-framework/scripts/agent-init.sh
# ~/ops/bin/agent-install → symlink to ~/repos/agents/agent-framework/scripts/agent-install.sh
# ~/ops/bin/agent-install-all → symlink to ~/repos/agents/agent-framework/scripts/agent-install-all.sh
```

Update `~/CLAUDE.md` and `~/AGENTS.md` ops sections.

---

## Implementation Order

| Phase | What | Estimated |
|-------|------|-----------|
| **1** | Repo structure + README | 10 min |
| **2** | Templates (CLAUDE.md.tmpl, AGENTS.md.tmpl, memory/) | 30 min |
| **3** | Generic skills (7 commands — extract from KK + parameterize) | 60 min |
| **4** | Wizard skill (adapted from awaken) | 45 min |
| **5** | Install scripts (init, install, install-all) | 30 min |
| **6** | Docs (LEARNING-LOOP.md, CUSTOMIZATION.md) | 20 min |
| **7** | PATH integration + ops update | 10 min |
| **8** | Test: scaffold a test agent + verify skills work | 15 min |

**Total: ~3.5 hours**

---

## Validation Criteria

- [ ] `agent-init` wizard runs and produces working agent repo
- [ ] Generated CLAUDE.md loads in Claude Code with correct persona
- [ ] Generated AGENTS.md readable by Codex
- [ ] All 7 skills work: /remember, /recall, /apply, /audit, /handoff, /resume, /promote
- [ ] Learning loop: remember → recall → apply → verify cycle works
- [ ] `agent-install-all` updates existing agent repos without breaking them
- [ ] KK's existing memory system NOT broken (no regressions)
