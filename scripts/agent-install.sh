#!/usr/bin/env bash
set -euo pipefail

FRAMEWORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"

TARGET_DIR="."
TARGETS_RAW=""
FORCE=false

print_help() {
    cat <<'EOF'
Usage: agent-install [target-directory] [options]

Install/update agent-framework skills in an existing agent repo.

Options:
  --target <list>    Comma-separated install targets: claude,cursor,codex,generic
                      (default: auto-detect from repo contents)
  --force             Non-interactive install: overwrite locally modified files
                      (a .bak backup is created first) without prompting
  -h, --help          Show this help

Examples:
  agent-install /path/to/agent
  agent-install /path/to/agent --target claude,cursor
  agent-install /path/to/agent --target generic --force
EOF
}

# Parse args: any leading non-flag arg is treated as the target directory.
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            TARGETS_RAW="${2:-}"
            shift 2
            ;;
        --target=*)
            TARGETS_RAW="${1#*=}"
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [ "${#POSITIONAL[@]}" -gt 0 ]; then
    TARGET_DIR="${POSITIONAL[0]}"
fi

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    echo "Error: Directory '$TARGET_DIR' does not exist."
    print_help
    exit 1
}

echo "=== Agent Framework — Install/Update Skills ==="
echo "Source: $FRAMEWORK_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Identity file detection: AGENT.md is the source of truth; fall back to
# legacy CLAUDE.md / AGENTS.md with a migration warning (backward compat).
IDENTITY_FILE=""
if [ -f "$TARGET_DIR/AGENT.md" ]; then
    IDENTITY_FILE="AGENT.md"
elif [ -f "$TARGET_DIR/CLAUDE.md" ]; then
    IDENTITY_FILE="CLAUDE.md"
    echo "WARNING: No AGENT.md found — using legacy CLAUDE.md as identity file."
    echo "         Consider migrating to AGENT.md (see docs/INSTALLATION.md)."
elif [ -f "$TARGET_DIR/AGENTS.md" ]; then
    IDENTITY_FILE="AGENTS.md"
    echo "WARNING: No AGENT.md found — using legacy AGENTS.md as identity file."
    echo "         Consider migrating to AGENT.md (see docs/INSTALLATION.md)."
else
    echo "Error: No AGENT.md, CLAUDE.md, or AGENTS.md found in $TARGET_DIR"
    echo "Run 'agent-init $TARGET_DIR' first to create an agent."
    exit 1
fi

# ---- md5 helper (Linux md5sum, macOS md5 -q fallback) ----
md5_of() {
    if command -v md5sum &>/dev/null; then
        md5sum "$1" | awk '{print $1}'
    elif command -v md5 &>/dev/null; then
        md5 -q "$1"
    else
        echo "no-md5-available"
    fi
}

STAMP_FILE="$TARGET_DIR/.agent-framework-install-stamp"

# ---- Conflict-aware single-file installer ----
# Copies $src to $dest. If $dest already exists, differs from $src, and was
# modified since the last recorded install, warn (or, with --force, back up
# and overwrite non-interactively).
install_skill_file() {
    local src="$1" dest="$2"

    if [ -f "$dest" ]; then
        local src_hash dest_hash
        src_hash="$(md5_of "$src")"
        dest_hash="$(md5_of "$dest")"

        if [ "$src_hash" != "$dest_hash" ]; then
            local modified_after_install=true
            if [ -f "$STAMP_FILE" ] && [ ! "$dest" -nt "$STAMP_FILE" ]; then
                modified_after_install=false
            fi

            if [ "$modified_after_install" = true ]; then
                if [ "$FORCE" = true ]; then
                    cp "$dest" "$dest.bak"
                    echo "  WARNING: $(basename "$dest") has local modifications. Backed up to $(basename "$dest").bak and overwritten (--force)."
                else
                    local reply="n"
                    read -r -p "  WARNING: $(basename "$dest") has local modifications. Overwrite? [y/N] " reply || reply="n"
                    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
                        echo "  Skipped $(basename "$dest")"
                        return 0
                    fi
                    cp "$dest" "$dest.bak"
                fi
            fi
        fi
    fi

    cp "$src" "$dest"
}

# Copies every skills/*.md from the framework into $1, returns count on stdout.
copy_skills_to() {
    local dest_dir="$1"
    mkdir -p "$dest_dir"
    local count=0
    for skill in "$FRAMEWORK_DIR/skills/"*.md; do
        [ -f "$skill" ] || continue
        local filename
        filename="$(basename "$skill")"
        install_skill_file "$skill" "$dest_dir/$filename"
        count=$((count + 1))
    done
    echo "$count"
}

# Regenerates a tool-specific compatibility stub (CLAUDE.md / AGENTS.md) from
# AGENT.md. Stubs are derived artifacts — AGENT.md remains the source of truth.
generate_stub() {
    local stub_name="$1"
    if [ ! -f "$TARGET_DIR/AGENT.md" ]; then
        return 0
    fi
    local stub_path="$TARGET_DIR/$stub_name"
    {
        echo "<!-- Auto-generated from AGENT.md by agent-framework. Edit AGENT.md, not this file. -->"
        echo ""
        cat "$TARGET_DIR/AGENT.md"
    } > "$stub_path"
    echo "  Regenerated $stub_name from AGENT.md"
}

# ---- Target resolution: explicit --target list, or auto-detect ----
detect_targets() {
    local detected=()
    [ -d "$TARGET_DIR/.claude" ] && detected+=("claude")
    [ -d "$TARGET_DIR/.cursor" ] && detected+=("cursor")
    if [ -f "$TARGET_DIR/AGENTS.md" ] && [ ! -d "$TARGET_DIR/.claude" ]; then
        detected+=("codex")
    fi
    if [ "${#detected[@]}" -eq 0 ]; then
        detected+=("generic")
    fi
    printf '%s\n' "${detected[@]}"
}

TARGET_LIST=()
if [ -n "$TARGETS_RAW" ]; then
    IFS=',' read -ra TARGET_LIST <<< "$TARGETS_RAW"
else
    while IFS= read -r t; do
        [ -n "$t" ] && TARGET_LIST+=("$t")
    done < <(detect_targets)
fi

INSTALLED=0

for raw_target in "${TARGET_LIST[@]:-}"; do
    target="$(echo "$raw_target" | tr -d '[:space:]')"
    [ -n "$target" ] || continue

    case "$target" in
        claude)
            echo "Installing target: claude"
            n=$(copy_skills_to "$TARGET_DIR/.claude/commands/agent-core")
            INSTALLED=$((INSTALLED + n))
            echo "  Installed $n skills -> .claude/commands/agent-core/"
            generate_stub "CLAUDE.md"
            ;;
        codex)
            echo "Installing target: codex"
            n=$(copy_skills_to "$TARGET_DIR/.claude/commands/agent-core")
            INSTALLED=$((INSTALLED + n))
            echo "  Installed $n skills -> .claude/commands/agent-core/"
            generate_stub "AGENTS.md"
            ;;
        cursor)
            echo "Installing target: cursor"
            n=$(copy_skills_to "$TARGET_DIR/.cursor/rules/agent-core")
            INSTALLED=$((INSTALLED + n))
            echo "  Installed $n skills -> .cursor/rules/agent-core/"
            ;;
        generic)
            echo "Installing target: generic"
            n=$(copy_skills_to "$TARGET_DIR/skills")
            INSTALLED=$((INSTALLED + n))
            echo "  Installed $n skills -> skills/"
            generate_stub "AGENTS.md"
            ;;
        *)
            echo "Warning: unknown target '$target', skipping"
            ;;
    esac
done

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

# Record install stamp (used for conflict detection on next run)
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STAMP_FILE" 2>/dev/null || touch "$STAMP_FILE"

echo ""
echo "Done! $INSTALLED skills installed/updated."
echo "Run '/resume' in your next session to verify."
