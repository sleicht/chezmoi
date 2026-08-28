# 🏠 Dotfiles

[![chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-blue?logo=homeassistant&logoColor=white)](https://www.chezmoi.io/)
[![macOS](https://img.shields.io/badge/macOS-Tahoe-000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/shell-zsh-green?logo=gnubash&logoColor=white)](https://www.zsh.org/)
[![License](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)

Personal dotfiles for macOS, managed with [chezmoi](https://www.chezmoi.io/) and encrypted with [age](https://age-encryption.org/).

**[@sleicht](https://github.com/sleicht)** · Stephan Leicht Vogt · [Fanaka GmbH](https://fanaka.ch)

> **Note:** These are my personal dotfiles, tailored to my workflow and preferences. You're welcome to fork, browse, or borrow ideas — but this isn't a supported project. No pull requests, issues, or support are expected.

---

## ✨ What's Inside

| Category      | Tools                                                                                                                                                                                                                                                                                                                                                                            |
|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Shell**     | ZSH · `.profile` (POSIX base env) · [Sheldon](https://sheldon.cli.rs/) (plugin manager, cached source) · [Spaceship](https://spaceship-prompt.sh/) (prompt) · [zsh-defer](https://github.com/romkatv/zsh-defer) (lazy loading) · [evalcache](https://github.com/mroth/evalcache) (cached eval inits) · `pj` (fzf project picker)                                                       |
| **Terminal**  | [Ghostty](https://ghostty.org/) · [Kitty](https://sw.kovidgoyal.net/kitty/) · [WezTerm](https://wezfurlong.org/wezterm/)                                                                                                                                                                                                                                                         |
| **Editor**    | EditorConfig · [aider](https://aider.chat/) (AI pair programming)                                                                                                                                                                                                                                                                                                                |
| **Git**       | [Lazygit](https://github.com/jesseduffield/lazygit) · [Gitleaks](https://gitleaks.io/) (secret scanning) · global config + hooks                                                                                                                                                                                                                                                 |
| **Dev Tools** | [mise](https://mise.jdx.dev/) (runtime manager + task runner) · [topgrade](https://github.com/topgrade-rs/topgrade) (all-in-one updater) · [bat](https://github.com/sharkdp/bat) · [lsd](https://github.com/lsd-rs/lsd) · [btop](https://github.com/aristocratos/btop) · [atuin](https://atuin.sh/) (shell history) · [worktrunk](https://worktrunk.dev/) (git worktree manager) |
| **macOS**     | [Homebrew](https://brew.sh/) (Brewfile) · [Hyprspace](https://hyprspace.net/) (tiling WM) · [SketchyBar](https://github.com/FelixKratz/SketchyBar) (status bar) · [Karabiner-Elements](https://karabiner-elements.pqrs.org/) · [Finicky](https://github.com/nickmilo/finicky) (browser routing)                                                                |
| **Security**  | age encryption for SSH keys · Bitwarden for secrets · permission hardening                                                                                                                                                                                                                                                                                                       |

## 🚀 Getting Started

### Fresh Machine Setup

#### Prerequisites

Two tools must be installed and configured **before** `chezmoi init` — templates pull secrets from Bitwarden at render time, which happens before any package-install scripts run.

**1. Homebrew** (if not already installed)

```bash
# macOS / Linux
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

> On Linux, follow the "Next steps" printed by the installer to add Homebrew to your PATH.

**2. rbw** (Rust Bitwarden CLI)

```bash
brew install rbw
rbw config set email <your-bitwarden-email>
rbw login
rbw unlock
rbw sync
```

**3. age private key** — must be placed manually. See [Age Encryption Bootstrap](#-security) below.

#### Install

```bash
# install chezmoi and initialise from this repo
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply sleicht/chezmoi
```

You'll be prompted for machine type (`personal` / `client` / `server` / `container`) and email addresses.

### Docker / Container

Use the `container` machine type for a minimal shell experience without Homebrew, secrets, or run scripts:

```dockerfile
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y zsh curl git \
 && sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply \
      --promptString machine_type=container \
      --promptString 'Personal email address=' \
      --exclude=encrypted \
      sleicht/chezmoi \
 && chsh -s "$(command -v zsh)"
```

This deploys only shell config (zsh, sheldon plugins, Spaceship prompt, git config) — no encrypted files, desktop apps, or package management.

### Existing Machine

```bash
chezmoi init sleicht/chezmoi
chezmoi diff    # preview changes
chezmoi apply   # deploy
```

### Forking

If you'd like to use this as a starting point for your own dotfiles:

1. Fork this repository
2. Replace `.chezmoidata.yaml` with your own package lists
3. Update `.chezmoi.yaml.tmpl` with your own prompts and age recipient
4. Remove or replace the encrypted files (`encrypted_*.age`) with your own
5. Run `chezmoi init --apply <your-username>/chezmoi`

## 🔧 Daily Workflow

Common operations are wrapped as [mise tasks](https://mise.jdx.dev/tasks/) with short aliases:

```bash
mise run d                # preview pending changes (dotfiles:diff)
mise run a                # deploy configs (dotfiles:apply)
mise run v                # run 112 verification checks (dotfiles:verify)
mise run s                # full sync: backup → pull → apply → verify (dotfiles:sync)
```

Git workflows with conventional commit enforcement:

```bash
mise run c                # guided conventional commit with Jira prefix (git:commit)
mise run b                # create feature branch with naming convention (git:branch)
mise run git:pr           # create PR/MR via gh or glab (auto-detects platform)
mise run git:cleanup      # prune merged local branches
```

Navigate projects with the fzf-based project picker:

```bash
pj                        # fzf picker: Enter=cd, Ctrl+E=editor, Ctrl+O=cd+editor, Ctrl+R=refresh
```

Discovers git repos under `~/Projects` and `~/git`, sorted by [zoxide](https://github.com/ajeetdsouza/zoxide) frecency. Shows branch, dirty status, relative time, and detected editor (IntelliJ/Sublime). Persistent disk cache with 1-hour TTL.

Update everything (Homebrew, mise, chezmoi, sheldon, etc.) in one go with [topgrade](https://github.com/topgrade-rs/topgrade):

```bash
topgrade                  # update all detected tools
topgrade -n               # dry-run — preview what would be updated
```

### SketchyBar (Status Bar)

[SketchyBar](https://github.com/FelixKratz/SketchyBar) provides a workspace-aware status bar driven by Hyprspace callbacks. After first `chezmoi apply`:

```bash
brew services start sketchybar    # start the bar service
brew services restart sketchybar  # restart after config changes
```

The bar displays active workspaces with app icons (via [sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font)), front app name, battery, volume, clock, and swap usage. The `icon_map_fn.sh` plugin and its companion font are managed by a `run_onchange_` script — not tracked in the chezmoi source — and automatically rebuilt when `sketchybarrc` changes.

> **Raw chezmoi** still works for anything not covered by tasks:
> ```bash
> chezmoi edit ~/.zshrc     # edit source file
> chezmoi re-add ~/.zshrc   # pull direct edits back into source
> ```

## 📁 Structure

```
.
├── dot_profile.tmpl                   # → ~/.profile (POSIX env vars + PATH)
├── dot_bash_profile                   # → ~/.bash_profile (sources .profile)
├── dot_zshenv                         # → ~/.zshenv (startup timing, zprof, PATH dedup)
├── dot_zprofile                       # → ~/.zprofile (Homebrew, mise shims)
├── dot_zshrc.tmpl                     # → ~/.zshrc (sources .profile, cached Sheldon)
├── dot_zlogin                         # → ~/.zlogin (background zcompile)
├── dot_zsh.d/                         # → ~/.zsh.d/ (modular ZSH config, sync/defer split)
│   ├── projects.zsh                   #   pj() project picker (deferred via Sheldon)
├── dot_Brewfile.tmpl                  # → ~/.Brewfile (machine-aware packages)
├── private_dot_config/                # → ~/.config/
│   ├── sheldon/plugins.toml           #   plugin manager (sync + defer groups)
│   ├── ghostty/config                 #   terminal config
│   ├── mise/config.toml.tmpl          #   runtime versions
│   ├── mise/tasks/                    #   mise task scripts (dotfiles, git, projects)
│   ├── hyprspace/config.toml           #   tiling WM + sketchybar callbacks
│   ├── sketchybar/sketchybarrc        #   status bar config
│   ├── sketchybar/plugins/            #   bar plugin scripts (workspace, app icons, battery, etc.)
│   ├── topgrade/topgrade.toml         #   all-in-one updater config
│   ├── worktrunk/config.toml          #   git worktree manager config
│   └── ...                            #   + 10 more tools
├── private_dot_ssh/                   # → ~/.ssh/
│   ├── private_config.tmpl            #   SSH config wrapper (Include per machine type)
│   ├── encrypted_private_config_*.age #   age-encrypted SSH configs (personal/client/server)
│   └── encrypted_*.age                #   age-encrypted private keys
├── run_once_before_*                  # bootstrap scripts (Homebrew, bw-wrapper, etc.)
├── run_once_after_*                   # one-time cleanup scripts
├── run_onchange_after_*               # package install/cleanup/evalcache on change
└── run_after_*                        # permission hardening on every apply
```

## 🖥️ Machine Types

Configs adapt based on machine type (set during `chezmoi init`):

|                 | `personal`                | `client` (work)         | `server`         | `container`              |
|-----------------|---------------------------|-------------------------|------------------|--------------------------|
| **Packages**    | `personal_*` + `common_*` | `client_*` + `common_*` | `common_*`       | none (apt in Dockerfile) |
| **Git email**   | personal                  | work                    | personal         | —                        |
| **Age key**     | `key-personal.txt`        | `key-client.txt`        | `key-server.txt` | none                     |
| **Encryption**  | age                       | age                     | age              | disabled                 |
| **SSH config**  | `config_personal`         | `config_client`         | `config_server`  | skipped                  |
| **Run scripts** | all                       | all                     | all              | skipped                  |
| **Extra tools** | personal apps             | work-specific apps      | minimal          | shell config only        |

## 🔒 Security

- **SSH keys** — age-encrypted at rest, decrypted on `chezmoi apply`
- **SSH config** — age-encrypted per machine type ([migration guide](docs/RUNBOOK-07-ssh-config-migration.md))
- **Secrets** — pulled from Bitwarden at apply time via templates
- **Permissions** — `run_after_` script enforces 600/700 on sensitive files
- **Pre-commit** — gitleaks scans every commit for accidental secret exposure

### Age Encryption Bootstrap

The age private key is the root of the secret chain — it must be placed manually before `chezmoi apply` can decrypt anything.

```
Bitwarden (dotfiles/shared/age-private-key)
  → manual copy to ~/.config/age/key-{machine_type}.txt
    → chezmoi reads identity from .chezmoi.yaml.tmpl
      → decrypts encrypted_*.age files (SSH keys, config)
        → SSH access unlocked
```

| What                       | Where                                                        |
|----------------------------|--------------------------------------------------------------|
| **Private key (on disk)**  | `~/.config/age/key-{machine_type}.txt` (600 perms)           |
| **Private key (backup)**   | Bitwarden item `age-private-key` in `dotfiles/shared` folder |
| **Public key (recipient)** | Hardcoded in `.chezmoi.yaml.tmpl`                            |
| **Encrypted files**        | `private_dot_ssh/encrypted_*.age` (5 files)                  |

> **Note:** Chezmoi does **not** fetch the age key from Bitwarden automatically. It is a manual one-time setup per machine. See the [bootstrap runbook](docs/RUNBOOK-02-bootstrap.md) for step-by-step instructions.

## 🎯 Task Runner Reference

All tasks are file-based scripts in `~/.config/mise/tasks/`, deployed by chezmoi. Run `mise tasks` to list them.

| Task                  | Alias | Description                                                |
|-----------------------|-------|------------------------------------------------------------|
| `dotfiles:apply`      | `a`   | Deploy configs with verbose output                         |
| `dotfiles:diff`       | `d`   | Preview changes before applying                            |
| `dotfiles:verify`     | `v`   | Run 112 verification checks                                |
| `dotfiles:smoke-test` | —     | Validate shell functionality                               |
| `dotfiles:update`     | `u`   | Pull remote + apply in one step                            |
| `dotfiles:sync`       | `s`   | Full sync: backup → pull → apply → verify                  |
| `git:commit`          | `c`   | Guided conventional commit with Jira prefix (AI or manual) |
| `git:branch`          | `b`   | Create feature branch with naming convention               |
| `git:cleanup`         | —     | Prune merged local branches (safe delete)                  |
| `git:pr`              | —     | Create PR/MR via gh or glab (auto-detects platform)        |
| `projects:pj`         | —     | Project picker usage instructions (run `pj` in shell)      |

Git tasks offer **hybrid AI/manual mode** — when `claude` CLI is available, AI generates commit messages from diffs and converts descriptions to kebab-case branch names. Falls back to interactive `fzf` prompts otherwise.
