#!/usr/bin/env bash
# bbpr installer — sets up the CLI, agent skill file, and credentials.
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bitbucket-review"
BIN_DIR="$HOME/.local/bin"
VENV_PYTHON=""

say()  { echo -e "\n${BOLD}$*${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC}  $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC}   $*"; }
fail() { echo -e "  ${RED}✗${NC}  $*"; }
info() { echo -e "  ${BLUE}→${NC}  $*"; }

echo ""
echo -e "${BOLD}bbpr installer${NC}"
echo "────────────────────────────────────────"


# ── 1. Python 3.8+ ────────────────────────────────────────────────────────────

say "Checking Python..."

PYTHON_BIN=""
for py in python3 python; do
    if command -v "$py" &>/dev/null; then
        ver=$("$py" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null || true)
        major="${ver%%.*}"
        minor="${ver##*.}"
        if [[ -n "$ver" ]] && (( major >= 3 && minor >= 8 )); then
            PYTHON_BIN=$(command -v "$py")
            ok "Found $PYTHON_BIN ($ver)"
            break
        fi
    fi
done

if [[ -z "$PYTHON_BIN" ]]; then
    fail "Python 3.8+ not found."
    info "Install via: brew install python3"
    exit 1
fi


# ── 2. Venv + requests ────────────────────────────────────────────────────────

say "Setting up Python environment..."

mkdir -p "$INSTALL_DIR"
if [[ ! -d "$INSTALL_DIR/.venv" ]]; then
    "$PYTHON_BIN" -m venv "$INSTALL_DIR/.venv"
    ok "Created venv at $INSTALL_DIR/.venv"
else
    ok "Venv already exists at $INSTALL_DIR/.venv"
fi

"$INSTALL_DIR/.venv/bin/pip" install --quiet --upgrade pip requests
ok "requests installed"

VENV_PYTHON="$INSTALL_DIR/.venv/bin/python3"


# ── 3. Install bbpr to ~/.local/bin ──────────────────────────────────────────

say "Installing bbpr..."

mkdir -p "$BIN_DIR"

# Rewrite shebang to point to our venv's python so the right requests is used
{
    echo "#!$VENV_PYTHON"
    tail -n +2 "$SCRIPT_DIR/bbpr"
} > "$BIN_DIR/bbpr"
chmod +x "$BIN_DIR/bbpr"
ok "Installed to $BIN_DIR/bbpr"


# ── 4. PATH check ─────────────────────────────────────────────────────────────

say "Checking PATH..."

if echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    ok "$BIN_DIR is already in PATH"
else
    warn "$BIN_DIR is not in your PATH"
    echo ""
    read -r -p "    Add it to ~/.zshrc? [Y/n] " ans
    ans="${ans:-Y}"
    if [[ "$ans" =~ ^[Yy] ]]; then
        {
            echo ""
            echo "# Added by bbpr installer"
            echo 'export PATH="$HOME/.local/bin:$PATH"'
        } >> "$HOME/.zshrc"
        ok "Added to ~/.zshrc"
        info "Restart your terminal or run: source ~/.zshrc"
    else
        info "Add this line to your shell config manually:"
        echo '        export PATH="$HOME/.local/bin:$PATH"'
    fi
fi


# ── 5. Skill file installation ────────────────────────────────────────────────

say "Installing agent skill file..."
info "This teaches agents how and when to use bbpr automatically."
echo ""

n_skill_installed=0

install_skill_to() {
    local dir="$1" display="$2" ext="${3:-md}"
    local dest="$dir/bbpr.$ext"
    local src="$SCRIPT_DIR/skill.$ext"
    [[ -f "$src" ]] || src="$SCRIPT_DIR/skill.md"   # fallback to .md if no variant

    read -r -p "    Install to $display ($dest)? [Y/n] " ans
    ans="${ans:-Y}"
    if [[ "$ans" =~ ^[Yy] ]]; then
        if mkdir -p "$dir" 2>/dev/null && cp "$src" "$dest" 2>/dev/null; then
            ok "Installed → $dest"
            n_skill_installed=$((n_skill_installed + 1))
        else
            fail "Could not write to $dest"
        fi
    else
        info "Skipped $display"
    fi
}

# Claude Code — proactive: create skills dir if ~/.claude exists
[[ -d "$HOME/.claude" ]] && install_skill_to "$HOME/.claude/skills" "Claude Code" "md"

# Cursor — only if rules dir already exists
[[ -d "$HOME/.cursor/rules" ]] && install_skill_to "$HOME/.cursor/rules" "Cursor" "mdc"

# OpenCode
[[ -d "$HOME/.config/opencode" ]] && install_skill_to "$HOME/.config/opencode" "OpenCode" "md"

# Codex CLI
[[ -d "$HOME/.codex" ]] && install_skill_to "$HOME/.codex" "Codex CLI" "md"

# Custom path
echo ""
read -r -p "    Add a custom agent skill path? (Enter to skip): " custom_dir
if [[ -n "$custom_dir" ]]; then
    install_skill_to "$custom_dir" "Custom" "md"
fi

echo ""
if [[ $n_skill_installed -eq 0 ]]; then
    warn "No skill files installed."
    info "To install later, copy skill.md to your agent's skills directory."
else
    ok "Skill file installed to $n_skill_installed location(s)"
fi


# ── 6. Credentials setup ──────────────────────────────────────────────────────

say "Credentials setup..."
echo ""

if [[ -f "$HOME/.config/bbpr/credentials" ]]; then
    ok "Credentials already exist at ~/.config/bbpr/credentials"
    read -r -p "    Re-run setup wizard to update them? [y/N] " ans
    ans="${ans:-N}"
    if [[ "$ans" =~ ^[Yy] ]]; then
        echo ""
        "$BIN_DIR/bbpr" setup
    fi
else
    read -r -p "    Set up Bitbucket credentials now? [Y/n] " ans
    ans="${ans:-Y}"
    if [[ "$ans" =~ ^[Yy] ]]; then
        echo ""
        "$BIN_DIR/bbpr" setup
    else
        info "Run 'bbpr setup' whenever you're ready."
    fi
fi


# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────"
echo -e "${BOLD}bbpr is ready!${NC}"
echo ""
echo "  bbpr 123                      # review PR from current repo"
echo "  bbpr <bitbucket-pr-url>       # review any PR by URL"
echo "  bbpr <url> diff               # just the diff"
echo "  bbpr <url> comments           # just the comments"
echo "  bbpr setup                    # reconfigure credentials"
echo ""
