---
description: Evolve a repeated memory workflow into an executable skill after meeting criteria (Learning Loop Stage 6)
---

# /evolve — Evolve memory entry into a skill (Learning Loop Stage 6)

Verify a memory entry meets evolution criteria, draft a new skill file from its "How to apply" workflow, and update tracking files. Parallel to `/promote` (Stage 5), but graduates a **workflow** into an executable skill instead of a **rule** into a Hard Rule.

## Self-Configuration (run once per session)

Read the repo's `AGENT.md` (fallback: `CLAUDE.md`, for repos not yet migrated to the tool-neutral identity file) to extract:
- **AGENT_NAME**: from Identity table -> Name field
- **AGENT_ID**: from Identity table -> Agent ID field
- **HUMAN_NAME**: from "Workspace Human" section
- **LANGUAGE**: from Identity table or default English
- **PERSONA_PARTICLE**: from Persona section (speech ending particle, if any)

Use these values throughout. If neither file exists, use defaults:
- AGENT_NAME = repo directory name
- HUMAN_NAME = "human"

Also read `.agent-config.yaml` (repo root) if it exists, for `learning_loop.evolution_threshold`. If the file is missing or the key is unset, default `evolution_threshold = 3`.

## When to Use

- `/audit` reports a "Ready to Evolve" candidate and user agrees
- User manually requests evolution of a specific memory (`$ARGUMENTS`)
- `/remember` proactively suggests evolution while saving a similar pattern (advisory only — see `remember.md` Step 4.5)

## Arguments

- `$ARGUMENTS` = memory entry short slug (e.g. `pattern-pre-deploy-workflow`)
- If empty, ask user which memory to evolve (suggest candidates via `/audit`)

## Steps

### Step 1 — Find memory entry

```bash
find memory -type f -name "*-$ARGUMENTS.md" -not -path "*/_template/*"
```

If multiple matches, pick the latest by date prefix. Read the matched file.

### Step 2 — Verify evolution criteria

All must pass:

- `applied_count >= evolution_threshold` (from Self-Configuration, default 3)
- `verified_by_user = yes` (consistently — check Change Log for any "no" entries)
- **"How to apply" section has >= 3 actionable steps.** Count only numbered list items (`1.`, `2.`, `3.`) or `### Step N` subsections that appear **under the "How to apply" heading** — stop counting at the next `##`/`###` heading. Exclude lines starting with `e.g.`, `Example:`, or `Note:`. Never count items from "Anti-patterns", "Trigger", or "Related" sections.
- **Applied across >= 2 distinct contexts.** Prefer the `contexts` list in frontmatter. If `contexts` is empty or missing (pre-v2 memory), fall back to parsing the Change Log for unique `context:` / `last_context` strings across entries.
- `evolved_to = null` (not already evolved)
- `status = active`

If criteria not met: output the reasoning (which criterion failed, by how much) and offer a fast-track path only with explicit user approval — never proceed silently.

### Step 3 — Extract workflow steps

From the "How to apply" section, pull each step verbatim. Cross-reference the Change Log for variations observed across different applications (edge cases, alternate paths) and fold them in as notes under the relevant step.

### Step 4 — Draft skill file

Compose the new skill content (do not write it yet):

- Frontmatter: `description: {distilled from memory description}`
- `# /{name} — {Short title}`
- `## Evolved From` — `[[source-memory]]` link, `applied_count`, contexts list, evolution date
- `## Steps` — each extracted step as its own `### Step N` subsection
- `## Revision History` — single entry: `{date}: created from [[source-memory]]`

Skill file name = verb form of the pattern slug (e.g. `pattern-pre-deploy-workflow` -> `pre-deploy.md`).

### Step 5 — Show draft, get confirmation

Present the full draft to the user along with the proposed filename. **Never auto-create.** Ask the user to confirm or rename before writing anything.

### Step 6 — On approval, write and update

1. Write the skill file to `skills/` (or the configured skill location).
2. Update the source memory's frontmatter: `evolved_to: "skill:{name}"`, `status: evolved`.
3. Append to the source memory's Change Log: `{date}: evolved to skill:{name}`.

The source memory file is **kept** — it remains the audit trail and is never deleted.

### Step 7 — Update _evolutions.md

Append a row to the Active Evolutions table in `memory/_evolutions.md` (create from `templates/memory/_evolutions.md.tmpl` if missing):

```markdown
| {YYYY-MM-DD} | [[{source-slug}]] | {name}.md | {applied_count} | {contexts summary} | 1.0 | active |
```

### Step 8 — Update MEMORY.md

Find the source entry's index line in `memory/MEMORY.md` and append a `⚡ evolved to skill` marker.

### Step 9 — Confirm to user

```
Evolved: {memory-name}
   -> skills/{name}.md (new)
   -> memory entry: status=evolved, evolved_to=skill:{name}
   -> _evolutions.md: logged

Memory entry remains as audit trail.
```

## Rules

- **Never auto-create a skill without user confirmation** — evolution is a governance decision, same weight as promotion
- **Always keep the source memory file** — it is the audit trail
- **Skill file name is a verb**, not the pattern slug
- **Read `.agent-config.yaml` for `evolution_threshold`** if the file exists; otherwise default to 3

## See also

- `/promote` — parallel graduation path for rules (Stage 5)
- `/audit` — finds evolution candidates (Step 3.5)
- `/apply` — increments `applied_count` and records contexts (prerequisite for evolution)
- `/supersede` — mark a memory replaced (warns if it was already evolved)
- `memory/_evolutions.md` — evolution log
