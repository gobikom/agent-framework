# Learning Loop — 6-Stage Architecture

> This document describes how an agent learns and improves through a structured feedback loop.
> Reference: AGENT.md "Memory System" section, `memory/` directory

---

## Why Structural Learning?

AI agents are not humans. They have three fundamental limitations that make ad hoc learning impossible:

1. **Context window** — Knowledge that is not loaded into the current context does not exist. The agent cannot "remember" anything outside its active window, no matter how many times it has seen it before.

2. **No spontaneous recall** — An agent will not think "wait, I learned something about this last week" unless an explicit mechanism forces retrieval. Without triggers, lessons evaporate between sessions.

3. **No shame from correction** — A human who gets corrected three times feels embarrassed and changes behavior. An agent can be corrected infinitely without behavioral change unless a structural mechanic enforces it.

**Therefore**: Learning must be **structural** (files on disk with defined schemas), **auditable** (humans can inspect what was learned and when), and **transparent** (the agent announces when it applies a lesson, so the human can verify or correct in real time).

The Learning Loop is not "trying to remember." It is a six-stage pipeline that captures corrections, forces pre-action recall, tracks verification, audits health, graduates proven lessons into permanent rules, and evolves repeated workflows into executable skills.

---

## The 6-Stage Loop

```
                      +--------------------------------------------------+
                      |                                                    |
                      v                                                    |
   +----------+  +----------+  +----------+  +----------+  +----------+  +----------+
   | 1 CAPTURE|->| 2 APPLY  |->| 3 VERIFY |->| 4 EVOLVE |->| 5 PROMOTE|->| 6 SKILL  |
   | Save     |  | Use      |  | Confirm  |  | Audit    |  | Graduate |  | Evolve   |
   +----------+  +----------+  +----------+  +----------+  +----------+  +----------+
        ^                                          |              |              |
        |                                          v              v              v
        |                                  +------------+  +------------+  +------------+
        +----------------------------------| Refine     |  | Hard Rule  |  | Executable |
                                           | memory     |  | in AGENT   |  | skill      |
                                           +------------+  +------------+  +------------+
```

Each stage has clear inputs, outputs, and enforcement rules. Stages 1 and 2 happen during work. Stage 3 is embedded in Stage 2 (verification happens immediately after application). Stage 4 runs at session end. Stage 5 triggers when promotion criteria are met. Stage 6 triggers when a multi-step pattern proves itself — it graduates from a memory entry into a reusable executable skill.

---

## Stage 1: CAPTURE — Save a lesson

**Command**: `/remember`

When the agent detects a learning signal — a correction, a teaching question, a confirmed pattern — it saves a memory entry immediately. Not at the end of the session. Not "later." Now.

### Trigger Detection (Auto)

The agent monitors the human's phrasing for signals that indicate a teaching moment:

| Phrase Pattern | Signal | Memory Type |
|----------------|--------|-------------|
| "why / why not / why didn't you" | Agent missed an assumption | `feedback` |
| "should you / shouldn't you" (leading question) | Human teaching through questions | `feedback` (high priority) |
| "missing / forgot / should have" | Agent missed a proactive step | `lesson` |
| "I already told you / told you before" | Lesson from prior session not applied | `feedback` (upgrade existing priority) |
| "instead of / you should / better to" | Human proposing a superior approach | `pattern` or `feedback` refinement |
| "perfect / exactly / that's right" | Approach validated | `pattern` (positive) |
| "remember this" | Explicit save instruction | Per content |

These triggers are language-specific. Agents can define additional triggers in their Persona section (see docs/CUSTOMIZATION.md for adding triggers in other languages).

### Capture Checklist

At the end of each task or phase, the agent should reflect:

- Was there a correction from the human? -> `feedback`
- Was there an approach that worked well? -> `pattern`
- Was there an approach that failed? -> `lesson`
- Was there a significant decision with reasoning? -> `decision`

### Memory Types

| Type | When to use |
|------|-------------|
| `feedback` | Human corrected the agent, sent a leading question, or signaled a preference |
| `pattern` | Reusable approach that worked — a workflow, code pattern, communication style |
| `lesson` | Mistake to avoid, friction point, what NOT to do |
| `decision` | Key decision with reasoning (so future sessions understand "why") |
| `session` | Session checkpoint or handoff note |
| `reference` | Pointer to external resource (URL, dashboard, channel, API endpoint) |
| `project` | Project-level fact (deadlines, stakeholders, scope, motivation) |

---

## Stage 2: APPLY — Use a lesson

**Commands**: `/recall` + `/apply`

Before performing an action in a domain where memories may exist, the agent MUST search for relevant memories first. This is not optional — it is a hard rule.

### Pre-Action Check

| Action about to perform | Memory categories to recall |
|-------------------------|----------------------------|
| Creating a new file or script | `feedback` + `pattern` (topic: tooling) |
| Starting a new project | `pattern` + `decision` (project-level) |
| Writing documentation | `pattern` (documentation patterns) |
| Answering "why did we choose X" | `decision` entries |
| Setting up new tooling | all `feedback` + `pattern` related |

### Transparency Rule

When applying a lesson, the agent MUST announce it in its reply so the human can see:

> "(Agent recall: `feedback-always-run-tests-before-commit` — applying this lesson: will run test suite before committing)"

Why this matters:
- **Audit trail** — the human sees whether lessons are actually being used
- **Correction opportunity** — if the lesson is being misapplied, the human can intervene immediately
- **Trust building** — transparency breeds confidence

### Apply Tracking

When `/apply` runs, it updates the memory entry's metadata:

```yaml
metadata:
  applied_count: N+1                    # bump
  last_applied: 2026-07-06              # today
  last_context: "API refactor sprint"   # short description of current work
```

---

## Stage 3: VERIFY — Confirm the lesson works

Verification is embedded in the apply stage. After the agent announces and applies a lesson, it watches for the human's response:

| Human Signal | Interpretation | Memory Update |
|--------------|----------------|---------------|
| Confirms or does not correct | Lesson is valid | `verified_by_user: yes` |
| Corrects or refines | Lesson needs adjustment | `verified_by_user: no` + refine body |
| No comment (moves on) | Inconclusive | `verified_by_user: pending` (wait for next apply) |

### Refinement on Correction

When `verified_by_user: no`:

1. Read the human's correction carefully
2. Update the memory body to cover the edge case that was missed
3. Add an entry to the Change Log section of the memory file
4. Do NOT delete the original content — show what changed and why

---

## Stage 4: EVOLVE — Session-end audit

**Command**: `/audit` (runs automatically as part of `/handoff`)

At the end of every session, the agent runs a health audit of its memory system. This produces a structured report:

```markdown
## Session Audit — {date}

### Lessons Applied
- Applied `feedback-X` (verified) — used 1 time this session
- Applied `feedback-Y` (corrected by human) — refined body

### Lessons Skipped (had opportunity but did not recall)
- Should have applied `feedback-Z` when doing X

### Stale Lessons (5+ sessions unreferenced)
- `lesson-A` — last applied 2026-03-01 — still relevant?

### New Lessons Created
- `feedback-B` — captured from "..." phrase
```

### Actions from Audit

| Finding | Action |
|---------|--------|
| Skipped lessons | Review trigger map in Stage 1 — does it cover this case? |
| Stale lessons | Ask human: still relevant? Archive? Mark superseded? |
| Frequently corrected | Upgrade priority or fundamentally refine the memory |
| High apply count + all verified | Check promotion criteria (Stage 5) |

---

## Stage 5: PROMOTE — Graduate to permanent rules

**Command**: `/promote`

When a memory entry proves itself reliable across time and contexts, it graduates from a memory file into a permanent hard rule in AGENT.md.

### Promotion Criteria (all must be met)

- `applied_count >= 3` — used at least 3 times
- `verified_by_user = yes` every time — never corrected after application
- Applied across **2+ different contexts or projects** — not just repeated in one narrow scenario

### Promotion Process

1. Agent proposes in reply: "Lesson X is ready for promotion to AGENT.md (applied N times, all verified across M contexts) — promote?"
2. Human approves -> agent runs `/promote`:
   - Adds the rule to the appropriate section of AGENT.md
   - Updates memory entry: `promoted_to: "AGENT.md#section-name"`, `status: promoted`
   - Adds entry to `memory/_promotions.md` (audit trail)
   - Updates MEMORY.md index with promotion marker
3. The memory file is **kept** — it serves as the audit trail for why the rule exists

### Demotion (rare)

If a promoted rule is later found to be wrong (context changed, was too narrow):

1. Remove the rule from AGENT.md
2. Update memory: `promoted_to: null`, `status: active`, add demotion reason to Change Log
3. Log demotion in `memory/_promotions.md`

The lesson re-enters the loop at Stage 2 for further refinement.

---

## Stage 6: EVOLVE SKILL — Graduate to executable command

**Command**: `/evolve`

When a memory entry describes a multi-step workflow (not a simple rule) and has been applied reliably across contexts, it can graduate from a memory file into an executable skill — a reusable command the agent runs directly.

### How It Differs from Promotion

| | Stage 5: Promote | Stage 6: Evolve Skill |
|---|---|---|
| **Input** | Any proven memory | Multi-step workflow patterns |
| **Output** | Hard rule in AGENT.md | Executable skill file in `skills/` |
| **Criteria** | `applied_count >= 3`, verified, multi-context | Same + "How to apply" has >= 3 steps |
| **Best for** | One-liner rules, constraints, principles | Multi-step procedures, workflows, recipes |

### Evolution Criteria (all must be met)

- `applied_count >= 3` (or configured `evolution_threshold`)
- `verified_by_user = yes` consistently
- "How to apply" section contains >= 3 distinct actionable steps
- Applied across >= 2 distinct contexts
- `evolved_to = null` (not already evolved)
- `status = active`

### Evolution Process

1. `/audit` detects evolution candidates at session end (Step 3.5)
2. Agent proposes: "Pattern X has a multi-step workflow applied 4 times across 3 contexts — evolve into a skill?"
3. Human approves → agent runs `/evolve {slug}`:
   - Extracts workflow steps from "How to apply" section
   - Drafts a skill file with proper frontmatter, Self-Configuration, Steps
   - Shows draft to user — **never auto-creates**
4. On approval:
   - Writes skill file to `skills/` directory
   - Updates source memory: `evolved_to: "skill:{name}"`, `status: evolved`
   - Logs in `memory/_evolutions.md` (parallel to `_promotions.md`)
   - Adds `⚡ evolved to skill` marker in `memory/MEMORY.md`

### Skill Improvement Loop

Skills evolved from patterns are not static. When the agent receives corrections while using an evolved skill:

1. `/remember` saves the correction as `feedback`
2. `/audit` Step 3.6 detects feedback matching an existing skill's category
3. After enough verified corrections → agent suggests updating the skill
4. Updated skill gets a version bump in `_evolutions.md`

This closes the loop: patterns become skills, skills get improved by feedback, improvements accumulate into the next skill version.

### Proactive Detection

`/remember` includes Step 4.5: when saving a multi-step `pattern`, it checks for similar existing patterns. If overlap is detected, it proactively suggests `/evolve` — so the agent doesn't wait for session-end audit to notice.

---

## Memory Schema

**File location**: `memory/YYYY-MM/YYYY-MM-DD-{type}-{slug}.md`
**Example**: `memory/2026-07/2026-07-06-feedback-always-confirm-before-deploy.md`

### Full Schema (feedback / pattern types)

```yaml
---
name: {type}-{kebab-case-slug}
aliases:
  - {type}-{kebab-case-slug}     # short slug for [[wikilinks]]
description: "{one-line summary — used for relevance search}"
metadata:
  type: feedback | pattern | lesson | decision | session | reference | project
  category: "{topic — e.g., tooling, communication, workflow, architecture}"
  status: active | superseded | promoted | archived
  date: YYYY-MM-DD
  # Learning Loop tracking
  applied_count: 0
  last_applied: null
  last_context: null
  verified_by_user: pending  # yes | no | pending
  promoted_to: null          # null | "AGENT.md#section"
  evolved_to: null           # null | "skill:{skill-name}"
  skill_version: null         # null | 1, 2, 3...
---

# {Title}

## Rule / Pattern / Decision
{Core content}

## Why
{Reasoning — cite original phrase or scenario}

## How to apply
{Concrete trigger + action}

## Anti-patterns
- {what NOT to do}

## Trigger
- {situation that fires this lesson}

## Related
- [[other-memory-entry]]

## Change Log
- YYYY-MM-DD: created — captured from "{original phrase/scenario}"
- (when refined): {what changed and why}
```

### Simplified Schema (other types)

For `lesson`, `decision`, `session`, `reference`, `project` — a lighter format is acceptable:

```yaml
---
name: {type}-{slug}
aliases:
  - {type}-{slug}
description: "{summary}"
metadata:
  type: {type}
  category: "{topic}"
  status: active
  date: YYYY-MM-DD
---

# {Title}

{Content}

## Context / Why
{Reasoning for future sessions}
```

---

## File Convention

```
memory/
├── MEMORY.md                    <- Index / Map of Content (wikilinks)
├── _promotions.md               <- Promotion audit trail
├── _evolutions.md               <- Skill evolution audit trail
├── _template/                   <- Memory file templates
│   ├── feedback-template.md
│   └── pattern-template.md
├── latest-handoff.md            <- Symlink or copy of most recent handoff
└── YYYY-MM/                     <- Monthly folders (auto-created)
    └── YYYY-MM-DD-{type}-{slug}.md  <- Individual memory entries
```

### Naming Rules

- **Folder**: `YYYY-MM` (ISO year-month) — new folder each month, auto-created by `/remember`
- **Filename**: `YYYY-MM-DD-{type}-{kebab-slug}.md` — date prefix sorts naturally
- **Wikilinks**: use short slug `[[feedback-my-slug]]` — Obsidian resolves via `aliases` in frontmatter
- **Never delete**: set `status: superseded` + `superseded_by: "[[new-entry]]"` instead

---

## Session Lifecycle

A typical session follows this pattern:

```
Session Start
  |
  v
/resume (or read latest-handoff.md)
  |-- Load context from last session
  |-- Summarize for human before starting work
  |
  v
Work Phase (repeat)
  |-- Before action: /recall relevant memories
  |-- Announce: "(Agent recall: ...)"
  |-- /apply memory -> bump applied_count
  |-- After action: watch for verification signal
  |-- On correction: /remember (refine or new)
  |-- On validated pattern: /remember (positive)
  |
  v
/handoff (session end)
  |-- /audit runs inline (health report)
  |-- /save runs (session summary + memory update)
  |-- Check promotion candidates (Stage 5)
  |-- Check skill evolution candidates (Stage 6)
  |-- Commit + push memory/ to git
  |
  v
Session End
```

---

## Workflow Example

### Scenario: Agent is creating a deployment script

```
[1] CAPTURE (happened in a prior session)
    -> memory/feedback-always-run-tests-before-deploy.md exists
    -> Captured when human asked: "shouldn't you run tests first?"

[2] APPLY (this session)
    -> Agent about to write deploy script
    -> /recall finds feedback about testing before deploy
    -> Announces: "(Agent recall: feedback-always-run-tests-before-deploy
       — adding test step before deployment)"
    -> /apply bumps applied_count: 2 -> 3

[3] VERIFY
    -> Human does not correct — script looks good
    -> verified_by_user: yes

[4] EVOLVE (end of session)
    -> Audit report: "feedback-always-run-tests-before-deploy applied 1 time,
       verified. applied_count=3, all verified, 2 different projects.
       PROMOTION CANDIDATE."

[5] PROMOTE (criteria met)
    -> Agent proposes: "This lesson is ready for AGENT.md
       (applied 3 times, all verified, 2 projects) — promote?"
    -> Human approves
    -> /promote adds hard rule to AGENT.md
    -> Memory entry: promoted_to = "AGENT.md#philosophy-hard-rules"
```

---

## Design Principle: Leading Questions as Teaching

When a human asks "should you do X?" instead of commanding "do X," they are teaching through discovery. The agent must recognize this as a high-priority learning signal:

- Direct command -> agent does it this time, but may not generalize
- Leading question -> agent must reason about "why" -> understands the principle -> can apply in novel contexts

This is why "should you / shouldn't you" phrases get `feedback` type with high priority in the trigger table. They represent the human investing effort in the agent's long-term improvement, not just solving the immediate problem.

---

## References

- `AGENT.md` — "Memory System" section (rules the agent follows)
- `memory/_template/feedback-template.md` — feedback schema template
- `memory/_template/pattern-template.md` — pattern schema template
- `memory/_promotions.md` — promotion audit log
- `memory/_evolutions.md` — skill evolution audit log
- `memory/MEMORY.md` — Map of Content (index of all memories)
- `docs/CUSTOMIZATION.md` — guide for customizing triggers, types, and persona
