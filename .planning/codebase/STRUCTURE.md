# Codebase Structure

**Analysis Date:** 2026-02-15

## Directory Layout

```
/Users/stephanlv_fanaka/.local/share/chezmoi/
├── .chezmoi.yaml.tmpl             # Master configuration template (init prompts)
├── .chezmoidata.yaml              # Shared static data (packages, tool versions)
├── .chezmoiignore                 # Deployment rules (what gets deployed to $HOME)
├── .claude/                        # Claude Code configuration and GSD framework
├── .planning/                      # Planning artifacts for GSD commands
├── dot_*.{,tmpl}                  # Shell config files (zshrc, profile, etc.)
├── private_dot_*/                 # Encrypted directories (config, ssh, gnupg)
├── run_*/*.sh.tmpl                # Lifecycle scripts (install, verify, cleanup)
├── scripts/                        # Utility scripts for development
├── CLAUDE.md                       # Project instructions for Claude
├── README.md                       # Repository documentation
├── LICENSE                         # MIT license
├── .git/                           # Git repository metadata
├── .gitignore                      # Git ignore rules
├── .gitleaks.toml                  # Secret scanning allowlist
├── .pre-commit-config.yaml         # Pre-commit hooks config
└── firebase-debug.log              # Temporary debug file (excluded)
```

## Directory Purposes

**`.chezmoi.yaml.tmpl`:**
- Purpose: Master configuration template for chezmoi init
- Contains: Prompts for machine_type (client/personal/server), personal_email, work_email (conditional)
- Key responsibility: Define encryption (age), Bitwarden CLI path, data sources
- Defines variables: `.machine_type`, `.personal_email`, `.work_email`, `.osid`

**`.chezmoidata.yaml`:**
- Purpose: Single source of truth for all static data (~6300 lines)
- Contains: Homebrew package lists (taps, brews, casks, fonts, MAS apps) organized by machine type
- Contains: Bitwarden folder names, tool versions (mise), plugin definitions
- Machine type organization: `darwin.common_*` (all), `darwin.client_*` (work), `darwin.fanaka_*` (personal)
- Consumed by: All templates via `.data` context variable

**`.chezmoiignore`:**
- Purpose: Control which files deploy to `$HOME` during `chezmoi apply`
- Contains: 11 sections covering Dotbot legacy code, repo meta, OS-specific configs, deprecated tools
- Key patterns: Repository files (README.md, .git/) never deployed; encrypted age keys never deployed
- Conditional blocks: OS-specific exclusions using template syntax

**`.claude/` directory:**
- Purpose: Claude Code configuration and GSD framework
- Contains: Agent definitions (gsd-codebase-mapper.md, gsd-executor.md, etc.), commands, skills
- Key subdirectories: `agents/`, `commands/`, `projects/`
- Never deployed: Excluded in .chezmoiignore; local state only

**`.planning/` directory:**
- Purpose: GSD framework planning artifacts
- Contains: Phase plans, implementation notes, codebase analysis documents
- Key subdirectories: `codebase/` (architecture/structure/conventions/concerns)
- Never deployed: Repository-only; listed in .chezmoiignore

**`dot_zshrc.tmpl`:**
- Purpose: Main ZSH interactive shell configuration
- Contains: POSIX profile loading, Sheldon plugin caching, startup performance monitoring
- Conditional: Work proxy setup for `client` machine type
- Key responsibility: Load shell modules from `dot_zsh.d/`

**`dot_zshenv`:**
- Purpose: ZSH environment for all shells (login, interactive, non-interactive)
- Contains: Startup time monitoring, profiling hooks, PATH uniqueness enforcement
- Key responsibility: Define `_fzf_complete_realpath()` helper for fzf previews

**`dot_profile.tmpl`:**
- Purpose: POSIX-portable base environment (sourced by bash/sh and zsh via .zshrc)
- Contains: XDG base directories, Homebrew architecture detection (x86_64 vs arm64), compiler flags
- Contains: PATH construction with priority order (GNU tools, dotfiles bins, runtime homes)
- Key responsibility: Set up environment before any shell-specific config

**`dot_zsh.d/` directory:**
- Purpose: Modular ZSH configuration files loaded via Sheldon
- Contains: 18 files organized by function (aliases, completions, functions, keybinds, etc.)
- Files: `aliases.zsh`, `functions.zsh`, `variables.zsh`, `completions-sync.zsh`, `completions-defer.zsh`, etc.
- Key pattern: `*-sync.zsh` loaded immediately; `*-defer.zsh` loaded in background
- Special: `path.zsh.tmpl` (machine-aware PATH setup); private overrides at `~/.zsh.d.private/` (optional)

**`private_dot_config/` directory:**
- Purpose: Tool-specific configuration under `.config`
- Contains: 17 subdirectories for tools (mise, sheldon, git, kitty, aerospace, etc.)
- Key subdirectories:
  - `sheldon/plugins.toml`: Plugin management (fzf, syntax highlighting, completions, oh-my-posh)
  - `mise/config.toml.tmpl`: Runtime versions (node, python, go, rust, java, ruby, terraform)
  - `git/hooks/`: Pre-commit and pre-push hooks for git
- All subject to template rendering; some encrypted (git/hooks)

**`private_dot_ssh/` directory:**
- Purpose: SSH configuration and encrypted keys
- Contains: Encrypted SSH keys (`encrypted_private_id_rsa*.age`), encrypted SSH config
- Key pattern: `encrypted_` prefix + `.age` suffix for age-encrypted files
- Files: `id_rsa`, `id_rsa_digiocean`, `id_rsa_infomaniak`, `google_compute_engine`, `config`

**`private_dot_gnupg/` directory:**
- Purpose: GPG configuration and keys
- Contains: Encrypted GPG key material
- Permissions enforced: `~/.gnupg/private-keys-v1.d` set to 700 by permission verification script

**`private_dot_claude/` directory:**
- Purpose: Claude Code configuration (not deployed)
- Contains: Agent definitions, command definitions, skill definitions, settings
- Key subdirectories: `agents/`, `commands/`, `skills/`
- Never deployed: Excluded in .chezmoiignore; maintained as part of GSD framework

**`run_*` lifecycle scripts:**
- Purpose: Execute operations at specific phases during `chezmoi apply`
- Prefixes define execution:
  - `run_once_before_*`: Execute once on first apply
  - `run_once_after_*`: Execute once after deploy
  - `run_onchange_after_*`: Execute when templated content hash changes
  - `run_after_*`: Execute after every apply

**`run_once_before_install-homebrew.sh.tmpl`:**
- Location: `/Users/stephanlv_fanaka/.local/share/chezmoi/run_once_before_install-homebrew.sh.tmpl`
- Triggers: First apply on macOS
- Responsibility: Bootstrap Homebrew (checks architecture, sets PATH)

**`run_onchange_after_01-install-packages.sh.tmpl`:**
- Location: `/Users/stephanlv_fanaka/.local/share/chezmoi/run_onchange_after_01-install-packages.sh.tmpl`
- Triggers: When `.chezmoidata.yaml` changes (hash embedded in script)
- Responsibility: Run `brew bundle --global --verbose` for package installation

**`run_onchange_after_02-cleanup-packages.sh.tmpl`:**
- Location: `/Users/stephanlv_fanaka/.local/share/chezmoi/run_onchange_after_02-cleanup-packages.sh.tmpl`
- Responsibility: Remove unlisted Homebrew packages (brew bundle cleanup)

**`run_onchange_after_03-clear-evalcache.sh.tmpl`:**
- Responsibility: Clear Sheldon evalcache to force plugin regeneration

**`run_after_10-verify-permissions.sh.tmpl`:**
- Location: `/Users/stephanlv_fanaka/.local/share/chezmoi/run_after_10-verify-permissions.sh.tmpl`
- Triggers: After every apply
- Responsibility: Verify and fix permissions on sensitive files (SSH keys, GPG, age, AWS, git)
- Logs fixes to `~/.local/state/chezmoi/permission-fixes.log`

## Key File Locations

**Entry Points:**

- `.chezmoi.yaml.tmpl`: Chezmoi init configuration and prompts
- `dot_zshrc.tmpl`: Main shell entry point (rendered to `~/.zshrc`)
- `dot_profile.tmpl`: POSIX environment entry point (rendered to `~/.profile`)

**Configuration Hubs:**

- `.chezmoidata.yaml`: Central data store (packages, tool versions)
- `private_dot_config/sheldon/plugins.toml`: Plugin management central
- `private_dot_config/mise/config.toml.tmpl`: Runtime version management
- `dot_gitconfig`: Git alias and core config (template-safe, not templated)

**Shell Module System:**

- `dot_zsh.d/aliases.zsh`: Shell aliases (7287 lines)
- `dot_zsh.d/functions.zsh`: Shell functions (11090 lines)
- `dot_zsh.d/external-sync.zsh`: External tools initialization (sync)
- `dot_zsh.d/external-defer.zsh`: External tools initialization (deferred)
- `dot_zsh.d/completions-sync.zsh`: Shell completions (sync load)
- `dot_zsh.d/completions-defer.zsh`: Shell completions (deferred load)

**Encrypted/Sensitive Files:**

- `private_dot_gitconfig_local.tmpl`: Git user config (templated with Bitwarden secrets)
- `private_dot_ssh/encrypted_*`: SSH keys (age-encrypted)
- `private_dot_gnupg/`: GPG keyring (permissions enforced)
- `private_dot_config/git/hooks/`: Git hooks (executable)

**Lifecycle Automation:**

- `run_once_before_setup-bw-wrapper.sh.tmpl`: Set up Bitwarden CLI wrapper
- `run_once_before_setup-phantom-wrapper.sh.tmpl`: Set up Phantom wrapper
- `run_once_after_cleanup-homebrew-runtimes.sh.tmpl`: Remove legacy runtime symlinks
- `run_once_after_remove-nix-references.sh.tmpl`: Clean up nix references (migration cleanup)

## Naming Conventions

**Files:**

- `dot_` prefix: Becomes `.` when deployed (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_dot_` prefix: Hidden AND restricted permissions (e.g., `private_dot_config` → `~/.config` with perms enforced)
- `executable_` prefix: Sets executable bit (+x) on deployed file
- `.tmpl` suffix: File will be templated (Go template processing) before deployment
- `encrypted_` prefix: File is age-encrypted; decrypted transparently by chezmoi
- `run_once_` prefix: Script runs only on first apply (marked via chezmoi's state)
- `run_onchange_` prefix: Script runs when templated content hash changes
- `run_after_` prefix: Script runs after every apply

**Directories:**

- `dot_zsh.d/`: Shell modules directory (deployed as `~/.zsh.d/`)
- `private_dot_config/`: Private config directory (deployed as `~/.config/` with permissions)
- `private_dot_ssh/`: Private SSH directory (deployed as `~/.ssh/` with 600/700 perms)
- `private_dot_gnupg/`: Private GPG directory (deployed as `~/.gnupg/`)

## Where to Add New Code

**New Shell Feature/Alias:**
- Primary code: `dot_zsh.d/` directory (create new file or add to `aliases.zsh`, `functions.zsh`)
- If deferred: Add to `external-defer.zsh` or `completions-defer.zsh`, update `plugins.toml` if plugin
- If sync-critical: Add to `external-sync.zsh` or create sync module
- Private overrides: User can add to `~/.zsh.d.private/*.zsh` (not version-controlled)

**New Tool Configuration:**
- Create directory: `private_dot_config/{tool-name}/`
- Add main config: `private_dot_config/{tool-name}/config.toml` (or tool-specific format)
- Update sheldon: If plugin-based, add entry to `private_dot_config/sheldon/plugins.toml`
- Template if needed: Use `.tmpl` suffix if configuration requires machine-type or email interpolation

**New System Package:**
- Update data source: Add to appropriate list in `.chezmoidata.yaml`:
  - All machines: `packages.darwin.common_brews` or `common_casks`
  - Work machines: `packages.darwin.client_brews` or `client_casks`
  - Personal machines: `packages.darwin.fanaka_brews` or `fanaka_casks`
- Automatic deployment: Next `chezmoi apply` will include new packages

**New Lifecycle Script:**
- Create file: `run_{phase}_{description}.sh.tmpl` where phase is:
  - `once_before`: Bootstrap phase (runs once on first apply, before deploy)
  - `once_after`: Post-deploy setup (runs once after files deployed)
  - `onchange_after`: Conditional setup (runs when templated data changes)
  - `after`: Verification/fixup phase (runs after every apply)
- Location: Repository root (chezmoi discovers via prefix)
- Use OS conditionals: Wrap with `{{- if eq .chezmoi.os "darwin" }} ... {{- end }}`

**New Bitwarden-Injected Secret:**
- Reference in template: Use `(bitwarden "item" "folder/name")` in any `*.tmpl` file
- Setup folder hierarchy: Ensure folder exists in Bitwarden under `dotfiles/shared` or `dotfiles/{client|personal}`
- Allowlist pattern: If gitleaks complains, add pattern to `.gitleaks.toml` (e.g., `"dotfiles/shared"`)

**New Encrypted File:**
- Create or mark: Place sensitive file in `private_dot_*` directory
- Prefix with `encrypted_`: Use `encrypted_` prefix for explicit age encryption
- Chezmoi handles: Encryption/decryption automatic; no extra setup needed
- Permissions: If not set automatically, add to `run_after_10-verify-permissions.sh.tmpl`

## Special Directories

**`.git/`:**
- Purpose: Git repository metadata
- Generated: Yes (managed by git)
- Committed: Yes (but files ignored by .gitignore)
- Auto-commit enabled: `git.autoCommit: true` in `.chezmoi.yaml.tmpl`

**`dot_zsh.d/`:**
- Purpose: Modular shell configuration files
- Generated: No (maintained by hand)
- Committed: Yes
- Loaded by: Sheldon plugin manager via `plugins.toml`

**`private_dot_config/`:**
- Purpose: Private tool configuration
- Generated: Some files generated from templates
- Committed: Yes (encrypted files never exposed)
- Permissions: `private_` prefix ensures restricted access on deploy

**`private_dot_ssh/`:**
- Purpose: SSH keys and config
- Generated: Some files generated (config.age)
- Committed: Yes (age-encrypted)
- Permissions: Enforced to 600 (keys) and 700 (directory) by permission verification script

**`.planning/codebase/`:**
- Purpose: Architecture and structure documentation
- Generated: Created by GSD mapping agents
- Committed: Yes
- Deployed: No (excluded in .chezmoiignore)

**`~/.local/state/chezmoi/`:**
- Purpose: Runtime state (not in repository)
- Generated: Yes (created by permission verification script)
- Committed: No
- Content: `permission-fixes.log` with timestamped permission corrections

---

*Structure analysis: 2026-02-15*
