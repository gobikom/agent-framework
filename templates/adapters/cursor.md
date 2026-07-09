# Adapter: Cursor

Wires `AGENT.md` into a Cursor repo. Cursor does not read `AGENT.md` or
`CLAUDE.md` directly — it reads rule files under `.cursor/rules/` and (for
older setups) a root `.cursorrules` file.

## Directory setup

```bash
mkdir -p .cursor/rules/agent-core
```

## Skill install location

Copy every skill file (`skills/*.md`) into:

```
.cursor/rules/agent-core/
```

## .cursorrules compatibility stub (REQUIRED)

Generate `.cursorrules` as a **derived artifact**, not a symlink, built from
the identity-relevant sections of `AGENT.md` (Identity, Persona, Philosophy,
Capabilities, Memory System, Budget, Escalation Rules):

```bash
{
  echo '# Auto-generated from AGENT.md by agent-framework. Edit AGENT.md, not this file.'
  cat AGENT.md
} > .cursorrules
```

- `AGENT.md` is the single source of truth.
- `.cursorrules` is regenerated (overwritten) on **every** `agent-install --target cursor` run.
- `.cursorrules` should be listed in `.gitignore` as a generated file.
- Never hand-edit `.cursorrules` — edits will be lost on the next install.

## Regeneration trigger

Run this adapter's steps every time `scripts/agent-install.sh --target cursor`
is invoked, so `.cursorrules` always reflects the latest `AGENT.md`.
