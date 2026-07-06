#!/usr/bin/env bash
set -euo pipefail

FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)"

echo "=== Agent Framework — Install/Update Skills ==="
echo "Source: $FRAMEWORK_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Verify target has agent identity
if [ ! -f "$TARGET_DIR/CLAUDE.md" ] && [ ! -f "$TARGET_DIR/AGENTS.md" ]; then
    echo "Error: No CLAUDE.md or AGENTS.md found in $TARGET_DIR"
    echo "Run 'agent-init $TARGET_DIR' first to create an agent."
    exit 1
fi

INSTALLED=0

# Install Claude Code commands
if [ -d "$TARGET_DIR/.claude" ] || [ -f "$TARGET_DIR/CLAUDE.md" ]; then
    echo "Installing Claude Code commands..."
    mkdir -p "$TARGET_DIR/.claude/commands/agent-core"
    for skill in "$FRAMEWORK_DIR/skills/"*.md; do
        [ -f "$skill" ] || continue
        filename=$(basename "$skill")
        cp "$skill" "$TARGET_DIR/.claude/commands/agent-core/$filename"
        INSTALLED=$((INSTALLED + 1))
    done
    echo "  Installed $INSTALLED skills -> .claude/commands/agent-core/"
fi

# Install memory templates (if memory/ exists)
if [ -d "$TARGET_DIR/memory" ]; then
    echo "Updating memory templates..."
    mkdir -p "$TARGET_DIR/memory/_template"
    cp "$FRAMEWORK_DIR/templates/memory/_template/"*.md "$TARGET_DIR/memory/_template/" 2>/dev/null || true
    echo "  Templates updated"
fi

# Install docs
if [ -d "$FRAMEWORK_DIR/docs" ]; then
    echo "Installing documentation..."
    mkdir -p "$TARGET_DIR/docs"
    for doc in "$FRAMEWORK_DIR/docs/"*.md; do
        [ -f "$doc" ] || continue
        filename=$(basename "$doc")
        # Don't overwrite existing docs (user may have customized)
        if [ ! -f "$TARGET_DIR/docs/$filename" ]; then
            cp "$doc" "$TARGET_DIR/docs/$filename"
            echo "  $filename (new)"
        else
            echo "  $filename (exists, skipped)"
        fi
    done
fi

# Save framework path
echo "$FRAMEWORK_DIR" > "$TARGET_DIR/.agent-framework-path"

echo ""
echo "Done! $INSTALLED skills installed/updated."
echo "Run '/resume' in your next session to verify."
