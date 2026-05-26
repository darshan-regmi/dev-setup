#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║          Mac Dev Setup — v2                                      ║
# ║   Web:    Next.js · Express · Node · Firebase · TS               ║
# ║   Mobile: Expo · React Native · Firebase · TS                    ║
# ║   DB:     PostgreSQL (Prisma) + MySQL                            ║
# ║   Student: Notion · MS Word · iWork                              ║
# ║   8GB RAM · 245GB SSD · Apple Silicon                            ║
# ╚══════════════════════════════════════════════════════════════════╝
# Usage: chmod +x setup.sh && ./setup.sh

set -o pipefail

# ── styling ──────────────────────────────────────────────────────────
RESET="\033[0m"; BOLD="\033[1m"; DIM="\033[2m"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"

hdr()  { echo ""; echo -e "${BOLD}${CYAN}━━ $1 ━━${RESET}"; }
step() { echo -e "  ${CYAN}➜${RESET} $1"; }
ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
skip() { echo -e "  ${DIM}─ skipped: $1${RESET}"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $1"; }
err()  { echo -e "  ${RED}✗${RESET} $1"; }
info() { echo -e "    ${DIM}$1${RESET}"; }

# ── precheck ─────────────────────────────────────────────────────────
if [[ "$(uname -m)" != "arm64" ]]; then
  err "Apple Silicon (M1/M2/M3/M4) only."; exit 1
fi

# ── helpers ──────────────────────────────────────────────────────────
brew_install() {
  if brew list --formula "$1" &>/dev/null; then skip "$1"
  else step "installing $1"; brew install "$1" && ok "$1"; fi
}
cask_install() {
  if brew list --cask "$1" &>/dev/null; then skip "$1"
  else step "installing $1"; brew install --cask "$1" && ok "$1"; fi
}

# ════════════════════════════════════════════════════════════════════
# 01 · Foundation — Xcode CLT + Homebrew
# ════════════════════════════════════════════════════════════════════
hdr "01 · Foundation"

if ! xcode-select -p &>/dev/null; then
  step "installing Xcode Command Line Tools"
  xcode-select --install
  info "click Install in the dialog, then re-run this script"
  exit 0
else
  ok "Xcode CLT ready"
fi

if ! command -v brew &>/dev/null; then
  step "installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"
brew update &>/dev/null

# ════════════════════════════════════════════════════════════════════
# 02 · CLI tools + font + Starship
# ════════════════════════════════════════════════════════════════════
hdr "02 · CLI & Shell"

for t in git gh ripgrep fd bat eza fzf zoxide jq tldr starship mas; do
  brew_install "$t"
done
cask_install font-jetbrains-mono-nerd-font

# ════════════════════════════════════════════════════════════════════
# 03 · Node — fnm + Node LTS + pnpm
# ════════════════════════════════════════════════════════════════════
hdr "03 · Node + pnpm"

brew_install fnm
eval "$(fnm env --use-on-cd)"

if ! fnm list 2>/dev/null | grep -q lts-latest; then
  step "installing Node LTS"
  fnm install --lts
  fnm default lts-latest
  ok "Node $(node -v 2>/dev/null)"
else
  ok "Node $(node -v 2>/dev/null) already installed"
fi

if ! command -v pnpm &>/dev/null; then
  step "installing pnpm"
  npm install -g pnpm && ok "pnpm $(pnpm --version)"
else
  ok "pnpm $(pnpm --version) already installed"
fi

# ════════════════════════════════════════════════════════════════════
# 04 · Git + GitHub
# ════════════════════════════════════════════════════════════════════
hdr "04 · Git + GitHub"

if [[ -z "$(git config --global user.name)" ]]; then
  echo -n "  git user name: "; read gname
  git config --global user.name "$gname"
fi
if [[ -z "$(git config --global user.email)" ]]; then
  echo -n "  git email: "; read gemail
  git config --global user.email "$gemail"
fi
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor "cursor --wait"
ok "git configured for $(git config --global user.name) <$(git config --global user.email)>"

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  step "generating ed25519 SSH key"
  ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$HOME/.ssh/id_ed25519" -N ""
  pbcopy < "$HOME/.ssh/id_ed25519.pub"
  ok "SSH pubkey copied to clipboard"
  info "paste it at https://github.com/settings/keys, then re-run this script"
else
  ok "SSH key exists"
fi

if command -v gh &>/dev/null && ! gh auth status &>/dev/null; then
  info "run: gh auth login (when you're ready)"
fi

# ════════════════════════════════════════════════════════════════════
# 05 · Editors — Cursor + VS Code
# ════════════════════════════════════════════════════════════════════
hdr "05 · Editors"

cask_install cursor
cask_install visual-studio-code
info "both editors share VS Code extensions and keybindings"

# ════════════════════════════════════════════════════════════════════
# 06 · Terminal — iTerm2
# ════════════════════════════════════════════════════════════════════
hdr "06 · Terminal"

cask_install iterm2

# ════════════════════════════════════════════════════════════════════
# 07 · AI Tools — Claude Desktop + Claude Code + ChatGPT (desktop only)
# ════════════════════════════════════════════════════════════════════
hdr "07 · AI Tools"

cask_install claude        # Claude Desktop (GUI, MCP-capable)
cask_install claude-code   # Claude Code (terminal coding agent)
cask_install chatgpt       # ChatGPT Desktop GUI (Option+Space hotkey)
info "after install:"
info "  claude doctor          (verify Claude Code)"
info "  cd into a project → run 'claude' to start a session"
info ""
info "Claude Code needs a paid Claude account (Pro / Max) or API key"
info "ChatGPT desktop: free-tier sign-in works (Codex CLI NOT installed)"

# ════════════════════════════════════════════════════════════════════
# 08 · Mobile Dev (Expo path, no native SDKs)
# ════════════════════════════════════════════════════════════════════
hdr "08 · Mobile (Expo)"

brew_install watchman
cask_install android-platform-tools
info "test android device:  adb devices"
info "iOS: install Expo Go from the App Store"

# ════════════════════════════════════════════════════════════════════
# 09 · Databases — PostgreSQL + MySQL
# ════════════════════════════════════════════════════════════════════
hdr "09 · Databases"

# PostgreSQL (latest stable on Homebrew at script time — postgresql@17)
brew_install postgresql@17
if ! brew services info postgresql@17 2>/dev/null | grep -q "Running: true"; then
  step "starting postgresql"
  brew services start postgresql@17 &>/dev/null && ok "postgres running"
else
  ok "postgres already running"
fi

# MySQL
brew_install mysql
info "first-time MySQL: mysql_secure_installation"

info ""
info "Postgres aliases:  pgup · pgdown · pgstatus · psqlroot"
info "MySQL aliases:     mysqlup · mysqldown · mysqlstatus · mysqlroot"
info "Prisma + Postgres in a project:"
info "  pnpm add -D prisma && npx prisma init --datasource-provider postgresql"

# ════════════════════════════════════════════════════════════════════
# 10 · Database GUI + API client
# ════════════════════════════════════════════════════════════════════
hdr "10 · DB GUI + API client"

cask_install beekeeper-studio
cask_install bruno
info "Beekeeper: Postgres + MySQL GUI · Bruno: git-versioned API client"

# ════════════════════════════════════════════════════════════════════
# 11 · Deploy CLIs — Vercel · Wrangler · EAS · Firebase
# ════════════════════════════════════════════════════════════════════
hdr "11 · Deploy CLIs"

for p in vercel wrangler eas-cli; do
  if npm list -g --depth=0 2>/dev/null | grep -q " $p@"; then skip "$p"
  else step "installing $p"; npm install -g "$p" && ok "$p"; fi
done
brew_install firebase-cli

info "logins:  vercel login · wrangler login · eas login · firebase login"

# ════════════════════════════════════════════════════════════════════
# 12 · Design — Figma
# ════════════════════════════════════════════════════════════════════
hdr "12 · Design"

cask_install figma

# ════════════════════════════════════════════════════════════════════
# 13 · Notes + Research — Notion + Obsidian + Zotero
# ════════════════════════════════════════════════════════════════════
hdr "13 · Notes + Research"

cask_install notion
cask_install obsidian
cask_install zotero
info "Notion → primary notes / exam study"
info "Obsidian → local markdown vault (offline backup of key notes)"
info "Zotero → citation manager. Browser connector: https://www.zotero.org/download/connectors"

# ════════════════════════════════════════════════════════════════════
# 14 · Productivity — Raycast + OrbStack + Arc
# ════════════════════════════════════════════════════════════════════
hdr "14 · Productivity"

cask_install raycast    # Cmd+Space launcher (replaces Spotlight)
cask_install orbstack   # lightweight Docker / Linux VM
cask_install arc        # browser

info "Raycast → clipboard history, snippets, window mgmt, app launcher"
info "OrbStack → use instead of Docker Desktop (lighter on 8GB RAM)"
info "Arc → primary browser (in maintenance mode but still patched)"

# ════════════════════════════════════════════════════════════════════
# 15 · Media — Discord + Spotify + Spicetify + Stremio
# ════════════════════════════════════════════════════════════════════
hdr "15 · Media"

cask_install discord
cask_install spotify
cask_install stremio

# Spicetify — official curl installer (brew formula was deprecated upstream)
if ! command -v spicetify &>/dev/null; then
  step "installing spicetify (official installer)"
  curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh \
    && ok "spicetify installed" \
    || warn "spicetify install failed — re-run section 15"
else
  ok "spicetify already installed"
fi

info "Spotify: launch ONCE so it builds its data folder, then quit it"
info "         before running:  spicetify backup apply"
info "         (auto-updates wipe themes; re-run after each Spotify update)"

# ════════════════════════════════════════════════════════════════════
# 16 · Docs + Cloud Drives
# ════════════════════════════════════════════════════════════════════
hdr "16 · Docs + Cloud Drives"

# MS Word for academic reports
cask_install microsoft-word

# Apple iWork via mas (Mac App Store CLI installed in section 02)
if ! mas account &>/dev/null; then
  warn "Not signed in to the Mac App Store."
  info "Open the App Store app, sign in, then re-run section 16."
else
  for app in "Pages:409201541" "Keynote:409183694" "Numbers:409203825"; do
    name="${app%%:*}"; id="${app##*:}"
    if mas list 2>/dev/null | grep -q "^$id "; then
      skip "$name (already installed)"
    else
      step "installing $name from App Store"
      mas install "$id" && ok "$name installed" || warn "$name failed"
    fi
  done
fi

# Cloud drives
cask_install onedrive
cask_install google-drive

info "Word: trial unless you sign in with M365 (your school may provide it free)"
info "Pages / Keynote / Numbers: free with Apple ID"
info "OneDrive + Google Drive: avoid syncing ~/Developer (node_modules will burn data)"

# ════════════════════════════════════════════════════════════════════
# 17 · Folders
# ════════════════════════════════════════════════════════════════════
hdr "17 · Folders"

mkdir -p "$HOME/Developer" "$HOME/University"
ok "~/Developer and ~/University ready"

# ════════════════════════════════════════════════════════════════════
# 18 · Shell config — Starship + aliases
# ════════════════════════════════════════════════════════════════════
hdr "18 · Shell Config (.zshrc)"

# Starship minimal config
mkdir -p "$HOME/.config"
if [[ ! -f "$HOME/.config/starship.toml" ]]; then
  cat > "$HOME/.config/starship.toml" << 'STARSHIP'
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
STARSHIP
  ok "starship config written"
fi

# Append .zshrc block (idempotent)
if grep -q "# === V2 SETUP ===" "$HOME/.zshrc" 2>/dev/null; then
  skip ".zshrc block already present"
else
  cat >> "$HOME/.zshrc" << 'ZSHRC'

# === V2 SETUP ===

# ── Tool init ────────────────────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(fnm env --use-on-cd)"
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)" 2>/dev/null
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export PATH="$PATH:$HOME/.spicetify"

# ── History ──────────────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS SHARE_HISTORY

# ── Navigation ───────────────────────────────────────────────────────
alias dev="cd ~/Developer"
alias uni="cd ~/University"
alias ..="cd .."
alias ...="cd ../.."

# ── Better defaults ──────────────────────────────────────────────────
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias cat="bat"
alias find="fd"

# ── pnpm (Next.js / Express / Node) ──────────────────────────────────
alias pn="pnpm"
alias pni="pnpm install"
alias pnid="pnpm add -D"
alias pnr="pnpm run"
alias pnd="pnpm dev"
alias pnb="pnpm build"
alias pns="pnpm start"
alias pnt="pnpm test"

# ── Prisma ───────────────────────────────────────────────────────────
alias px="npx prisma"
alias pxg="npx prisma generate"
alias pxm="npx prisma migrate dev"
alias pxs="npx prisma studio"

# ── Expo (React Native) ──────────────────────────────────────────────
alias exs="pnpm expo start"
alias exa="pnpm expo start --android"
alias exi="pnpm expo start --ios"
alias exb="eas build --platform all"

# ── Firebase ─────────────────────────────────────────────────────────
alias fbd="firebase deploy"
alias fbe="firebase emulators:start"
alias fbl="firebase login"

# ── PostgreSQL ───────────────────────────────────────────────────────
alias pgup="brew services start postgresql@17"
alias pgdown="brew services stop postgresql@17"
alias pgstatus="brew services info postgresql@17"
alias psqlroot="psql postgres"

# ── MySQL ────────────────────────────────────────────────────────────
alias mysqlup="mysql.server start"
alias mysqldown="mysql.server stop"
alias mysqlstatus="mysql.server status"
alias mysqlroot="mysql -u root -p"

# ── Git (simple) ─────────────────────────────────────────────────────
alias gs="git status"
alias gco="git checkout"
alias gp="git push"
alias gl="git pull"
alias gb="git branch"
alias gd="git diff"
alias glog="git log --oneline --decorate -20"

# ── System ───────────────────────────────────────────────────────────
alias ip="ipconfig getifaddr en0"
alias ports="lsof -i -P | grep LISTEN"
alias memcheck="memory_pressure | head -3"
alias zconf="cursor ~/.zshrc"
alias zreload="source ~/.zshrc && echo '✓ reloaded'"
alias cleanup="rm -rf ~/Library/Developer/Xcode/DerivedData/* && npm cache clean --force && pnpm store prune && brew cleanup && echo '✓ cleaned'"

# ── Functions ────────────────────────────────────────────────────────

# add + commit + push current branch.   usage: gcp "message"
gcp() {
  git add . && git commit -m "${1:-update}" && git push origin "$(git branch --show-current)"
}

# undo last commit, keep changes staged
gundo() {
  git reset --soft HEAD~1 && echo "✓ undone; changes staged"
}

# pull origin/main into current branch
gsync() {
  git fetch origin main && git merge origin/main
}

# ── Git branch manager (interactive) ─────────────────────────────────

_current_branch() {
  git branch --show-current 2>/dev/null
}

_validate_branch_name() {
  [[ $1 =~ ^[a-zA-Z0-9._/-]+$ ]] || {
    echo "  \033[0;31m✗ Invalid branch name. Use alphanumeric, - _ / .\033[0m"
    return 1
  }
}

# interactive branch manager.   usage: git-branch
git-branch() {
  local branch=$(_current_branch)
  echo "  \033[1;37m📋 BRANCH MANAGER\033[0m  \033[0;90m(current: $branch)\033[0m"
  echo ""
  git branch -a | sed 's/^/  /'
  echo ""
  echo "  \033[0;36m[1]\033[0m Switch   \033[0;36m[2]\033[0m Create   \033[0;36m[3]\033[0m Delete   \033[0;36m[4]\033[0m Rename   \033[0;36m[5]\033[0m Cancel"
  echo ""
  echo -n "  \033[1;37mOption: \033[0m"; read opt

  case $opt in
    1)
      echo -n "  Branch name: "; read b
      [[ -z "$b" ]] && echo "  \033[0;31m✗ Empty\033[0m" && return 1
      git checkout "$b" 2>/dev/null \
        && echo "  \033[0;32m✓ Switched to $b\033[0m" \
        || echo "  \033[0;31m✗ Branch not found\033[0m" ;;
    2)
      echo -n "  New branch name: "; read b
      [[ -z "$b" ]] && echo "  \033[0;31m✗ Empty\033[0m" && return 1
      _validate_branch_name "$b" || return 1
      git checkout -b "$b" && echo "  \033[0;32m✓ Created & switched to $b\033[0m" ;;
    3)
      echo -n "  Branch to delete: "; read b
      [[ -z "$b" ]] && echo "  \033[0;31m✗ Empty\033[0m" && return 1
      echo -n "  \033[0;33mSure? (y/n): \033[0m"; read c
      if [[ $c == "y" ]]; then
        git branch -d "$b" 2>/dev/null \
          && echo "  \033[0;32m✓ Deleted $b\033[0m" \
          || {
            echo -n "  \033[0;33mForce delete? (y/n): \033[0m"; read fc
            [[ $fc == "y" ]] && git branch -D "$b" && echo "  \033[0;32m✓ Force deleted $b\033[0m"
          }
      else
        echo "  \033[0;33m⊘ Cancelled\033[0m"
      fi ;;
    4)
      echo -n "  New name for '$branch': "; read b
      [[ -z "$b" ]] && echo "  \033[0;31m✗ Empty\033[0m" && return 1
      _validate_branch_name "$b" || return 1
      git branch -m "$branch" "$b" && echo "  \033[0;32m✓ Renamed → $b\033[0m" ;;
    5) echo "  \033[0;33m⊘ Cancelled\033[0m" ;;
    *) echo "  \033[0;31m✗ Invalid option\033[0m" ;;
  esac
  echo ""
}

# quick local HTTP server (default 3000)
serve() {
  local port="${1:-3000}"
  echo "→ http://localhost:$port"
  python3 -m http.server "$port"
}

# show local + public IP
myip() {
  echo "local : $(ipconfig getifaddr en0 2>/dev/null || echo 'n/a')"
  echo "public: $(curl -s https://api.ipify.org)"
}

# mkdir + cd
mkcd() { mkdir -p "$1" && cd "$1"; }

# kill process on a port.   usage: port 3000
port() {
  [[ -z "$1" ]] && { echo "usage: port <number>"; return 1; }
  local pid=$(lsof -ti :"$1")
  [[ -z "$pid" ]] && { echo "nothing on port $1"; return; }
  kill -9 "$pid" && echo "✓ killed PID $pid on port $1"
}

# === END V2 SETUP ===
ZSHRC
  ok ".zshrc block appended"
fi

# ════════════════════════════════════════════════════════════════════
# 19 · Cleanup
# ════════════════════════════════════════════════════════════════════
hdr "19 · Cleanup"

brew cleanup -s &>/dev/null && ok "brew cleaned"
npm cache clean --force &>/dev/null 2>&1 && ok "npm cache cleared"
command -v pnpm &>/dev/null && pnpm store prune &>/dev/null && ok "pnpm store pruned"

echo ""
echo -e "${GREEN}${BOLD}━━ all done ━━${RESET}"
echo ""
info "next steps:"
info "  1. restart terminal (or: source ~/.zshrc)"
info "  2. gh auth login"
info "  3. vercel login · wrangler login · eas login · firebase login"
info "  4. claude doctor  (verify Claude Code)"
info "  5. createdb \$USER          # so 'psql' works without args"
info "  6. mysql_secure_installation"
info "  7. sign in: Cursor · VS Code · Notion · Obsidian · MS Word · OneDrive · Google Drive"
info "  8. launch Spotify once, quit, then: spicetify backup apply"
info "  9. test Expo: pnpm dlx create-expo-app demo && cd demo && exs"
echo ""
