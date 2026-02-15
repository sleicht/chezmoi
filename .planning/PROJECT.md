# Dotfiles Stack

## What This Is

A complete ZSH dotfiles management system powered by chezmoi, providing cross-platform templating (macOS/Linux), machine-specific configuration (client/personal), automated Homebrew package management, mise runtime version management (7 runtimes), Bitwarden-backed secret templating with age encryption, gitleaks leak prevention, a plugin-based verification framework with 112 automated checks, and a mise-powered task runner with 10 user-friendly commands for dotfiles operations and git workflows. All configs (135 files) are managed by chezmoi with all legacy tooling (Nix, Dotbot, asdf) fully removed.

## Core Value

**Cross-platform dotfiles that "just work"** -- one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.

## Requirements

### Validated

#### v1.0.0 -- shipped 2026-02-08

- Remove Nix completely (nix-config/, nix-darwin, home-manager)
- Migrate core Dotbot symlinks to chezmoi
- Add chezmoi templating for OS-specific configurations (macOS vs Linux)
- Add chezmoi templating for machine-specific configurations (work vs personal)
- Replace asdf with mise for runtime version management
- Move runtime tools (node, python, go, rust, java, ruby, terraform) to mise
- Keep CLI tools in Homebrew (pragmatic -- works well on both platforms)
- Migrate Sheldon configuration to be managed by chezmoi
- Ensure shell startup time is not degraded (0.87s maintained)
- Bitwarden integration for secret templating
- Age encryption for SSH keys with per-machine key pairs
- Global gitleaks scanning via git hooks (warn on commit, block on push)
- Automated permission verification for sensitive files

#### v1.1 -- shipped 2026-02-12

- Migrate all remaining configs to chezmoi (69 files: basic dotfiles, CLI tools, terminal emulators, dev tools, Claude Code)
- Build verification framework with automated checks (112 checks across 5 phases)
- OS-conditional templating for gpg-agent pinentry path
- Selective sync for .claude/ directory (47 files tracked, local state excluded)
- Retire Dotbot infrastructure (submodules, install script, steps/ directory)
- Drop deprecated configs (nushell, zgenom)
- Update README to chezmoi-only workflow

#### v1.2 -- shipped 2026-02-14

- ✓ Remove all legacy .config/ directories and flat files (104+ files) -- v1.2
- ✓ Remove redundant zsh.d/ and legacy Brewfiles -- v1.2
- ✓ Migrate san-proxy to chezmoi with client-only conditional template -- v1.2
- ✓ Unify mise activation to single location (external.zsh) -- v1.2
- ✓ Remove stale asdf activation and hardcoded npm PATH -- v1.2
- ✓ Modernise Python 2 code to Python 3 (http.server, urllib.parse) -- v1.2
- ✓ Fix stale omz reload and npm/gem update commands -- v1.2
- ✓ Clean audit scripts of retired directory references -- v1.2
- ✓ Add .gitignore prevention patterns for legacy artifacts -- v1.2
- ✓ Resolve tech debt: orphaned files and obsolete scripts -- v1.2
- Rescinded: Volta PATH removal (kept unconditionally -- add_to_path guards missing dirs)
- Rescinded: rbenv PATH removal (kept unconditionally -- add_to_path guards missing dirs)

#### v2.0 -- shipped 2026-02-14

- ✓ Profile shell startup with zprof and establish baseline (PERF-01) -- v2.0 (314.6ms baseline established)
- ✓ Implement lazy loading for non-critical tool initialisation (PERF-02) -- v2.0 (sync/defer architecture, ~70ms to prompt)
- ✓ Add eval caching for expensive startup commands (PERF-03) -- v2.0 (evalcache for oh-my-posh, zoxide, atuin, carapace)
- ✓ Achieve < 300ms total shell startup time (PERF-04) -- v2.0 (139.8ms achieved, 53.4% better than target)

#### v2.1 -- shipped 2026-02-15

- ✓ Mise file-based task pipeline with chezmoi deployment (10 tasks, 8 aliases) -- v2.1
- ✓ Dotfiles operation tasks: apply, verify, smoke-test, diff, update, sync -- v2.1
- ✓ Git workflow tasks with hybrid AI/manual mode: commit, branch, cleanup, pr -- v2.1
- ✓ Conventional commit enforcement with Jira ticket prefix validation -- v2.1
- ✓ Remote-aware PR/MR creation (auto-detects GitHub vs GitLab) -- v2.1

### Active

(No active requirements — start next milestone with `/gsd:new-milestone`)

### Out of Scope

- Moving all Homebrew packages to mise -- most CLI tools work fine in Homebrew
- Windows support -- not a current need
- Nix-style reproducibility -- accepting Homebrew version drift as trade-off
- Neovim config -- stays separate from chezmoi (own repo, intentional exception documented in README)
- Removing .config/ from git history -- rewriting history is destructive; files removed from HEAD
- Fixing phantom/firebase-cli shebangs -- requires Homebrew node reinstall or mise shim; deferred

## Context

**Current milestone:** All milestones shipped (v1.0.0 → v2.1)

**Current state (post v2.1):**
- chezmoi manages 135 files with cross-platform templates and OS-conditional configs
- 171+ Homebrew packages consolidated in .chezmoidata.yaml with automated installation
- mise manages 7 runtime versions (node, python, go, rust, java, ruby, terraform)
- Bitwarden provides secrets to chezmoi templates (git config email/name)
- 4 SSH keys encrypted with age in chezmoi source
- Global gitleaks hooks deployed to all git repos
- Permission verification runs on every chezmoi apply
- Plugin-based verification framework: 112 automated checks across Phases 8-12
- Dotbot fully retired -- no submodules, no install script, no steps/ directory
- All legacy artifacts removed -- repository reflects chezmoi-only reality
- Repository is clean: no orphaned files, no stale code, no dead references
- Shell startup optimised: 139.8ms total (evalcache, sync/defer architecture, startup monitoring)
- Two-tier Sheldon loading: dotfiles-sync (immediate) + dotfiles-defer (zsh-defer) plugin groups
- Startup self-monitoring with 300ms threshold warning
- Automatic evalcache invalidation via chezmoi run_onchange_ hook on tool version changes
- 13-check smoke test script for ongoing validation
- Mise task runner: 10 file-based tasks (6 dotfiles + 4 git) deployed via chezmoi
- Hybrid AI/manual git workflows: claude CLI for AI generation, fzf for manual fallback
- Task aliases for quick access: a (apply), v (verify), d (diff), u (update), s (sync), c (commit), b (branch)

**Architecture:**
- chezmoi source: ~/.local/share/chezmoi (templates, data, run scripts)
- Package data: .chezmoidata.yaml (single source of truth for all packages)
- Config template: .chezmoi.yaml.tmpl (machine identity, encryption, Bitwarden)
- Shell config: modular zsh.d/*.zsh files managed by chezmoi
- Plugin management: Sheldon (.config/sheldon/plugins.toml)
- Verification: scripts/verify-configs.sh with scripts/verify-checks/*.sh plugins

**Target machines:**
- macOS (Apple Silicon) -- primary development
- Linux (Ubuntu/Debian) -- servers and containers

## Constraints

- **Cross-platform**: Must work on macOS (Homebrew) and Linux (apt/Homebrew)
- **Backwards compatible**: Existing shell functionality must not break
- **No secrets in git**: chezmoi age encryption and Bitwarden integration handle sensitive configs
- **Bitwarden session required**: BW_SESSION env var needed for chezmoi apply with secret templates

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| chezmoi over Dotbot | Templating for OS/machine differences, built-in secret handling | ✓ Good -- cross-platform templates working, age encryption, Bitwarden integration, Dotbot retired v1.1 |
| mise over asdf | Faster, more backends (aqua, cargo, npm), better ergonomics | ✓ Good -- 7 runtimes managed, auto-install working, 10x faster version switching |
| Keep Homebrew for CLI tools | Works on both platforms, well-maintained, familiar | ✓ Good -- 171+ packages, automated via chezmoi run scripts |
| Keep Sheldon for ZSH plugins | Already in use, fast, simple | ✓ Good -- no changes needed, works with chezmoi-managed config |
| Age encryption for SSH keys | Per-machine isolation, Bitwarden as bootstrap | ✓ Good -- 4 keys encrypted, bootstrap chain working |
| Bitwarden for secrets | Free, CLI available, vault already in use | ✓ Good -- git config templated from vault |
| Global gitleaks hooks | Prevent secret leaks across all repos | ✓ Good -- warn on commit, block on push |
| Manual cp -L for chezmoi add | chezmoi add --follow limitation with directories | ✓ Good -- reliable workaround used across all v1.1 phases (8-11) |
| Plugin-based verification | Extensible check framework per phase | ✓ Good -- 112 checks, 5 phase check files, auto-discovered by runner |
| Selective sync for .claude/ | Track synced files, exclude 491MB cache/state | ✓ Good -- 47 files tracked, 43 exclusion patterns, ~13s diff (upstream limitation) |
| Three-step submodule removal | Complete cleanup of Dotbot submodules | ✓ Good -- 4 submodules + orphaned metadata fully cleaned |
| Keep Volta/rbenv PATH unconditionally | add_to_path guards missing dirs; Volta may be used on client | ✓ Good -- safe, no side effects on machines without these tools |
| Consolidate mise activation to external.zsh | Eliminated dual activation (hooks.zsh + external.zsh) | ✓ Good -- single activation point, cleaner shell init |
| Machine-type conditional template pattern | `{{- if eq .machine_type "client" }}` for client-only config | ✓ Good -- san-proxy only sourced on client machines |
| evalcache for tool init calls | Cache static eval outputs, skip dynamic (mise) | ✓ Good -- 152.5ms saved, sub-150ms startup |
| Sync/defer Sheldon architecture | Two plugin groups: immediate sync + zsh-defer | ✓ Good -- ~70ms to prompt, deferred work invisible |
| EPOCHREALTIME startup monitoring | Microsecond-precision timing with 300ms threshold | ✓ Good -- negligible overhead, catches regressions |
| chezmoi run_onchange_ for cache invalidation | Track tool versions, auto-clear evalcache | ✓ Good -- zero-maintenance cache lifecycle |
| File-based mise tasks with chezmoi deployment | executable_ prefix for chmod +x, #MISE directives for metadata | ✓ Good -- 10 tasks deployed, all discoverable |
| Explicit mise run calls for task composition | Avoid mise depends field due to timing issues | ✓ Good -- deterministic sequential execution in sync workflow |
| Hybrid AI/manual mode for git workflows | AI speed when available, manual reliability as fallback | ✓ Good -- both paths converge to same preview/confirmation UX |
| Remote-aware PR creation (gh/glab dispatch) | Parse origin URL for platform, auto-dispatch to correct CLI | ✓ Good -- works in both GitHub and GitLab environments |

## Known Limitations

1. **Shell startup time**: 139.8ms total, ~70ms to first prompt (optimised in v2.0 from 870ms baseline).
2. **Phantom/firebase-cli broken**: Shebangs point to removed Homebrew node. Work via mise node when called directly.
3. **chezmoi diff performance**: ~13s with .claude/ tracked (491MB directory). Selective sync correct; upstream chezmoi limitation.
4. **Neovim exception**: nvim config stays as symlink outside chezmoi management (intentional, documented in README).

---
*Last updated: 2026-02-15 after v2.1 Mise Task Runner milestone shipped*
