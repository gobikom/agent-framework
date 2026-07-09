#!/usr/bin/env bash
set -euo pipefail

FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=false
REPOS_DIR="${HOME}/repos"
TARGET_ARG=""

print_help() {
    echo "Usage: agent-install-all [--dry-run] [--repos-dir=PATH] [--target=claude,cursor,codex,generic]"
    echo ""
    echo "Install/update agent-framework skills in all agent repos."
    echo ""
    echo "Options:"
    echo "  --dry-run          Preview which repos would be updated"
    echo "  --repos-dir=PATH   Root directory to scan (default: ~/repos)"
    echo "  --target=LIST      Comma-separated install targets, passed through to agent-install.sh"
}

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --repos-dir=*)
            REPOS_DIR="${1#*=}"
            shift
            ;;
        --repos-dir)
            REPOS_DIR="${2:-$REPOS_DIR}"
            shift 2
            ;;
        --target=*)
            TARGET_ARG="${1#*=}"
            shift
            ;;
        --target)
            TARGET_ARG="${2:-}"
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            print_help
            exit 1
            ;;
    esac
done

echo "=== Agent Framework — Install All ==="
echo "Framework: $FRAMEWORK_DIR"
echo "Scanning: $REPOS_DIR"
[ "$DRY_RUN" = true ] && echo "Mode: DRY RUN"
[ -n "$TARGET_ARG" ] && echo "Target: $TARGET_ARG"
echo ""

COUNT=0
UPDATED=0
FAILED=0

# Find repos with an identity file (AGENT.md preferred, CLAUDE.md legacy
# fallback) that contain agent identity markers. "AGENT.md" itself is a
# marker string because auto-generated CLAUDE.md compat stubs contain the
# line "Auto-generated from AGENT.md by agent-framework".
while IFS= read -r repo_dir; do
    [ -n "$repo_dir" ] || continue

    # Skip the framework itself
    if [ "$repo_dir" = "$FRAMEWORK_DIR" ]; then
        continue
    fi

    identity_file=""
    if [ -f "$repo_dir/AGENT.md" ]; then
        identity_file="$repo_dir/AGENT.md"
    elif [ -f "$repo_dir/CLAUDE.md" ]; then
        identity_file="$repo_dir/CLAUDE.md"
    else
        continue
    fi

    if grep -q "Agent ID\|Memory System\|Learning Loop\|AGENT.md" "$identity_file" 2>/dev/null; then
        COUNT=$((COUNT + 1))
        agent_name=$(grep -m1 "^# " "$identity_file" | sed 's/^# //' || echo "unknown")

        if [ "$DRY_RUN" = true ]; then
            echo "  Would update: $repo_dir ($agent_name)"
        else
            echo "  Updating: $repo_dir ($agent_name)"
            install_args=("$repo_dir")
            if [ -n "$TARGET_ARG" ]; then
                install_args+=("--target" "$TARGET_ARG")
            fi
            if "$FRAMEWORK_DIR/scripts/agent-install.sh" "${install_args[@]}" 2>&1 | sed 's/^/    /'; then
                UPDATED=$((UPDATED + 1))
            else
                echo "    FAILED: $repo_dir"
                FAILED=$((FAILED + 1))
            fi
            echo ""
        fi
    fi
done < <(find "$REPOS_DIR" -maxdepth 4 \( -name "CLAUDE.md" -o -name "AGENT.md" \) -type f -exec dirname {} \; 2>/dev/null | sort -u)

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "Found $COUNT agent repos. Run without --dry-run to update."
else
    echo "Updated $UPDATED/$COUNT agent repos."
    [ "$FAILED" -gt 0 ] && echo "Failed: $FAILED repos (check output above)"
fi
