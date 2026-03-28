# External Integrations

**Analysis Date:** 2026-02-15

## APIs & External Services

**Git Platforms:**
- GitHub
  - Client: `gh` CLI (GitHub official)
  - Purpose: PR creation, automation, repository management
  - Integration: `.planning/codebase/` agents use gh commands for PR/MR operations
- GitLab
  - Client: `glab` CLI (GitLab official)
  - Purpose: MR creation, group/project management
  - Integration: `mise run git:pr` auto-detects platform (GitHub or GitLab) and dispatches

**AI/Code Assistance:**
- Claude AI (Anthropic)
  - Client: `claude` CLI (command-line tool)
  - Purpose: Commit message generation (worktrunk integration)
  - Command: `claude -p --model=haiku` (set in `private_dot_config/worktrunk/config.toml`)
  - Integration: Conventional commit generation with Jira ticket prefix
- Aider
  - Purpose: AI pair programming
  - Configuration: `.aider.conf.yml`

**Infrastructure/Cloud:**
- Google Cloud Platform
  - Client: `gcloud-cli` (Google Cloud SDK)
  - Credentials: `~/.config/gcloud/application_default_credentials.json`
  - Permissions: 600 (enforced by permission script)
- AWS
  - Client: AWS CLI (via Homebrew)
  - Credentials: `~/.aws/credentials` (600 permissions)
  - Config: `~/.aws/config` (644 permissions)

**Git Infrastructure:**
- Artifactory/JFrog
  - Client: `jfrog-cli`
  - Purpose: Artifact repository management
- Firebase
  - Client: `firebase-cli`
  - Purpose: Firebase project deployment
- Tailscale
  - Client: `tailscale` (VPN client)
  - Purpose: Private network access

**Container Registry:**
- Docker
  - Config: `~/.docker/config.json` (600 permissions)
  - Purpose: Container image management, registry auth

## Data Storage

**Databases:**
- None configured as permanent stores
- Shell history stored locally via atuin (`~/.local/share/atuin/history.db`)

**Shell History:**
- atuin - Advanced shell history
  - Database: `~/.local/share/atuin/history.db`
  - Encryption key: `~/.local/share/atuin/key`
  - Session: `~/.local/share/atuin/session`
  - Config: `private_dot_config/atuin/config.toml`
  - Features: Workspace filtering, command chaining, secret filtering enabled
  - Auto-sync: Disabled (manual sync only)
  - Server: `api.atuin.sh` (default, can be customized)

**File Storage:**
- Local filesystem only
- No cloud storage integration (user-level decision)

**Caching:**
- Sheldon plugin cache: `~/.cache/sheldon/source.zsh`
- zsh evalcache: Cached in `~/.cache/` (cleared on hash change)
- fzf cache: Standard fzf caching locations

## Secret Management & Encryption

**Primary Secret Provider:**
- Bitwarden
  - Client: `bitwarden-cli` (bw)
  - Wrapper: Custom Node-based wrapper at `~/.local/bin/bw`
  - Reason: Homebrew's bw has hardcoded shebang to Homebrew's node; wrapper uses PATH-resolved node
  - Config location: Set in `.chezmoi.yaml.tmpl`:
    ```
    bitwarden:
      command: "{{ .chezmoi.homeDir }}/.local/bin/bw"
    ```
  - Folder structure (from `.chezmoidata.yaml`):
    - `dotfiles/shared` - Shared secrets across all machines
    - `dotfiles/client` - Work-machine secrets
    - `dotfiles/personal` - Personal-machine secrets
  - Usage in templates:
    - `{{ bitwarden "item" "dotfiles/shared/git-config" }}` - Fetch secret items
    - `{{ bitwardenFields "item" "dotfiles/shared/git-config" }}` - Fetch custom fields

**File Encryption:**
- age (age-encryption.org)
  - Encryption method: Set in `.chezmoi.yaml.tmpl` as primary encryption
  - Identity key: `{{ .chezmoi.homeDir }}/.config/age/key-{{ .machine_type }}.txt`
  - Machine types: `personal`, `client`, `server` (each has own key)
  - Recipient public key: Hardcoded in template for encryption
  - Usage: SSH keys, SSH config, git config (all encrypted at rest)
  - File naming: `encrypted_*.age` (files with sensitive data)

**SSH Keys:**
- Storage: age-encrypted at `private_dot_ssh/encrypted_*.age`
- Decryption: On-demand by chezmoi during apply
- Permissions: Enforced to 600 by `run_after_10-verify-permissions.sh.tmpl`

## Authentication & Identity

**Git Authentication:**
- Git credential manager: `git-credential-manager` (universal)
- Machine-aware config: `private_dot_gitconfig_local.tmpl`
  - Credentials sourced from Bitwarden:
    - Username from: `bitwarden "item" "dotfiles/shared/git-config"`
    - Personal email from: `bitwardenFields "item" "dotfiles/shared/git-config"` → `.personal_email`
    - Work email from: `bitwardenFields "item" "dotfiles/shared/git-config"` → `.work_email` (client only)

**SSH:**
- Keys: age-encrypted at rest
- Config: age-encrypted SSH config (`private_dot_ssh/encrypted_private_config.age`)
- openssh client for connections

**API Authentication:**
- Environment-based secrets loaded via Bitwarden templates
- Pre-commit hooks allowlist chezmoi template expressions to prevent false-positives on secrets

## CI/CD & Deployment

**Hosting:**
- Deployed to local machine (`~/`)
- No cloud deployment (dotfiles are local-only)

**Version Control:**
- Git remote: Origin tracked via `.chezmoi.yaml.tmpl`
- Auto-commit: Enabled (`git.autoCommit: true`)
- Auto-push: Disabled (`git.autoPush: false`)
- Manual push required after `chezmoi edit`

**Pre-commit Hooks:**
- Secret scanning: gitleaks v8.24.2
  - Config: `.gitleaks.toml`
  - Allowlists:
    - Chezmoi template expressions: `{{.*bitwarden.*}}`, `{{.*chezmoi.*}}`
    - age public keys: `age1[a-z0-9]{58}`
    - Stopwords: Function names (bitwarden, chezmoi, etc.)
  - Runs on: pre-commit (warning) + pre-push (blocking)
- Other checks:
  - YAML validation: `check-yaml`
  - Trailing whitespace: `trailing-whitespace`
  - Merge conflict markers: `check-merge-conflict`

**Verification:**
- 112 verification checks (via `mise run v` / `dotfiles:verify` task)
- Checks implemented in `~/.config/mise/tasks/`
- Smoke test: Shell functionality validation

## Git Integration & Workflow

**Git Worktree Manager:**
- worktrunk - Manages feature branch worktrees
  - Worktree path template: `{{ repo_path }}/../{{ branch | sanitize }}`
  - Mirrors Phantom layout for consistency
  - Config: `private_dot_config/worktrunk/config.toml`
  - Commit generation: AI-powered via `claude -p --model=haiku`
  - Merge strategy: `squash`, `commit`, `rebase`, `remove` enabled
  - Verification: Enabled (verifies before merge)

**Conventional Commits:**
- Format: `<jira-ticket>: <type>(scope): <description>`
- Enforced by: `mise run git:commit` task
- AI generation: Falls back to interactive `fzf` if claude unavailable
- Jira ticket inference: Extracted from branch name when possible

**Branching:**
- Task: `mise run git:branch` / alias `b`
- Naming convention: Feature branch prefixes with Jira ticket
- Auto-cleanup: Safe delete of merged branches (via `git:cleanup` task)

**PR/MR Creation:**
- Task: `mise run git:pr`
- Platform detection: Auto-detects GitHub vs GitLab from origin URL
- CLI dispatch: Uses `gh pr create` for GitHub or `glab mr create` for GitLab
- Template: Guides user through PR body with test plan

## Monitoring & Observability

**Error Tracking:**
- None configured
- Pre-commit gitleaks prevents accidental secret commits

**Logs:**
- Shell history via atuin (searchable, filterable)
- Git logs via lazygit (TUI interface)
- System logs: macOS system log visible via standard tools

**Performance Monitoring:**
- Shell startup time: `ZSHRC_START_TIME` environment variable
- Target: <300ms (warns if exceeded)
- Profiling: `ZSH_PROFILE_STARTUP=1 zsh -i -c exit` (zprof top 20)

## Plugin & Extension Integrations

**Shell Plugins (managed by Sheldon):**
- evalcache - Cache eval results from slow inits
- zsh-defer - Lazy load heavy plugins
- fzf-tab - Fuzzy tab completion integration
- fzf-git - fzf integration for git operations
- zsh-syntax-highlighting - Syntax highlighting
- zsh-autosuggestions - Command suggestions
- zsh-sdkman - SDKMAN integration (two versions)
- ohmyzsh - Shared plugin library (gitfast, zoxide, kubectl, gcloud, mvn, macos)
- zsh-abbr - Abbreviations system
- Local dotfiles: `.zsh.d/` (sync, defer, private modules)

**Oh My Posh:**
- Prompt theme engine
- Config: `private_dot_config/oh-my-posh.omp.json`
- Loaded by default in `.zshrc`

**AeroSpace (Window Manager):**
- Configuration: `private_dot_config/aerospace/aerospace.toml`
- macOS tiling window manager
- Integration: Loaded as part of graphical session

**Karabiner-Elements:**
- Keyboard customization framework
- Configuration: `private_dot_config/karabiner/karabiner.json`
- Purpose: Custom key bindings and device-specific rules

## External URLs & Endpoints

**Package Sources:**
- Homebrew official taps (20+ custom taps listed in `.chezmoidata.yaml`)
- GitHub releases (direct downloads in bootstrap scripts)

**Documentation:**
- Official tool docs linked throughout config (mise.jdx.dev, sheldon.cli.rs, etc.)

**API Endpoints:**
- atuin sync server: `https://api.atuin.sh` (default, configurable)
- Bitwarden server: User-configured
- Git platforms: github.com, gitlab.com (inferred from origin URL)

---

*Integration audit: 2026-02-15*
