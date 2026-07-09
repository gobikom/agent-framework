# Adapter: Codex

Wires `AGENT.md` into a Codex (or Codex-compatible) repo. Codex reads the same
skill directory Claude Code uses, but its primary identity file is
`AGENTS.md`, and it does not natively understand `/slash-command` syntax —
commands must read as plain instructions.

## Directory setup

```bash
mkdir -p .claude/commands/agent-core
```

## Skill install location

Copy every skill file (`skills/*.md`) into:

```
.claude/commands/agent-core/
```

(Same directory as the Claude adapter — Codex-compatible tools read this
location too. See each skill file's Self-Configuration section for how to
invoke it by plain command name.)

## AGENTS.md compatibility stub (REQUIRED)

Generate `AGENTS.md` as a **derived artifact**, not a symlink:

```bash
{
  echo '<!-- Auto-generated from AGENT.md by agent-framework. Edit AGENT.md, not this file. -->'
  cat AGENT.md
} > AGENTS.md
```

Adapt command syntax while generating the stub (mirror
`templates/AGENTS.md.tmpl:39-49`):

- Replace `` `/remember <slug>` `` style references with plain `` `remember <slug>` `` (no leading slash).
- Insert a note directing the reader to the full skill procedures:

  ```
  > **Note for codex-compatible tools**: Full skill procedures are in `.claude/commands/agent-core/*.md`.
  > These files contain the step-by-step instructions for each command (file schemas, git safety checks, etc.).
  > Read the relevant skill file before executing a command. For Claude Code, these are loaded as slash commands automatically.
  ```

- `AGENT.md` is the single source of truth.
- `AGENTS.md` is regenerated (overwritten) on **every** `agent-install --target codex` run.
- `AGENTS.md` should be listed in `.gitignore` as a generated file.
- Never hand-edit `AGENTS.md` — edits will be lost on the next install.

## Regeneration trigger

Run this adapter's steps every time `scripts/agent-install.sh --target codex`
is invoked, so `AGENTS.md` always reflects the latest `AGENT.md`.
