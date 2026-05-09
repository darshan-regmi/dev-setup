# Mac M2 Dev Setup

> Minimal. Tailored. No bloat.
> Web + Mobile + Writing — built for Apple Silicon with 8GB RAM and 256GB SSD.

A focused, idempotent installer for a developer who ships **Next.js / React / TypeScript** on the web, **Expo** on mobile, takes notes as a **student**, and writes **poetry** on the side.

---

## Quick Start

```bash
git clone https://github.com/<your-username>/dev-setup.git
cd dev-setup
chmod +x setup.sh
./setup.sh
```

Interactive menu. Pick what you want. Re-run anytime — completed sections are skipped.

---

## What It Installs

| Layer | Tools |
|---|---|
| **Foundation** | Xcode CLT · Homebrew (ARM-native) |
| **CLI** | git · gh · ripgrep · fd · bat · eza · fzf · zoxide · jq · tldr · JetBrains Mono Nerd Font |
| **Shell** | Starship (fast, no Oh My Zsh slowdown) |
| **Node** | fnm · Node LTS · pnpm |
| **Editor** | Cursor (you can still use VS Code; same shortcuts/extensions) |
| **Terminals** | iTerm2 · Termius (SSH client) |
| **AI Tools** | Claude Desktop · Claude Code · ChatGPT · Codex |
| **Mobile** | Watchman · adb (via android-platform-tools) — **no Xcode, no Android Studio** |
| **Database & API** | Beekeeper Studio · Bruno |
| **Deploy CLIs** | vercel · netlify-cli · wrangler · eas-cli · supabase · firebase-cli |
| **Design** | Figma desktop (Canva stays in browser) |
| **Notes & Research** | Obsidian · Zotero |
| **Productivity** | Raycast · OrbStack · Arc browser |
| **Media** | Discord · Spotify · Spicetify · Stremio |
| **Office** | Microsoft Office (Word/Excel/PowerPoint) · OneDrive |

---

## Why These Choices

This setup is opinionated for the constraints. Every "yes" has a "no" behind it:

- **fnm over nvm**: faster shell startup on M2; written in Rust.
- **pnpm over npm/yarn**: hardlinks packages across projects. Saves 30-80GB over a year on a 256GB SSD.
- **Starship, no Oh My Zsh**: OMZ slows shell startup with hundreds of plugins you'll never use. Starship gives you the prompt without the bloat.
- **No Xcode, no Android Studio**: Expo Go on your physical phone + EAS Build (cloud) covers 90% of mobile dev. Saves ~30GB. Install Xcode the day you actually need a custom dev client.
- **OrbStack over Docker Desktop**: Docker Desktop hammers 8GB RAM. OrbStack does the same job with a fraction of the memory.
- **No Rectangle, no Magnet**: macOS 26 Tahoe has mature native window tiling (drag-to-edge, green button menus, Globe+Ctrl+arrows). Third-party tools are redundant now.
- **No The Unarchiver**: macOS handles .zip natively, dev work rarely involves .rar. Install on demand if you ever hit one.
- **Arc browser, but be aware**: Arc entered maintenance mode in May 2025 after Atlassian's acquisition of The Browser Company. Still works, still gets Chromium security patches, no new features. Zen Browser (open-source, Firefox-based, similar UI) is the migration path if you want active development.
- **Termius over OpenSSH-only**: native macOS SSH works, but Termius adds key management, host snippets, and a UI for when you're juggling multiple servers (Render, Cloudflare, etc.).
- **Two coding agents (Claude Code + Codex)**: they overlap in capability but feel different in practice. Claude Code is stronger at multi-file reasoning across large codebases; Codex is strong at debugging and code analysis. Both via Homebrew casks: clean install, but you run `brew upgrade claude-code codex` periodically (no auto-update). Each requires its own paid account (Claude Pro/Max for Claude Code, ChatGPT Plus or higher for Codex), or an API key.
- **Two desktop chat apps (Claude + ChatGPT)**: small disk cost, different strengths. ChatGPT has Option+Space global hotkey for quick questions; Claude Desktop has MCP support for connecting to your tools.
- **Spicetify warning**: customizes Spotify but Spotify auto-updates wipe changes. You'll re-run `spicetify backup apply` after every Spotify update.
- **Cursor over VS Code**: same shortcuts, same extensions, better AI integration. Free tier is plenty to start.
- **Bruno over Postman**: free, faster, files stored in your repo (versioned with git), no forced login.
- **Beekeeper Studio over TablePlus**: TablePlus is freemium (2-tab limit on free tier). Beekeeper Studio is fully free, open source, similar UI quality.
- **Obsidian over Notion (for drafts)**: local markdown files you own. Keep Notion for your poetry website CMS; draft in Obsidian, publish to Notion.

---

## Constraints Respected

- **Apple Silicon only** — every formula installs to `/opt/homebrew`, no Rosetta
- **8GB RAM discipline** — no Docker Desktop, no MongoDB/MySQL services running in background, no Android emulator unless you choose to install one later
- **256GB SSD discipline** — pnpm by default, Xcode/Android Studio skipped, cleanup utilities included

---

## How the Script Works

19 sections, all optional and resumable. Completed steps are tracked in `~/.devsetup_state` — re-run anytime, finished work is skipped.

```
  ╔══════════════════════════════════════════════════════════╗
  ║         Mac M2 Dev Setup — Web + Expo + Writing          ║
  ╚══════════════════════════════════════════════════════════╝

  Installation Menu
  ✔ 01 · Foundation (Xcode CLT + Homebrew)
  ✔ 02 · Core CLI Tools
  ○ 03 · Shell Prompt (Starship)
  ...

  [A] Install All    [R] Reset state    [Q] Quit    [01-19] Jump
```

---

## All 19 Sections

| # | Section | Installs |
|---|---|---|
| 01 | Foundation | Xcode CLT · Homebrew |
| 02 | Core CLI | git · gh · ripgrep · fd · bat · eza · fzf · zoxide · jq · tldr · JetBrains Mono NF |
| 03 | Shell | Starship + minimal config |
| 04 | Node | fnm · Node LTS · pnpm |
| 05 | Git + GitHub | global config · ed25519 SSH key · gh auth |
| 06 | Editor | Cursor + recommended extensions |
| 07 | Terminals | iTerm2 · Termius |
| 08 | AI Tools | Claude Desktop · Claude Code · ChatGPT · Codex (paid accounts required for the CLIs) |
| 09 | Mobile (Expo path) | watchman · android-platform-tools (adb) |
| 10 | Database + API | Beekeeper Studio · Bruno |
| 11 | Deploy CLIs | vercel · netlify-cli · wrangler · eas-cli · supabase · firebase-cli |
| 12 | Design | Figma |
| 13 | Notes, Poetry & Research | Obsidian · Zotero |
| 14 | Productivity | Raycast · OrbStack · Arc browser |
| 15 | Media & Communication | Discord · Spotify · Spicetify · Stremio |
| 16 | Office + OneDrive | Microsoft Office suite · OneDrive |
| 17 | Folders | `~/Developer/` and `~/Writing/` structure + `.env.template` |
| 18 | Aliases | aliases appended to `~/.zshrc` |
| 19 | Cleanup | brew cleanup · pnpm store prune · npm cache · disk report |

---

## Folder Structure

```
~/Developer/
├── web/
│   ├── next/              # Next.js + TS apps
│   └── express/           # Node/Express APIs
├── mobile/
│   └── expo/              # React Native + Expo
├── scripts/               # Automation
├── labs/                  # Experiments
├── work/                  # Client / job projects
├── university/            # Coursework
├── archive/               # Old projects
└── .envs/
    └── .env.template      # Shared env keys (Supabase, Firebase, Notion, etc.)

~/Writing/
├── poetry/
│   ├── drafts/            # Work-in-progress poems (markdown)
│   └── published/         # Poems shipped to your Notion CMS
├── notes/                 # Student notes
└── essays/                # Long-form writing
```

---

## Key Aliases

```bash
# Navigation
dev            cd ~/Developer
write          cd ~/Writing
ll             eza -la --icons --git
lt             eza --tree --level=2 --icons

# Git
gs             git status
gc             git commit -m
gp             git push
gl             git pull

# pnpm
pn             pnpm
pnd            pnpm dev
pnb            pnpm build
pni            pnpm install

# Expo
exs            pnpm expo start
exa            pnpm expo start --android
exi            pnpm expo start --ios
exb            eas build --platform all

# Disk hygiene
dud            du -sh * | sort -h
clean-node     remove node_modules in current tree
clean-pnpm     pnpm store prune
clean-expo     clear Expo cache
clean-derived  clear Xcode DerivedData
clean-all      run all cleanups + brew cleanup

# Shell
zconf          edit .zshrc in Cursor
zreload        source ~/.zshrc
```

---

## Mobile Dev Workflow (No SDKs Required)

You have:
- **Nothing Phone 3a** (Android, primary daily driver)
- **iPhone XR** (iOS test device)

The setup uses both phones as your dev fleet:

```
Cursor on Mac  →  pnpm start  →  Expo dev server
                                       │
                          ┌────────────┴────────────┐
                          ↓                         ↓
                 Expo Go on Nothing       Expo Go on iPhone XR
                       (Android)                   (iOS)
                          │                         │
                          └─────────  WiFi  ────────┘
```

**Production builds** go through EAS (cloud):

```bash
eas build --profile preview --platform all
# Get download links by email
# Android: install APK directly on Nothing
# iOS: install via TestFlight on iPhone XR
```

You touch Xcode and Android Studio **only** when you need a custom dev client (rare for typical apps). Until then, you save 25-30GB on disk.

---

## Memory Guide

| State | Expected RAM |
|---|---|
| Idle | < 3 GB |
| Cursor + Next.js dev server | < 5 GB |
| Cursor + Expo dev server + Expo Go on phone | < 5 GB |
| Cursor + Next.js + Bruno + Beekeeper + Figma | < 7 GB |
| ⚠️ Add Chrome with 30 tabs | swap territory |

**Survival rule**: close Chrome tabs, not your dev server.
**Monitor**: `memcheck` (alias) for swap pressure.

---

## After Running the Script

| # | Action |
|---|---|
| 1 | Restart your terminal (or `source ~/.zshrc`) |
| 2 | `gh auth login` — sign in to GitHub CLI |
| 3 | `vercel login` · `netlify login` · `wrangler login` · `eas login` · `supabase login` · `firebase login` |
| 4 | Open Cursor, sign in, install recommended extensions (commands printed during install) |
| 5 | Open Claude Desktop, ChatGPT, Claude Code, and Codex; sign in to each (paid accounts needed for the CLIs). Verify with `claude doctor` and `codex --version`. |
| 6 | Sign in to Microsoft Office (use your school account if your university provides Microsoft 365 free) |
| 7 | Open OneDrive, choose folders to sync — **avoid `~/Developer/` to skip syncing `node_modules`** |
| 8 | Launch Spotify once to initialize its data folders, quit it, then run `spicetify backup apply` |
| 9 | Open Obsidian → create vault at `~/Writing/vault` |
| 10 | Open Zotero → install the browser connector for Arc: https://www.zotero.org/download/connectors |
| 11 | Open Beekeeper Studio → connect your Supabase Postgres (Settings → Database → connection string) |
| 12 | Test Expo end-to-end:<br>`pnpm dlx create-expo-app test-app && cd test-app && pnpm start`<br>Scan QR with Expo Go on your Nothing Phone and iPhone XR |
| 13 | (Optional) Create dotfiles repo: `cd ~ && git init dotfiles` |

---

## Requirements

- MacBook with Apple Silicon (M1 / M2 / M3 / M4)
- macOS Ventura 13 or newer (macOS 26 Tahoe recommended)
- Internet connection
- ~15 GB free disk space for the full install (Office alone is ~3GB; skip section 16 to halve this)
- Paid Claude account (Pro/Max) for Claude Code, paid ChatGPT account (Plus or higher) for Codex; everything else works without paid accounts

---

## What's Deliberately Excluded

These were in the old script and are **gone for good reason**:

- **Java / .NET / Tomcat** — not in your stack
- **MongoDB / MySQL** — you use Postgres via Supabase
- **Anaconda + full Python AI stack** — too heavy for 8GB; install per-project with `uv` or `pyenv` if needed
- **Ollama + multiple LLMs** — 7B models alone push your RAM into swap; use cloud LLMs (Claude Code does this for you)
- **Hardhat / Solidity** — not in your stack
- **Flutter** — you chose React Native + Expo
- **Android Studio + Xcode** — Expo Go + EAS Build replaces both for 90% of mobile dev
- **Docker Desktop** — OrbStack does the same job, half the RAM
- **Oh My Zsh** — measurable shell startup slowdown; Starship alone is enough
- **Rectangle / Magnet** — macOS 26 Tahoe has native window tiling now
- **The Unarchiver** — macOS handles .zip natively; install on demand for .rar
- **Roblox** — not a dev tool

If you ever need any of the above, install on demand. Don't carry them by default.

---

## License

MIT — use it, fork it, strip it down further.

*Built for a Mac that has work to do.*
