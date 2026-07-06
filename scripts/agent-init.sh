#!/usr/bin/env bash
set -euo pipefail

FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
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

# Check existing agent
if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
    echo "Warning: CLAUDE.md already exists in $TARGET_DIR"
    read -p "Overwrite? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Save framework path for wizard to find templates
echo "$FRAMEWORK_DIR" > "$TARGET_DIR/.agent-framework-path"

# Install wizard command temporarily
mkdir -p "$TARGET_DIR/.claude/commands"
cp "$FRAMEWORK_DIR/wizard/wizard.md" "$TARGET_DIR/.claude/commands/agent-init.md"

echo ""
echo "Wizard installed. Next steps:"
echo ""

# Try to launch claude directly
if command -v claude &>/dev/null; then
    echo "  Run in the target directory:"
    echo "    cd $TARGET_DIR"
    echo "    claude"
    echo "    Then type: /agent-init"
else
    echo "  1. Open Claude Code in: $TARGET_DIR"
    echo "  2. Run: /agent-init"
fi

echo ""
echo "The wizard will guide you through creating your agent."
