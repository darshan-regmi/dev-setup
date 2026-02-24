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
  echo -e "${DIM}  ✔ = done  ○ = pending  |  [A] All  [Q] Quit  [01-19] Jump${RESET}"
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
    "mobile"    "09 · Mobile Dev (Flutter, React Native, Expo)"
    "editors"   "10 · Cursor + VS Code + Google Antigravity"
    "apps"      "11 · Productivity Apps"
    "git"       "12 · Git + GitHub + SSH"
    "folders"   "13 · Developer Folder Structure"
    "zshrc"     "14 · Write ~/.zshrc (all aliases + tools)"
    "starship"  "15 · Starship Prompt Config"
    "cleanup"   "16 · Brew Cleanup + System Tidy"
    "javanet"   "17 · Java + .NET + JSP Tools (Maven, Gradle, Tomcat)"
    "openclaw"  "18 · OpenClaw — Free Claude Code Alternative"
    "mysql"     "19 · MySQL (manual-start only) + TablePlus"
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
  log_header "04 · Python + Conda AI Environment"
  is_done "python" && { log_skip "Already configured"; return; }

  # ── Standalone Python via brew (lightweight, for scripts) ──
  if brew list python &>/dev/null; then
    log_success "Python (brew) already installed"
  else
    if confirm "Install Python via Homebrew (lightweight, for scripts/tools)?"; then
      run_quiet "Installing python" brew install python
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
        log_success "Anaconda installed"
        ;;
      2)
        log_step "Installing Miniforge (ARM-native, ~200MB)..."
        run_quiet "Installing Miniforge" brew install --cask miniforge
        log_success "Miniforge installed"
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

  brew services stop mongodb-community &>/dev/null || true
  log_success "MongoDB installed — NOT auto-started"
  log_info "  Use: 'mongoup' to start · 'stop-mongo' to kill"

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
  log_info "Ollama stopped — use 'ollamaup' alias when needed"

  mark_done "ollama"
  section_done
}

# ─────────────────────────────────────────────────
# 09 · MOBILE DEV
# ─────────────────────────────────────────────────
install_mobile() {
  log_header "09 · Mobile Dev (Flutter, React Native, Expo)"
  is_done "mobile" && { log_skip "Already configured"; return; }

  # Watchman — required by React Native Metro bundler
  if brew list watchman &>/dev/null; then
    log_success "Watchman already installed"
  else
    run_quiet "Installing Watchman" brew install watchman
  fi

  # Flutter
  if command -v flutter &>/dev/null; then
    log_success "Flutter: $(flutter --version 2>/dev/null | head -1)"
  else
    confirm "Install Flutter SDK?" && {
      run_quiet "Installing Flutter" brew install --cask flutter
      flutter doctor &>/dev/null || true
    }
  fi

  # Android Studio
  if brew list --cask android-studio &>/dev/null; then
    log_success "Android Studio already installed"
  else
    confirm "Install Android Studio? (~1.5GB)" && {
      run_quiet "Installing Android Studio" brew install --cask android-studio
      log_info "  → Open Android Studio → SDK Manager → Android 14 (API 34)"
    }
  fi

  # React Native CLI
  confirm "Install React Native CLI?" && {
    run_quiet "Installing React Native CLI" npm install -g react-native-cli
  }

  # Expo is the standard managed workflow for React Native (snack, EAS, OTA updates)
  echo ""
  echo -e "${DIM}  Expo gives you: Expo Go app, EAS Build, OTA updates, and a managed"
  echo -e "  workflow so you don't need to touch Xcode/Android Studio for most projects.${RESET}"
  echo ""
  if npm list -g @expo/cli &>/dev/null; then
    log_success "Expo CLI already installed"
  else
    confirm "Install Expo CLI (@expo/cli)?" && {
      run_quiet "Installing Expo CLI" npm install -g @expo/cli
      run_quiet "Installing EAS CLI (Expo build service)" npm install -g eas-cli
      log_success "Expo CLI ready"
      log_info "  Create a project: npx create-expo-app@latest MyApp"
      log_info "  Start dev server: npx expo start"
      log_info "  Build for stores: eas build --platform all"
    }
  fi

  log_info "Xcode: install via the Mac App Store for iOS development"

  mark_done "mobile"
  section_done
}

# ─────────────────────────────────────────────────
# 10 · EDITORS
# ─────────────────────────────────────────────────
install_editors() {
  log_header "10 · Cursor + VS Code + Google Antigravity"
  is_done "editors" && { log_skip "Already installed"; return; }

  # Cursor — primary editor
  confirm "Install Cursor (primary AI-first editor)?" && {
    if ! brew list --cask cursor &>/dev/null; then
      run_quiet "Installing Cursor" brew install --cask cursor
    else
      log_success "Cursor already installed"
    fi
  }

  # VS Code — fallback
  confirm "Install VS Code (fallback / pair sessions)?" && {
    if ! brew list --cask visual-studio-code &>/dev/null; then
      run_quiet "Installing VS Code" brew install --cask visual-studio-code
    else
      log_success "VS Code already installed"
    fi
  }

  # Google Antigravity — AI IDE
  echo ""
  echo -e "${DIM}  Google Antigravity is Google's AI-native IDE (secondary AI editor).${RESET}"
  confirm "Install Google Antigravity?" && {
    if ! brew list --cask antigravity &>/dev/null; then
      run_quiet "Installing Google Antigravity" brew install --cask antigravity
      if [[ $? -ne 0 ]]; then
        log_warn "brew cask 'antigravity' not found — may need manual install."
        log_info "  → Check: https://antigravity.dev for the latest download"
        confirm "Open Antigravity website?" && open "https://antigravity.dev"
      fi
    else
      log_success "Google Antigravity already installed"
    fi
  }

  # VS Code Extensions
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

  # VS Code settings
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
    "microsoft-office|Microsoft Office — Productivity suite"
    "hiddenbar|HiddenBar — Menubar cleaner"
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
    "$HOME/Developer/web"
    "$HOME/Developer/web/next"
    "$HOME/Developer/web/express"
    "$HOME/Developer/mobile"
    "$HOME/Developer/mobile/flutter"
    "$HOME/Developer/mobile/react-native"
    "$HOME/Developer/mobile/expo"
    "$HOME/Developer/mobile/swift"
    "$HOME/Developer/blockchain"
    "$HOME/Developer/ai"
    "$HOME/Developer/scripts"
    "$HOME/Developer/creative"
    "$HOME/Developer/labs"
    "$HOME/Developer/work"
    "$HOME/Developer/university"
    "$HOME/Developer/ops"
    "$HOME/Developer/experiments"
    "$HOME/Developer/archive"
    "$HOME/Developer/java"
    "$HOME/Developer/dotnet"
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
# ─────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ─────────────────────────────────────────────────
# JAVA — OpenJDK via Temurin
# JAVA_HOME set to latest installed JDK
# ─────────────────────────────────────────────────
export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null || echo "")
[[ -n "$JAVA_HOME" ]] && export PATH="$JAVA_HOME/bin:$PATH"

# ─────────────────────────────────────────────────
# .NET SDK
# ─────────────────────────────────────────────────
export DOTNET_ROOT="/usr/local/share/dotnet"
export PATH="$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"

# ─────────────────────────────────────────────────
# ANDROID / FLUTTER
# ─────────────────────────────────────────────────
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"
export FLUTTER_HOME="$HOME/Developer/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"

# ─────────────────────────────────────────────────
# OLLAMA — bind to localhost explicitly
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

# ── Expo ──
alias exs="npx expo start"
alias exb="eas build --platform all"
alias exa="npx expo start --android"
alias exi="npx expo start --ios"

# ── Python ──
alias py="python3"
alias pip="pip3"

# ── Java ──
alias jv="java -version"
alias mvnw="./mvnw"
alias gw="./gradlew"

# ── .NET ──
alias dn="dotnet"
alias dnr="dotnet run"
alias dnb="dotnet build"
alias dnt="dotnet test"
alias dnn="dotnet new"

# ─────────────────────────────────────────────────
# ALIASES — Services (manual-start only)
# ─────────────────────────────────────────────────
alias mongoup="mongod --dbpath ~/Developer/.data/mongodb"
alias mongodown="mongod --dbpath ~/Developer/.data/mongodb --shutdown"
alias start-mongo="mongod --config /opt/homebrew/etc/mongod.conf"
alias stop-mongo="pkill mongod"

alias ollamaup="ollama serve"
alias dstats="docker stats --no-stream"

# ─────────────────────────────────────────────────
# ALIASES — MySQL (manual-start only)
# ─────────────────────────────────────────────────
alias mysqlup="mysql.server start"
alias mysqldown="mysql.server stop"
alias mysqlstatus="mysql.server status"
alias mysqlroot="mysql -u root -p"

# ─────────────────────────────────────────────────
# ALIASES — System Maintenance
# ─────────────────────────────────────────────────
alias cleanup="rm -rf ~/Library/Developer/Xcode/DerivedData/* && npm cache clean --force && echo '✔ Cleaned'"
alias l-gpu="top -u -s 5"
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

HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_DEFAULT_OPTS="--height 40% --border --layout=reverse"
ZSHRC

  log_success "~/.zshrc written"
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
$directory$git_branch$git_status$nodejs$python$conda$java$dotnet$cmd_duration
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

[java]
style = "bold red"
symbol = " "

[dotnet]
style = "bold blue"
symbol = "󰪮 "

[cmd_duration]
min_time = 2000
style = "bold yellow"
format = "took [$duration]($style) "
STARSHIP

  log_success "Starship config written (Java + .NET modules added)"
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
# 17 · JAVA + .NET + JSP TOOLS
# New section — covers enterprise/backend stack
# ─────────────────────────────────────────────────
install_javanet() {
  log_header "17 · Java + .NET + JSP Tools"
  is_done "javanet" && { log_skip "Already configured"; return; }

  echo ""
  echo -e "${DIM}  This section installs:${RESET}"
  echo -e "  Java (Temurin OpenJDK 21 LTS) + Maven + Gradle"
  echo -e "  .NET SDK (latest LTS)"
  echo -e "  Apache Tomcat (JSP / Servlet container)"
  echo ""

  # ── Java (Temurin = most compatible ARM-native OpenJDK) ──
  if command -v java &>/dev/null; then
    log_success "Java already installed: $(java -version 2>&1 | head -1)"
  else
    if confirm "Install Java 21 LTS (Temurin OpenJDK)?"; then
      brew tap homebrew/cask-versions &>/dev/null || true
      run_quiet "Installing Temurin JDK 21" brew install --cask temurin@21
      log_success "Java 21 (Temurin) installed"
      log_info "  JAVA_HOME is auto-set in ~/.zshrc via /usr/libexec/java_home"
    fi
  fi

  # ── Maven (JSP / Spring Boot build tool) ──
  if brew list maven &>/dev/null; then
    log_success "Maven already installed: $(mvn -v 2>/dev/null | head -1)"
  else
    if confirm "Install Apache Maven (build tool for Java/JSP projects)?"; then
      run_quiet "Installing Maven" brew install maven
      log_info "  Usage: mvn spring-boot:run · mvn package · mvn test"
    fi
  fi

  # ── Gradle (Android + Kotlin + Spring alternative) ──
  if brew list gradle &>/dev/null; then
    log_success "Gradle already installed: $(gradle -v 2>/dev/null | head -1)"
  else
    if confirm "Install Gradle (alternative build tool — used by Android + Kotlin)?"; then
      run_quiet "Installing Gradle" brew install gradle
    fi
  fi

  # ── Apache Tomcat (JSP Servlet container) ──
  echo ""
  echo -e "${DIM}  Tomcat is needed to run JSP/Servlet apps locally."
  echo -e "  Installed manually-start only — no auto-launch.${RESET}"
  echo ""
  if brew list tomcat &>/dev/null; then
    log_success "Tomcat already installed"
  else
    if confirm "Install Apache Tomcat (JSP/Servlet container)?"; then
      run_quiet "Installing Tomcat" brew install tomcat
      log_success "Tomcat installed"
      log_info "  Start: catalina run"
      log_info "  Deploy WAR: copy to \$(brew --prefix)/opt/tomcat/libexec/webapps/"
      log_info "  Access: http://localhost:8080"
    fi
  fi

  # ── .NET SDK ──
  echo ""
  if command -v dotnet &>/dev/null; then
    log_success ".NET SDK already installed: $(dotnet --version)"
  else
    if confirm "Install .NET SDK (latest LTS)?"; then
      run_quiet "Installing .NET SDK" brew install --cask dotnet-sdk
      log_success ".NET SDK installed"
      log_info "  Create app:   dotnet new webapi -n MyApi"
      log_info "  Run:          dotnet run"
      log_info "  Build:        dotnet build"
      log_info "  Test:         dotnet test"
    fi
  fi

  # ── Quick verification ──
  echo ""
  log_step "Environment check..."
  command -v java   &>/dev/null && log_success "  java   $(java -version 2>&1 | awk -F '"' '/version/ {print $2}')"
  command -v mvn    &>/dev/null && log_success "  maven  $(mvn -v 2>/dev/null | awk 'NR==1{print $3}')"
  command -v gradle &>/dev/null && log_success "  gradle $(gradle -v 2>/dev/null | awk '/Gradle/{print $2}')"
  command -v dotnet &>/dev/null && log_success "  dotnet $(dotnet --version 2>/dev/null)"

  mark_done "javanet"
  section_done
}

# ─────────────────────────────────────────────────
# 18 · OPENCLAW — Free Claude Code Alternative
# ─────────────────────────────────────────────────
install_openclaw() {
  log_header "18 · OpenClaw — Free Claude Code Alternative"
  is_done "openclaw" && { log_skip "Already installed"; return; }

  echo ""
  echo -e "${DIM}  OpenClaw is a free, open-source alternative to Claude Code."
  echo -e "  It provides an agentic coding CLI experience powered by local"
  echo -e "  or remote LLMs — pairs well with Ollama.${RESET}"
  echo ""

  if ! confirm "Install OpenClaw?"; then
    log_skip "OpenClaw"
    return
  fi

  # Try brew cask first — if it fails, fall back to manual instructions
  if brew install --cask openclaw &>/dev/null; then
    log_success "OpenClaw installed via Homebrew"
  else
    log_warn "Homebrew cask not found — trying npm install..."
    if npm install -g openclaw &>/dev/null; then
      log_success "OpenClaw installed via npm"
    else
      log_warn "Could not auto-install OpenClaw."
      echo ""
      echo -e "${DIM}  Manual options:${RESET}"
      echo -e "  ${CYAN}Option A)${RESET} Check https://github.com/openclaw/openclaw for latest install"
      echo -e "  ${CYAN}Option B)${RESET} Use Open Interpreter (similar free alternative):"
      echo -e "           pip install open-interpreter"
      echo -e "           interpreter"
      echo ""
      confirm "Install Open Interpreter (fallback)?" && {
        conda run -n ai pip install open-interpreter &>/dev/null && \
          log_success "Open Interpreter installed in 'ai' conda env" || \
          log_error "Failed — run manually: pip install open-interpreter"
      }
    fi
  fi

  mark_done "openclaw"
  section_done
}

# ─────────────────────────────────────────────────
# 19 · MYSQL
# Manual-start only — same discipline as MongoDB
# ─────────────────────────────────────────────────
install_mysql() {
  log_header "19 · MySQL (Manual-Only Policy)"
  is_done "mysql" && { log_skip "Already installed"; return; }

  echo ""
  echo -e "${DIM}  MySQL is installed but NOT started as a service."
  echo -e "  Use aliases: mysqlup / mysqldown / mysqlstatus / mysqlroot${RESET}"
  echo ""

  # ── MySQL Server ──
  if brew list mysql &>/dev/null; then
    log_success "MySQL already installed: $(mysql --version 2>/dev/null)"
  else
    if confirm "Install MySQL?"; then
      run_quiet "Installing MySQL" brew install mysql
      log_success "MySQL installed"

      # Explicitly stop any auto-started instance
      brew services stop mysql &>/dev/null || true
      log_info "  MySQL stopped — will NOT auto-start on boot"
      log_info "  Aliases: mysqlup · mysqldown · mysqlstatus · mysqlroot"

      echo ""
      log_step "Securing MySQL installation..."
      echo -e "${YELLOW}  ⚠  Run this manually after first start:${RESET}"
      echo -e "  ${BOLD}mysqlup && mysql_secure_installation${RESET}"
      echo -e "${DIM}  This sets the root password and removes anonymous users.${RESET}"
    fi
  fi

  # ── MySQL Shell (optional) ──
  if brew list mysql-shell &>/dev/null; then
    log_success "MySQL Shell already installed"
  else
    if confirm "Install MySQL Shell (mysqlsh — advanced CLI client)?"; then
      run_quiet "Installing MySQL Shell" brew install mysql-shell
    fi
  fi

  # ── TablePlus — GUI client for MySQL, PostgreSQL, SQLite, Redis ──
  echo ""
  echo -e "${DIM}  TablePlus is a clean, fast GUI client that works with MySQL,"
  echo -e "  PostgreSQL, SQLite, Redis, and MongoDB — one tool for all DBs.${RESET}"
  echo ""
  if brew list --cask tableplus &>/dev/null; then
    log_success "TablePlus already installed"
  else
    if confirm "Install TablePlus (GUI for MySQL + all databases)?"; then
      run_quiet "Installing TablePlus" brew install --cask tableplus
      log_success "TablePlus installed"
      log_info "  Add a connection: Open TablePlus → + → MySQL → localhost:3306"
    fi
  fi

  # ── Quick verification ──
  echo ""
  log_step "Environment check..."
  command -v mysql     &>/dev/null && log_success "  mysql      $(mysql --version 2>/dev/null | awk '{print $3, $4}' | tr -d ',')"
  command -v mysqlsh   &>/dev/null && log_success "  mysqlsh    installed"
  brew list --cask tableplus &>/dev/null && log_success "  TablePlus  installed"

  echo ""
  log_warn "First-time setup after install:"
  log_info "  1. mysqlup                    — start MySQL"
  log_info "  2. mysql_secure_installation  — set root password, remove anonymous users"
  log_info "  3. mysqlroot                  — connect as root"
  log_info "  4. CREATE DATABASE mydb;      — create your first database"

  mark_done "mysql"
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
    "python|Python + Conda AI Environment"
    "webdev|Firebase CLI + Hardhat"
    "mongodb|MongoDB (manual-start)"
    "docker|Docker Desktop (2GB cap)"
    "ollama|Ollama + LLM Models"
    "mobile|Flutter + React Native + Expo"
    "editors|Cursor + VS Code + Google Antigravity"
    "apps|Productivity Apps (incl. Stremio, Roblox)"
    "git|Git + SSH + GitHub CLI"
    "folders|Developer Folder Structure"
    "zshrc|~/.zshrc (all aliases)"
    "starship|Starship Prompt (Java + .NET modules)"
    "cleanup|Brew Cleanup + System Tidy"
    "javanet|Java 21 + Maven + Gradle + Tomcat + .NET SDK"
    "openclaw|OpenClaw — Free Claude Code Alternative"
    "mysql|MySQL (manual-start) + TablePlus"
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
  echo "  1.  Reopen iTerm2 — or run: source ~/.zshrc"
  echo "  2.  Docker: Settings → Resources → Memory → 2 GB"
  echo "  3.  SSH key: already on clipboard → github.com/settings/keys"
  echo "  4.  Android Studio: SDK Manager → Android 14 (API 34)"
  echo "  5.  Flutter: run 'flutter doctor' and follow remaining prompts"
  echo "  6.  AI env: conda activate ai"
  echo "      MPS check: python3 -c \"import torch; print(torch.backends.mps.is_available())\""
  echo "  7.  Java: java -version · mvn -v · gradle -v"
  echo "  8.  .NET: dotnet --version · dotnet new webapi -n MyApi"
  echo "  9.  JSP: catalina run → http://localhost:8080"
  echo "  10. Expo: npx create-expo-app@latest MyApp → npx expo start"
  echo "  11. MySQL: mysqlup → mysqlroot → create databases"
  echo -e "${RESET}"

  echo -e "${BOLD}  Full alias list:${RESET}"
  echo -e "  ${CYAN}dev${RESET}         cd ~/Developer"
  echo -e "  ${CYAN}ll${RESET}          eza -la with git status"
  echo -e "  ${CYAN}nrd${RESET}         npm run dev"
  echo -e "  ${CYAN}exs / exa / exi${RESET}  Expo start / android / ios"
  echo -e "  ${CYAN}dn / dnr / dnb${RESET}   dotnet / run / build"
  echo -e "  ${CYAN}mvnw / gw${RESET}   Maven/Gradle wrapper shortcuts"
  echo -e "  ${CYAN}mongoup${RESET}     Start MongoDB"
  echo -e "  ${CYAN}stop-mongo${RESET}  Kill MongoDB"
  echo -e "  ${CYAN}mysqlup${RESET}     Start MySQL"
  echo -e "  ${CYAN}mysqldown${RESET}   Stop MySQL"
  echo -e "  ${CYAN}mysqlroot${RESET}   Connect as root"
  echo -e "  ${CYAN}ollamaup${RESET}    Start Ollama LLM server"
  echo -e "  ${CYAN}cleanup${RESET}     Clear Xcode DerivedData + npm cache"
  echo -e "  ${CYAN}l-gpu${RESET}       Monitor GPU/RAM pressure"
  echo -e "  ${CYAN}memcheck${RESET}    Swap + memory pressure"
  echo -e "  ${CYAN}zconf${RESET}       Edit ~/.zshrc in Cursor"
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
  install_javanet
  install_openclaw
  install_mysql
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
      "17") install_javanet ;;
      "18") install_openclaw ;;
      "19") install_mysql ;;
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