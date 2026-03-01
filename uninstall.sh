#!/usr/bin/env bash
# uninstall.sh - Remove OpenClaw on Android from Termux
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}  OpenClaw on Android - Uninstaller${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""

# Confirm
read -rp "This will remove OpenClaw and all related config. Continue? [y/N] " REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

# 1. Uninstall OpenClaw npm package
echo "Removing OpenClaw npm package..."
if command -v openclaw &>/dev/null; then
    npm uninstall -g openclaw 2>/dev/null || true
    echo -e "${GREEN}[OK]${NC}   openclaw package removed"
else
    echo -e "${YELLOW}[SKIP]${NC} openclaw not installed"
fi

# 2. Remove code-server
echo ""
echo "Removing code-server..."
# Stop code-server if running
if pgrep -f "code-server" &>/dev/null; then
    pkill -f "code-server" 2>/dev/null || true
    echo -e "${GREEN}[OK]${NC}   Stopped running code-server"
fi

if ls "$HOME/.local/lib"/code-server-* &>/dev/null 2>&1; then
    rm -rf "$HOME/.local/lib"/code-server-*
    echo -e "${GREEN}[OK]${NC}   Removed code-server from ~/.local/lib"
else
    echo -e "${YELLOW}[SKIP]${NC} code-server not found in ~/.local/lib"
fi

if [ -f "$HOME/.local/bin/code-server" ] || [ -L "$HOME/.local/bin/code-server" ]; then
    rm -f "$HOME/.local/bin/code-server"
    echo -e "${GREEN}[OK]${NC}   Removed ~/.local/bin/code-server"
else
    echo -e "${YELLOW}[SKIP]${NC} ~/.local/bin/code-server not found"
fi

# Clean up empty directories
rmdir "$HOME/.local/bin" 2>/dev/null || true
rmdir "$HOME/.local/lib" 2>/dev/null || true
rmdir "$HOME/.local" 2>/dev/null || true

# 3. Optionally remove OpenCode / oh-my-opencode
OPENCODE_INSTALLED=false
OMO_INSTALLED=false
[ -f "$PREFIX/bin/opencode" ] || [ -f "$PREFIX/tmp/ld.so.opencode" ] && OPENCODE_INSTALLED=true
[ -f "$PREFIX/bin/oh-my-opencode" ] || [ -f "$PREFIX/tmp/ld.so.omo" ] && OMO_INSTALLED=true

if [ "$OPENCODE_INSTALLED" = true ]; then
    echo ""
    read -rp "Remove OpenCode (AI coding assistant)? [Y/n] " REPLY
    if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
        # Stop OpenCode if running
        if pgrep -f "ld.so.opencode" &>/dev/null; then
            pkill -f "ld.so.opencode" 2>/dev/null || true
            echo -e "${GREEN}[OK]${NC}   Stopped running OpenCode"
        fi
        [ -f "$PREFIX/tmp/ld.so.opencode" ] && rm -f "$PREFIX/tmp/ld.so.opencode" && echo -e "${GREEN}[OK]${NC}   Removed ld.so.opencode"
        [ -f "$PREFIX/bin/opencode" ] && rm -f "$PREFIX/bin/opencode" && echo -e "${GREEN}[OK]${NC}   Removed opencode wrapper"
        [ -d "$HOME/.config/opencode" ] && rm -rf "$HOME/.config/opencode" && echo -e "${GREEN}[OK]${NC}   Removed ~/.config/opencode"
    else
        echo -e "${YELLOW}[KEEP]${NC} Keeping OpenCode"
    fi
fi

if [ "$OMO_INSTALLED" = true ]; then
    read -rp "Remove oh-my-opencode (OpenCode plugin framework)? [Y/n] " REPLY
    if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
        [ -f "$PREFIX/tmp/ld.so.omo" ] && rm -f "$PREFIX/tmp/ld.so.omo" && echo -e "${GREEN}[OK]${NC}   Removed ld.so.omo"
        [ -f "$PREFIX/bin/oh-my-opencode" ] && rm -f "$PREFIX/bin/oh-my-opencode" && echo -e "${GREEN}[OK]${NC}   Removed oh-my-opencode wrapper"
    else
        echo -e "${YELLOW}[KEEP]${NC} Keeping oh-my-opencode"
    fi
fi

# Remove Bun if both OpenCode and oh-my-opencode are gone
if [ ! -f "$PREFIX/bin/opencode" ] && [ ! -f "$PREFIX/bin/oh-my-opencode" ] && [ -d "$HOME/.bun" ]; then
    rm -rf "$HOME/.bun"
    echo -e "${GREEN}[OK]${NC}   Removed ~/.bun"
fi

# 4. Remove oa and oaupdate commands
if [ -f "$PREFIX/bin/oa" ]; then
    rm -f "$PREFIX/bin/oa"
    echo -e "${GREEN}[OK]${NC}   Removed $PREFIX/bin/oa"
else
    echo -e "${YELLOW}[SKIP]${NC} $PREFIX/bin/oa not found"
fi

if [ -f "$PREFIX/bin/oaupdate" ]; then
    rm -f "$PREFIX/bin/oaupdate"
    echo -e "${GREEN}[OK]${NC}   Removed $PREFIX/bin/oaupdate"
else
    echo -e "${YELLOW}[SKIP]${NC} $PREFIX/bin/oaupdate not found"
fi

# 5. Remove glibc components (proot rootfs is inside openclaw-android dir)
echo ""
echo "Removing glibc components..."

# Remove pacman glibc-runner package (non-critical if fails)
if command -v pacman &>/dev/null; then
    if pacman -Q glibc-runner &>/dev/null 2>&1; then
        pacman -R glibc-runner --noconfirm 2>/dev/null || true
        echo -e "${GREEN}[OK]${NC}   Removed glibc-runner package"
    fi
fi

# 6. Remove environment block from .bashrc
BASHRC="$HOME/.bashrc"
MARKER_START="# >>> OpenClaw on Android >>>"
MARKER_END="# <<< OpenClaw on Android <<<"

if [ -f "$BASHRC" ] && grep -qF "$MARKER_START" "$BASHRC"; then
    sed -i "/${MARKER_START//\//\\/}/,/${MARKER_END//\//\\/}/d" "$BASHRC"
    # Collapse consecutive blank lines left behind
    sed -i '/^$/{ N; /^\n$/d }' "$BASHRC"
    echo -e "${GREEN}[OK]${NC}   Removed environment block from $BASHRC"
else
    echo -e "${YELLOW}[SKIP]${NC} No environment block found in $BASHRC"
fi

# 7. Clean up temp directory
if [ -d "$PREFIX/tmp/openclaw" ]; then
    rm -rf "$PREFIX/tmp/openclaw"
    echo -e "${GREEN}[OK]${NC}   Removed $PREFIX/tmp/openclaw"
fi

# ─────────────────────────────────────────────
# Optional removal prompts
# ─────────────────────────────────────────────

# 8. Optionally remove openclaw-android directory
echo ""
if [ -d "$HOME/.openclaw-android" ]; then
    read -rp "Remove installation directory (~/.openclaw-android)? Includes Node.js, patches, configs. [Y/n] " REPLY
    if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
        rm -rf "$HOME/.openclaw-android"
        echo -e "${GREEN}[OK]${NC}   Removed $HOME/.openclaw-android"
    else
        echo -e "${YELLOW}[KEEP]${NC} Keeping $HOME/.openclaw-android"
    fi
fi

# 9. Optionally remove openclaw data
if [ -d "$HOME/.openclaw" ]; then
    read -rp "Remove OpenClaw data directory (~/.openclaw)? Includes workspace and settings. [y/N] " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.openclaw"
        echo -e "${GREEN}[OK]${NC}   Removed $HOME/.openclaw"
    else
        echo -e "${YELLOW}[KEEP]${NC} Keeping $HOME/.openclaw"
    fi
fi

# 10. Optionally remove AI CLI tools
AI_TOOLS_FOUND=()
AI_TOOL_LABELS=()
if command -v claude &>/dev/null; then
    AI_TOOLS_FOUND+=("@anthropic-ai/claude-code")
    AI_TOOL_LABELS+=("Claude Code")
fi
if command -v gemini &>/dev/null; then
    AI_TOOLS_FOUND+=("@google/gemini-cli")
    AI_TOOL_LABELS+=("Gemini CLI")
fi
if command -v codex &>/dev/null; then
    AI_TOOLS_FOUND+=("@openai/codex")
    AI_TOOL_LABELS+=("Codex CLI")
fi

if [ ${#AI_TOOLS_FOUND[@]} -gt 0 ]; then
    echo ""
    echo "Installed AI CLI tools detected:"
    for label in "${AI_TOOL_LABELS[@]}"; do
        echo "  - $label"
    done
    read -rp "Remove these AI CLI tools? [y/N] " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        for pkg in "${AI_TOOLS_FOUND[@]}"; do
            if npm uninstall -g "$pkg" 2>/dev/null; then
                echo -e "${GREEN}[OK]${NC}   Removed $pkg"
            else
                echo -e "${YELLOW}[WARN]${NC} Failed to remove $pkg"
            fi
        done
    else
        echo -e "${YELLOW}[KEEP]${NC} Keeping AI CLI tools"
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}Uninstall complete.${NC}"
echo "Restart your Termux session to clear environment variables."
echo ""
