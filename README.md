# Dotfiles (chezmoi)

This directory contains dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Quick Reference

### Daily Workflow

```bash
# Edit a file (opens source file in editor)
chezmoi edit ~/.zshrc

# Or open this directory as IDE project
code ~/.local/share/chezmoi

# Preview what would change
chezmoi diff

# Apply changes to home directory
chezmoi apply
```

### Important

**Never edit files directly in home directory** (e.g., `~/.zshrc`).
Always edit the source files here, then run `chezmoi apply`.

### Managed Files

**Shell Configuration:**
- `dot_zshrc` -> `~/.zshrc`
- `dot_zshenv` -> `~/.zshenv`
- `dot_zprofile` -> `~/.zprofile`
- `dot_zsh.d/*` -> `~/.zsh.d/*`

**Git Configuration:**
- `dot_gitconfig` -> `~/.gitconfig`
- `dot_gitignore_global` -> `~/.gitignore_global`
- `dot_gitattributes_global` -> `~/.gitattributes_global`

### Common Commands

| Command | Description |
|---------|-------------|
| `chezmoi diff` | Show pending changes |
| `chezmoi apply` | Apply changes to home |
| `chezmoi edit FILE` | Edit source file |
| `chezmoi verify` | Check for drift |
| `chezmoi doctor` | Diagnose problems |
| `chezmoi cd` | Change to source dir |

### Configuration

Config file: `~/.config/chezmoi/chezmoi.toml`
- `autoCommit = true` - Auto-commits source changes
- `autoPush = false` - Manual push (safety)

## Migration Status

- [x] Shell files (.zshrc, .zshenv, .zprofile, zsh.d/)
- [x] Git config (.gitconfig, .gitignore_global, .gitattributes_global)
- [ ] Templating (Phase 3)
- [ ] Package management (Phase 4)
- [ ] Tool versions (Phase 5)
- [ ] Secrets (Phase 6)
