# Roadmap: Dotfiles Stack

## Milestones

- ✅ **v1.0.0 Dotfiles Stack Migration** - Phases 1-6 (shipped 2026-02-08)
- ✅ **v1.1 Complete Migration** - Phases 7-12 (shipped 2026-02-12)

## Phases

<details>
<summary>✅ v1.0.0 Dotfiles Stack Migration (Phases 1-6) - SHIPPED 2026-02-08</summary>

Complete migration from Nix/Dotbot/Zgenom/asdf to chezmoi/mise/Homebrew/Sheldon with cross-platform templating and Bitwarden secret management. See `.planning/milestones/v1.0.0-ROADMAP.md` for full details.

**Stats:** 6 phases, 25 plans, 3.10 hours total execution time

</details>

### ✅ v1.1 Complete Migration (Shipped 2026-02-12)

**Milestone Goal:** Migrate all remaining Dotbot-managed configs to chezmoi and retire Dotbot entirely.

#### Phase 7: Preparation
**Goal**: Establish protective infrastructure before any config migration
**Depends on**: Phase 6 (v1.0.0 complete)
**Requirements**: PREP-01, PREP-02, PREP-03
**Success Criteria** (what must be TRUE):
  1. chezmoi apply ignores all Dotbot infrastructure files without user intervention
  2. All configs cleared of embedded secrets before migration (audit complete)
  3. Verification script confirms migrated configs deploy correctly after chezmoi apply
**Plans**: 2 plans

Plans:
- [x] 07-01-PLAN.md — Comprehensive .chezmoiignore setup with OS-conditional templates
- [x] 07-02-PLAN.md — Secret audit script and plugin-based verification framework

#### Phase 8: Basic Configs & CLI Tools
**Goal**: Migrate low-risk static configuration files to chezmoi
**Depends on**: Phase 7
**Requirements**: BASE-01, BASE-02, BASE-03, BASE-04, CLI-01, CLI-02, CLI-03, CLI-04, WM-01, SEC-02, DEV-03, DEV-04, SHELL-01
**Success Criteria** (what must be TRUE):
  1. User can apply basic dotfiles (.hushlogin, .inputrc, .editorconfig, .nanorc) via chezmoi apply
  2. CLI tools (bat, lsd, btop, oh-my-posh) use chezmoi-managed configs without errors
  3. Window manager (aerospace) config deploys on macOS machines only
  4. Database tools (psql, sqlite) load chezmoi-managed configs
  5. Shell abbreviations (zsh-abbr) expand correctly after chezmoi apply
**Plans**: 3 plans

Plans:
- [x] 08-01-PLAN.md — Migrate all 13 configs to chezmoi source and update .chezmoiignore
- [x] 08-02-PLAN.md — Create verification check file and run full verification
- [x] 08-03-PLAN.md — Fix bat theme override (UAT gap closure)

#### Phase 9: Terminal Emulators
**Goal**: Migrate terminal emulator configs with cache exclusion patterns
**Depends on**: Phase 8
**Requirements**: TERM-01, TERM-02, TERM-03
**Success Criteria** (what must be TRUE):
  1. kitty terminal launches with chezmoi-managed configuration
  2. ghostty terminal launches with chezmoi-managed configuration
  3. wezterm terminal launches with chezmoi-managed configuration
  4. Terminal cache files do not trigger chezmoi diff changes
**Plans**: 2 plans

Plans:
- [x] 09-01-PLAN.md — Migrate 3 terminal emulator configs to chezmoi and update .chezmoiignore cache exclusions
- [x] 09-02-PLAN.md — Create verification check file and run full verification

#### Phase 10: Dev Tools with Secrets
**Goal**: Migrate development tool configs with Bitwarden secret integration
**Depends on**: Phase 9
**Requirements**: DEV-01, DEV-02, DEV-05, DEV-06, SEC-01
**Success Criteria** (what must be TRUE):
  1. lazygit loads chezmoi-managed configuration correctly
  2. atuin syncs shell history using Bitwarden-templated sync key
  3. aider uses API keys from environment variables (no embedded secrets)
  4. finicky browser routing works with chezmoi-managed config
  5. GPG agent uses OS-specific pinentry path from templated config
**Plans**: 2 plans

Plans:
- [x] 10-01-PLAN.md — Migrate 5 dev tool configs to chezmoi with gpg-agent OS-conditional template
- [x] 10-02-PLAN.md — Create verification check file and run full verification

#### Phase 11: Claude Code
**Goal**: Migrate Claude Code directory with selective sync and local state exclusion
**Depends on**: Phase 10
**Requirements**: CLAUDE-01, CLAUDE-02
**Success Criteria** (what must be TRUE):
  1. Claude Code commands and skills sync across machines via chezmoi apply
  2. Local settings (settings.local.json) never appear in chezmoi diff
  3. Cache and temporary files excluded from chezmoi tracking
  4. chezmoi diff completes in under 2 seconds with .claude/ tracked *(known gap: ~13s due to chezmoi scanning 491MB .claude/ directory — selective sync is correct, performance is a chezmoi architectural limitation)*
**Plans**: 2 plans

Plans:
- [x] 11-01-PLAN.md -- Migrate Claude Code synced configs to chezmoi with .chezmoiignore exclusions
- [x] 11-02-PLAN.md -- Create verification check and validate full migration

#### Phase 12: Dotbot Retirement
**Goal**: Complete removal of Dotbot infrastructure and deprecated configs
**Depends on**: Phase 11
**Requirements**: CLEAN-01, CLEAN-02, CLEAN-03
**Success Criteria** (what must be TRUE):
  1. No Dotbot symlinks remain in filesystem (find command returns empty)
  2. Dotbot infrastructure removed from repository (install script, steps/, submodules)
  3. Deprecated configs (nushell, zgenom) removed from repo and target
  4. chezmoi-only workflow documented in README
  5. Fresh chezmoi apply on clean machine deploys all configs correctly
**Plans**: 2 plans

Plans:
- [x] 12-01-PLAN.md — Remove deprecated configs (nushell, zgenom) and Dotbot infrastructure (submodules, install, steps)
- [x] 12-02-PLAN.md — Create verification check script and update README for chezmoi-only workflow

## Progress

**Execution Order:**
Phases execute in numeric order: 7 → 8 → 9 → 10 → 11 → 12

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
| 11. Claude Code | v1.1 | 2/2 | Complete* | 2026-02-12 |
| 12. Dotbot Retirement | v1.1 | 2/2 | Complete | 2026-02-12 |

*\* Phase 11 has 1 known gap: chezmoi diff takes ~13s (not <2s) due to scanning 491MB .claude/ directory. Selective sync implementation is correct; performance is a chezmoi architectural limitation.*

---
*Last updated: 2026-02-12 (v1.1 complete)*
