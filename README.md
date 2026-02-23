# ⚡ M2 MacBook Air — Engineering Workstation

> Minimal. Intentional. Production-ready.  
> A complete dev environment for full-stack, mobile, blockchain, and AI development — optimized for Apple Silicon with 8GB RAM.
---

## Quick Start

```bash
git clone https://github.com/darshan-regmi/dev-setup.git
cd dev-setup
chmod +x setup.sh
./setup.sh
```

That's it. The script walks you through everything interactively.

---

## What's Inside

```
dev-setup/
├── setup.sh              # Interactive installer (merged: Claude +  + Gemini)
└── README.md             # You are here
```

---

## Stack

| Layer | Tools |
|---|---|
| **Shell** | Zsh · Oh My Zsh · Starship · iTerm2 · tmux |
| **Package Manager** | Homebrew (ARM-native `/opt/homebrew`) |
| **Runtime** | NVM · Node LTS · Python 3.12 (brew) · Anaconda or Miniforge |
| **Web** | Next.js · React · Tailwind · Express · Firebase · Hardhat |
| **Mobile** | Flutter · React Native · Android Studio · Swift/Xcode |
| **AI / ML** | PyTorch (MPS) · TensorFlow Metal · Transformers · LangChain · OpenAI SDK |
| **Local LLM** | Ollama · phi3:mini · tinyllama · nomic-embed-text · deepseek-coder:1.3b |
| **Database** | MongoDB (manual-start only) |
| **Containers** | Docker (2GB RAM hard cap) |
| **Editors** | Cursor · VS Code |

---

## Constraints This Respects

- **ARM-native only** — every tool installs to `/opt/homebrew`, no Rosetta
- **8GB RAM discipline** — MongoDB, Ollama, and Docker never auto-start
- **256GB storage** — no models over 7B; Miniforge preferred over full Anaconda; Docker disk capped at 32GB
- **No background bloat** — services start manually, stop when done

---

## How the Script Works

The installer has 16 sections, all optional and resumable. Completed steps are tracked in `~/.devsetup_state` — re-running the script never repeats finished work.

```
  ╔══════════════════════════════════════════════════════════╗
  ║     M2 MacBook Air — Engineering Workstation Setup       ║
  ║     Merged: Claude +  + Gemini — Best of All      ║
  ╚══════════════════════════════════════════════════════════╝

  Installation Menu
  ✔ 01 · Homebrew + Core CLI Tools (incl. tmux)
  ✔ 02 · Zsh + Oh My Zsh + iTerm2
  ○ 03 · NVM + Node LTS + Global Packages
  ...

  [A] Install All    [Q] Quit    [01-16] Jump to section
```

---

## Developer Folder Structure

Created automatically at `~/Developer/` — merged layout from all three scripts:

```
~/Developer/
├── web/
│   ├── next/              # Next.js apps      
│   └── express/           # Express APIs        
├── mobile/
│   ├── flutter/           # Flutter projects     
│   ├── react-native/      # RN projects          
│   └── swift/             # iOS / Swift
├── blockchain/            # Hardhat, Solidity
├── ai/                    # Python ML, LangChain
├── scripts/               # Automation
├── creative/              # Writing, AI poetry    
├── labs/                  # Experiments & R&D     
├── work/                  # Client / job projects 
├── university/            # Coursework, notebooks
├── ops/                   # DevOps, infra         
├── experiments/           # Hackathon prototypes
├── archive/               # Old projects          
├── .data/
│   └── mongodb/           # Manual MongoDB data dir
├── .envs/
│   └── .env.template      # Shared secrets template
└── .templates/
    └── docker-compose.yml
```

---

## Ollama Models

| Model | Size | Source | Use Case |
|---|---|---|---|
| `phi3:mini` | 2.3 GB | Claude | Daily reasoning, chat, LangChain |
| `tinyllama` | 0.6 GB | Claude | Ultra-fast prototyping |
| `nomic-embed-text` | 0.3 GB | Claude | Embeddings, RAG pipelines |
| `deepseek-coder:1.3b` | 0.8 GB | **Gemini** | Lightweight code assistant |
| `codellama:7b` | 4.8 GB | Claude | Full code model — run alone |

```bash
ollamaup                      # start server
ollama run phi3:mini          # chat
ollama run deepseek-coder:1.3b  # code help
ollama ps                     # check memory usage
```

---

## Key Aliases

All aliases are written to `~/.zshrc` automatically. Sources noted inline.

```bash
# ── Navigation ──────────────────────────────────
dev          # cd ~/Developer
ll           # eza -la with icons + git status

# ── Dev ─────────────────────────────────────────
nrd          # npm run dev

# ── Services (start manually, stop when done) ───
mongoup      # Start MongoDB via dbpath         (Claude)
mongodown    # Stop MongoDB via dbpath          (Claude)
start-mongo  # Start MongoDB via config file    (Gemini)
stop-mongo   # pkill mongod — fast kill         (Gemini)
ollamaup     # Start Ollama server

# ── System Maintenance ───────────────────────────
cleanup      # Clear Xcode DerivedData + npm cache  (Gemini)
l-gpu        # Real-time GPU/RAM pressure monitor   (Gemini)
memcheck     # Swap usage + memory pressure         (Claude)

# ── Shell ────────────────────────────────────────
zconf        # Edit ~/.zshrc in Cursor
zreload      # Reload shell config
```

---

## Conda: Anaconda vs Miniforge

The script now offers a choice — Miniforge is the new recommended default:

| | Anaconda | Miniforge |
|---|---|---|
| Install size | ~3 GB | ~200 MB |
| ARM-native | ✔ (via manual download) | ✔ (via brew cask) |
| Package source | Anaconda defaults | conda-forge |
| Automation | Manual download only | `brew install --cask miniforge` |
| **Recommended** | | **✔** |

Both create the same `conda activate ai` environment with identical AI/ML libraries.

---

## Memory Guide

| State | Expected RAM |
|---|---|
| Idle desktop | < 3 GB |
| Next.js dev server | < 5 GB |
| Ollama phi3:mini + Node | < 6 GB |
| Ollama + Docker (2GB cap) | < 7.5 GB |
| ⚠️ Swap territory | > 7.5 GB |

**Never run simultaneously:** `codellama:7b` + Docker + Android Emulator.  
**Check pressure:** `memcheck` or `l-gpu` aliases.

---

## After Running the Script

A few things require manual steps:

1. **Restart iTerm2** (or `source ~/.zshrc`) to load the new shell config
2. **Docker RAM cap** → Settings → Resources → Memory: `2 GB`
3. **SSH key** → already on your clipboard → `github.com/settings/keys`
4. **Android SDK** → Android Studio → SDK Manager → Android 14 (API 34)
5. **Flutter** → run `flutter doctor` and follow remaining prompts
6. **AI environment** → `conda activate ai` then verify:

```bash
python3 -c "import torch; print('MPS:', torch.backends.mps.is_available())"
```

---

## Reference Docs

Full setup guide with annotated commands, config explanations, and deployment workflows: [`m2-devenv-setup.md`](./m2-devenv-setup.md)

---

## Requirements

- MacBook with Apple Silicon (M1/M2/M3/M4)
- macOS Ventura 13+ recommended
- Internet connection
- ~30 GB free disk space before starting

---

*Built for M2 · 8GB · 256GB — every decision intentional.*  
*Merged from Claude +  + Gemini. The best script wins.*
