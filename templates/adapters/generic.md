# Adapter: Generic / Fallback

Wires `AGENT.md` into any AI coding assistant that does not have a dedicated
adapter (e.g. Windsurf, Aider, or a tool not yet covered). Skills are
installed as plain markdown files and a codex-style `AGENTS.md` compatibility
stub is generated, since `AGENTS.md` is the closest thing to a de facto
standard identity filename across non-Claude tools.

## Directory setup

```bash
mkdir -p skills
```

## Skill install location

Copy every skill file (`skills/*.md`) into the repo root's:

```
skills/
```

## AGENTS.md compatibility stub (REQUIRED)

Generate `AGENTS.md` as a **derived artifact**, not a symlink (same approach
as the Codex adapter):

```bash
{
  echo '<!-- Auto-generated from AGENT.md by agent-framework. Edit AGENT.md, not this file. -->'
  cat AGENT.md
} > AGENTS.md
```

- `AGENT.md` is the single source of truth.
- `AGENTS.md` is regenerated (overwritten) on **every** `agent-install --target generic` run.
- `AGENTS.md` should be listed in `.gitignore` as a generated file.
- Never hand-edit `AGENTS.md` — edits will be lost on the next install.

## Tools needing a specific filename

If your tool requires an identity file with a specific name that isn't
`AGENTS.md`, create your own symlink or copy pointed at `AGENT.md` (or at the
generated `AGENTS.md` stub) after running `agent-install --target generic`.
The framework does not generate tool-specific stubs beyond `AGENTS.md` for
the generic target.

## Regeneration trigger

Run this adapter's steps every time `scripts/agent-install.sh --target generic`
is invoked, so `AGENTS.md` always reflects the latest `AGENT.md`.
