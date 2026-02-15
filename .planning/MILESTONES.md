# Milestones

## v1.0.0 Dotfiles Stack Migration (Shipped: 2026-02-08)

**Delivered:** Complete migration from Nix/Dotbot/Zgenom/asdf to chezmoi/mise/Homebrew/Sheldon with cross-platform templating and Bitwarden secret management.

**Phases completed:** 1-6 (25 plans total)

**Key accomplishments:**
- chezmoi managing all dotfiles with cross-platform templates (macOS/Linux), machine-specific config (client/personal), and interactive setup prompts
- mise managing 7 runtime versions (node, python, go, rust, java, ruby, terraform) with auto-install and directory-based version switching
- Homebrew automation via chezmoi run scripts: 171+ packages consolidated from 5 sources into single .chezmoidata.yaml, change-triggered installation, automated cleanup with audit trail
- Bitwarden secret management with age encryption for SSH keys, per-machine age key pairs, and bootstrap chain (Bitwarden -> age key -> SSH keys -> full access)
- Global gitleaks scanning for all git repos via chezmoi-deployed hooks (warn on commit, block on push) with pre-commit framework delegation
- Automated permission verification on every chezmoi apply (13 sensitive file patterns, cross-platform stat detection, audit logging)

**Stats:**
- 6 phases, 25 plans
- 15 days from start to ship (2026-01-25 to 2026-02-08)
- 3.10 hours total execution time (average 7.4 min/plan)

**Git range:** feature/nix branch

**What's next:** v2 -- Performance optimisation, mise task runner

---

## v1.1 Complete Migration (Shipped: 2026-02-12)

**Delivered:** Migrated all remaining Dotbot-managed configs to chezmoi and retired Dotbot entirely. 69 config files migrated with 112 automated verification checks, plugin-based verification framework, and OS-conditional templating.

**Phases completed:** 7-12 (13 plans total)

**Key accomplishments:**
- Migrated 69 config files from Dotbot symlinks to chezmoi-managed real files (basic dotfiles, CLI tools, terminal emulators, dev tools, Claude Code)
- Built plugin-based verification framework with 112 automated checks across 5 phases (scripts/verify-configs.sh + verify-checks/)
- Implemented OS-conditional templating for gpg-agent pinentry path (macOS Homebrew vs Linux system)
- Established selective sync for .claude/ directory (47 files tracked, 43 exclusion patterns for cache/state)
- Retired Dotbot infrastructure entirely (4 submodules, install script, steps/ directory removed)
- Updated README to chezmoi-only workflow with 0 Dotbot references and nvim exception documented

**Stats:**
- 6 phases, 13 plans
- 4 days from start to ship (2026-02-08 to 2026-02-12)
- 57 commits, 310 files changed, +55,375 / -958 lines
- 30/30 requirements satisfied (100%)

**Git range:** feature/nix branch (4ed17d9..b42e4a5)

**Tech debt accepted:**
- chezmoi diff takes ~13s (vs 2s target) due to scanning 491MB .claude/ directory (upstream limitation)

**What's next:** v2 -- Performance optimisation, mise task runner

---


## v1.2 Legacy Cleanup (Shipped: 2026-02-14)

**Delivered:** Removed all pre-chezmoi artifacts from the repository and fixed stale code in the chezmoi source, so the repository reflects reality. Net -16,609 lines removed.

**Phases completed:** 13-18 (7 plans total)

**Key accomplishments:**
- Removed 104+ legacy Dotbot-era files (10 directories, 17 flat files, 3 Brewfiles, zsh.d/)
- Migrated san-proxy to chezmoi with client-only conditional template
- Unified mise activation to single location, removed stale asdf/Volta/npm PATH code
- Modernised Python 2 code to Python 3 (http.server, urllib.parse) and fixed stale aliases
- Cleaned audit scripts of retired directory references, added .gitignore prevention patterns
- Resolved all tech debt identified by milestone audit (orphaned files, obsolete scripts)

**Stats:**
- 6 phases, 7 plans
- 2 days from start to ship (2026-02-13 to 2026-02-14)
- 40 commits, 154 files changed, +3,791 / -20,400 lines
- 19/21 requirements satisfied (2 rescinded by user decision)

**Git range:** feature/nix branch

**What's next:** v2.0 -- Performance optimisation, mise task runner

---


## v2.0 Performance (Shipped: 2026-02-14)

**Delivered:** Achieved 139.8ms shell startup (55.6% faster than 314.6ms baseline, 53.4% better than 300ms target) through eval caching, sync/defer architecture, and startup monitoring.

**Phases completed:** 19-22 (8 plans total)

**Key accomplishments:**
- Established three-stage performance baseline (hyperfine, EPOCHREALTIME, zsh-bench) at 314.6ms
- Applied four zero-risk quick wins reducing startup to 283.7ms (duplicate load removal, pure-zsh SSH parsing, command check optimisation, PATH deduplication)
- Implemented evalcache layer caching oh-my-posh, zoxide, atuin, carapace — achieving sub-150ms startup
- Split shell init into sync/defer architecture with two-tier Sheldon plugin groups (~70ms to first prompt)
- Added startup self-monitoring (300ms threshold warning) and automatic evalcache invalidation via chezmoi hook
- Created 13-check smoke test script validating all critical shell functionality

**Stats:**
- 4 phases, 8 plans
- 1 day (2026-02-14)
- 27 commits
- 22/23 requirements satisfied (1 acceptable: PERF-02 at ~70ms vs 50ms target)

**Performance progression:**
- 314.6ms → 283.7ms (quick wins) → 131.2ms (eval caching) → 128.7ms (sync/defer) → 139.8ms (with monitoring)

**Git range:** feature/nix branch

**Tech debt accepted:**
- First-prompt lag ~70ms vs 50ms target (Should priority, excellent UX)
- Phase 20 SUMMARY references commit hashes from chezmoi source tree (documentation mismatch)

**What's next:** Future milestone TBD

---


## v2.1 Mise Task Runner (Shipped: 2026-02-15)

**Delivered:** Implemented mise task runner for dotfiles operations and git workflows, providing 10 user-friendly commands with short aliases for chezmoi operations, verification, and conventional git commits with hybrid AI/manual mode.

**Phases completed:** 23-25 (4 plans total)

**Key accomplishments:**
- Established mise file-based task pipeline via chezmoi with executable deployment, namespace discovery (dotfiles:*/git:*), and 8 short aliases
- Implemented six dotfiles operation tasks (apply, verify, smoke-test, diff, update, sync) with proper error handling and composite workflows
- Built hybrid AI/manual git:commit with conventional commit + Jira prefix (claude CLI generation from diffs or fzf manual selection)
- Built hybrid AI/manual git:branch with feature branch naming convention enforcement
- Implemented git:cleanup (safe merged branch pruning) and git:pr (remote-aware GitHub/GitLab dispatch via gh/glab)

**Stats:**
- 3 phases, 4 plans
- 2 days (2026-02-14 to 2026-02-15)
- 15 commits, 13 files changed, +3,066 / -24 lines
- 15/15 requirements satisfied (100%)

**Git range:** feature/nix branch (b4af276..a5f0a9d)

**Tech debt accepted:**
- Alias display shows null in `mise tasks --json` (runtime works correctly)
- PR body input via cat + Ctrl-D (adequate for MVP)
- glab CLI required for GitLab repos (straightforward install)

**What's next:** Future milestone TBD

---

