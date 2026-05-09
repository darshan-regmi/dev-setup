#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                  Mac M2 Dev Setup — Web + Expo                   ║
# ║         Next.js · React · TypeScript · Expo · Supabase           ║
# ║              Optimized for 8GB RAM · 256GB SSD                   ║
# ╚══════════════════════════════════════════════════════════════════╝
# Usage: chmod +x setup.sh && ./setup.sh

set -o pipefail

# ─────────────────────────────────────────────────
# STYLES
# ─────────────────────────────────────────────────
RESET="\033[0m"; BOLD="\033[1m"; DIM="\033[2m"
RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"
MAGENTA="\033[35m"; CYAN="\033[36m"; WHITE="\033[37m"
BG_BLUE="\033[44m"

# ─────────────────────────────────────────────────
# LOGGERS
# ─────────────────────────────────────────────────
hdr()  { echo ""; echo -e "${BG_BLUE}${WHITE}${BOLD}  $1  ${RESET}"; echo -e "${DIM}──────────────────────────────────────────────${RESET}"; }
step() { echo -e "${CYAN}${BOLD}  ➜ ${RESET}${BOLD}$1${RESET}"; }
ok()   { echo -e "${GREEN}  ✔ $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
err()  { echo -e "${RED}  ✖ $1${RESET}"; }
info() { echo -e "${DIM}    $1${RESET}"; }
skip() { echo -e "${DIM}  ─ Skipped: $1${RESET}"; }

confirm() {
  echo -ne "${MAGENTA}  ? ${RESET}${BOLD}$1${RESET} ${DIM}[Y/n]${RESET}: "
  read -r ans
  case "${ans:=Y}" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

pause() { echo ""; echo -ne "${DIM}  Press [Enter] to continue...${RESET}"; read -r; }

# ─────────────────────────────────────────────────
# STATE TRACKING (skip completed steps on re-run)
# ─────────────────────────────────────────────────
STATE_FILE="$HOME/.devsetup_state"
touch "$STATE_FILE"
mark_done() { echo "$1" >> "$STATE_FILE"; }
is_done()   { grep -qx "$1" "$STATE_FILE" 2>/dev/null; }

# ─────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────
brew_install() {
  if brew list --formula "$1" &>/dev/null; then
    skip "$1 (already installed)"
  else
    step "Installing $1..."
    brew install "$1" && ok "$1 installed"
  fi
}

cask_install() {
  if brew list --cask "$1" &>/dev/null; then
    skip "$1 (already installed)"
  else
    step "Installing $1..."
    brew install --cask "$1" && ok "$1 installed"
  fi
}

# ─────────────────────────────────────────────────
# PRECHECK: Apple Silicon
# ─────────────────────────────────────────────────
precheck() {
  if [[ "$(uname -m)" != "arm64" ]]; then
    err "This script is for Apple Silicon Macs (M1/M2/M3/M4) only."
    exit 1
  fi
  ok "Apple Silicon detected: $(uname -m)"
}

# ════════════════════════════════════════════════════════════════════
# SECTIONS
# ════════════════════════════════════════════════════════════════════

# 01 · FOUNDATION ─ Xcode CLT + Homebrew
sec_foundation() {
  hdr "01 · Foundation (Xcode CLT + Homebrew)"

  if ! xcode-select -p &>/dev/null; then
    step "Installing Xcode Command Line Tools..."
    xcode-select --install
    info "A dialog has opened. Click Install, then re-run this script."
    exit 0
  else
    ok "Xcode CLT already installed"
  fi

  if ! command -v brew &>/dev/null; then
    step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew installed"
  else
    ok "Homebrew already installed: $(brew --version | head -1)"
  fi

  step "Updating Homebrew..."
  brew update &>/dev/null && ok "Homebrew up to date"

  mark_done "foundation"
}

# 02 · CORE CLI ─ Essential terminal tools
sec_cli() {
  hdr "02 · Core CLI Tools"

  local tools=(git gh wget curl jq ripgrep fd bat eza fzf zoxide tldr)
  for t in $tools; do
    brew_install "$t"
  done

  cask_install font-jetbrains-mono-nerd-font

  mark_done "cli"
}

# 03 · SHELL ─ Starship prompt (no Oh My Zsh, keep it fast)
sec_shell() {
  hdr "03 · Shell Prompt (Starship)"

  brew_install starship

  if ! grep -q 'starship init zsh' "$HOME/.zshrc" 2>/dev/null; then
    step "Adding Starship to .zshrc..."
    {
      echo ''
      echo '# Starship prompt'
      echo 'eval "$(starship init zsh)"'
    } >> "$HOME/.zshrc"
    ok "Starship configured"
  else
    skip "Starship already in .zshrc"
  fi

  # Minimal Starship config
  mkdir -p "$HOME/.config"
  if [[ ! -f "$HOME/.config/starship.toml" ]]; then
    cat > "$HOME/.config/starship.toml" << 'EOF'
# Minimal Starship config — fast and unobtrusive
add_newline = true
command_timeout = 1000

format = """
$directory\
$git_branch\
$git_status\
$nodejs\
$character"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
symbol = " "

[nodejs]
symbol = " "
format = "[$symbol($version )]($style)"
EOF
    ok "Starship config written"
  fi

  mark_done "shell"
}

# 04 · NODE ─ fnm + Node LTS + pnpm
sec_node() {
  hdr "04 · Node Ecosystem (fnm + pnpm)"

  brew_install fnm

  if ! grep -q 'fnm env' "$HOME/.zshrc" 2>/dev/null; then
    {
      echo ''
      echo '# fnm (Fast Node Manager)'
      echo 'eval "$(fnm env --use-on-cd)"'
    } >> "$HOME/.zshrc"
    ok "fnm added to .zshrc"
  fi

  eval "$(fnm env --use-on-cd)"

  if ! fnm list 2>/dev/null | grep -q lts-latest; then
    step "Installing Node LTS..."
    fnm install --lts
    fnm default lts-latest
    ok "Node LTS installed"
  else
    ok "Node LTS already installed"
  fi

  if ! command -v pnpm &>/dev/null; then
    step "Installing pnpm..."
    npm install -g pnpm
    ok "pnpm installed"
  else
    ok "pnpm already installed: $(pnpm --version)"
  fi

  info "pnpm saves disk by hardlinking packages across projects."

  mark_done "node"
}

# 05 · GIT + GITHUB ─ identity, SSH key, auth
sec_git() {
  hdr "05 · Git + GitHub"

  if [[ -z "$(git config --global user.name)" ]]; then
    echo -ne "${MAGENTA}  ? ${RESET}${BOLD}Git user name${RESET}: "
    read -r gname
    git config --global user.name "$gname"
    ok "Git name set: $gname"
  else
    ok "Git name already set: $(git config --global user.name)"
  fi

  if [[ -z "$(git config --global user.email)" ]]; then
    echo -ne "${MAGENTA}  ? ${RESET}${BOLD}Git email${RESET}: "
    read -r gemail
    git config --global user.email "$gemail"
    ok "Git email set: $gemail"
  else
    ok "Git email already set: $(git config --global user.email)"
  fi

  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.editor "cursor --wait"

  if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    if confirm "Generate SSH key for GitHub?"; then
      step "Generating ed25519 SSH key..."
      ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$HOME/.ssh/id_ed25519" -N ""
      eval "$(ssh-agent -s)" >/dev/null
      pbcopy < "$HOME/.ssh/id_ed25519.pub"
      ok "SSH key generated and copied to clipboard"
      info "Paste it at: https://github.com/settings/keys"
      pause
    fi
  else
    ok "SSH key already exists"
  fi

  if command -v gh &>/dev/null && ! gh auth status &>/dev/null; then
    if confirm "Login to GitHub CLI now?"; then
      gh auth login
    fi
  fi

  mark_done "git"
}

# 06 · EDITOR ─ Cursor (replaces VS Code as main)
sec_editor() {
  hdr "06 · Code Editor (Cursor)"

  cask_install cursor

  info "Cursor imports VS Code settings on first launch."
  info "After install, run these commands to install your essentials:"
  cat << 'EOF'

  cursor --install-extension dbaeumer.vscode-eslint
  cursor --install-extension esbenp.prettier-vscode
  cursor --install-extension bradlc.vscode-tailwindcss
  cursor --install-extension eamodio.gitlens
  cursor --install-extension usernamehw.errorlens
  cursor --install-extension Prisma.prisma
EOF

  mark_done "editor"
}

# 07 · TERMINAL ─ iTerm2 + Termius (SSH client)
sec_terminal() {
  hdr "07 · Terminal Apps"

  cask_install iterm2
  cask_install termius

  info "iTerm2: better default terminal than macOS Terminal (split panes, search,"
  info "        themes, hotkey window). Set as default after first launch."
  info ""
  info "Termius: SSH client with cloud-synced keys, snippets, and host management."
  info "         Free tier covers basic SSH; cloud sync needs paid Pro."
  info "         (Note: NOT to be confused with 'Tabby' aka the old Eugeny Terminus."
  info "          Tell me if you wanted that one instead — different tool.)"

  mark_done "terminal"
}

# 08 · AI TOOLS ─ Claude Desktop, Claude Code, ChatGPT, Codex
sec_ai_tools() {
  hdr "08 · AI Tools (Claude + ChatGPT + Codex)"

  # Anthropic
  cask_install claude
  cask_install claude-code

  # OpenAI
  cask_install chatgpt
  cask_install codex

  info "Desktop apps:"
  info "  • Claude Desktop  — Anthropic GUI, MCP server support"
  info "  • ChatGPT         — OpenAI GUI, Option+Space global hotkey"
  info ""
  info "Terminal coding agents (run in any project folder):"
  info "  • claude          — Anthropic's coding agent"
  info "  • codex           — OpenAI's coding agent"
  info ""
  info "Account requirements:"
  info "  • Claude apps    → paid Claude account (Pro or Max)"
  info "  • ChatGPT/Codex  → paid ChatGPT account (Plus or higher) OR API key"
  info "  Free tiers do NOT include the coding agent CLIs."
  info ""
  info "After install:"
  info "  1. claude doctor          (verify Claude Code install)"
  info "  2. cd into a project, run: claude   or   codex   (login prompts open browser)"
  info "  3. In Claude Code: type /init to generate a CLAUDE.md for the project"
  info "  4. In Codex: it will create AGENTS.md / .codex/ config in the repo"
  info ""
  info "Tip: Codex and Claude Code both work in the same project. Try both, see"
  info "     which feels better for the kind of work you're doing."

  mark_done "ai_tools"
}

# 09 · MOBILE DEV ─ Expo-only path (no Xcode/Android Studio)
sec_mobile() {
  hdr "09 · Mobile Dev (Expo path, no SDKs)"

  brew_install watchman
  brew_install --cask android-platform-tools 2>/dev/null || cask_install android-platform-tools

  info "watchman: required by React Native for file watching"
  info "android-platform-tools: gives you 'adb' without the 10GB Android Studio"
  info ""
  info "Test with your Nothing Phone 3a (USB connected, USB debugging on):"
  info "  adb devices"
  info ""
  info "For iPhone XR: install Expo Go from App Store, scan QR over WiFi"
  info "Skip Xcode and Android Studio until you genuinely need a custom dev client."

  mark_done "mobile"
}

# 10 · DATABASE + API GUI ─ Beekeeper Studio + Bruno (both free)
sec_dbtools() {
  hdr "10 · Database + API Tools"

  cask_install beekeeper-studio
  cask_install bruno

  info "Beekeeper Studio: free, open-source Postgres GUI"
  info "  Connect to Supabase: Project Settings → Database → connection string"
  info ""
  info "Bruno: API testing, files stored as plain text → version with git"

  mark_done "dbtools"
}

# 11 · DEPLOY CLIs ─ matches your hosts
sec_deploy() {
  hdr "11 · Deploy CLIs (Vercel · Netlify · Cloudflare · EAS · Supabase · Firebase)"

  local pkgs=(vercel netlify-cli wrangler eas-cli supabase)
  for p in $pkgs; do
    if npm list -g --depth=0 2>/dev/null | grep -q " $p@"; then
      skip "$p (already installed globally)"
    else
      step "Installing $p..."
      npm install -g "$p" && ok "$p installed"
    fi
  done

  brew_install firebase-cli

  info "Login commands (run when ready):"
  info "  vercel login · netlify login · wrangler login"
  info "  eas login    · supabase login · firebase login"

  mark_done "deploy"
}

# 12 · DESIGN ─ Figma desktop (Canva stays in browser)
sec_design() {
  hdr "12 · Design Tools"

  cask_install figma

  info "Canva runs fine in the browser; the macOS app is just an Electron wrapper."

  mark_done "design"
}

# 13 · NOTES, POETRY & RESEARCH ─ Obsidian + Zotero
sec_writing() {
  hdr "13 · Notes, Poetry & Research"

  cask_install obsidian
  cask_install zotero

  info "Obsidian: local markdown vault, syncs free via iCloud"
  info "  Suggested vault: ~/Writing/vault"
  info "  Keep Notion as your poetry website CMS; draft in Obsidian, publish to Notion."
  info ""
  info "Zotero: citation manager + PDF library for academic work"
  info "  Install the browser connector for Arc separately:"
  info "  https://www.zotero.org/download/connectors"

  mark_done "writing"
}

# 14 · PRODUCTIVITY ─ Raycast, OrbStack, Arc browser
sec_productivity() {
  hdr "14 · Productivity Apps"

  cask_install raycast
  cask_install orbstack
  cask_install arc

  info "Raycast → replaces Spotlight (clipboard history, snippets, window mgmt)"
  info "OrbStack → Docker replacement, much lighter on 8GB"
  info "Arc → your browser. Note: in maintenance mode since May 2025 (Atlassian"
  info "       acquired The Browser Company). Still gets security patches but no"
  info "       new features. Zen Browser is the open-source successor when you're"
  info "       ready: brew install --cask zen-browser"
  info ""
  info "Skipped (not needed on macOS 26 Tahoe):"
  info "  • Rectangle → native window tiling is now solid (drag-to-edge, green"
  info "                button menu, or Globe+Ctrl+arrows)"
  info "  • The Unarchiver → install on demand if you hit a .rar file"

  mark_done "productivity"
}

# 15 · MEDIA & COMMUNICATION ─ Discord, Spotify, Spicetify, Stremio
sec_media() {
  hdr "15 · Media & Communication"

  cask_install discord
  cask_install spotify
  cask_install stremio

  # Spicetify: install via brew, but warn about Spotify update behavior
  if ! command -v spicetify &>/dev/null; then
    step "Installing spicetify-cli..."
    brew install spicetify-cli && ok "spicetify-cli installed"
  else
    skip "spicetify (already installed)"
  fi

  info "Discord: chat. Sign in after install."
  info ""
  info "Spotify: launch it ONCE so it creates its data folders, then quit it"
  info "         BEFORE running spicetify."
  info ""
  info "Spicetify (after Spotify is installed and launched once):"
  info "  spicetify backup apply"
  info "  Browse themes: https://spicetify.app/docs/marketplace/themes"
  info "  Heads-up: Spotify auto-updates wipe spicetify changes. Re-run"
  info "  'spicetify backup apply' after each Spotify update."
  info ""
  info "Stremio: streaming with addons. Use legitimate sources only."

  mark_done "media"
}

# 16 · MICROSOFT OFFICE & ONEDRIVE
sec_office() {
  hdr "16 · Microsoft Office + OneDrive"

  if confirm "Install full Office suite (Word + Excel + PowerPoint + Outlook + OneNote, ~3GB)?"; then
    cask_install microsoft-office
  else
    info "Installing Word, Excel, PowerPoint individually..."
    cask_install microsoft-word
    cask_install microsoft-excel
    cask_install microsoft-powerpoint
  fi

  cask_install onedrive

  info "Office apps require a Microsoft 365 subscription or one-time license"
  info "to use past the trial. Sign in with your school/work account if you"
  info "have one (many universities provide free Microsoft 365 to students)."
  info ""
  info "OneDrive: sign in, choose folders to sync. Avoid syncing large project"
  info "          folders like node_modules — they will eat your bandwidth."

  mark_done "office"
}

# 17 · FOLDERS ─ ~/Developer + ~/Writing structure
sec_folders() {
  hdr "17 · Project Folder Structure"

  step "Creating ~/Developer/..."
  mkdir -p \
    "$HOME/Developer/web/next" \
    "$HOME/Developer/web/express" \
    "$HOME/Developer/mobile/expo" \
    "$HOME/Developer/scripts" \
    "$HOME/Developer/labs" \
    "$HOME/Developer/work" \
    "$HOME/Developer/university" \
    "$HOME/Developer/archive" \
    "$HOME/Developer/.envs"
  ok "~/Developer/ ready"

  step "Creating ~/Writing/..."
  mkdir -p \
    "$HOME/Writing/poetry/drafts" \
    "$HOME/Writing/poetry/published" \
    "$HOME/Writing/notes" \
    "$HOME/Writing/essays"
  ok "~/Writing/ ready"

  if [[ ! -f "$HOME/Developer/.envs/.env.template" ]]; then
    cat > "$HOME/Developer/.envs/.env.template" << 'EOF'
# Shared env template — copy into individual projects
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=

NOTION_API_KEY=
NOTION_DATABASE_ID=

DATABASE_URL=postgresql://user:pass@host:5432/db
EOF
    ok ".env.template created"
  fi

  mark_done "folders"
}

# 18 · ALIASES ─ append to .zshrc
sec_aliases() {
  hdr "18 · Shell Aliases"

  if grep -q "# === DEV SETUP ALIASES ===" "$HOME/.zshrc" 2>/dev/null; then
    skip "Aliases already in .zshrc"
    mark_done "aliases"
    return
  fi

  cat >> "$HOME/.zshrc" << 'EOF'

# === DEV SETUP ALIASES ===

# Navigation
alias dev='cd ~/Developer'
alias write='cd ~/Writing'
alias ll='eza -la --icons --git'
alias lt='eza --tree --level=2 --icons'

# Git
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gb='git branch'

# pnpm (use everywhere)
alias pn='pnpm'
alias pnd='pnpm dev'
alias pnb='pnpm build'
alias pni='pnpm install'
alias pnr='pnpm run'

# Expo
alias exs='pnpm expo start'
alias exa='pnpm expo start --android'
alias exi='pnpm expo start --ios'
alias exb='eas build --platform all'

# Disk hygiene (critical at 256GB)
alias dud='du -sh * | sort -h'
alias clean-node='find . -name "node_modules" -type d -prune -exec rm -rf {} +'
alias clean-pnpm='pnpm store prune'
alias clean-expo='rm -rf ~/.expo ~/Library/Caches/Expo'
alias clean-derived='rm -rf ~/Library/Developer/Xcode/DerivedData/*'
alias clean-all='clean-pnpm && clean-expo && clean-derived && brew cleanup'

# Quick edits
alias zconf='cursor ~/.zshrc'
alias zreload='source ~/.zshrc'

# System
alias ip='ipconfig getifaddr en0'
alias memcheck='memory_pressure | head -3'
# === END DEV SETUP ALIASES ===
EOF

  ok "Aliases appended to .zshrc"
  mark_done "aliases"
}

# 19 · CLEANUP ─ first-pass disk reclaim
sec_cleanup() {
  hdr "19 · Cleanup"

  step "Cleaning Homebrew cache..."
  brew cleanup -s &>/dev/null
  ok "Homebrew cleaned"

  step "Cleaning npm cache..."
  npm cache clean --force &>/dev/null 2>&1
  ok "npm cache cleared"

  if command -v pnpm &>/dev/null; then
    step "Pruning pnpm store..."
    pnpm store prune &>/dev/null
    ok "pnpm store pruned"
  fi

  step "Disk usage:"
  df -h / | awk 'NR==2 {print "    Used: " $3 "  /  Available: " $4 "  (" $5 " full)"}'

  mark_done "cleanup"
}

# ════════════════════════════════════════════════════════════════════
# MENU
# ════════════════════════════════════════════════════════════════════

declare -a SECTIONS=(
  "01 · Foundation (Xcode CLT + Homebrew)|sec_foundation|foundation"
  "02 · Core CLI Tools|sec_cli|cli"
  "03 · Shell Prompt (Starship)|sec_shell|shell"
  "04 · Node Ecosystem (fnm + pnpm)|sec_node|node"
  "05 · Git + GitHub|sec_git|git"
  "06 · Editor (Cursor)|sec_editor|editor"
  "07 · Terminal Apps (iTerm2 + Termius)|sec_terminal|terminal"
  "08 · AI Tools (Claude + ChatGPT + Codex)|sec_ai_tools|ai_tools"
  "09 · Mobile Dev (Expo path)|sec_mobile|mobile"
  "10 · Database + API Tools|sec_dbtools|dbtools"
  "11 · Deploy CLIs|sec_deploy|deploy"
  "12 · Design Tools|sec_design|design"
  "13 · Notes, Poetry & Research|sec_writing|writing"
  "14 · Productivity Apps|sec_productivity|productivity"
  "15 · Media & Communication|sec_media|media"
  "16 · Microsoft Office + OneDrive|sec_office|office"
  "17 · Project Folders|sec_folders|folders"
  "18 · Shell Aliases|sec_aliases|aliases"
  "19 · Cleanup|sec_cleanup|cleanup"
)

show_menu() {
  clear
  echo ""
  echo -e "${BG_BLUE}${WHITE}${BOLD}                                                            ${RESET}"
  echo -e "${BG_BLUE}${WHITE}${BOLD}        Mac M2 Dev Setup — Web + Expo + Writing            ${RESET}"
  echo -e "${BG_BLUE}${WHITE}${BOLD}                                                            ${RESET}"
  echo ""
  echo -e "${DIM}  Stack: Next.js · React · TS · Expo · Supabase · Postgres${RESET}"
  echo -e "${DIM}  Optimized for: 8GB RAM · 256GB SSD · Apple Silicon${RESET}"
  echo ""
  echo -e "${BOLD}  Installation Menu${RESET}"
  echo ""

  local i=1
  for entry in "${SECTIONS[@]}"; do
    local label="${entry%%|*}"
    local key="${entry##*|}"
    if is_done "$key"; then
      echo -e "  ${GREEN}✔${RESET} ${DIM}$label${RESET}"
    else
      echo -e "  ${DIM}○${RESET} $label"
    fi
    ((i++))
  done

  echo ""
  echo -e "  ${BOLD}[A]${RESET} Install All    ${BOLD}[R]${RESET} Reset state    ${BOLD}[Q]${RESET} Quit"
  echo -e "  ${BOLD}[01-15]${RESET} Jump to a section"
  echo ""
  echo -ne "${MAGENTA}  ? ${RESET}${BOLD}Choice${RESET}: "
}

run_section() {
  local idx="$1"
  local entry="${SECTIONS[$idx]}"
  local fn="${entry#*|}"; fn="${fn%%|*}"
  $fn
  pause
}

run_all() {
  for entry in "${SECTIONS[@]}"; do
    local fn="${entry#*|}"; fn="${fn%%|*}"
    $fn
  done
  echo ""
  hdr "✓ All sections complete"
  echo ""
  info "Next steps:"
  info "  1. Restart your terminal (or run: source ~/.zshrc)"
  info "  2. Run: gh auth login         (if not done)"
  info "  3. Run: vercel login          (and other deploy CLIs)"
  info "  4. Open Cursor, sign in, sync settings"
  info "  5. Test Expo: pnpm dlx create-expo-app test && cd test && pnpm start"
  info "     → scan QR with Expo Go on your Nothing Phone or iPhone XR"
}

# ════════════════════════════════════════════════════════════════════
# ENTRY
# ════════════════════════════════════════════════════════════════════

main() {
  precheck

  while true; do
    show_menu
    read -r choice

    case "$choice" in
      [Aa]) run_all; pause ;;
      [Qq]) echo ""; ok "Bye."; exit 0 ;;
      [Rr])
        if confirm "Reset state file? (re-runs everything)"; then
          : > "$STATE_FILE"
          ok "State reset"
          pause
        fi
        ;;
      ''|*[!0-9]*) warn "Invalid choice"; sleep 1 ;;
      *)
        local n=$((10#$choice))
        if (( n >= 1 && n <= ${#SECTIONS[@]} )); then
          run_section $((n - 1))
        else
          warn "Choice out of range"; sleep 1
        fi
        ;;
    esac
  done
}

main "$@"
