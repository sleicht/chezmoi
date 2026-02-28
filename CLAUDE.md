# CLAUDE.md

This file provides guidance to AI coding agents working with this repository.
The filename stays `CLAUDE.md` for tool compatibility, and `AGENTS.md` points here.

## What This Is

A chezmoi dotfiles repository. Source files here deploy to `~/` via `chezmoi apply`. Never edit target files in `~/` directly — always edit source files in this repo.

## Commands

```bash
# Daily workflow (via mise shortcuts)
mise run d                # preview pending changes (dotfiles:diff)
mise run a                # deploy configs (dotfiles:apply)
mise run v                # run verification checks (dotfiles:verify)
mise run s                # full sync: backup → pull → apply → verify
mise run c                # guided conventional commit with Jira prefix
mise run b                # create feature branch
mise run git:pr           # create PR/MR (auto-detects gh/glab)
topgrade                  # update all tools (Homebrew, mise, chezmoi, sheldon)
topgrade -n               # dry-run preview

# Raw chezmoi (for advanced use)
chezmoi diff              # preview pending changes
chezmoi apply             # deploy to home directory
chezmoi apply --dry-run   # simulate apply without writing
chezmoi doctor            # diagnose problems
chezmoi verify            # check for drift from source

# Pre-commit hooks
pre-commit install --hook-type pre-commit --hook-type pre-push
pre-commit run --all-files   # run all checks manually
```

> **Note:** Commands that expand chezmoi templates (`chezmoi diff`, `chezmoi apply`, `mise run d`, `mise run a`, `mise run s`) require the rbw agent to be running and unlocked (`rbw unlock`). Automated agents typically cannot unlock or access your vault, so run these commands manually in a terminal.

## Architecture

### Chezmoi Naming Conventions

Source files use chezmoi prefixes that transform on apply:

| Prefix | Effect | Example |
|--------|--------|---------|
| `dot_` | Becomes `.` | `dot_zshrc` → `~/.zshrc` |
| `private_dot_` | Hidden + restricted perms | `private_dot_config/` → `~/.config/` |
| `executable_` | Sets +x | `executable_pre-commit` |
| `.tmpl` suffix | Go template processing | `path.zsh.tmpl` |
| `run_once_` | Runs once ever | `run_once_before_install-homebrew.sh.tmpl` |
| `run_onchange_` | Runs when content hash changes | `run_onchange_after_01-install-packages.sh.tmpl` |
| `run_after_` | Runs on every apply | `run_after_10-verify-permissions.sh.tmpl` |

### Template System

- **`.chezmoi.yaml.tmpl`** — master config; prompts for machine type on `chezmoi init`
- **`.chezmoidata.yaml`** — static data (package lists, tool versions, bitwarden folders); ~6300 lines
- **`.chezmoiignore`** — controls which files deploy; 11 sections with OS-conditional rules

Templates use Go template syntax with these key variables:
- `.machine_type` — `"client"` (work) or `"personal"`
- `.personal_email`, `.work_email` — set during init
- `.chezmoi.os` — `"darwin"` or `"linux"`
- `.chezmoi.homeDir` — home directory path

### Machine-Aware Configuration

The Brewfile, git config, and run scripts conditionally include content based on `.machine_type`. When editing `.chezmoidata.yaml`, package lists are scoped:
- `darwin.common_*` — all machines
- `darwin.client_*` — work machines only
- `darwin.personal_*` — personal machines only

### Encryption

Sensitive files use age encryption. The identity key lives outside chezmoi at `~/.config/age/key-{machine_type}.txt`.

### Shell Configuration

ZSH config is modular: `dot_zshrc` loads Sheldon (plugin manager with deferred loading via `zsh-defer`), which sources `dot_zsh.d/*.zsh` modules. Plugin definitions live in `private_dot_config/sheldon/plugins.toml`. Mise tasks are file-based scripts in `private_dot_config/mise/tasks/` deployed by chezmoi.

### Project Picker

```bash
pj                        # fzf-based project picker
```

- Discovers git repos under `~/Projects` and `~/git`
- Sorted by zoxide frecency
- Shows branch, dirty status, relative time

### Run Scripts

Seven lifecycle scripts execute during `chezmoi apply` in order: Homebrew bootstrap → package install → cleanup → permission verification. All are templated (`.tmpl`) and OS-conditional.

## Key Conventions

- **autoCommit is on** — chezmoi auto-commits source changes on `chezmoi edit`/`chezmoi add`, but does NOT auto-push
- **`edit.apply: false`** — editing source files does not auto-apply; you must run `chezmoi apply` manually
- **Gitleaks allowlist** — `.gitleaks.toml` allowlists chezmoi template expressions (`{{rbw.*}}`, `{{chezmoi.*}}`); update it if adding new secret template patterns
- **Permission verification** — `run_after_10-verify-permissions.sh.tmpl` enforces 600/700 on sensitive files after every apply
