# Changelog

All notable changes to Agent Framework. Versioning: `MAJOR.MINOR.PATCH`.

## [2.1.0] — 2026-08-30

### Added
- **Multi-project scoping** (optional, backward-compatible — single-project agents unaffected):
  - `promote` Step 1.5 — routes a memory to its **per-project identity file** by the `project:` tag (`_shared`/untagged → root `AGENT.md`; `<project>` → `projects/<project>/AGENT.md`), so project-specific hard rules don't clutter unrelated projects.
  - `resume` Step 1.5 — loads the active project's identity file from the handoff's `project:` tag before work begins.
  - `remember` — documents the optional `project:` scoping metadata field (scopes recall + routes promotion).
  - `docs/CUSTOMIZATION.md §6` — multi-project layout, how the skills cooperate, and the tool-adapter note (Claude Code → `projects/<name>/CLAUDE.md`).
  - `README.md` + `docs/LEARNING-LOOP.md` — feature + promote-stage notes.

Origin: proven in the `gg` (ux-assistant) agent, where Power Apps rules were cluttering non-Power Apps projects; ported upstream so sibling agents get it.

## [2.0.0] — 2026-07-09

- Tool-agnostic agent scaffolding: `AGENT.md` single-source identity + adapters (Claude Code, Cursor, Codex, generic).
- Persistent `memory/` with YAML-frontmatter markdown.
- 6-stage Learning Loop (Capture → Apply → Verify → Evolve → Promote → Skill Evolution).
- 11 core skills: remember, recall, apply, audit, handoff, resume, promote, evolve, supersede, archive, save.
- Zero dependencies (markdown + bash).
