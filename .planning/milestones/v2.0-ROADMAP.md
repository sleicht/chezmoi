# Roadmap: Dotfiles Stack

## Milestones

- ✅ **v1.0.0 Dotfiles Stack Migration** -- Phases 1-6 (shipped 2026-02-08)
- ✅ **v1.1 Complete Migration** -- Phases 7-12 (shipped 2026-02-12)
- ✅ **v1.2 Legacy Cleanup** -- Phases 13-18 (shipped 2026-02-14)
- 📋 **v2.0 Performance** -- Phases 19-22 (active)

## Phases

<details>
<summary>✅ v1.0.0 Dotfiles Stack Migration (Phases 1-6) -- SHIPPED 2026-02-08</summary>

Complete migration from Nix/Dotbot/Zgenom/asdf to chezmoi/mise/Homebrew/Sheldon with cross-platform templating and Bitwarden secret management. See `.planning/milestones/v1.0.0-ROADMAP.md` for full details.

**Stats:** 6 phases, 25 plans, 3.10 hours total execution time

- [x] Phase 1: Nix Removal (4/4 plans) -- completed 2026-01-25
- [x] Phase 2: Chezmoi Foundation (5/5 plans) -- completed 2026-01-28
- [x] Phase 3: Runtime Management Migration (4/4 plans) -- completed 2026-01-30
- [x] Phase 4: Homebrew Automation (4/4 plans) -- completed 2026-02-02
- [x] Phase 5: Secret Management (4/4 plans) -- completed 2026-02-05
- [x] Phase 6: Security & Verification (4/4 plans) -- completed 2026-02-08

</details>

<details>
<summary>✅ v1.1 Complete Migration (Phases 7-12) -- SHIPPED 2026-02-12</summary>

Migrated all remaining Dotbot-managed configs to chezmoi and retired Dotbot entirely. 69 config files migrated with 112 automated verification checks. See `.planning/milestones/v1.1-ROADMAP.md` for full details.

**Stats:** 6 phases, 13 plans, 57 commits, 30/30 requirements satisfied

- [x] Phase 7: Preparation (2/2 plans) -- completed 2026-02-08
- [x] Phase 8: Basic Configs & CLI Tools (3/3 plans) -- completed 2026-02-11
- [x] Phase 9: Terminal Emulators (2/2 plans) -- completed 2026-02-09
- [x] Phase 10: Dev Tools with Secrets (2/2 plans) -- completed 2026-02-10
- [x] Phase 11: Claude Code (2/2 plans) -- completed 2026-02-12
- [x] Phase 12: Dotbot Retirement (2/2 plans) -- completed 2026-02-12

</details>

<details>
<summary>✅ v1.2 Legacy Cleanup (Phases 13-18) -- SHIPPED 2026-02-14</summary>

Removed all pre-chezmoi artifacts from the repository and fixed stale code in the chezmoi source. Net -16,609 lines removed. See `.planning/milestones/v1.2-ROADMAP.md` for full details.

**Stats:** 6 phases, 7 plans, 40 commits, 19/21 requirements satisfied (2 rescinded)

- [x] Phase 13: Remove Legacy Config Files (2/2 plans) -- completed 2026-02-13
- [x] Phase 14: Migrate san-proxy to chezmoi (1/1 plan) -- completed 2026-02-14
- [x] Phase 15: Fix PATH and Version Manager Code (1/1 plan) -- completed 2026-02-14
- [x] Phase 16: Fix Python 2 and Shell Utilities (1/1 plan) -- completed 2026-02-14
- [x] Phase 17: Clean Audit Scripts and Artifacts (1/1 plan) -- completed 2026-02-14
- [x] Phase 18: Clean Tech Debt from Audit (1/1 plan) -- completed 2026-02-14

</details>

### v2.0 Performance (Active)

**Milestone Goal:** Achieve < 300ms shell startup time through profiling, lazy loading, and eval caching.

**Target:** 870ms -> < 300ms wall-clock, < 50ms first-prompt lag (zsh-bench)

#### Phase 19: Baseline & Quick Wins

**Goal:** Establish measurement baseline, apply zero-risk optimisations.

**Requirements:** PROF-01, QUICK-01, QUICK-02, QUICK-03, QUICK-04

**Scope:**
- Install zsh-bench, establish three-stage baseline (hyperfine, EPOCHREALTIME, zsh-bench)
- Remove duplicate zsh-autosuggestions + zsh-syntax-highlighting loads from hooks.zsh
- Replace Ruby SSH config parsing with pure-zsh
- Replace `command -v` with `(( $+commands[tool] ))`
- Add `typeset -U PATH path FPATH fpath`
- Re-measure after changes

**Expected savings:** ~100-150ms (from removing duplicate loads + Ruby parsing)
**Risk:** LOW — no architecture changes, all reversible

#### Phase 20: Eval Caching Layer

**Goal:** Cache all expensive `eval "$(tool init)"` calls and sheldon output.

**Requirements:** CACHE-01, CACHE-02, CACHE-03, CACHE-04, CACHE-05, CACHE-06

**Scope:**
- Add evalcache (mroth/evalcache) as Sheldon plugin
- Cache oh-my-posh init (sync, prompt-critical)
- Cache zoxide, atuin, carapace, intelli-shell init
- Cache sheldon source output to file with mtime-based invalidation
- zcompile .zcompdump in background (.zlogin)
- Simplify compinit to always use `-C`
- Measure improvement

**Expected savings:** ~250-400ms (brings total from ~720ms to ~320-470ms)
**Risk:** LOW — behaviour identical, only source changes from subprocess to file
**Dependency:** None (Phase 19 provides baseline but is not blocking)

#### Phase 21: Sync/Defer Architecture Split

**Goal:** Move non-critical startup work after first prompt via Sheldon plugin group split.

**Requirements:** LAZY-01, LAZY-02, LAZY-03, LAZY-04, LAZY-05, LAZY-06

**Scope:**
- Split hooks.zsh into prompt.zsh (sync) and remove redundant sources
- Split external.zsh into external-sync.zsh (FZF exports) + external-defer.zsh (zoxide, mise)
- Split completions.zsh into sync (zstyles) + defer (SSH hosts, autoloads)
- Update plugins.toml with dotfiles-sync and dotfiles-defer groups
- Add `mise activate --shims` to .zprofile as immediate PATH fallback
- Defer: ssh-add, intelli-shell, completion definitions (lens, wt, xlaude)
- Measure improvement

**Expected savings:** ~100-200ms perceived (deferred work invisible to user)
**Risk:** MEDIUM — file refactoring, ordering constraints
**Dependency:** Phase 20 (evalcache must be in place for cached evals in deferred files)

#### Phase 22: Monitoring & Hardening

**Goal:** Prevent regressions and ensure long-term maintainability.

**Requirements:** PROF-02, PROF-03, PERF-01, PERF-02, PERF-03, PERF-04

**Scope:**
- Add startup time self-monitoring (warn if > 300ms)
- Create smoke test script (prompt styled, tools on PATH, no double-loads, completions work)
- Add chezmoi run_onchange_ hook to clear eval caches on tool version change
- Final three-stage measurement confirming < 300ms target
- Document benchmarking methodology

**Expected savings:** 0ms (preventive)
**Risk:** LOW — monitoring only
**Dependency:** Phase 21 (all optimisations in place)

- [x] Phase 19: Baseline & Quick Wins — **Plans:** 2 plans — completed 2026-02-14
  - [x] 19-01-PLAN.md — Establish three-stage performance baseline
  - [x] 19-02-PLAN.md — Apply quick wins (QUICK-01 to QUICK-04) and re-measure
- [x] Phase 20: Eval Caching Layer — **Plans:** 2 plans — completed 2026-02-14
  - [x] 20-01-PLAN.md — Add evalcache plugin, simplify compinit, cache sheldon source, background zcompile
  - [x] 20-02-PLAN.md — Convert eval init calls to evalcache and measure improvement
- [x] Phase 21: Sync/Defer Architecture Split — **Plans:** 2 plans — completed 2026-02-14
  - [x] 21-01-PLAN.md — Split zsh.d files into sync/defer pairs, add mise shims to .zprofile
  - [x] 21-02-PLAN.md — Reconfigure Sheldon plugins.toml with sync/defer groups and measure
- [x] Phase 22: Monitoring & Hardening — **Plans:** 2 plans — completed 2026-02-14
  - [x] 22-01-PLAN.md — Self-monitoring, conditional zprof, and evalcache invalidation hook
  - [x] 22-02-PLAN.md — Smoke test script and final three-stage performance measurement

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Nix Removal | v1.0.0 | 4/4 | Complete | 2026-01-25 |
| 2. Chezmoi Foundation | v1.0.0 | 5/5 | Complete | 2026-01-28 |
| 3. Runtime Management Migration | v1.0.0 | 4/4 | Complete | 2026-01-30 |
| 4. Homebrew Automation | v1.0.0 | 4/4 | Complete | 2026-02-02 |
| 5. Secret Management | v1.0.0 | 4/4 | Complete | 2026-02-05 |
| 6. Security & Verification | v1.0.0 | 4/4 | Complete | 2026-02-08 |
| 7. Preparation | v1.1 | 2/2 | Complete | 2026-02-08 |
| 8. Basic Configs & CLI Tools | v1.1 | 3/3 | Complete | 2026-02-11 |
| 9. Terminal Emulators | v1.1 | 2/2 | Complete | 2026-02-09 |
| 10. Dev Tools with Secrets | v1.1 | 2/2 | Complete | 2026-02-10 |
| 11. Claude Code | v1.1 | 2/2 | Complete | 2026-02-12 |
| 12. Dotbot Retirement | v1.1 | 2/2 | Complete | 2026-02-12 |
| 13. Remove Legacy Config Files | v1.2 | 2/2 | Complete | 2026-02-13 |
| 14. Migrate san-proxy to chezmoi | v1.2 | 1/1 | Complete | 2026-02-14 |
| 15. Fix PATH and Version Manager Code | v1.2 | 1/1 | Complete | 2026-02-14 |
| 16. Fix Python 2 and Shell Utilities | v1.2 | 1/1 | Complete | 2026-02-14 |
| 17. Clean Audit Scripts and Artifacts | v1.2 | 1/1 | Complete | 2026-02-14 |
| 18. Clean Tech Debt from Audit | v1.2 | 1/1 | Complete | 2026-02-14 |
| 19. Baseline & Quick Wins | v2.0 | 2/2 | Complete | 2026-02-14 |
| 20. Eval Caching Layer | v2.0 | 2/2 | Complete | 2026-02-14 |
| 21. Sync/Defer Architecture Split | v2.0 | 2/2 | Complete | 2026-02-14 |
| 22. Monitoring & Hardening | v2.0 | 2/2 | Complete | 2026-02-14 |

---
*Last updated: 2026-02-14 — Phase 22 complete (139.8ms total startup, monitoring & hardening in place, v2.0 milestone achieved)*
