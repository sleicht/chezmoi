# Technology Stack

**Analysis Date:** 2026-02-15

## Languages

**Primary:**
- Bash/Shell - Bootstrap scripts, package management, and install automation
- ZSH - Interactive shell configuration and plugin management
- Go Templates - Chezmoi template processing for conditional deployment

**Secondary:**
- TOML - Configuration files (mise, sheldon, worktrunk, atuin, aerospace)
- YAML - Configuration files (pre-commit, Brewfile metadata)
- JSON - Tool configuration (Karabiner, Oh My Posh)

## Runtime

**Environment:**
- macOS Tahoe (primary target)
- Linux support planned (conditional scripts in place via `.chezmoi.os`)

**Package Manager:**
- Homebrew - Primary macOS package manager
- Lockfile: `.Brewfile` template-generated from `.chezmoidata.yaml`

**Language Runtime Manager:**
- mise (polyglot runtime manager) - Manages Node, Python, Go, Rust, Java, Ruby, Terraform versions
  - Version management via `.tool-versions` files (idiomatic support enabled)
  - Global defaults: Node LTS, Python 3.12, Go 1.22, Rust stable, Java temurin-25, Ruby 3, Terraform 1.9

## Frameworks & Tools

**Core System:**
- chezmoi - Dotfiles management framework (template + encryption)
  - Template engine: Go templates with chezmoi functions
  - Encryption: age-encryption for sensitive files
  - Data config: `.chezmoidata.yaml` (~6300 lines, static data)

**Shell Configuration:**
- Sheldon - Plugin manager for ZSH (manages plugin lifecycle, caching)
- Oh My Posh - Prompt/theme engine
- zsh-defer - Lazy loading for heavy plugins (performance optimization)
- evalcache - Cached eval results for slow initializations

**Development Tools:**
- Git:
  - Lazygit - TUI git client
  - Gitleaks - Secret scanning (pre-commit + pre-push)
- worktrunk - Git worktree manager (spawns feature branches with auto-cleanup)
- atuin - Shell history with sync capability (workspace filtering enabled)
- bat - Syntax-highlighted cat replacement
- lsd - ls replacement with icons
- btop/bottom - System monitoring
- fzf - Fuzzy finder (integrated via fzf-tab, fzf-git)
- ripgrep (rg) - Fast text search
- fd - Fast directory search

**macOS-Specific:**
- Homebrew - Package ecosystem (200+ brews, 70+ casks, fonts)
- AeroSpace - Tiling window manager
- Karabiner-Elements - Keyboard remapping
- Finicky - URL/browser routing
- oh-my-posh - Terminal prompt

**Build/Task Running:**
- mise tasks - Wrapper for shell scripts in `~/.config/mise/tasks/`
  - Dotfiles tasks: diff, apply, verify, sync, update
  - Git tasks: commit (with Jira validation), branch, cleanup, pr (GitHub/GitLab auto-detect)
  - Task language: Bash (file-based scripts)

**Testing/Verification:**
- bats-core - Bash unit testing framework
- shellcheck - Shell script linting

## Key Dependencies

**Critical Infrastructure:**
- pre-commit - Git hook framework
  - Hooks: YAML validation, trailing-whitespace, merge-conflict checking, gitleaks scanning
  - Configuration: `.pre-commit-config.yaml` (v4.4.0 hooks, gitleaks v8.24.2)
- age - File encryption tool
  - Identity key location: `~/.config/age/key-{machine_type}.txt` (machine-aware)
- bitwarden-cli - Secret management client (wrapped via custom Node shim)

**Terminal & Editor:**
- Ghostty, Kitty, WezTerm - Terminal emulators
- aider - AI pair programming (EditorConfig support)
- EditorConfig - Cross-editor settings

**System Management:**
- GNU coreutils, GNU sed, GNU grep - POSIX-compliant tools
- openssh - SSH client/server
- openssl, gnupg - Cryptography tools
- curl, wget, httpie - HTTP clients
- jq - JSON query tool

**Observability:**
- archey4 - System info display
- glances - Process monitoring
- ncdu - Disk usage analyzer
- duf - Disk usage formatter

**Container/Infrastructure:**
- Docker, Docker Compose - Container platform
- podman - OCI-compatible container runtime
- Helm - Kubernetes package manager
- kubectl - Kubernetes CLI
- argocd - GitOps CD tool
- opentofu - IaC tool (Terraform fork)
- trivy - Vulnerability scanner
- dive - Docker image layer inspector
- lazydocker - Docker TUI

**Cloud SDKs:**
- gcloud-cli - Google Cloud SDK
- jfrog-cli - Artifactory/JFrog CLI
- firebase-cli - Firebase CLI
- tailscale - VPN client

**Development Languages/Tools:**
- Node/npm/pnpm - Managed by mise
- Python - Managed by mise
- Ruby - Managed by mise (rbenv removed in favour of mise)
- Rust - Managed by mise
- Go - Managed by mise
- Java - Managed by mise (JProfiler, VisualVM available)

**Git Integration:**
- git-credential-manager - Cross-platform git credential storage
- GitHub CLI (gh) - GitHub automation
- GitLab CLI (glab) - GitLab automation

## Configuration System

**Environment Variables:**
- Machine-aware via Go templates in `.chezmoi.yaml.tmpl`
- Prompts for machine type (`personal` / `client` / `server`) on init
- Email configuration: personal + optional work email (client only)

**Template Processing:**
- Input: `.chezmoidata.yaml` static data + machine-specific conditionals
- Output: Generated `.Brewfile`, shell configs, SSH configs, git configs
- Conditional logic: `.machine_type`, `.chezmoi.os`, `.chezmoi.osRelease`

**Data Files:**
- `.chezmoidata.yaml`:
  - Package lists (taps, brews, casks, fonts, MAS apps) - machine-aware
  - Bitwarden folder paths for different machines
  - Tool versions (Node LTS, Python 3.12, etc.)
  - Sheldon plugin configuration placeholders

## Build & Deployment

**Deployment:**
- chezmoi apply - Deploys templates to `~/`
- Automatic git commit on source changes (autoCommit: true)
- Manual push required (autoPush: false)
- Lifecycle scripts:
  - `run_once_before_*` - One-time bootstrap (Homebrew install, bw wrapper setup)
  - `run_onchange_after_*` - On hash change (package install, cleanup, evalcache)
  - `run_after_*` - Every apply (permission hardening)

**Installation Script Hooks:**
```bash
run_once_before_install-homebrew.sh.tmpl      # Install Homebrew (macOS only)
run_once_before_setup-bw-wrapper.sh.tmpl      # Create bw wrapper for mise-managed node
run_onchange_after_01-install-packages.sh.tmpl    # brew bundle --global
run_onchange_after_02-cleanup-packages.sh.tmpl    # Remove packages not in Brewfile
run_onchange_after_03-clear-evalcache.sh.tmpl    # Clear zsh evalcache on change
run_after_10-verify-permissions.sh.tmpl       # Enforce 600/700 on sensitive files
```

**Conditional Execution:**
- All scripts check `{{ .chezmoi.os }}` - Darwin-only by default
- Brewfile generation conditional on `{{ .machine_type }}`
- SSH config decryption conditional on machine type

## Platform Requirements

**Development:**
- macOS (primary - Tahoe tested)
- Bash 5.0+ for scripts
- ~200-350 packages via Homebrew depending on machine type
- age encryption library
- Node.js (managed by mise, not system)

**Secrets Management:**
- age encryption identity: `~/.config/age/key-{machine_type}.txt` (600 permissions)
- Bitwarden credentials via `bw` CLI wrapper
- AWS credentials: `~/.aws/credentials` (600 permissions)
- Docker config: `~/.docker/config.json` (600 permissions)
- GCloud credentials: `~/.config/gcloud/application_default_credentials.json` (600 permissions)

**Performance Targets:**
- Shell startup: <300ms target (measured via `ZSHRC_START_TIME`)
- Sheldon plugin caching to `~/.cache/sheldon/source.zsh`
- Lazy loading via zsh-defer for non-critical plugins

---

*Stack analysis: 2026-02-15*
