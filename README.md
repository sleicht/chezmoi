# 🏠 Dotfiles

[![chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-blue?logo=homeassistant&logoColor=white)](https://www.chezmoi.io/)
[![macOS](https://img.shields.io/badge/macOS-Tahoe-000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Shell](https://img.shields.io/badge/shell-zsh-green?logo=gnubash&logoColor=white)](https://www.zsh.org/)
[![License](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)

Personal dotfiles for macOS, managed with [chezmoi](https://www.chezmoi.io/) and encrypted with [age](https://age-encryption.org/).

**[@sleicht](https://github.com/sleicht)** · Stephan Leicht Vogt · [Fanaka GmbH](https://fanaka.ch)

---

## ✨ What's Inside

| Category | Tools |
|----------|-------|
| **Shell** | ZSH · [Sheldon](https://sheldon.cli.rs/) (plugin manager) · [Oh My Posh](https://ohmyposh.dev/) (prompt) · [zsh-defer](https://github.com/romkatv/zsh-defer) (lazy loading) |
| **Terminal** | [Ghostty](https://ghostty.org/) · [Kitty](https://sw.kovidgoyal.net/kitty/) · [WezTerm](https://wezfurlong.org/wezterm/) |
| **Editor** | EditorConfig · [aider](https://aider.chat/) (AI pair programming) |
| **Git** | [Lazygit](https://github.com/jesseduffield/lazygit) · [Gitleaks](https://gitleaks.io/) (secret scanning) · global config + hooks |
| **Dev Tools** | [mise](https://mise.jdx.dev/) (runtime manager) · [bat](https://github.com/sharkdp/bat) · [lsd](https://github.com/lsd-rs/lsd) · [btop](https://github.com/aristocratos/btop) · [atuin](https://atuin.sh/) (shell history) |
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

## 🔧 Daily Workflow

```bash
chezmoi edit ~/.zshrc     # edit source file (auto-commits on save)
chezmoi diff              # preview pending changes
chezmoi apply             # deploy to home directory
```

> **Never edit files directly in `~/`** — always edit source files here, then apply.

## 📁 Structure

```
.
├── dot_zshrc                          # → ~/.zshrc (loads Sheldon + modules)
├── dot_zsh.d/                         # → ~/.zsh.d/ (modular ZSH config)
├── dot_Brewfile.tmpl                  # → ~/.Brewfile (machine-aware packages)
├── private_dot_config/                # → ~/.config/
│   ├── sheldon/plugins.toml           #   plugin manager config
│   ├── ghostty/config                 #   terminal config
│   ├── mise/config.toml.tmpl          #   runtime versions
│   └── ...                            #   + 10 more tools
├── private_dot_ssh/                   # → ~/.ssh/
│   ├── encrypted_private_config.age   #   age-encrypted SSH config
│   └── encrypted_*.age                #   age-encrypted private keys
├── run_once_before_*                  # bootstrap scripts (Homebrew, etc.)
├── run_onchange_after_*               # package install/cleanup on change
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
