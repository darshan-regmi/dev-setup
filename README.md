# ⚡ Engineering Workstation Setup

> Minimal. Intentional. Production-ready.  
> Full-stack · Mobile · Blockchain · AI · Java · .NET — optimized for Apple Silicon with 8GB RAM.

---

## Quick Start

```bash
git clone https://github.com/darshan-regmi/dev-setup.git
cd dev-setup
chmod +x setup.sh
./setup.sh
```

Interactive menu. Choose exactly what to install. Completed steps are never repeated.

---

## What's Inside

```
dev-setup/
├── setup.sh      # Interactive installer — 18 sections
└── README.md     # You are here
```

---

## Stack

| Layer | Tools |
|---|---|
| **Shell** | Zsh · Oh My Zsh · Starship · iTerm2 · tmux |
| **Package Manager** | Homebrew (ARM-native `/opt/homebrew`) |
| **JavaScript** | NVM · Node LTS · pnpm · yarn · TypeScript |
| **Python / AI** | Python 3 (brew) · Anaconda or Miniforge · PyTorch MPS · TensorFlow Metal · Transformers · LangChain · OpenAI SDK |
| **Local LLM** | Ollama · phi3:mini · tinyllama · nomic-embed-text · deepseek-coder:1.3b |
| **Web** | Next.js · React · Tailwind · Express · Firebase · Hardhat |
| **Mobile** | Flutter · React Native · **Expo + EAS** · Android Studio · Swift/Xcode |
| **Java / JSP** | Temurin JDK 21 LTS · Maven · Gradle · Apache Tomcat |
| **.NET** | .NET SDK (latest LTS) |
| **Database** | MongoDB (manual-start) · **MySQL (manual-start)** |
| **Containers** | Docker (2GB RAM hard cap) |
| **Editors** | Cursor · VS Code · Google Antigravity |
| **Agentic Coding** | OpenClaw (free Claude Code alternative) |

---

## Constraints This Respects

- **ARM-native only** — every tool installs to `/opt/homebrew`, no Rosetta
- **8GB RAM discipline** — MongoDB, Ollama, Docker, and Tomcat never auto-start
- **256GB storage** — no models over 7B, Miniforge preferred over Anaconda, Docker disk capped at 32GB
- **No background bloat** — services start manually, stop when done

---

## How the Script Works

18 sections, all optional and resumable. Completed steps are tracked in `~/.devsetup_state` — re-running the script skips everything already done.

```
  ╔══════════════════════════════════════════════════════════╗
  ║             Engineering Workstation Setup                ║
  ║        Minimal · Intentional · Production-Ready          ║
  ╚══════════════════════════════════════════════════════════╝

  Installation Menu
  ✔ 01 · Homebrew + Core CLI Tools (incl. tmux)
  ✔ 02 · Zsh + Oh My Zsh + iTerm2
  ○ 03 · NVM + Node LTS + Global Packages
  ...

  [A] Install All    [Q] Quit    [01-18] Jump to section
```

---

## All 19 Sections

| # | Section | What Gets Installed |
|---|---|---|
| 01 | Homebrew + Core CLI | brew · git · gh · bat · eza · fd · ripgrep · fzf · zoxide · starship · tmux · tldr · JetBrains Mono NF |
| 02 | Zsh + iTerm2 | Oh My Zsh · zsh-autosuggestions · zsh-syntax-highlighting · zsh-completions |
| 03 | NVM + Node LTS | nvm (via curl) · Node LTS · pnpm · yarn · typescript · ts-node · firebase-tools |
| 04 | Python + Conda | brew python · Anaconda or Miniforge (your choice) · full AI/ML stack in `conda ai` env |
| 05 | Web Dev | Firebase CLI · Hardhat starter project with toolbox |
| 06 | MongoDB | mongodb-community · manual-start only · MongoDB Compass (optional) |
| 07 | Docker | Docker Desktop · 2GB RAM cap reminder |
| 08 | Ollama | phi3:mini · tinyllama · nomic-embed-text · deepseek-coder:1.3b · codellama:7b |
| 09 | Mobile Dev | Flutter · Android Studio · React Native CLI · Expo CLI · EAS CLI · Watchman |
| 10 | Editors | Cursor · VS Code + 9 extensions + settings.json · Google Antigravity |
| 11 | Productivity Apps | Notion · Spotify · Discord · Brave · Chrome · Raycast · Microsoft Office · HiddenBar · Stremio · Roblox |
| 12 | Git + SSH | Global git config · SSH keygen (ed25519) · clipboard copy · GitHub CLI auth |
| 13 | Folder Structure | Full `~/Developer/` layout — 20 directories incl. java/ dotnet/ mobile/expo/ |
| 14 | ~/.zshrc | All aliases + PATH exports for every tool in this stack |
| 15 | Starship Prompt | Prompt with Node · Python · Conda · Java · .NET modules |
| 16 | Cleanup | brew cleanup · conda clean · npm cache · Xcode DerivedData |
| 17 | Java + .NET + JSP | Temurin JDK 21 · Apache Maven · Gradle · Apache Tomcat · .NET SDK |
| 18 | OpenClaw | Free Claude Code alternative — brew → npm → Open Interpreter fallback chain |
| **19** | **MySQL** | **mysql · mysql-shell (optional) · TablePlus GUI · first-time setup guide** |

---

## Everything This Script Can Install

A complete flat list — every tool, app, and package across all 19 sections.

### 🔧 CLI & Shell
`brew` · `git` · `gh` · `wget` · `curl` · `jq` · `tree` · `htop` · `bat` · `eza` · `fd` · `ripgrep` · `fzf` · `zoxide` · `starship` · `tmux` · `tldr` · `JetBrains Mono Nerd Font`

### 🐚 Terminal
`iTerm2` · `Oh My Zsh` · `zsh-autosuggestions` · `zsh-syntax-highlighting` · `zsh-completions`

### 🟢 JavaScript / Node
`nvm` · `Node LTS` · `npm` · `pnpm` · `yarn` · `typescript` · `ts-node` · `firebase-tools`

### 🐍 Python / AI
`python@3.12` (brew) · `Anaconda` or `Miniforge` · `torch` · `torchvision` · `torchaudio` · `tensorflow-metal` · `tensorflow-macos` · `transformers` · `datasets` · `accelerate` · `langchain` · `langchain-community` · `langchain-openai` · `openai` · `anthropic` · `jupyterlab` · `notebook` · `ipywidgets` · `pandas` · `numpy` · `scipy` · `matplotlib` · `seaborn` · `scikit-learn` · `huggingface_hub` · `python-dotenv`

### 🤖 Local LLMs (Ollama)
`ollama` · `phi3:mini` · `tinyllama` · `nomic-embed-text` · `deepseek-coder:1.3b` · `codellama:7b`

### 🌐 Web Dev
`firebase-tools` · `hardhat` · `@nomicfoundation/hardhat-toolbox`

### 📱 Mobile Dev
`Flutter` · `Android Studio` · `react-native-cli` · `@expo/cli` · `eas-cli` · `watchman`

### ☕ Java / JSP / Enterprise
`temurin@21` (OpenJDK) · `maven` · `gradle` · `tomcat`

### 💜 .NET
`.NET SDK` (latest LTS)

### 🗄️ Databases
`mongodb-community` · `MongoDB Compass` · `mysql` · `mysql-shell` · `TablePlus`

### 🐳 Containers
`Docker Desktop` (2GB RAM cap)

### ✏️ Editors
`Cursor` · `Visual Studio Code` · `Google Antigravity`

**VS Code Extensions:** `vscode-eslint` · `prettier-vscode` · `vscode-tailwindcss` · `ms-python` · `jupyter` · `gitlens` · `auto-rename-tag` · `material-icon-theme` · `material-theme`

### 🤖 Agentic Coding
`OpenClaw` (or `Open Interpreter` fallback)

### 🎯 Productivity Apps
`Notion` · `Spotify` · `Discord` · `Brave Browser` · `Google Chrome` · `Raycast` · `Rectangle` · `HiddenBar` · `Stremio` · `Roblox`

---

## Developer Folder Structure

```
~/Developer/
├── web/
│   ├── next/              # Next.js apps
│   └── express/           # Express APIs
├── mobile/
│   ├── flutter/
│   ├── react-native/
│   ├── expo/              # Expo managed workflow
│   └── swift/
├── blockchain/            # Hardhat, Solidity
├── ai/                    # Python ML, LangChain, notebooks
├── java/                  # Spring Boot, JSP, Maven/Gradle projects
├── dotnet/                # .NET Web APIs, C# projects
├── scripts/               # Automation
├── creative/              # Writing, AI poetry
├── labs/                  # R&D, experiments
├── work/                  # Client / job projects
├── university/            # Coursework, notebooks
├── ops/                   # DevOps, infra
├── experiments/           # Hackathon prototypes
├── archive/               # Old projects
├── .data/
│   ├── mongodb/           # Manual MongoDB data directory
│   └── mysql/             # Reference — MySQL data managed by brew
├── .envs/
│   └── .env.template      # Shared secrets template
└── .templates/
    └── docker-compose.yml
```

---

## Ollama Models

| Model | Size | Use Case |
|---|---|---|
| `phi3:mini` | 2.3 GB | Daily driver — reasoning, chat, LangChain |
| `tinyllama` | 0.6 GB | Ultra-fast prototyping |
| `nomic-embed-text` | 0.3 GB | Embeddings, RAG pipelines |
| `deepseek-coder:1.3b` | 0.8 GB | Lightweight code assistant |
| `codellama:7b` | 4.8 GB | Full code model — run alone only |

```bash
ollamaup                         # start server (use alias)
ollama run phi3:mini             # chat
ollama run deepseek-coder:1.3b   # code help
ollama ps                        # check what's loaded in memory
```

---

## Key Aliases

```bash
# ── Navigation ─────────────────────────────────────
dev            cd ~/Developer
ll             eza -la --icons --git

# ── Node ───────────────────────────────────────────
nrd            npm run dev
ni             npm install
nrb            npm run build

# ── Expo ───────────────────────────────────────────
exs            npx expo start
exa            npx expo start --android
exi            npx expo start --ios
exb            eas build --platform all

# ── Java ───────────────────────────────────────────
jv             java -version
mvnw           ./mvnw   (Maven wrapper)
gw             ./gradlew (Gradle wrapper)

# ── .NET ───────────────────────────────────────────
dn             dotnet
dnr            dotnet run
dnb            dotnet build
dnt            dotnet test
dnn            dotnet new

# ── Services (start manually, stop when done) ──────
mongoup        Start MongoDB (dbpath)
mongodown      Stop MongoDB (dbpath shutdown)
start-mongo    Start MongoDB (config file)
stop-mongo     pkill mongod — fast kill
mysqlup        Start MySQL server
mysqldown      Stop MySQL server
mysqlstatus    Check MySQL status
mysqlroot      Connect to MySQL as root (-u root -p)
ollamaup       Start Ollama server
dstats         docker stats --no-stream

# ── System Maintenance ─────────────────────────────
cleanup        Clear Xcode DerivedData + npm cache
l-gpu          Real-time GPU/RAM pressure monitor
memcheck       Swap usage + memory pressure

# ── Shell ──────────────────────────────────────────
zconf          Edit ~/.zshrc in Cursor
zreload        Reload shell config
ip             Get local IP address
```

---

## Conda: Anaconda vs Miniforge

| | Anaconda | Miniforge |
|---|---|---|
| Install size | ~3 GB | ~200 MB |
| ARM-native | ✔ | ✔ |
| Automation | Via brew (large) | `brew install --cask miniforge` |
| **Recommended** | | **✔** |

Both produce the same `conda activate ai` environment with identical AI/ML libraries installed.

---

## Memory Guide

| State | Expected RAM |
|---|---|
| Idle desktop | < 3 GB |
| Next.js dev server | < 5 GB |
| Spring Boot app (Java) | < 5.5 GB |
| .NET WebAPI | < 5 GB |
| Ollama phi3:mini + Node | < 6 GB |
| MySQL + Node | < 5.5 GB |
| MongoDB + MySQL (both running) | < 6 GB |
| Docker active (2GB cap) | < 7.5 GB |
| ⚠️ Swap territory | > 7.5 GB |

**Never run simultaneously:** `codellama:7b` + Docker + Android Emulator + Tomcat.  
**Monitor:** `memcheck` (swap check) · `l-gpu` (live RAM pressure)

---

## After Running the Script

| # | Action | Where |
|---|---|---|
| 1 | Restart iTerm2 | or run `source ~/.zshrc` |
| 2 | Set Docker RAM to 2GB | Docker Desktop → Settings → Resources → Memory |
| 3 | Add SSH key | Clipboard is ready → `github.com/settings/keys` |
| 4 | Install Android SDK | Android Studio → SDK Manager → Android 14 (API 34) |
| 5 | Finish Flutter setup | `flutter doctor` |
| 6 | Create your first Expo app | `npx create-expo-app@latest MyApp` |
| 7 | Verify Java | `java -version` · `mvn -v` |
| 8 | Verify .NET | `dotnet --version` · `dotnet new webapi -n MyApi` |
| 9 | Start Tomcat (JSP) | `catalina run` → `http://localhost:8080` |
| 10 | Activate AI environment | `conda activate ai` |
| 11 | First-time MySQL setup | `mysqlup` → `mysql_secure_installation` → `mysqlroot` |

Verify PyTorch Metal (MPS) is working:
```bash
python3 -c "import torch; print('MPS:', torch.backends.mps.is_available())"
```

---

## Requirements

- MacBook with Apple Silicon (M1 / M2 / M3 / M4)
- macOS Ventura 13+
- Internet connection
- ~35 GB free disk space (Java + .NET + MySQL add ~2.5GB on top of base stack)

---

*Built for MAC with Apple Silicon Chips — every decision intentional.*