# Customization Guide

This guide explains how to customize an agent created by the agent-framework. All customization happens in your agent's own repo — the framework itself is not modified.

---

## 1. Customizing Persona

Your agent's personality lives in the **Persona** section of `AGENT.md`. This controls how the agent communicates: tone, vocabulary, speech patterns, and character.

### What to edit

Open `AGENT.md` and find the `## Persona` section. Replace or extend the content with your agent's personality.

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

### Step 2: Register in AGENT.md

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

If the new type should be recalled before specific actions, add it to the Apply table in AGENT.md:

```markdown
| Deploying to production | `incident` + `feedback` (topic: deployment) |
```

---

## 3. Adding Trigger Phrases for Different Languages

The default trigger phrases in `/remember` are English. If your agent works in another language, add language-specific triggers.

### Where to add

In `AGENT.md`, under the **Proactive Memory** section, add a phrase trigger table for your language:

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

If your agent handles multiple languages, add multiple trigger tables. The `/remember` skill reads these from AGENT.md at session start and uses them for auto-detection.

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

Skills are commands that extend what your agent can do. They are installed by `agent-install` into the appropriate directory for your tool (`.claude/commands/` for Claude Code, `.cursor/rules/` for Cursor, etc.).

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

- **Self-configuring**: read AGENT.md at the start to extract agent name, persona, and language — do not hardcode
- **Idempotent**: running the skill twice should not create duplicates or corrupt state
- **Transparent**: show the human what the skill is doing at each step
- **Memory-aware**: if the skill performs an action covered by the recall table, it should `/recall` first

---

## 5. Tool-Specific Adapters

`AGENT.md` is the single source of truth for your agent's identity. Tool-specific files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`) are **derived artifacts** generated automatically by `agent-install`.

### How adapters work

When you run `agent-install --target <tool>`, the framework reads the adapter template (`templates/adapters/<tool>.md`) and generates the correct files for that tool:

| Target | Generated files | Skill location |
|--------|----------------|----------------|
| `claude` | `CLAUDE.md` (copy of AGENT.md) | `.claude/commands/agent-core/` |
| `codex` | `AGENTS.md` (adapted syntax) | `.claude/commands/agent-core/` |
| `cursor` | `.cursorrules` (reference) | `.cursor/rules/agent-core/` |
| `generic` | `AGENTS.md` (plain syntax) | `skills/` |

### No more manual sync

In v1, you had to keep `CLAUDE.md` and `AGENTS.md` in sync manually. In v2:

- Edit `AGENT.md` only — it is the single source of truth
- Run `agent-install` to regenerate tool-specific stubs
- Stubs are marked auto-generated and can be gitignored
- `agent-install` auto-detects installed tools if `--target` is omitted

### Multi-tool support

If your agent works with multiple tools, pass comma-separated targets:

```bash
agent-install --target claude,cursor ~/repos/my-agent/
```

This generates files for both Claude Code and Cursor from the same `AGENT.md`.
