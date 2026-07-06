# Installation Guide

## Prerequisites

| Requirement | Version | Check |
|-------------|---------|-------|
| **git** | any | `git --version` |
| **bash** | 4.0+ | `bash --version` |
| **Claude Code** (or Codex) | any | `claude --version` or IDE extension |

No other dependencies. No Node.js, no Python, no Docker.

## Install the Framework

### Option 1: Clone (recommended)

```bash
cd ~/repos/agents/   # or wherever you keep agent tooling
git clone git@github.com:gobikom/agent-framework.git
```

### Option 2: Already cloned (OpenClaw workspace)

The framework lives at `~/repos/agents/agent-framework/`. Nothing to install — it's already there.

## PATH Integration (optional but recommended)

Add the scripts to your PATH so you can run `agent-init` from anywhere:

```bash
# Create symlinks in ~/ops/bin/ (already in PATH on OpenClaw)
ln -sf ~/repos/agents/agent-framework/scripts/agent-init.sh ~/ops/bin/agent-init
ln -sf ~/repos/agents/agent-framework/scripts/agent-install.sh ~/ops/bin/agent-install
ln -sf ~/repos/agents/agent-framework/scripts/agent-install-all.sh ~/ops/bin/agent-install-all
```

Verify:
```bash
agent-init --help     # should show usage
agent-install --help  # should show usage
```

Alternative — add the scripts directory to PATH directly:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/repos/agents/agent-framework/scripts:$PATH"
```

## Create Your First Agent

### Step 1: Prepare the repo

```bash
# New repo
mkdir ~/repos/my-agent && cd ~/repos/my-agent
git init && git branch -m main

# Or use an existing repo
cd ~/repos/existing-project
```

### Step 2: Run agent-init

```bash
agent-init .
# or with full path:
~/repos/agents/agent-framework/scripts/agent-init.sh .
```

This will:
- Verify git is set up
- Save the framework path (`.agent-framework-path`)
- Copy the wizard command (`.claude/commands/agent-init.md`)
- Print next steps

### Step 3: Run the wizard

Open Claude Code in the repo directory:

```bash
cd ~/repos/my-agent
claude
```

Then type:
```
/agent-init
```

The wizard will:
1. **System check** — verify git, detect runtimes
2. **Ask 6 questions** — name, role, personality, philosophy, your name, language
3. **Ask about memory** — full learning loop or minimal?
4. **Show confirmation** — review all answers, edit if needed
5. **Build everything** — create CLAUDE.md, AGENTS.md, memory/, skills, docs
6. **Git commit** — all files committed in one clean commit

### Step 4: Start using your agent

Open a new Claude Code session (to pick up the new CLAUDE.md):

```bash
claude
```

Your agent now has:
- `/resume` — start of session
- `/remember` — save to memory
- `/recall` — search memory
- `/handoff` — end of session

## Update Skills in Existing Agents

When the framework is updated (new skills, bug fixes), propagate to your agents:

### Single repo

```bash
agent-install ~/repos/my-agent/
```

This copies the latest skill files to `.claude/commands/agent-core/` without touching your CLAUDE.md, AGENTS.md, or memory.

### All agent repos

```bash
# Preview first
agent-install-all --dry-run

# Then apply
agent-install-all
```

Scans `~/repos/` (4 levels deep) for repos with agent identity markers in CLAUDE.md. Skips the framework's own repo.

Options:
```bash
agent-install-all --dry-run              # Preview only
agent-install-all --repos-dir=/other/dir # Scan different root
```

## Framework Updates

Pull the latest framework:

```bash
cd ~/repos/agents/agent-framework
git pull origin main
```

Then update all agents:

```bash
agent-install-all
```

## What Gets Installed Where

When you run `agent-init` or `agent-install`, here's what goes into the target repo:

| Source (framework) | Destination (agent repo) | Tracked in git? |
|--------------------|-------------------------|-----------------|
| `skills/*.md` | `.claude/commands/agent-core/*.md` | No (gitignored) |
| `templates/memory/*` | `memory/*` | Optional |
| `docs/*.md` | `docs/*.md` | Yes |
| `templates/.gitignore.tmpl` | `.gitignore` | Yes |
| (wizard generates) | `CLAUDE.md` | Yes |
| (wizard generates) | `AGENTS.md` | Yes |
| (auto) | `.agent-framework-path` | No (gitignored) |

Skills are **not** tracked in the agent repo's git — they're installed from the framework and updated via `agent-install`. This means:
- One source of truth for skill logic
- `agent-install-all` propagates fixes to every agent
- Agent repos stay clean (no duplicated skill code in git history)

## Uninstall

To remove the framework from an agent repo:

```bash
cd ~/repos/my-agent
rm -rf .claude/commands/agent-core/
rm -f .agent-framework-path
rm -f .claude/commands/agent-init.md
# Memory and identity files (CLAUDE.md, AGENTS.md, memory/) are yours — keep or delete as needed
```

## Troubleshooting

### "Cannot find agent-framework directory"

The wizard can't find the framework. Fix:

```bash
# Option 1: Set environment variable
export AGENT_FRAMEWORK_DIR=~/repos/agents/agent-framework

# Option 2: Re-run agent-init (recreates .agent-framework-path)
agent-init .

# Option 3: Create the path file manually
echo "$HOME/repos/agents/agent-framework" > .agent-framework-path
```

### Skills not showing up as slash commands

After `agent-install`, you need to **restart Claude Code** (or reload the window in VS Code) for new commands to appear.

### "CLAUDE.md already exists" warning

If you're re-initializing an existing agent, `agent-init` warns before overwriting. To update skills without touching identity files, use `agent-install` instead.

### agent-install-all skips a repo

The script only updates repos where CLAUDE.md contains one of: "Agent ID", "Memory System", or "Learning Loop". If your CLAUDE.md doesn't have these markers, the script won't detect it as an agent repo.

### Memory not persisting between sessions

Make sure you run `/handoff` before ending a session. This saves the session context to `memory/latest-handoff.md` and commits to git. The next session's `/resume` reads this file.
