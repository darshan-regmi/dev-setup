#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║                    Engineering Workstation Setup                 ║
# ║              Minimal · Intentional · Production-Ready            ║
# ╚══════════════════════════════════════════════════════════════════╝
# Usage: chmod +x setup.sh && ./setup.sh

setopt PIPE_FAIL

# ─────────────────────────────────────────────────
# COLORS & STYLES
# ─────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

BG_BLUE="\033[44m"

# ─────────────────────────────────────────────────
# LOGGING HELPERS
# ─────────────────────────────────────────────────
log_header()  { echo ""; echo -e "${BG_BLUE}${WHITE}${BOLD}  $1  ${RESET}"; echo -e "${DIM}──────────────────────────────────────────────${RESET}"; }
log_step()    { echo -e "${CYAN}${BOLD}  ➜ ${RESET}${BOLD}$1${RESET}"; }
log_success() { echo -e "${GREEN}  ✔ $1${RESET}"; }
log_warn()    { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
log_error()   { echo -e "${RED}  ✖ $1${RESET}"; }
log_info()    { echo -e "${DIM}    $1${RESET}"; }
log_skip()    { echo -e "${DIM}  ─ Skipped: $1${RESET}"; }

ask() {
  local varname="$1" prompt="$2" default="$3"
  echo -ne "${MAGENTA}  ? ${RESET}${BOLD}$prompt${RESET} ${DIM}[$default]${RESET}: "
  read -r input
  eval "$varname=\"${input:-$default}\""
}

confirm() {
  echo -ne "${MAGENTA}  ? ${RESET}${BOLD}$1${RESET} ${DIM}[Y/n]${RESET}: "
  read -r answer
  case "${answer:=Y}" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

pause() {
  echo ""
  echo -ne "${DIM}  Press [Enter] to continue...${RESET}"
  read -r
}

spinner() {
  local pid=$1 msg=$2
  local spinchars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    echo -ne "\r${CYAN}  ${spinchars[$((i % ${#spinchars[@]}))]} ${RESET}${DIM}$msg...${RESET}"
    sleep 0.1
    ((i++))
  done
  echo -ne "\r"
}

run_quiet() {
  local msg="$1"; shift
  "$@" &>/dev/null &
  local pid=$!
  spinner "$pid" "$msg"
  wait "$pid"
  local status=$?
  if [ $status -eq 0 ]; then log_success "$msg"
  else log_error "Failed: $msg"; return $status; fi
}

section_done() {
  echo ""
  echo -e "${GREEN}${BOLD}  ✔ Section complete${RESET}"
  echo ""
}

# ─────────────────────────────────────────────────
# STATE TRACKING
# ─────────────────────────────────────────────────
STATE_FILE="$HOME/.devsetup_state"
touch "$STATE_FILE"
mark_done() { echo "$1" >> "$STATE_FILE"; }
is_done()   { grep -qx "$1" "$STATE_FILE" 2>/dev/null; }

# ─────────────────────────────────────────────────
# PREFLIGHT
# ─────────────────────────────────────────────────
preflight() {
  log_header "Pre-flight Checks"

  local arch; arch=$(uname -m)
  if [[ "$arch" == "arm64" ]]; then
    log_success "Apple Silicon (arm64) confirmed"
  else
    log_error "Requires Apple Silicon (arm64). Detected: $arch"
    exit 1
  fi

  local macos; macos=$(sw_vers -productVersion)
  log_info "macOS $macos"

  local free_gb; free_gb=$(df -g / | awk 'NR==2 {print $4}')
  if (( free_gb < 30 )); then
    log_warn "Low disk space: ${free_gb}GB free. Recommended: 30GB+"
  else
    log_success "Disk space: ${free_gb}GB free"
  fi

  local ram_gb; ram_gb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
  log_success "RAM: ${ram_gb}GB detected"

  if xcode-select -p &>/dev/null; then
    log_success "Xcode CLI tools installed"
  else
    log_step "Installing Xcode CLI tools..."
    xcode-select --install
    log_warn "Complete the install dialog, then re-run this script."
    exit 0
  fi

  section_done
}

# ─────────────────────────────────────────────────
# WELCOME SCREEN
# ─────────────────────────────────────────────────
welcome() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}"
  echo "  ╔══════════════════════════════════════════════════════════╗"
  echo "  ║                                                          ║"
  echo "  ║             Engineering Workstation Setup                ║"
  echo "  ║        Minimal · Intentional · Production-Ready          ║"
  echo "  ║                                                          ║"
  echo "  ╚══════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "${DIM}  Fully interactive — choose exactly what to install."
  echo -e "  Completed steps are saved and never repeated.${RESET}"
  echo ""
  echo -e "${YELLOW}  ⚠  Estimated time: 20–45 min depending on internet speed${RESET}"
  echo -e "${YELLOW}  ⚠  Keep your laptop plugged in during setup${RESET}"
  echo ""

  confirm "Ready to begin?" || exit 0

  echo ""
  log_header "Your Details"
  ask GIT_NAME  "Full name (for Git config)" "$(id -F 2>/dev/null || echo 'Dev')"
  ask GIT_EMAIL "Email address (for Git + SSH)" ""
  ask GH_USER   "GitHub username" ""

  echo ""
  log_success "Got it. Let's build your workstation."
  pause
}

# ─────────────────────────────────────────────────
# MENU
# ─────────────────────────────────────────────────
show_menu() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}  Installation Menu${RESET}"
  echo -e "${DIM}  ✔ = done  ○ = pending  |  [A] All  [Q] Quit  [01-16] Jump${RESET}"
  echo ""

  local sections=(
    "homebrew"  "01 · Homebrew + Core CLI Tools (incl. tmux)"
    "zsh"       "02 · Zsh + Oh My Zsh + iTerm2"
    "node"      "03 · NVM + Node LTS + Global Packages"
    "python"    "04 · Python — Anaconda or Miniforge + AI Libs"
    "webdev"    "05 · Web Dev Stack (Firebase, Hardhat)"
    "mongodb"   "06 · MongoDB (manual-start only)"
    "docker"    "07 · Docker (2GB RAM cap)"
    "ollama"    "08 · Ollama + Lightweight LLM Models"
    "mobile"    "09 · Mobile Dev (Flutter, React Native)"
    "editors"   "10 · Cursor + VS Code"
    "apps"      "11 · Productivity Apps"
    "git"       "12 · Git + GitHub + SSH"
    "folders"   "13 · Developer Folder Structure"
    "zshrc"     "14 · Write ~/.zshrc (all aliases + tools)"
    "starship"  "15 · Starship Prompt Config"
    "cleanup"   "16 · Brew Cleanup + System Tidy"
  )

  for (( i=0; i<${#sections[@]}; i+=2 )); do
    local key="${sections[$i]}" label="${sections[$((i+1))]}"
    if is_done "$key"; then
      echo -e "  ${GREEN}✔${RESET} ${DIM}$label${RESET}"
    else
      echo -e "  ${CYAN}○${RESET} $label"
    fi
  done

  echo ""
  echo -ne "${MAGENTA}  ? ${RESET}${BOLD}Choice${RESET}: "
  read -r MENU_CHOICE
}

# ─────────────────────────────────────────────────
# 01 · HOMEBREW + CORE CLI
# ─────────────────────────────────────────────────
install_homebrew() {
  log_header "01 · Homebrew + Core CLI Tools"
  is_done "homebrew" && { log_skip "Already configured"; return; }

  if command -v brew &>/dev/null; then
    log_success "Homebrew already installed"
  else
    log_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Write to zprofile so brew is available in login shells too
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  fi

  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  log_success "Homebrew at /opt/homebrew (ARM-native)"

  run_quiet "Updating Homebrew" brew update

  log_step "Installing core CLI tools..."
  local tools=(
    git gh wget curl jq tree
    htop bat eza fd ripgrep
    fzf zoxide starship
    tmux tldr
  )

  for tool in "${tools[@]}"; do
    if brew list "$tool" &>/dev/null; then
      log_info "  $tool — already installed"
    else
      run_quiet "  Installing $tool" brew install "$tool"
    fi
  done

  if ! brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
    run_quiet "  Installing JetBrains Mono Nerd Font" brew install --cask font-jetbrains-mono-nerd-font
  else
    log_info "  JetBrains Mono NF — already installed"
  fi

  "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish &>/dev/null || true

  # brew cleanup — run after every install block
  run_quiet "Running brew cleanup" brew cleanup

  mark_done "homebrew"
  section_done
}

# ─────────────────────────────────────────────────
# 02 · ZSH + iTERM2
# ─────────────────────────────────────────────────
install_zsh() {
  log_header "02 · Zsh + Oh My Zsh + iTerm2"
  is_done "zsh" && { log_skip "Already configured"; return; }

  if ! brew list --cask iterm2 &>/dev/null; then
    run_quiet "Installing iTerm2" brew install --cask iterm2
  else
    log_success "iTerm2 already installed"
  fi

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_success "Oh My Zsh already installed"
  else
    log_step "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &>/dev/null
    log_success "Oh My Zsh installed"
  fi

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  local plugins=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
    "zsh-completions|https://github.com/zsh-users/zsh-completions"
  )

  for entry in "${plugins[@]}"; do
    local name="${entry%%|*}" url="${entry##*|}"
    if [[ -d "$ZSH_CUSTOM/plugins/$name" ]]; then
      log_info "  $name — already installed"
    else
      run_quiet "  Installing $name" git clone "$url" "$ZSH_CUSTOM/plugins/$name"
    fi
  done

  mark_done "zsh"
  section_done
}

# ─────────────────────────────────────────────────
# 03 · NVM + NODE
# ─────────────────────────────────────────────────
install_node() {
  log_header "03 · NVM + Node LTS"
  is_done "node" && { log_skip "Already configured"; return; }

  if [[ -d "$HOME/.nvm" ]]; then
    log_success "NVM already installed"
  else
    log_step "Installing NVM via curl (preferred over brew nvm)..."
    mkdir -p "$HOME/.nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash &>/dev/null
    log_success "NVM installed"
  fi

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  if nvm ls --no-colors 2>/dev/null | grep -q "lts/"; then
    log_success "Node LTS already installed: $(node -v 2>/dev/null)"
  else
    log_step "Installing Node LTS (ARM-native)..."
    nvm install --lts &>/dev/null
    log_success "Node LTS: $(node -v)"
  fi

  nvm use --lts &>/dev/null
  nvm alias default node &>/dev/null

  log_step "Installing global npm packages..."
  local globals=(pnpm yarn typescript ts-node firebase-tools)
  for pkg in "${globals[@]}"; do
    if npm list -g "$pkg" &>/dev/null; then
      log_info "  $pkg — already installed"
    else
      run_quiet "  Installing $pkg" npm install -g "$pkg"
    fi
  done

  mark_done "node"
  section_done
}

# ─────────────────────────────────────────────────
# 04 · PYTHON + CONDA
# ─────────────────────────────────────────────────
install_python() {
  log_header "04 · Python 3.12 + Conda AI Environment"
  is_done "python" && { log_skip "Already configured"; return; }

  # ── Standalone Python 3.12 via brew ──
  # Useful for scripts and lightweight tools without the full conda overhead
  if brew list python &>/dev/null; then
    log_success "Python (brew) already installed"
  else
    if confirm "Install Python via Homebrew (lightweight, for scripts/tools)?"; then
      run_quiet "Installing python latest version" brew install python
    fi
  fi

  # ── Conda distribution choice ──
  if command -v conda &>/dev/null; then
    log_success "Conda already installed: $(conda --version)"
  else
    echo ""
    echo -e "${DIM}  Choose a Conda distribution for the AI/ML environment:${RESET}"
    echo -e "  ${CYAN}[1]${RESET} Anaconda   — Full-featured, ~3GB install"
    echo -e "  ${CYAN}[2]${RESET} Miniforge  — Lightweight ARM-native, ~200MB ${GREEN}← recommended${RESET}"
    echo -e "  ${CYAN}[s]${RESET} Skip"
    echo ""
    echo -ne "${MAGENTA}  ? ${RESET}${BOLD}Choice${RESET} ${DIM}[2]${RESET}: "
    read -r conda_choice

    case "${conda_choice:-2}" in
      1)
        log_step "Installing Anaconda (full, ~3GB)..."
        run_quiet "Installing Anaconda" brew install anaconda
        log_success "Anaconda installed — includes many pre-built ML packages"
        ;;
      2)
        log_step "Installing Miniforge (ARM-native, community conda)..."
        run_quiet "Installing Miniforge" brew install --cask miniforge
        log_success "Miniforge installed — smaller and fully ARM-native"
        ;;
      s|S)
        log_skip "Conda"
        return
        ;;
    esac
  fi

  if command -v conda &>/dev/null; then
    conda init zsh &>/dev/null || true
    run_quiet "Updating conda base" conda update -n base conda --yes
  fi

  # ── Create and populate AI environment ──
  if conda env list 2>/dev/null | grep -q "^ai "; then
    log_success "Conda 'ai' environment already exists"
  else
    log_step "Creating conda 'ai' environment (Python 3.12)..."
    conda create -n ai python=3.12 -y &>/dev/null
    log_success "Environment 'ai' created"
  fi

  log_step "Installing AI/ML libraries into 'ai' environment..."
  log_info "This may take 5–15 minutes on first run..."

  local ai_packages=(
    "torch torchvision torchaudio"
    "tensorflow-metal tensorflow-macos"
    "transformers datasets accelerate"
    "langchain langchain-community langchain-openai"
    "openai anthropic"
    "jupyterlab notebook ipywidgets"
    "pandas numpy scipy matplotlib seaborn scikit-learn"
    "huggingface_hub python-dotenv"
  )

  for pkg_group in "${ai_packages[@]}"; do
    run_quiet "  Installing $pkg_group" conda run -n ai pip install $pkg_group
  done

  log_step "Verifying PyTorch Metal (MPS) backend..."
  local mps_check
  mps_check=$(conda run -n ai python3 -c "
import torch
print('MPS available:', torch.backends.mps.is_available())
print('MPS built:    ', torch.backends.mps.is_built())
" 2>&1)
  echo -e "${DIM}$mps_check${RESET}"

  mark_done "python"
  section_done
}

# ─────────────────────────────────────────────────
# 05 · WEB DEV STACK
# ─────────────────────────────────────────────────
install_webdev() {
  log_header "05 · Web Dev Stack (Firebase, Hardhat)"
  is_done "webdev" && { log_skip "Already configured"; return; }

  if command -v firebase &>/dev/null; then
    log_success "Firebase CLI: $(firebase --version)"
  else
    run_quiet "Installing Firebase CLI" npm install -g firebase-tools
  fi

  local hh_dir="$HOME/Developer/blockchain/hardhat-starter"
  if [[ -d "$hh_dir" ]]; then
    log_info "  Hardhat starter already exists"
  else
    mkdir -p "$hh_dir" && cd "$hh_dir"
    npm init -y &>/dev/null
    run_quiet "  Installing Hardhat" npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
    log_success "  Hardhat starter → ~/Developer/blockchain/hardhat-starter"
    cd - &>/dev/null
  fi

  mark_done "webdev"
  section_done
}

# ─────────────────────────────────────────────────
# 06 · MONGODB
# ─────────────────────────────────────────────────
install_mongodb() {
  log_header "06 · MongoDB (Manual-Only Policy)"
  is_done "mongodb" && { log_skip "Already installed"; return; }

  if brew list mongodb-community &>/dev/null; then
    log_success "MongoDB Community already installed"
  else
    brew tap mongodb/brew &>/dev/null
    run_quiet "Installing MongoDB Community" brew install mongodb-community
  fi

  # Explicitly prevent auto-start (critical for 8GB RAM)
  brew services stop mongodb-community &>/dev/null || true
  log_success "MongoDB installed — NOT auto-started"
  log_info "  Use aliases: 'mongoup' to start, 'stop-mongo' to kill"

  mkdir -p "$HOME/Developer/.data/mongodb"
  log_success "Data dir: ~/Developer/.data/mongodb"

  confirm "Install MongoDB Compass (GUI)?" && \
    run_quiet "Installing MongoDB Compass" brew install --cask mongodb-compass

  mark_done "mongodb"
  section_done
}

# ─────────────────────────────────────────────────
# 07 · DOCKER
# ─────────────────────────────────────────────────
install_docker() {
  log_header "07 · Docker (2GB RAM Limit)"
  is_done "docker" && { log_skip "Already installed"; return; }

  if brew list --cask docker &>/dev/null; then
    log_success "Docker Desktop already installed"
  else
    run_quiet "Installing Docker Desktop" brew install --cask docker
  fi

  echo ""
  echo -e "${YELLOW}  ⚠  IMPORTANT — After Docker opens, go to:${RESET}"
  echo -e "     ${BOLD}Settings → Resources${RESET} and set:"
  echo -e "     Memory: ${BOLD}2 GB${RESET}  |  CPUs: ${BOLD}4${RESET}  |  Swap: ${BOLD}512 MB${RESET}  |  Disk: ${BOLD}32 GB${RESET}"
  echo ""
  confirm "Open Docker Desktop now to configure memory?" && open -a Docker

  mark_done "docker"
  section_done
}

# ─────────────────────────────────────────────────
# 08 · OLLAMA
# ─────────────────────────────────────────────────
install_ollama() {
  log_header "08 · Ollama + Lightweight LLM Models"
  is_done "ollama" && { log_skip "Already configured"; return; }

  if command -v ollama &>/dev/null; then
    log_success "Ollama already installed: $(ollama --version 2>/dev/null)"
  else
    run_quiet "Installing Ollama" brew install ollama
  fi

  echo ""
  echo -e "${DIM}  Models — all safe for 8GB RAM:${RESET}"
  echo -e "  ${CYAN}[1]${RESET} phi3:mini           2.3GB  Best daily driver (reasoning + chat)"
  echo -e "  ${CYAN}[2]${RESET} tinyllama            0.6GB  Ultra-fast prototyping"
  echo -e "  ${CYAN}[3]${RESET} nomic-embed-text     0.3GB  Embeddings / RAG pipelines"
  echo -e "  ${CYAN}[4]${RESET} deepseek-coder:1.3b  0.8GB  Lightweight code assistant"
  echo -e "  ${CYAN}[5]${RESET} codellama:7b         4.8GB  Full code model (run alone only)"
  echo -e "  ${CYAN}[6]${RESET} All of the above"
  echo -e "  ${CYAN}[s]${RESET} Skip"
  echo ""
  echo -ne "${MAGENTA}  ? ${RESET}${BOLD}Which models to pull?${RESET} ${DIM}[1]${RESET}: "
  read -r model_choice

  log_info "Starting Ollama server temporarily for download..."
  ollama serve &>/dev/null &
  OLLAMA_PID=$!
  sleep 3

  pull_model() {
    log_step "Pulling $1..."
    ollama pull "$1" && log_success "$1 ready" || log_error "Failed: $1"
  }

  case "${model_choice:-1}" in
    1) pull_model "phi3:mini" ;;
    2) pull_model "tinyllama" ;;
    3) pull_model "nomic-embed-text" ;;
    4) pull_model "deepseek-coder:1.3b" ;;
    5) pull_model "codellama:7b" ;;
    6)
      pull_model "phi3:mini"
      pull_model "tinyllama"
      pull_model "nomic-embed-text"
      pull_model "deepseek-coder:1.3b"
      pull_model "codellama:7b"
      ;;
    s|S) log_skip "Model download" ;;
    *)   pull_model "phi3:mini" ;;
  esac

  kill "$OLLAMA_PID" &>/dev/null || true
  log_info "Ollama stopped — use 'ollamaup' alias when you need it"

  mark_done "ollama"
  section_done
}

# ─────────────────────────────────────────────────
# 09 · MOBILE DEV
# ─────────────────────────────────────────────────
install_mobile() {
  log_header "09 · Mobile Dev (Flutter, React Native)"
  is_done "mobile" && { log_skip "Already configured"; return; }

  if brew list watchman &>/dev/null; then
    log_success "Watchman already installed"
  else
    run_quiet "Installing Watchman" brew install watchman
  fi

  if command -v flutter &>/dev/null; then
    log_success "Flutter: $(flutter --version 2>/dev/null | head -1)"
  else
    confirm "Install Flutter SDK?" && {
      run_quiet "Installing Flutter" brew install --cask flutter
      flutter doctor &>/dev/null || true
    }
  fi

  if brew list --cask android-studio &>/dev/null; then
    log_success "Android Studio already installed"
  else
    confirm "Install Android Studio? (~1.5GB)" && {
      run_quiet "Installing Android Studio" brew install --cask android-studio
      log_info "  → Open Android Studio → SDK Manager → Android 14 (API 34)"
    }
  fi

  confirm "Install React Native CLI?" && {
    run_quiet "Installing React Native CLI" npm install -g react-native-cli
  }

  log_info "Xcode: install via the Mac App Store for iOS development"

  mark_done "mobile"
  section_done
}

# ─────────────────────────────────────────────────
# 10 · EDITORS
# ─────────────────────────────────────────────────
install_editors() {
  log_header "10 · Cursor + VS Code +  Google Antigravity"
  is_done "editors" && { log_skip "Already installed"; return; }

  confirm "Install Cursor (primary AI-first editor)?" && {
    if ! brew list --cask cursor &>/dev/null; then
      run_quiet "Installing Cursor" brew install --cask cursor
    else
      log_success "Cursor already installed"
    fi
  }

  confirm "Install VS Code (fallback / pair sessions)?" && {
    if ! brew list --cask visual-studio-code &>/dev/null; then
      run_quiet "Installing VS Code" brew install --cask visual-studio-code
    else
      log_success "VS Code already installed"
    fi
  }

  confirm "Install  Google Antigravity (Secondary AI IDE)?" && {
    if ! brew list --cask antigravity &>/dev/null; then
      run_quiet "Installing Google Antigravity" brew install --cask antigravity
    else
      log_success "Google Antigravity already installed"
    fi
  } 

  if command -v code &>/dev/null && confirm "Install recommended VS Code extensions?"; then
    local extensions=(
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode
      bradlc.vscode-tailwindcss
      ms-python.python
      ms-toolsai.jupyter
      eamodio.gitlens
      formulahendry.auto-rename-tag
      pkief.material-icon-theme
      zhuangtongfa.material-theme
    )
    for ext in "${extensions[@]}"; do
      code --install-extension "$ext" &>/dev/null && log_info "  ✔ $ext" || log_warn "  Failed: $ext"
    done
  fi

  local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
  if [[ ! -f "$vscode_settings" ]] && command -v code &>/dev/null; then
    mkdir -p "$(dirname "$vscode_settings")"
    cat > "$vscode_settings" << 'SETTINGS'
{
  "editor.fontFamily": "JetBrains Mono, monospace",
  "editor.fontSize": 13,
  "editor.lineHeight": 1.6,
  "editor.tabSize": 2,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.minimap.enabled": false,
  "editor.wordWrap": "on",
  "editor.smoothScrolling": true,
  "editor.cursorBlinking": "smooth",
  "editor.renderWhitespace": "none",
  "workbench.colorTheme": "One Dark Pro",
  "workbench.iconTheme": "material-icon-theme",
  "workbench.startupEditor": "none",
  "workbench.activityBar.location": "hidden",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.fontFamily": "JetBrains Mono NF",
  "files.autoSave": "onFocusChange",
  "explorer.confirmDelete": false,
  "breadcrumbs.enabled": false
}
SETTINGS
    log_success "VS Code settings.json written"
  fi

  mark_done "editors"
  section_done
}

# ─────────────────────────────────────────────────
# 11 · PRODUCTIVITY APPS
# ─────────────────────────────────────────────────
install_apps() {
  log_header "11 · Productivity Apps"
  is_done "apps" && { log_skip "Already installed"; return; }

  local apps=(
    "notion|Notion — Project management"
    "spotify|Spotify — Music"
    "discord|Discord — Dev communities"
    "brave-browser|Brave — Privacy-first browser"
    "google-chrome|Chrome — DevTools / testing"
    "raycast|Raycast — Spotlight replacement"
    "stremio|Stremio — Media streaming"
    "roblox|Roblox — Gaming platform"

  )

  local to_install=()
  for entry in "${apps[@]}"; do
    local cask="${entry%%|*}" desc="${entry##*|}"
    if brew list --cask "$cask" &>/dev/null; then
      echo -e "  ${GREEN}✔${RESET} ${DIM}$desc (already installed)${RESET}"
    else
      echo -ne "  ${CYAN}?${RESET} $desc — ${DIM}Install?${RESET} ${DIM}[Y/n]${RESET}: "
      read -r ans
      [[ "${ans:-Y}" =~ ^[Yy] ]] && to_install+=("$cask|$desc")
    fi
  done

  for entry in "${to_install[@]}"; do
    run_quiet "Installing ${entry##*|}" brew install --cask "${entry%%|*}"
  done

  mark_done "apps"
  section_done
}

# ─────────────────────────────────────────────────
# 12 · GIT + GITHUB + SSH
# ─────────────────────────────────────────────────
install_git() {
  log_header "12 · Git + GitHub + SSH"
  is_done "git" && { log_skip "Already configured"; return; }

  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  git config --global init.defaultBranch main
  git config --global core.editor "cursor --wait"
  git config --global pull.rebase true
  git config --global fetch.prune true
  log_success "Git global config set"

  cat > "$HOME/.gitignore_global" << 'GITIGNORE'
.DS_Store
.env
.env.local
.env*.local
node_modules/
__pycache__/
*.pyc
.venv/
.idea/
*.log
dist/
build/
.next/
out/
.cache/
GITIGNORE
  git config --global core.excludesfile "$HOME/.gitignore_global"
  log_success "Global .gitignore configured"

  local ssh_key="$HOME/.ssh/id_ed25519"
  if [[ -f "$ssh_key" ]]; then
    log_success "SSH key already exists"
  else
    [[ -z "$GIT_EMAIL" ]] && ask GIT_EMAIL "Email for SSH key" "dev@example.com"
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$ssh_key" -N "" &>/dev/null
    log_success "SSH key generated"
  fi

  eval "$(ssh-agent -s)" &>/dev/null
  ssh-add "$ssh_key" &>/dev/null
  pbcopy < "${ssh_key}.pub"

  echo ""
  echo -e "${GREEN}  ✔ SSH public key copied to clipboard!${RESET}"
  echo -e "${DIM}    → github.com → Settings → SSH Keys → New SSH Key → Paste${RESET}"
  echo ""
  confirm "Open GitHub SSH settings in browser?" && open "https://github.com/settings/keys"

  if command -v gh &>/dev/null; then
    gh auth status &>/dev/null || (confirm "Authenticate GitHub CLI (gh auth login)?" && gh auth login)
  fi

  mark_done "git"
  section_done
}

# ─────────────────────────────────────────────────
# 13 · FOLDER STRUCTURE
# ─────────────────────────────────────────────────
install_folders() {
  log_header "13 · Developer Folder Structure"
  is_done "folders" && { log_skip "Already created"; return; }

  local dirs=(
    # Web
    "$HOME/Developer/web"
    "$HOME/Developer/web/next"
    "$HOME/Developer/web/express"
    # Mobile
    "$HOME/Developer/mobile"
    "$HOME/Developer/mobile/flutter"
    "$HOME/Developer/mobile/react-native"
    "$HOME/Developer/mobile/swift"
    # Core dev
    "$HOME/Developer/blockchain"
    "$HOME/Developer/ai"
    "$HOME/Developer/scripts"
    # Creative + learning
    "$HOME/Developer/creative"
    "$HOME/Developer/labs"
    # Context-based 
    "$HOME/Developer/work"
    "$HOME/Developer/university"
    "$HOME/Developer/ops"
    # Scratch + archive
    "$HOME/Developer/experiments"
    "$HOME/Developer/archive"
    # Infrastructure
    "$HOME/Developer/.data/mongodb"
    "$HOME/Developer/.envs"
    "$HOME/Developer/.templates"
  )

  for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
    log_info "  $dir"
  done

  cat > "$HOME/Developer/.envs/.env.template" << 'ENVTEMPLATE'
# ─── OpenAI ───────────────────────────────────────
OPENAI_API_KEY=

# ─── Anthropic ────────────────────────────────────
ANTHROPIC_API_KEY=

# ─── Firebase ─────────────────────────────────────
FIREBASE_API_KEY=
FIREBASE_PROJECT_ID=
FIREBASE_AUTH_DOMAIN=

# ─── MongoDB ──────────────────────────────────────
MONGODB_URI=mongodb://localhost:27017/mydb

# ─── Web3 / Hardhat ───────────────────────────────
PRIVATE_KEY=
ALCHEMY_API_KEY=
ETHERSCAN_API_KEY=

# ─── Misc ─────────────────────────────────────────
NODE_ENV=development
ENVTEMPLATE

  cat > "$HOME/Developer/.templates/docker-compose.yml" << 'DC'
version: '3.8'
services:
  app:
    image: node:20-alpine
    platform: linux/arm64
    deploy:
      resources:
        limits:
          memory: 512M
    volumes:
      - .:/app
    working_dir: /app
    ports:
      - "3000:3000"
    command: npm run dev
DC

  log_success "Folder structure created"
  log_success ".env.template and docker-compose.yml written"

  mark_done "folders"
  section_done
}

# ─────────────────────────────────────────────────
# 14 · WRITE ~/.zshrc
# ─────────────────────────────────────────────────
write_zshrc() {
  log_header "14 · Write ~/.zshrc"
  is_done "zshrc" && { log_skip "Already written"; return; }

  if [[ -f "$HOME/.zshrc" ]]; then
    log_warn "Existing ~/.zshrc found"
    confirm "Back it up and overwrite?" || { log_skip ".zshrc unchanged"; return; }
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    log_info "Backup saved as ~/.zshrc.backup.*"
  fi

  cat > "$HOME/.zshrc" << 'ZSHRC'
# ─────────────────────────────────────────────────
# ZSH CORE
# ─────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # Starship handles the prompt

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  z
)

source $ZSH/oh-my-zsh.sh

# ─────────────────────────────────────────────────
# HOMEBREW (Apple Silicon — ARM path)
# ─────────────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"

# ─────────────────────────────────────────────────
# NVM — Node Version Manager
# ChatGPT: explicit NVM_DIR export before sourcing
# ─────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ─────────────────────────────────────────────────
# ANDROID / FLUTTER
# ─────────────────────────────────────────────────
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"
export FLUTTER_HOME="$HOME/Developer/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"

# ─────────────────────────────────────────────────
# OLLAMA — Gemini: bind to localhost explicitly
# ─────────────────────────────────────────────────
export OLLAMA_HOST=127.0.0.1

# ─────────────────────────────────────────────────
# ALIASES — Navigation
# ─────────────────────────────────────────────────
alias dev="cd ~/Developer"
alias ..="cd .."
alias ...="cd ../.."

# ── Better defaults ──
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias cat="bat"
alias find="fd"

# ── Git ──
alias gs="git status"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gaa='git add -A && git commit -m'

# ── Node / npm ──
alias ni="npm install"
alias nr="npm run"
alias nrd="npm run dev"
alias nrb="npm run build"

# ── Python ──
alias py="python3"
alias pip="pip3"

# ─────────────────────────────────────────────────
# ALIASES — Services (manual-start only)
# ─────────────────────────────────────────────────

# MongoDB — two styles for different situations:
# Claude: path-based (explicit, always works)
alias mongoup="mongod --dbpath ~/Developer/.data/mongodb"
alias mongodown="mongod --dbpath ~/Developer/.data/mongodb --shutdown"
# Gemini: config-based + pkill (faster for quick kill)
alias start-mongo="mongod --config /opt/homebrew/etc/mongod.conf"
alias stop-mongo="pkill mongod"

# Ollama — Gemini: OLLAMA_HOST set globally above
alias ollamaup="ollama serve"

# Docker
alias dstats="docker stats --no-stream"

# ─────────────────────────────────────────────────
# ALIASES — System Maintenance
# ─────────────────────────────────────────────────

# Gemini: clear Xcode junk + npm cache in one shot
alias cleanup="rm -rf ~/Library/Developer/Xcode/DerivedData/* && npm cache clean --force && echo '✔ Cleaned Xcode DerivedData + npm cache'"

# Gemini: GPU/RAM pressure monitor — run while Ollama or PyTorch is active
alias l-gpu="top -u -s 5"

# Claude: swap + memory pressure check
alias memcheck="sysctl vm.swapusage && memory_pressure"

alias ip="ipconfig getifaddr en0"
alias zreload="source ~/.zshrc"
alias zconf="cursor ~/.zshrc"

# ─────────────────────────────────────────────────
# TOOLS INIT
# ─────────────────────────────────────────────────
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# History
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# FZF
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_DEFAULT_OPTS="--height 40% --border --layout=reverse"
ZSHRC

  log_success "~/.zshrc written — includes aliases from all three scripts"
  mark_done "zshrc"
  section_done
}

# ─────────────────────────────────────────────────
# 15 · STARSHIP PROMPT
# ─────────────────────────────────────────────────
install_starship_config() {
  log_header "15 · Starship Prompt Config"
  is_done "starship" && { log_skip "Already written"; return; }

  mkdir -p "$HOME/.config"
  cat > "$HOME/.config/starship.toml" << 'STARSHIP'
format = """
$directory$git_branch$git_status$nodejs$python$conda$cmd_duration
$character"""

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[directory]
style = "bold cyan"
truncate_to_repo = true
truncation_length = 3

[git_branch]
style = "bold purple"
symbol = " "

[git_status]
style = "bold red"

[nodejs]
style = "bold green"
symbol = " "

[python]
style = "bold yellow"
symbol = " "
pyenv_version_name = true

[conda]
style = "bold green"
symbol = "🐍 "

[cmd_duration]
min_time = 2000
style = "bold yellow"
format = "took [$duration]($style) "
STARSHIP

  log_success "Starship config written to ~/.config/starship.toml"
  mark_done "starship"
  section_done
}

# ─────────────────────────────────────────────────
# 16 · BREW CLEANUP + SYSTEM TIDY
# ─────────────────────────────────────────────────
install_cleanup() {
  log_header "16 · Brew Cleanup + System Tidy"
  is_done "cleanup" && { log_skip "Already run"; return; }

  run_quiet "brew cleanup --prune=7" brew cleanup --prune=7
  run_quiet "Removing brew download cache" rm -rf "$(brew --cache)"

  if command -v conda &>/dev/null; then
    run_quiet "conda clean --all" conda clean --all -y
  fi

  if command -v npm &>/dev/null; then
    run_quiet "npm cache clean" npm cache clean --force
  fi

  if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
    run_quiet "Clearing Xcode DerivedData" bash -c "rm -rf $HOME/Library/Developer/Xcode/DerivedData/*"
  fi

  log_success "System tidied"
  mark_done "cleanup"
  section_done
}

# ─────────────────────────────────────────────────
# SUMMARY SCREEN
# ─────────────────────────────────────────────────
show_summary() {
  clear
  echo ""
  echo -e "${BOLD}${GREEN}"
  echo "  ╔══════════════════════════════════════════════════════════╗"
  echo "  ║                                                          ║"
  echo "  ║            Setup Complete — What's Installed             ║"
  echo "  ║                                                          ║"
  echo "  ╚══════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"

  local sections=(
    "homebrew|Homebrew + Core CLI (incl. tmux)"
    "zsh|Zsh + Oh My Zsh + iTerm2"
    "node|NVM + Node LTS + Global Packages"
    "python|Python 3.12 + Conda (Anaconda or Miniforge) + AI Libs"
    "webdev|Firebase CLI + Hardhat Starter"
    "mongodb|MongoDB (manual-start)"
    "docker|Docker Desktop (2GB cap)"
    "ollama|Ollama + LLM Models (incl. deepseek-coder)"
    "mobile|Flutter + Android Studio + React Native"
    "editors|Cursor + VS Code"
    "apps|Productivity Apps"
    "git|Git + SSH + GitHub CLI"
    "folders|Developer Folder Structure (merged layout)"
    "zshrc|~/.zshrc (aliases from all 3 scripts)"
    "starship|Starship Prompt"
    "cleanup|Brew Cleanup + System Tidy"
  )

  for entry in "${sections[@]}"; do
    local key="${entry%%|*}" label="${entry##*|}"
    if is_done "$key"; then
      echo -e "  ${GREEN}✔${RESET} $label"
    else
      echo -e "  ${DIM}─ $label (skipped)${RESET}"
    fi
  done

  echo ""
  echo -e "${BOLD}${CYAN}  Next Steps:${RESET}"
  echo -e "${DIM}"
  echo "  1. Reopen iTerm2 — or run: source ~/.zshrc"
  echo "  2. Docker: Settings → Resources → Memory → 2 GB"
  echo "  3. SSH key: already on clipboard → github.com/settings/keys"
  echo "  4. Android Studio: SDK Manager → Android 14 (API 34)"
  echo "  5. Flutter: run 'flutter doctor' and follow remaining prompts"
  echo "  6. AI env: conda activate ai"
  echo "     Verify MPS: python3 -c \"import torch; print(torch.backends.mps.is_available())\""
  echo -e "${RESET}"
  echo -e "${BOLD}  Aliases from the merged build:${RESET}"
  echo -e "  ${CYAN}cleanup${RESET}      Clear Xcode junk + npm cache"
  echo -e "  ${CYAN}l-gpu${RESET}        Monitor GPU/RAM pressure "
  echo -e "  ${CYAN}memcheck${RESET}     Swap usage + memory pressure "
  echo -e "  ${CYAN}stop-mongo${RESET}   Quick pkill MongoDB "
  echo -e "  ${CYAN}start-mongo${RESET}  Config-based MongoDB start "
  echo -e "  ${CYAN}mongoup${RESET}      Path-based MongoDB start "
  echo -e "  ${CYAN}ollamaup${RESET}     Start Ollama server"
  echo -e "  ${CYAN}dev${RESET}          cd ~/Developer"
  echo ""
  echo -e "${GREEN}${BOLD}  Your workstation is ready. Ship something great. ❯${RESET}"
  echo ""
}

# ─────────────────────────────────────────────────
# INSTALL ALL
# ─────────────────────────────────────────────────
install_all() {
  install_homebrew
  install_zsh
  install_node
  install_python
  install_webdev
  install_mongodb
  install_docker
  install_ollama
  install_mobile
  install_editors
  install_apps
  install_git
  install_folders
  write_zshrc
  install_starship_config
  install_cleanup
}

# ─────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────
main() {
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

  welcome
  preflight

  while true; do
    show_menu
    case "${MENU_CHOICE}" in
      [Aa]) install_all; break ;;
      [Qq]) break ;;
      "01") install_homebrew ;;
      "02") install_zsh ;;
      "03") install_node ;;
      "04") install_python ;;
      "05") install_webdev ;;
      "06") install_mongodb ;;
      "07") install_docker ;;
      "08") install_ollama ;;
      "09") install_mobile ;;
      "10") install_editors ;;
      "11") install_apps ;;
      "12") install_git ;;
      "13") install_folders ;;
      "14") write_zshrc ;;
      "15") install_starship_config ;;
      "16") install_cleanup ;;
      *)
        log_warn "Unknown option: $MENU_CHOICE"
        sleep 1
        ;;
    esac
    echo ""
    confirm "Return to menu?" || break
  done

  show_summary
}

main "$@"
