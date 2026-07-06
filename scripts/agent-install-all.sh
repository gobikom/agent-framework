#!/usr/bin/env bash
set -euo pipefail

FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=false
REPOS_DIR="${HOME}/repos"

# Parse args
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        --repos-dir=*) REPOS_DIR="${arg#*=}" ;;
        -h|--help)
            echo "Usage: agent-install-all [--dry-run] [--repos-dir=PATH]"
            echo ""
            echo "Install/update agent-framework skills in all agent repos."
            echo ""
            echo "Options:"
            echo "  --dry-run          Preview which repos would be updated"
            echo "  --repos-dir=PATH   Root directory to scan (default: ~/repos)"
            exit 0
            ;;
        *) echo "Usage: agent-install-all [--dry-run] [--repos-dir=PATH]"; exit 1 ;;
    esac
done

echo "=== Agent Framework — Install All ==="
echo "Framework: $FRAMEWORK_DIR"
echo "Scanning: $REPOS_DIR"
[ "$DRY_RUN" = true ] && echo "Mode: DRY RUN"
echo ""

COUNT=0
UPDATED=0
FAILED=0

# Find repos with CLAUDE.md that contain agent identity markers
while IFS= read -r claude_md; do
    repo_dir="$(dirname "$claude_md")"

    # Skip the framework itself
    if [ "$repo_dir" = "$FRAMEWORK_DIR" ]; then
        continue
    fi

    # Check if it has agent identity (look for "Agent ID" or "Memory System" section)
    if grep -q "Agent ID\|Memory System\|Learning Loop" "$claude_md" 2>/dev/null; then
        COUNT=$((COUNT + 1))
        agent_name=$(grep -m1 "^# " "$claude_md" | sed 's/^# //' || echo "unknown")

        if [ "$DRY_RUN" = true ]; then
            echo "  Would update: $repo_dir ($agent_name)"
        else
            echo "  Updating: $repo_dir ($agent_name)"
            if "$FRAMEWORK_DIR/scripts/agent-install.sh" "$repo_dir" 2>&1 | sed 's/^/    /'; then
                UPDATED=$((UPDATED + 1))
            else
                echo "    FAILED: $repo_dir"
                FAILED=$((FAILED + 1))
            fi
            echo ""
        fi
    fi
done < <(find "$REPOS_DIR" -maxdepth 4 -name "CLAUDE.md" -type f 2>/dev/null)

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "Found $COUNT agent repos. Run without --dry-run to update."
else
    echo "Updated $UPDATED/$COUNT agent repos."
    [ "$FAILED" -gt 0 ] && echo "Failed: $FAILED repos (check output above)"
fi
