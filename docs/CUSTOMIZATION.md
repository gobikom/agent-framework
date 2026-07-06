# Customization Guide

This guide explains how to customize an agent created by the agent-framework. All customization happens in your agent's own repo — the framework itself is not modified.

---

## 1. Customizing Persona

Your agent's personality lives in the **Persona** section of `CLAUDE.md` (and `AGENTS.md` if you maintain both). This controls how the agent communicates: tone, vocabulary, speech patterns, and character.

### What to edit

Open `CLAUDE.md` and find the `## Persona` section. Replace or extend the content with your agent's personality.

### Elements you can define

| Element | Example | Effect |
|---------|---------|--------|
| **Self-reference** | "Refers to itself as 'Atlas'" | Agent uses a name instead of "I" |
| **Speech particle** | Ends sentences with "yo" or a domain-specific word | Consistent verbal identity |
| **Language mix** | "Uses English for technical terms, Spanish for conversation" | Natural bilingual flow |
| **Tone** | "Friendly but direct. No filler words." | Communication style |
| **Emoji usage** | "Uses 1-2 emoji per message, never more" | Visual personality without clutter |
| **Character expressions** | Table mapping situations to reactions | Consistent emotional responses |

### Example: A DevOps agent persona

```markdown
## Persona

Atlas is a calm, methodical infrastructure engineer. Speaks in short, precise
sentences. Uses "Atlas" instead of "I." Prefers bullet points over paragraphs.

When something is risky: "Hold up. Let Atlas check the blast radius first."
When deployment succeeds: "Clean deploy. Moving on."
When something breaks: "Incident detected. Atlas is investigating — stand by."

Emoji: sparingly. One checkmark for success, one warning sign for risk. Never decorative.
```

### Formal vs casual

Many agents need two modes: casual in conversation, formal in deliverables. Define this explicitly:

```markdown
In conversation: use persona voice (casual, character expressions)
In documents (specs, reports, PRDs): use professional English, no persona quirks
```

---

## 2. Adding Custom Memory Types

The framework ships with 7 default memory types: `feedback`, `pattern`, `lesson`, `decision`, `session`, `reference`, `project`. You can add domain-specific types.

### Step 1: Create a template

Add a new file in `memory/_template/`:

```markdown
<!-- memory/_template/incident-template.md -->
---
name: incident-{slug}
aliases:
  - incident-{slug}
description: "{one-line summary}"
metadata:
  type: incident
  category: "{service or system}"
  status: active
  date: YYYY-MM-DD
  severity: P1 | P2 | P3
  resolved: false
  applied_count: 0
  last_applied: null
  verified_by_user: pending
  promoted_to: null
---

# Incident — {Title}

## What happened
{Timeline and symptoms}

## Root cause
{Why it happened}

## Resolution
{What fixed it}

## Prevention
{What to do differently — this becomes the lesson}

## Change Log
- YYYY-MM-DD: created
```

### Step 2: Register in CLAUDE.md

Add the new type to the Memory System section so the agent knows when to use it:

```markdown
### Memory Types

| Type | When to use |
|------|-------------|
| ... (existing types) ... |
| `incident` | Production incident with root cause and prevention steps |
```

### Step 3: Add to MEMORY.md index sections

In `memory/MEMORY.md`, add a section header for the new type:

```markdown
## Incidents
(entries will appear here)
```

### Step 4: Update recall mapping (optional)

If the new type should be recalled before specific actions, add it to the Apply table in CLAUDE.md:

```markdown
| Deploying to production | `incident` + `feedback` (topic: deployment) |
```

---

## 3. Adding Trigger Phrases for Different Languages

The default trigger phrases in `/remember` are English. If your agent works in another language, add language-specific triggers.

### Where to add

In `CLAUDE.md`, under the **Proactive Memory** section, add a phrase trigger table for your language:

```markdown
### Phrase Triggers (Thai)

| User Phrase Pattern | Signal | Action |
|---------------------|--------|--------|
| "ทำไม / ทำไมไม่" | Agent missed assumption | save `feedback` |
| "ต้อง...ไหม / ควร...ไหม" | Teaching through question | save `feedback` (high priority) |
| "ขาด / ลืม / หาย" | Missed proactive step | save `lesson` |
| "เคยบอกแล้ว" | Lesson not applied | upgrade priority |
| "ดีเลย / เพอร์เฟ็ค" | Validated approach | save `pattern` |
```

### Multi-language agents

If your agent handles multiple languages, add multiple trigger tables. The `/remember` skill reads these from CLAUDE.md at session start and uses them for auto-detection.

### Translation guidelines

When translating triggers, focus on **intent equivalence**, not literal translation:

| English intent | What to look for in target language |
|---------------|-------------------------------------|
| "Why didn't you..." | Phrases expressing surprise at omission |
| "Should you..." (leading) | Rhetorical questions implying the answer is "yes" |
| "I told you before" | Expressions of repetition or frustration |
| "Perfect / exactly" | Strong positive affirmation |

---

## 4. Adding Domain-Specific Skills

Skills are slash commands that extend what your agent can do. They live in `.claude/commands/` (for Claude Code) or are defined as instructions in `AGENTS.md` (for codex-compatible tools).

### Creating a skill

Create a markdown file in `.claude/commands/`:

```markdown
<!-- .claude/commands/analyze-logs.md -->
---
description: Parse and summarize application logs for error patterns
---

# /analyze-logs

Analyze application logs and produce a structured error summary.

## Arguments

$ARGUMENTS — path to log file or directory, or "latest" for most recent

## Steps

1. Read the log file(s)
2. Extract ERROR and WARN lines
3. Group by error type / stack trace signature
4. Produce summary table:
   | Error | Count | First Seen | Last Seen | Sample |
5. Highlight any NEW errors (not seen in previous analyses)

## Output format

Markdown table + brief analysis paragraph.
Save report to `reports/log-analysis-{date}.md` if `reports/` directory exists.
```

### Organizing skills

For agents with many skills, use subdirectories:

```
.claude/commands/
├── agent-core/          <- Framework skills (installed by agent-install.sh)
│   ├── remember.md
│   ├── recall.md
│   └── apply.md
├── my-domain/           <- Your custom skills
│   ├── analyze-logs.md
│   └── deploy-check.md
└── agent-init.md        <- Wizard (temporary, from agent-init.sh)
```

### Skill design principles

- **Self-configuring**: read CLAUDE.md at the start to extract agent name, persona, and language — do not hardcode
- **Idempotent**: running the skill twice should not create duplicates or corrupt state
- **Transparent**: show the human what the skill is doing at each step
- **Memory-aware**: if the skill performs an action covered by the recall table, it should `/recall` first

---

## 5. Connecting to MCP Memory Backend

> **Status: Future** — This section describes planned integration with MCP-based memory servers. The current implementation uses local files.

The Learning Loop currently stores memories as markdown files in the `memory/` directory. A future version will support plugging in an MCP memory server for:

- **Cross-device sync** without git push/pull
- **Semantic search** beyond keyword matching
- **Shared memory** across multiple agents in a team
- **Automatic backup** to cloud storage

### Planned architecture

```
Agent Session
  |
  v
/remember, /recall, /apply, /audit, /promote
  |
  v
Memory Adapter (selects backend)
  |
  +-- Local files (current, always available as fallback)
  +-- MCP Memory Server (future, via mcp__soul__* tools)
  +-- Hybrid (write to both, read from MCP with local fallback)
```

### What will NOT change

- Memory schema (YAML frontmatter + markdown body) stays the same
- Learning Loop stages stay the same
- Promotion to CLAUDE.md stays file-based (it must be in the repo)
- MEMORY.md index stays file-based (human-readable, git-trackable)

### What will change

- `/recall` will use semantic search instead of keyword grep
- `/remember` will write to MCP server in addition to local file
- `/audit` will pull cross-session analytics from the server
- New command `/sync` will reconcile local files with server state

When this feature ships, migration will be opt-in. Existing local-file agents will continue working unchanged.

---

## 6. Syncing CLAUDE.md and AGENTS.md

If your agent supports multiple runtimes (Claude Code + codex-compatible tools), you maintain two identity files:

| File | Used by | Command format |
|------|---------|----------------|
| `CLAUDE.md` | Claude Code | Slash commands: `/remember`, `/recall` |
| `AGENTS.md` | Codex, other tools | Plain commands: `remember`, `recall` |

### What must stay in sync

| Section | Sync required? | Notes |
|---------|---------------|-------|
| Identity table | Yes | Same agent ID, name, role, born date |
| Persona | Yes | Same personality in both files |
| Philosophy / Hard Rules | Yes | Same rules govern all runtimes |
| Memory System | Yes (adapted) | Same triggers, different command syntax |
| Capabilities | Yes | Same capability list |
| Budget | Yes | Same spending limits |
| Tooling sections | No | Runtime-specific (Figma MCP, etc.) |

### How to sync

**Option A: Manual** — When you edit one file, search for the corresponding section in the other and update it. This works for infrequent changes.

**Option B: Template-based** — The framework templates (`templates/CLAUDE.md.tmpl` and `templates/AGENTS.md.tmpl`) share the same placeholders. Re-running the wizard with the same answers regenerates both files in sync.

**Option C: Single source of truth** — Some teams keep only `CLAUDE.md` and generate `AGENTS.md` from it with a script that adjusts command syntax. This is the cleanest approach but requires a generation script (not yet included in the framework).

### Key differences between the files

The primary difference is command invocation syntax:

```markdown
<!-- CLAUDE.md -->
| `/remember <slug>` | Save memory entry | 1. CAPTURE |

<!-- AGENTS.md -->
| `remember <slug>` | Save a memory entry using the remember command | 1. CAPTURE |
```

AGENTS.md also includes a note for codex-compatible tools:

```markdown
> **Note for codex-compatible tools**: Commands above are built-in commands
> provided by the agent framework. Invoke them directly (e.g., `remember <slug>`)
> rather than as slash commands.
```

### Commit discipline

When changing either file, update both in the same commit. Include a note in the commit message:

```
chore: update agent persona — sync CLAUDE.md + AGENTS.md
```

This prevents drift where one file has rules the other does not.
