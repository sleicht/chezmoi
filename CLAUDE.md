# CLAUDE.md

Chezmoi dotfiles repository. Source files here deploy to `~/` via `chezmoi apply`. Always edit source files in this repo, never target files in `~/`.

## Commands

```bash
mise run d                # preview pending changes
mise run a                # deploy configs
mise run v                # run verification checks
mise run s                # full sync: backup → pull → apply → verify
mise run c                # guided conventional commit with Jira prefix
mise run b                # create feature branch
mise run git:pr           # create PR/MR (auto-detects gh/glab)
```

> **Note:** Commands that expand templates (`chezmoi diff/apply`, `mise run d/a/s`) require `rbw unlock` first. Agents cannot unlock the vault — run these manually.

## Chezmoi Naming Conventions

| Prefix | Effect | Example |
|--------|--------|---------|
| `dot_` | Becomes `.` | `dot_zshrc` → `~/.zshrc` |
| `private_dot_` | Hidden + restricted perms | `private_dot_config/` → `~/.config/` |
| `executable_` | Sets +x | `executable_pre-commit` |
| `.tmpl` suffix | Go template processing | `path.zsh.tmpl` |
| `run_once_` | Runs once ever | `run_once_before_install-homebrew.sh.tmpl` |
| `run_onchange_` | Runs when content hash changes | `run_onchange_after_01-install-packages.sh.tmpl` |
| `run_after_` | Runs on every apply | `run_after_10-verify-permissions.sh.tmpl` |

## Templates

Key variables in Go templates:
- `.machine_type` — `"client"` (work) or `"personal"`
- `.chezmoi.os` — `"darwin"` or `"linux"`
- `.personal_email`, `.work_email` — set during `chezmoi init`

## Machine-Aware Configuration

Package lists in `.chezmoidata.yaml` are scoped:
- `darwin.common_*` — all machines
- `darwin.client_*` — work machines only
- `darwin.personal_*` — personal machines only

The Brewfile, git config, and run scripts conditionally include content based on `.machine_type`.

## Key Conventions

- **autoCommit is on** — chezmoi auto-commits on `chezmoi edit`/`chezmoi add`, does NOT auto-push
- **`edit.apply: false`** — editing source does not auto-apply; run `chezmoi apply` manually
- **Gitleaks allowlist** — `.gitleaks.toml` allowlists template expressions (`{{rbw.*}}`, `{{chezmoi.*}}`); update when adding new secret patterns
- **Permission verification** — `run_after_10-verify-permissions.sh.tmpl` enforces 600/700 on sensitive files after every apply
