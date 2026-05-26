# Mac Dev Setup

> Web (Next.js · Express · Node · Firebase · TS) + Mobile (Expo · React Native · Firebase · TS)
> Student: Notion · MS Word · iWork
> Apple Silicon · 8 GB RAM · 245 GB SSD

A flat, sequential installer — one file, runs top to bottom, no menu. Idempotent: re-run anytime, already-installed packages are skipped.

---

## Quick Start

```bash
chmod +x setup.sh
./setup.sh
```

Runs sequentially. Idempotent — re-run anytime; already-installed packages are skipped automatically.

---

## What Gets Installed

| Layer                | Tools                                                                                                      |
| -------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Foundation**       | Xcode CLT · Homebrew                                                                                       |
| **CLI + Shell**      | git · gh · ripgrep · fd · bat · eza · fzf · zoxide · jq · tldr · starship · mas · JetBrains Mono Nerd Font |
| **Node**             | fnm · Node LTS · **pnpm**                                                                                  |
| **Editors**          | **Cursor + VS Code** (both)                                                                                |
| **Terminal**         | iTerm2                                                                                                     |
| **AI Tools**         | Claude Desktop · Claude Code · **ChatGPT Desktop** (no Codex CLI)                                          |
| **Mobile (Expo)**    | watchman · android-platform-tools (adb) — no Xcode, no Android Studio                                      |
| **Databases**        | **PostgreSQL 17** (for Prisma) + **MySQL**                                                                 |
| **DB GUI + API**     | Beekeeper Studio · Bruno                                                                                   |
| **Deploy CLIs**      | vercel · **wrangler** · eas-cli · firebase-cli                                                             |
| **Design**           | Figma                                                                                                      |
| **Notes + Research** | Notion · Obsidian · Zotero                                                                                 |
| **Productivity**     | Raycast · OrbStack · Arc                                                                                   |
| **Media**            | Discord · Spotify · Spicetify (curl installer) · Stremio                                                   |
| **Docs**             | MS Word · Apple Pages · Keynote · Numbers (via `mas`)                                                      |
| **Cloud Drives**     | OneDrive · Google Drive                                                                                    |

---

## Why These Choices

- **pnpm over npm**: hardlinks across projects — saves 30–80GB/year on a 245GB SSD.
- **fnm over nvm**: faster shell startup; Rust-native.
- **PostgreSQL native, not Docker**: lighter on 8GB RAM than a Postgres container.
- **PostgreSQL + MySQL (both)**: Postgres for Prisma/production work, MySQL for school coursework or legacy projects.
- **Cursor + VS Code (both)**: same extensions/shortcuts. Cursor for AI-heavy edits, VS Code as the always-stable fallback. Together ~1.5 GB, worth the disk.
- **Claude Code + Claude Desktop + ChatGPT Desktop (no Codex CLI)**: two AI sources without paying for two CLI subscriptions. ChatGPT free-tier desktop covers occasional questions; Claude Code is your primary coding agent.
- **Notion + Obsidian + Zotero**: Notion for active study, Obsidian for offline markdown backup, Zotero for citation work.
- **OrbStack over Docker Desktop**: half the RAM on 8GB.
- **Starship, no Oh My Zsh**: measurably faster shell startup.
- **No Termius**: macOS native `ssh` + `~/.ssh/config` is enough; add later if you start managing servers.
- **No iWork via cask**: installed via `mas` (Mac App Store CLI) because that's where Apple ships them — free with your Apple ID.

---

## Folder Structure

Flat. Two top-level project roots.

```
~/Developer/    # all coding projects (web · mobile · scripts · experiments)
~/University/   # coursework · notes · papers
```

Notion holds active notes; the filesystem holds your code. Obsidian vault location is your call.

---

## Aliases (cheat sheet)

```bash
# Navigation
dev            cd ~/Developer
uni            cd ~/University
..  ...        cd .. / cd ../..

# Better defaults
ls / ll        eza (icons + git)
cat            bat
find           fd

# pnpm — Next.js / Express / Node
pn             pnpm
pni / pnid     pnpm install / pnpm add -D
pnr            pnpm run
pnd            pnpm dev
pnb            pnpm build
pns            pnpm start
pnt            pnpm test

# Prisma
px / pxg / pxm / pxs       npx prisma { · generate · migrate dev · studio }

# PostgreSQL
pgup           brew services start postgresql@17
pgdown         brew services stop postgresql@17
pgstatus       brew services info postgresql@17
psqlroot       psql postgres

# MySQL
mysqlup        mysql.server start
mysqldown      mysql.server stop
mysqlstatus    mysql.server status
mysqlroot      mysql -u root -p

# Expo
exs / exa / exi   pnpm expo start { · --android · --ios }
exb               eas build --platform all

# Firebase
fbd / fbe / fbl   firebase deploy / emulators:start / login

# Git
gs / gco / gp / gl / gb / gd / glog
gcp "msg"      add + commit + push current branch
gundo          undo last commit (keep staged)
gsync          merge origin/main into current branch
git-branch     interactive branch manager (switch / create / delete / rename)

# System
ip · ports · memcheck · cleanup · zconf · zreload

# Functions
serve [port]   quick http server (default 3000)
myip           local + public IP
mkcd <dir>     mkdir -p + cd
port <n>       kill process on port n
```

---

## After Running

```bash
source ~/.zshrc          # or restart terminal
gh auth login            # GitHub CLI
vercel login             # Web deploys (Next.js)
wrangler login           # Cloudflare Workers
eas login                # Expo builds
firebase login           # Firebase

claude doctor            # verify Claude Code
createdb $USER           # so 'psql' works with no args
mysql_secure_installation  # MySQL first-time security

# Sign in to GUIs
# Cursor · VS Code · Claude · ChatGPT · Notion · Obsidian · MS Word · OneDrive · Google Drive

# Spotify + Spicetify
# 1. open Spotify, sign in, then quit it
# 2. spicetify backup apply
# (re-run after every Spotify auto-update)

# Smoke tests
pnpm dlx create-next-app@latest demo-web --typescript
cd demo-web && pnd                                  # next dev

cd ~/Developer
pnpm dlx create-expo-app demo-mobile
cd demo-mobile && exs                               # scan QR with Expo Go
```

---

## Notes on Versioning

- **PostgreSQL 17**: Homebrew dropped the unversioned `postgresql` formula a while back; you must specify a major version. `postgresql@17` is the latest stable formula. Bump to `@18` (and update the aliases) when it ships.
- Everything else uses unpinned brew formulae and casks — `brew update && brew upgrade` periodically.

---

## The `.zshrc` File

`setup.sh` appends a marked block (`# === V2 SETUP ===` … `# === END V2 SETUP ===`) to your existing `~/.zshrc`. Safe to re-run — duplicate-guarded by the marker.

A standalone reference is included as `.zshrc` at the repo root. Copy it over for a clean shell config (back up your existing one first).

---

## Approximate Disk Footprint

|                                                      |            |
| ---------------------------------------------------- | ---------- |
| Homebrew + CLI tools                                 | ~1.5 GB    |
| Cursor + VS Code + iTerm2 + Raycast                  | ~2.0 GB    |
| Claude + Claude Code + ChatGPT                       | ~1.2 GB    |
| Notion + Obsidian + Zotero                           | ~0.8 GB    |
| MS Word + iWork (Pages/Keynote/Numbers)              | ~1.5 GB    |
| OneDrive + Google Drive (apps, not synced files)     | ~0.3 GB    |
| Figma + Arc + Discord + Spotify + Stremio + OrbStack | ~2.0 GB    |
| PostgreSQL + MySQL + Beekeeper + Bruno               | ~1.0 GB    |
| Node + global CLIs                                   | ~0.5 GB    |
| **Total apps**                                       | **~11 GB** |

Leaves ~230 GB for projects and cloud-synced docs.

---

## License

MIT.
