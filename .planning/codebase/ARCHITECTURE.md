# Architecture

**Analysis Date:** 2026-02-15

## Pattern Overview

**Overall:** Declarative dotfiles system using chezmoi with machine-aware conditional deployment, templating, and encrypted secrets management.

**Key Characteristics:**
- **Template-driven**: Go template processing (`*.tmpl` files) for dynamic configuration
- **Machine-aware**: Single source deploys differently to `client` (work) vs `personal` (home) machines
- **Lifecycle-managed**: Run scripts execute in defined phases (bootstrap → configure → verify)
- **Modular shell**: ZSH config via plugin manager (Sheldon) with deferred loading for startup performance
- **Encrypted secrets**: Age encryption for sensitive files (SSH keys, git config)
- **Idempotent**: All changes templated; repeated applies are safe

## Layers

**Template Processing Layer:**
- Purpose: Transform source files into deployment-ready configuration
- Location: All `*.tmpl` files in repository root and subdirectories
- Contains: Go template syntax with conditional blocks, data interpolation, and logic
- Depends on: `.chezmoi.yaml.tmpl` (config), `.chezmoidata.yaml` (static data)
- Used by: chezmoi apply process during file deployment

**Data/Configuration Layer:**
- Purpose: Centralize shared data and static configuration across all machines
- Location: `.chezmoidata.yaml` (6300+ lines of static data)
- Contains: Package lists (darwin.common_brews, darwin.client_brews, etc.), tool versions, Bitwarden folder names
- Depends on: Machine type context from init prompts
- Used by: Templates to generate machine-specific Brewfile, tool configs

**Machine Context Layer:**
- Purpose: Define machine-specific identity and configuration choices
- Location: `.chezmoi.yaml.tmpl` (init prompts)
- Contains: Machine type (`client`/`personal`/`server`), personal/work email, OS detection
- Depends on: User input at `chezmoi init` and OS information from chezmoi runtime
- Used by: All templates via `.machine_type`, `.personal_email`, `.work_email` variables

**Shell Configuration Layer:**
- Purpose: Modular ZSH environment with performance optimization
- Location: `dot_zshrc.tmpl`, `dot_zshenv`, `dot_zsh.d/` directory
- Contains: ZSH startup, history, Sheldon plugin caching, path setup
- Depends on: `.profile` for POSIX environment, Sheldon for plugin management
- Used by: Every interactive shell session

**Plugin Management Layer:**
- Purpose: Manage ZSH plugins and defer loading for startup speed
- Location: `private_dot_config/sheldon/plugins.toml`
- Contains: Plugin definitions (fzf, syntax highlighting, completions) with apply rules
- Depends on: Sheldon binary from Homebrew, evalcache and zsh-defer plugins
- Used by: `dot_zshrc.tmpl` via cached `sheldon source` output

**Tool Configuration Layer:**
- Purpose: Centralized configuration for development tools and system utilities
- Location: `private_dot_config/` subdirectories (mise, git, kitty, aerospace, etc.)
- Contains: Tool-specific configs, keybinds, themes
- Depends on: Tool-specific environment variables from `.profile`
- Used by: Respective tools on startup

**Package Management Layer:**
- Purpose: Define and install system packages and applications
- Location: `dot_Brewfile.tmpl` (generated from `.chezmoidata.yaml`)
- Contains: Homebrew taps, brews, casks, fonts, MAS apps
- Depends on: `.chezmoidata.yaml` (packages lists), machine type context
- Used by: `run_onchange_after_01-install-packages.sh.tmpl`

**Lifecycle/Automation Layer:**
- Purpose: Execute setup, installation, and verification scripts
- Location: `run_*` scripts with chezmoi prefixes
- Contains: Bootstrap, package installation, cleanup, permission verification
- Depends on: Templated conditions (OS detection, machine type)
- Used by: chezmoi during `apply` and post-apply hooks

**Encryption Layer:**
- Purpose: Secure sensitive files using age encryption
- Location: `.chezmoi.yaml.tmpl` (encryption config), `private_dot_ssh/encrypted_*.age` files
- Contains: Age encryption settings, encrypted SSH keys, encrypted git config
- Depends on: Age identity key at `~/.config/age/key-{machine_type}.txt`
- Used by: chezmoi to decrypt files before deployment

**Secret Injection Layer:**
- Purpose: Fetch secrets from Bitwarden at template render time
- Location: `private_dot_gitconfig_local.tmpl`, bitwarden references in templates
- Contains: Bitwarden CLI integration, folder naming conventions
- Depends on: Bitwarden CLI binary, Bitwarden login credentials
- Used by: Template functions like `bitwarden "item"` and `bitwardenFields`

## Data Flow

**Initialization Flow:**

1. User runs `chezmoi init` on new machine
2. `.chezmoi.yaml.tmpl` prompts for: machine type, personal email, work email (if client)
3. OS detection runs automatically (darwin/linux)
4. Configuration stored in `~/.config/chezmoi/chezmoi.yaml`
5. Age encryption identity loaded from `~/.config/age/key-{machine_type}.txt`

**Template Rendering Flow:**

1. User runs `chezmoi apply`
2. For each source file (including `*.tmpl` files):
   - Load `.chezmoi.yaml` and `.chezmoidata.yaml` as data context
   - Render Go templates using context variables (`.machine_type`, `.personal_email`, etc.)
   - Decrypt age-encrypted content
   - Inject secrets from Bitwarden (if referenced)
   - Write rendered output to target path in `$HOME`

**Package Installation Flow:**

1. `dot_Brewfile.tmpl` rendered using machine type and package lists from `.chezmoidata.yaml`
2. Hash of `.chezmoidata.yaml` computed into run script
3. `run_onchange_after_01-install-packages.sh.tmpl` checks hash; only runs if packages changed
4. `brew bundle --global` installs packages from generated Brewfile
5. `run_onchange_after_02-cleanup-packages.sh.tmpl` removes unlisted packages

**Shell Startup Flow:**

1. `.zshenv` sourced (all shells) → enable profiling if needed
2. `.zprofile` sourced (login shells)
3. `.profile` sourced (defines XDG dirs, PATH, compiler flags)
4. `.zshrc` sourced (interactive shells):
   - Load Sheldon plugin cache (or regenerate if `plugins.lock` changed)
   - Load modules from `dot_zsh.d/` in defined order
5. Private overrides from `~/.zsh.d.private/` loaded (if exists)
6. Deferred plugins load via zsh-defer in background

**State Management:**

- **Immutable data**: `.chezmoidata.yaml` (package lists, tool versions)
- **Template-generated**: Brewfile, git config (regenerated on each apply)
- **Encrypted state**: SSH keys, sensitive credentials (age-encrypted)
- **Runtime state**: Shell history, caches, Sheldon cache (excluded from chezmoi)
- **Logged state**: Permission fixes logged to `~/.local/state/chezmoi/permission-fixes.log`

## Key Abstractions

**Machine Type Abstraction:**
- Purpose: Single repository serves multiple machine configurations
- Examples: `.machine_type` variable in `.chezmoi.yaml.tmpl`, conditional package lists
- Pattern: Use `{{- if eq .machine_type "client" }}` in templates to branch logic

**Template with Conditions:**
- Purpose: Generate OS-specific and machine-specific configuration files
- Examples: `dot_Brewfile.tmpl`, `private_dot_gitconfig_local.tmpl`, `run_once_before_install-homebrew.sh.tmpl`
- Pattern: Render once at apply time; result is static (not templated in target)

**Plugin with Deferred Loading:**
- Purpose: Keep shell startup fast by deferring non-critical plugin loading
- Examples: `fzf-tab`, `zsh-syntax-highlighting` marked with `apply = ["defer"]`
- Pattern: Sheldon generates two plugin groups: sync (immediate) and deferred (backgrounded)

**Data-Driven Configuration:**
- Purpose: Manage large configuration lists (100+ packages) without hardcoding
- Examples: `darwin.common_brews`, `darwin.client_casks`, `darwin.personal_mas`
- Pattern: `.chezmoidata.yaml` serves as single source of truth; templates reference it

**Lifecycle Script with Conditional Execution:**
- Purpose: Run operations once, or only when specific conditions change
- Examples: `run_once_before_install-homebrew.sh.tmpl`, `run_onchange_after_01-install-packages.sh.tmpl`
- Pattern: chezmoi prefixes (`run_once_`, `run_onchange_`, `run_after_`) control when scripts run

**Encrypted File Abstraction:**
- Purpose: Secure sensitive files while keeping them version-controlled
- Examples: `encrypted_private_id_rsa.age`, `encrypted_private_config.age`
- Pattern: Filename prefix `encrypted_` + age suffix; decrypted transparently by chezmoi

**Bitwarden Secret Injection:**
- Purpose: Keep credentials dynamic (fetch at render time, never store in repo)
- Examples: Git user name and email in `private_dot_gitconfig_local.tmpl`
- Pattern: Template function `(bitwarden "item" "folder/name")` or `(bitwardenFields ...)`

## Entry Points

**chezmoi init:**
- Location: `.chezmoi.yaml.tmpl` (prompts)
- Triggers: First-time setup on new machine
- Responsibilities: Collect machine type, emails, initialize encryption, create runtime config

**chezmoi apply:**
- Location: Entire repository (all source files evaluated)
- Triggers: User command or post-update hook
- Responsibilities: Render templates, decrypt secrets, write to `$HOME`, execute run scripts

**~/.zshrc:**
- Location: `dot_zshrc.tmpl` → rendered to `~/.zshrc`
- Triggers: Every interactive shell session
- Responsibilities: Load Sheldon plugins, source ZSH modules, set history options

**run_once_before_install-homebrew.sh.tmpl:**
- Location: `/Users/stephanlv_personal/.local/share/chezmoi/run_once_before_install-homebrew.sh.tmpl`
- Triggers: First apply on macOS
- Responsibilities: Bootstrap Homebrew if not installed

**run_onchange_after_01-install-packages.sh.tmpl:**
- Location: `/Users/stephanlv_personal/.local/share/chezmoi/run_onchange_after_01-install-packages.sh.tmpl`
- Triggers: When `.chezmoidata.yaml` hash changes
- Responsibilities: Run `brew bundle --global` to sync packages

**run_after_10-verify-permissions.sh.tmpl:**
- Location: `/Users/stephanlv_personal/.local/share/chezmoi/run_after_10-verify-permissions.sh.tmpl`
- Triggers: After every apply
- Responsibilities: Verify and fix permissions on sensitive files (600 for keys, 700 for dirs)

## Error Handling

**Strategy:** Fail-fast with clear error messages; idempotent design allows retry after fixing issues.

**Patterns:**

- **Template errors**: Caught by chezmoi during rendering; human-readable template syntax errors
- **Permission errors**: Post-apply script fixes automatically; logs to `~/.local/state/chezmoi/permission-fixes.log`
- **Encryption errors**: Age decryption fails with clear error if key is missing or wrong
- **Secret injection errors**: Bitwarden CLI errors logged; template render fails
- **Package installation errors**: Homebrew errors printed to console; script exits with non-zero code
- **Startup performance**: Shell startup time tracked; warning if exceeds 300ms (see `dot_zshenv`)

## Cross-Cutting Concerns

**Logging:**
- Permission fixes: `~/.local/state/chezmoi/permission-fixes.log` (timestamped entries)
- Shell startup profiling: `ZSH_PROFILE_STARTUP=1 zsh -i -c exit` shows top 20 slowest startup functions
- Run script output: Printed to console during `chezmoi apply`

**Validation:**
- Git config hooks: `private_dot_config/git/hooks/executable_pre-commit` (validates before commit)
- Pre-commit framework: `.pre-commit-config.yaml` runs gitleaks, YAML validation
- Package hash validation: Run scripts check `.chezmoidata.yaml` hash to avoid unnecessary installations

**Secrets Management:**
- Age encryption: Identity key at `~/.config/age/key-{machine_type}.txt` (generated outside chezmoi)
- Bitwarden integration: Folder hierarchy (`dotfiles/shared`, `dotfiles/client`, `dotfiles/personal`)
- File permissions: Sensitive files enforced to 600 (keys) or 700 (directories)

**Deployment Safety:**
- Edit does not auto-apply: `edit.apply: false` requires manual `chezmoi apply`
- Git auto-commit (no push): `git.autoCommit: true`, `autoPush: false` prevents accidental pushes
- Dry-run available: `chezmoi apply --dry-run` simulates without writing
- Diff preview: `chezmoi diff` shows pending changes before apply

---

*Architecture analysis: 2026-02-15*
