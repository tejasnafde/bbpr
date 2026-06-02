#!/usr/bin/env bash
# bbpr uninstaller
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC}  $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC}   $*"; }
info() { echo -e "  ${BLUE}→${NC}  $*"; }

echo ""
echo -e "${BOLD}bbpr uninstaller${NC}"
echo "────────────────────────────────────────"
echo ""

# CLI binary
if [[ -f "$HOME/.local/bin/bbpr" ]]; then
    rm "$HOME/.local/bin/bbpr"
    ok "Removed ~/.local/bin/bbpr"
else
    info "~/.local/bin/bbpr not found — already removed?"
fi

# Venv
if [[ -d "$HOME/.local/bitbucket-review" ]]; then
    read -r -p "  Remove ~/.local/bitbucket-review (Python venv)? [Y/n] " ans
    ans="${ans:-Y}"
    if [[ "$ans" =~ ^[Yy] ]]; then
        rm -rf "$HOME/.local/bitbucket-review"
        ok "Removed ~/.local/bitbucket-review"
    fi
fi

# Credentials
if [[ -f "$HOME/.config/bbpr/credentials" ]]; then
    read -r -p "  Remove ~/.config/bbpr/credentials? [Y/n] " ans
    ans="${ans:-Y}"
    if [[ "$ans" =~ ^[Yy] ]]; then
        rm -f "$HOME/.config/bbpr/credentials"
        rmdir "$HOME/.config/bbpr" 2>/dev/null || true
        ok "Removed credentials"
    fi
fi

# Skill files
declare -a skill_paths=(
    "$HOME/.claude/skills/bbpr.md"
    "$HOME/.cursor/rules/bbpr.mdc"
    "$HOME/.config/opencode/bbpr.md"
    "$HOME/.codex/bbpr.md"
)

found_any=0
for p in "${skill_paths[@]}"; do
    if [[ -f "$p" ]]; then
        found_any=1
        break
    fi
done

if [[ $found_any -eq 1 ]]; then
    echo ""
    info "Found skill files:"
    for p in "${skill_paths[@]}"; do
        [[ -f "$p" ]] && echo "      $p"
    done
    read -r -p "  Remove them? [Y/n] " ans
    ans="${ans:-Y}"
    if [[ "$ans" =~ ^[Yy] ]]; then
        for p in "${skill_paths[@]}"; do
            if [[ -f "$p" ]]; then
                rm -f "$p"
                ok "Removed $p"
            fi
        done
    fi
fi

echo ""
echo "────────────────────────────────────────"
echo -e "${BOLD}bbpr uninstalled.${NC}"
echo ""
