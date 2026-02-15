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

| Category | Tools |
|----------|-------|
| **Shell** | ZSH · `.profile` (POSIX base env) · [Sheldon](https://sheldon.cli.rs/) (plugin manager, cached source) · [Oh My Posh](https://ohmyposh.dev/) (prompt) · [zsh-defer](https://github.com/romkatv/zsh-defer) (lazy loading) · [evalcache](https://github.com/mroth/evalcache) (cached eval inits) |
| **Terminal** | [Ghostty](https://ghostty.org/) · [Kitty](https://sw.kovidgoyal.net/kitty/) · [WezTerm](https://wezfurlong.org/wezterm/) |
| **Editor** | EditorConfig · [aider](https://aider.chat/) (AI pair programming) |
| **Git** | [Lazygit](https://github.com/jesseduffield/lazygit) · [Gitleaks](https://gitleaks.io/) (secret scanning) · global config + hooks |
| **Dev Tools** | [mise](https://mise.jdx.dev/) (runtime manager + task runner) · [bat](https://github.com/sharkdp/bat) · [lsd](https://github.com/lsd-rs/lsd) · [btop](https://github.com/aristocratos/btop) · [atuin](https://atuin.sh/) (shell history) · [worktrunk](https://worktrunk.dev/) (git worktree manager) |
| **macOS** | [Homebrew](https://brew.sh/) (Brewfile) · [AeroSpace](https://github.com/nikitabobko/AeroSpace) (tiling WM) · [Karabiner-Elements](https://karabiner-elements.pqrs.org/) · [Finicky](https://github.com/nickmilo/finicky) (browser routing) |
| **Security** | age encryption for SSH keys · Bitwarden for secrets · permission hardening |

## 🚀 Getting Started

### Fresh Machine Setup

```bash
# install chezmoi and initialise from this repo
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply sleicht/chezmoi
```

You'll be prompted for machine type (`personal` / `client`) and email addresses.

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
├── dot_Brewfile.tmpl                  # → ~/.Brewfile (machine-aware packages)
├── private_dot_config/                # → ~/.config/
│   ├── sheldon/plugins.toml           #   plugin manager (sync + defer groups)
│   ├── ghostty/config                 #   terminal config
│   ├── mise/config.toml.tmpl          #   runtime versions
│   ├── mise/tasks/                    #   mise task scripts (dotfiles, git)
│   ├── worktrunk/config.toml          #   git worktree manager config
│   └── ...                            #   + 10 more tools
├── private_dot_ssh/                   # → ~/.ssh/
│   ├── encrypted_private_config.age   #   age-encrypted SSH config
│   └── encrypted_*.age                #   age-encrypted private keys
├── run_once_before_*                  # bootstrap scripts (Homebrew, bw-wrapper, etc.)
├── run_once_after_*                   # one-time cleanup scripts
├── run_onchange_after_*               # package install/cleanup/evalcache on change
└── run_after_*                        # permission hardening on every apply
```

## 🖥️ Machine Types

Configs adapt based on machine type (set during `chezmoi init`):

| | `personal` | `client` (work) |
|--|------------|------------------|
| **Packages** | `fanaka_*` + `common_*` | `client_*` + `common_*` |
| **Git email** | personal | work |
| **Age key** | `key-personal.txt` | `key-client.txt` |
| **Extra tools** | personal apps | work-specific apps |

## 🔒 Security

- **SSH keys** — age-encrypted at rest, decrypted on `chezmoi apply`
- **SSH config** — age-encrypted (hides hostnames, IPs, network topology)
- **Secrets** — pulled from Bitwarden at apply time via templates
- **Permissions** — `run_after_` script enforces 600/700 on sensitive files
- **Pre-commit** — gitleaks scans every commit for accidental secret exposure

## 🎯 Task Runner Reference

All tasks are file-based scripts in `~/.config/mise/tasks/`, deployed by chezmoi. Run `mise tasks` to list them.

| Task | Alias | Description |
|------|-------|-------------|
| `dotfiles:apply` | `a` | Deploy configs with verbose output |
| `dotfiles:diff` | `d` | Preview changes before applying |
| `dotfiles:verify` | `v` | Run 112 verification checks |
| `dotfiles:smoke-test` | — | Validate shell functionality |
| `dotfiles:update` | `u` | Pull remote + apply in one step |
| `dotfiles:sync` | `s` | Full sync: backup → pull → apply → verify |
| `git:commit` | `c` | Guided conventional commit with Jira prefix (AI or manual) |
| `git:branch` | `b` | Create feature branch with naming convention |
| `git:cleanup` | — | Prune merged local branches (safe delete) |
| `git:pr` | — | Create PR/MR via gh or glab (auto-detects platform) |

Git tasks offer **hybrid AI/manual mode** — when `claude` CLI is available, AI generates commit messages from diffs and converts descriptions to kebab-case branch names. Falls back to interactive `fzf` prompts otherwise.
