# ╔══════════════════════════════════════════════════════════════════╗
# ║          ~/.zshrc — v2 (reference)                               ║
# ║  Web (Next/Express/Node/Firebase/TS) + Mobile (Expo/Firebase)    ║
# ║  Prisma + PostgreSQL · MySQL · Notion · MS Word · iWork          ║
# ╚══════════════════════════════════════════════════════════════════╝

# ── Tool init ────────────────────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"   # Homebrew (Apple Silicon)
eval "$(fnm env --use-on-cd)"               # Node version manager
eval "$(starship init zsh)"                 # Prompt
eval "$(zoxide init zsh)"                   # Smarter cd
eval "$(fzf --zsh)" 2>/dev/null             # Fuzzy finder
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export PATH="$PATH:$HOME/.spicetify"        # spicetify CLI

# ── History ──────────────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS SHARE_HISTORY

# ══════════════════════════════════════════════════════════════════════
# ALIASES
# ══════════════════════════════════════════════════════════════════════

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
alias pnd="pnpm dev"        # next dev / generic dev
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

# ══════════════════════════════════════════════════════════════════════
# FUNCTIONS
# ══════════════════════════════════════════════════════════════════════

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

# quick local HTTP server.   usage: serve [port]   (default 3000)
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
