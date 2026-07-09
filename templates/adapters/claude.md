# Adapter: Claude Code

Wires `AGENT.md` (the universal identity file) and the framework skills into a
Claude Code repo. Claude Code requires slash commands to live under
`.claude/commands/` and requires the identity file to be named `CLAUDE.md`
(it does not read `AGENT.md` directly), so this adapter generates a
compatibility stub on every install.

## Directory setup

```bash
mkdir -p .claude/commands/agent-core
```

## Skill install location

Copy every skill file (`skills/*.md`) into:

```
.claude/commands/agent-core/
```

Each skill becomes available as a Claude Code slash command, e.g.
`skills/remember.md` → `/agent-core:remember`.

## CLAUDE.md compatibility stub (REQUIRED)

Claude Code will not load `AGENT.md` on its own — it looks for `CLAUDE.md`.
Generate `CLAUDE.md` as a **derived artifact**, not a symlink (symlinks break
on some filesystems and some sandboxed tool runners):

```bash
{
  echo '<!-- Auto-generated from AGENT.md by agent-framework. Edit AGENT.md, not this file. -->'
  cat AGENT.md
} > CLAUDE.md
```

- `AGENT.md` is the single source of truth.
- `CLAUDE.md` is regenerated (overwritten) on **every** `agent-install --target claude` run.
- `CLAUDE.md` should be listed in `.gitignore` as a generated file (see `templates/.gitignore.tmpl`).
- Never hand-edit `CLAUDE.md` — edits will be lost on the next install.

## Regeneration trigger

Run this adapter's steps every time `scripts/agent-install.sh --target claude`
is invoked, so `CLAUDE.md` always reflects the latest `AGENT.md`.
