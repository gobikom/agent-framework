#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit

SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
FRAMEWORK_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: agent-init [target-directory]"
    echo ""
    echo "Scaffold a new persistent AI agent (identity, memory, learning loop, skills)."
    echo "Installs the setup wizard as WIZARD.md at the project root, and additionally"
    echo "as .claude/commands/agent-init.md when Claude Code is detected."
    exit 0
fi

# bash 4.4+ required (inherit_errexit used for safe subshell error handling)
if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
    echo "Error: bash 4.4+ required (found ${BASH_VERSION}). On macOS: brew install bash"
    exit 1
fi

TARGET_DIR="${1:-.}"

# Resolve absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    echo "Error: Directory '$1' does not exist."
    echo "Usage: agent-init [target-directory]"
    exit 1
}

echo "=== Agent Framework — Initialize New Agent ==="
echo "Target: $TARGET_DIR"
echo ""

# Check git
if ! command -v git &>/dev/null; then
    echo "Error: git is required. Install git first."
    exit 1
fi

# Check/init git repo
if ! git -C "$TARGET_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not a git repo. Initializing..."
    git -C "$TARGET_DIR" init
    git -C "$TARGET_DIR" branch -m main
fi

# Check existing agent (AGENT.md is the source of truth; CLAUDE.md kept for
# backward compat detection so we don't clobber a v1 agent silently)
if [ -f "$TARGET_DIR/AGENT.md" ] || [ -f "$TARGET_DIR/CLAUDE.md" ]; then
    existing_file="AGENT.md"
    [ -f "$TARGET_DIR/AGENT.md" ] || existing_file="CLAUDE.md"
    echo "Warning: $existing_file already exists in $TARGET_DIR"
    if [ -t 0 ]; then
        read -p "Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    else
        echo "Error: $existing_file exists and no interactive terminal to confirm overwrite." >&2
        echo "Delete or rename $existing_file first, then re-run." >&2
        exit 1
    fi
fi

# Save framework path for the wizard to find templates
echo "$FRAMEWORK_DIR" > "$TARGET_DIR/.agent-framework-path"

# Always install the wizard as a plain instruction file at the project root
# so any AI coding assistant can run it (tool-agnostic).
cp "$FRAMEWORK_DIR/wizard/wizard.md" "$TARGET_DIR/WIZARD.md"

# Also install as a Claude Code slash command when Claude Code is present.
CLAUDE_WIZARD_INSTALLED=false
if [ -d "$TARGET_DIR/.claude" ] || command -v claude &>/dev/null; then
    mkdir -p "$TARGET_DIR/.claude/commands"
    cp "$FRAMEWORK_DIR/wizard/wizard.md" "$TARGET_DIR/.claude/commands/agent-init.md"
    CLAUDE_WIZARD_INSTALLED=true
fi

echo ""
echo "Wizard installed. Next steps:"
echo ""

if command -v claude &>/dev/null; then
    echo "  Run in the target directory:"
    echo "    cd $TARGET_DIR"
    echo "    claude"
    echo "    Then type: /agent-init"
else
    echo "  Run the wizard in your AI coding assistant:"
    echo "    cd $TARGET_DIR"
    echo "    Paste: \"Follow the instructions in WIZARD.md\""
    if [ "$CLAUDE_WIZARD_INSTALLED" = true ]; then
        echo "    (or use /agent-init in Claude Code)"
    fi
fi

echo ""
echo "The wizard will guide you through creating your agent."
